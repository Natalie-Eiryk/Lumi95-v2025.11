# =============================================================================
# EnvVars--GatherLumiEnv.cmake
# First-in module: detect host, normalize env/prefix variables, set in-repo
# defaults, create missing dirs, export to cache and process env, prime
# CMAKE_PREFIX_PATH (+ optionally CMAKE_MODULE_PATH), infer vcpkg triplet,
# optionally emit a header for runtime use.
# =============================================================================
include_guard(GLOBAL)
cmake_minimum_required(VERSION 3.21)

# ---------- helpers ----------
function(_lumi_norm_path OUT INP)
  if(NOT INP)
    set(${OUT} "" PARENT_SCOPE)
    return()
  endif()
  file(TO_CMAKE_PATH "${INP}" _np)
  get_filename_component(_abs "${_np}" ABSOLUTE BASE_DIR "${CMAKE_SOURCE_DIR}")
  set(${OUT} "${_abs}" PARENT_SCOPE)
endfunction()

function(_lumi_ensure_dir PATH_IN)
  if(PATH_IN)
    file(MAKE_DIRECTORY "${PATH_IN}")
  endif()
endfunction()

function(_lumi_cache_and_env NAME VAL TYPE DOC)
  # cache it (respect FORCE to keep it deterministic) and export to environment
  set(${NAME} "${VAL}" CACHE ${TYPE} "${DOC}" FORCE)
  set(ENV{${NAME}} "${VAL}")
endfunction()

function(_lumi_hint_prefix PREFIX_PATH ADD_TO_MODULE_PATH)
  if(NOT PREFIX_PATH)
    return()
  endif()
  list(APPEND CMAKE_PREFIX_PATH "${PREFIX_PATH}")
  set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
  if(ADD_TO_MODULE_PATH)
    list(APPEND CMAKE_MODULE_PATH "${PREFIX_PATH}")
    set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" PARENT_SCOPE)
  endif()
endfunction()

# ---------- host capability detection ----------
function(lumi_detect_host)
  if(WIN32)
    set(LUMI_HOST_OS "Windows")
  elseif(APPLE)
    set(LUMI_HOST_OS "macOS")
  elseif(UNIX)
    set(LUMI_HOST_OS "Linux")
  else()
    set(LUMI_HOST_OS "Unknown")
  endif()

  string(TOLOWER "${CMAKE_HOST_SYSTEM_PROCESSOR}" _proc)
  if(_proc MATCHES "amd64|x86_64")
    set(LUMI_HOST_CPU_ARCH "x86_64")
  elseif(_proc MATCHES "arm64|aarch64")
    set(LUMI_HOST_CPU_ARCH "arm64")
  else()
    set(LUMI_HOST_CPU_ARCH "${CMAKE_HOST_SYSTEM_PROCESSOR}")
  endif()

  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(LUMI_HOST_POINTER_BITS 64)
  else()
    set(LUMI_HOST_POINTER_BITS 32)
  endif()

  set(LUMI_COMPILER_ID  "${CMAKE_CXX_COMPILER_ID}")
  set(LUMI_COMPILER_VER "${CMAKE_CXX_COMPILER_VERSION}")

  set(LUMI_HAS_CUDA 0)
  find_package(CUDAToolkit QUIET)
  if(CUDAToolkit_FOUND)
    set(LUMI_HAS_CUDA 1)
  endif()

  set(LUMI_HOST_OS "${LUMI_HOST_OS}" CACHE STRING "Host OS" FORCE)
  set(LUMI_HOST_CPU_ARCH "${LUMI_HOST_CPU_ARCH}" CACHE STRING "Host CPU arch" FORCE)
  set(LUMI_HOST_POINTER_BITS "${LUMI_HOST_POINTER_BITS}" CACHE STRING "Pointer bits" FORCE)
  set(LUMI_COMPILER_ID "${LUMI_COMPILER_ID}" CACHE STRING "C++ compiler ID" FORCE)
  set(LUMI_COMPILER_VER "${LUMI_COMPILER_VER}" CACHE STRING "C++ compiler version" FORCE)
  set(LUMI_HAS_CUDA "${LUMI_HAS_CUDA}" CACHE BOOL "CUDA available" FORCE)
endfunction()

# ---------- main collector ----------
# Usage:
#   lumi_collect_env(
#     PREFIXES        LUMI CUDA TENSORRT PHYSX QT VCPKG
#     DEFAULT_ROOTS   VCPKG <path>  TENSORRT <path>  PHYSX <path>  QT <path>
#     OPTIONAL_PATHS  QT_DIR CUDA_PATH
#     REQUIRE_PATHS   # e.g. TENSORRT_ROOT PHYSX_ROOT
#     AS_DEFINES      LUMI_ENV LUMI_RUN_MODE
#     WRITE_HEADER    "${CMAKE_BINARY_DIR}/generated/LumiEnvConfig.h"
#     AUGMENT_MODULE_PATH  # if present, also add prefixes to CMAKE_MODULE_PATH
#   )
function(lumi_collect_env)
  set(options AUGMENT_MODULE_PATH)
  set(oneValueArgs WRITE_HEADER)
  set(multiValueArgs PREFIXES DEFAULT_ROOTS OPTIONAL_PATHS REQUIRE_PATHS AS_DEFINES)
  cmake_parse_arguments(LC "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT DEFINED LUMI_ENV_ALREADY_DETECTED)
    set(LUMI_ENV_ALREADY_DETECTED ON CACHE BOOL "" FORCE)
    lumi_detect_host()
  endif()

  set(_prefixes ${LC_PREFIXES})
  if(NOT _prefixes)
    set(_prefixes LUMI VCPKG QT CUDA TENSORRT PHYSX)
  endif()

  # map defaults <NAME;PATH;NAME;PATH...>
  set(_defaults)
   # --- Build flat defaults as NAME;PATH pairs (defensive against empty/odd lists)
  set(_defaults) # a list of 2-element lists: ("NAME;PATH" "NAME2;PATH2"...)

  list(LENGTH LC_DEFAULT_ROOTS _n)
  message(STATUS "[Lumi][Env] DEFAULT_ROOTS raw='${LC_DEFAULT_ROOTS}' (len=${_n})")

  if(_n GREATER 0)
    math(EXPR _last "${_n} - 1")
    foreach(_i RANGE 0 ${_last} 2)
      math(EXPR _j "${_i} + 1")
      if(_j LESS _n)
        list(GET LC_DEFAULT_ROOTS ${_i} _name)
        list(GET LC_DEFAULT_ROOTS ${_j} _path)
        list(APPEND _defaults "${_name};${_path}")
      else()
        message(WARNING "[Lumi][Env] DEFAULT_ROOTS has an odd number of items; ignoring trailing element at index ${_i}")
      endif()
    endforeach()
  endif()
  message(STATUS "[Lumi][Env] Parsed defaults='${_defaults}'")

  foreach(PFX IN LISTS _prefixes)
    set(_rootvar "${PFX}_ROOT")
    set(_root "")

    if(DEFINED ENV{${_rootvar}} AND NOT "$ENV{${_rootvar}}" STREQUAL "")
      _lumi_norm_path(_root "$ENV{${_rootvar}}")
    else()
      foreach(_pair IN LISTS _defaults)
        list(GET _pair 0 _n)
        list(GET _pair 1 _p)
        if("${_n}" STREQUAL "${PFX}")
          _lumi_norm_path(_root "${_p}")
        endif()
      endforeach()
      if(NOT _root)
        _lumi_norm_path(_root "${CMAKE_SOURCE_DIR}/deps/${PFX}")
      endif()
    endif()

    _lumi_ensure_dir("${_root}")
    _lumi_cache_and_env("${_rootvar}" "${_root}" PATH "Lumi ${PFX} root")
    _lumi_hint_prefix("${_root}" ${LC_AUGMENT_MODULE_PATH})
  endforeach()

  foreach(ENAME IN LISTS LC_OPTIONAL_PATHS)
    if(DEFINED ENV{${ENAME}} AND NOT "$ENV{${ENAME}}" STREQUAL "")
      _lumi_norm_path(_opt "$ENV{${ENAME}}")
      _lumi_cache_and_env("${ENAME}" "${_opt}" PATH "Optional hint ${ENAME}")
      _lumi_hint_prefix("${_opt}" ${LC_AUGMENT_MODULE_PATH})
    endif()
  endforeach()

  foreach(RQ IN LISTS LC_REQUIRE_PATHS)
    if(NOT DEFINED ${RQ} OR "${${RQ}}" STREQUAL "")
      message(FATAL_ERROR "[Lumi][Env] Required variable ${RQ} is not set/resolved.")
    endif()
  endforeach()

  # vcpkg triplet inference & priming
  if(DEFINED VCPKG_ROOT AND NOT VCPKG_ROOT STREQUAL "")
    if(NOT DEFINED VCPKG_TARGET_TRIPLET OR VCPKG_TARGET_TRIPLET STREQUAL "")
      if(WIN32 AND LUMI_HOST_CPU_ARCH STREQUAL "x86_64")
        set(_trip "x64-windows")
      elseif(APPLE AND LUMI_HOST_CPU_ARCH STREQUAL "arm64")
        set(_trip "arm64-osx")
      elseif(APPLE)
        set(_trip "x64-osx")
      elseif(UNIX AND LUMI_HOST_CPU_ARCH STREQUAL "x86_64")
        set(_trip "x64-linux")
      else()
        set(_trip "${LUMI_HOST_CPU_ARCH}-unknown")
      endif()
      _lumi_cache_and_env("VCPKG_TARGET_TRIPLET" "${_trip}" STRING "vcpkg triplet")
      _lumi_cache_and_env("VCPKG_DEFAULT_TRIPLET" "${_trip}" STRING "compat: default triplet")
    endif()
    set(_vcpkg_installed "${VCPKG_ROOT}/installed/${VCPKG_TARGET_TRIPLET}")
    _lumi_ensure_dir("${_vcpkg_installed}")
    _lumi_hint_prefix("${_vcpkg_installed}" FALSE)
  endif()

  if(LC_WRITE_HEADER)
    get_filename_component(_hdr_dir "${LC_WRITE_HEADER}" DIRECTORY)
    file(MAKE_DIRECTORY "${_hdr_dir}")
    file(WRITE  "${LC_WRITE_HEADER}" "/* Auto-generated by GatherLumiEnv */\n#pragma once\n\n")
    file(APPEND "${LC_WRITE_HEADER}" "#define LUMI_HOST_OS \"${LUMI_HOST_OS}\"\n")
    file(APPEND "${LC_WRITE_HEADER}" "#define LUMI_HOST_CPU_ARCH \"${LUMI_HOST_CPU_ARCH}\"\n")
    file(APPEND "${LC_WRITE_HEADER}" "#define LUMI_HOST_POINTER_BITS ${LUMI_HOST_POINTER_BITS}\n")
    file(APPEND "${LC_WRITE_HEADER}" "#define LUMI_COMPILER_ID \"${LUMI_COMPILER_ID}\"\n")
    file(APPEND "${LC_WRITE_HEADER}" "#define LUMI_COMPILER_VER \"${LUMI_COMPILER_VER}\"\n")
    file(APPEND "${LC_WRITE_HEADER}" "#define LUMI_HAS_CUDA ${LUMI_HAS_CUDA}\n")
    foreach(PFX IN LISTS _prefixes)
      file(APPEND "${LC_WRITE_HEADER}" "#define ${PFX}_ROOT \"${${PFX}_ROOT}\"\n")
    endforeach()
  endif()

  foreach(DEF IN LISTS LC_AS_DEFINES)
    if(DEFINED ${DEF} AND NOT "${${DEF}}" STREQUAL "")
      add_compile_definitions(${DEF}="${${DEF}}")
    endif()
  endforeach()

  message(STATUS "[Lumi][Env] Host=${LUMI_HOST_OS}/${LUMI_HOST_CPU_ARCH}  CXX=${LUMI_COMPILER_ID} ${LUMI_COMPILER_VER}  CUDA=${LUMI_HAS_CUDA}")
  if(DEFINED VCPKG_ROOT)
    message(STATUS "[Lumi][Env] vcpkg: root='${VCPKG_ROOT}', triplet='${VCPKG_TARGET_TRIPLET}'")
  endif()
endfunction()

# ---------- apply env include/lib/defines to a target ----------
function(lumi_apply_env_to_target tgt)
  set(options)
  set(oneValueArgs)
  set(multiValueArgs INCLUDE_VARS LIB_VARS DEFINE_VARS)
  cmake_parse_arguments(LAT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  foreach(V IN LISTS LAT_INCLUDE_VARS)
    if(DEFINED ${V} AND NOT "${${V}}" STREQUAL "")
      target_include_directories(${tgt} PRIVATE "${${V}}")
    endif()
  endforeach()

  foreach(V IN LISTS LAT_LIB_VARS)
    if(DEFINED ${V} AND NOT "${${V}}" STREQUAL "")
      target_link_directories(${tgt} PRIVATE "${${V}}")
    endif()
  endforeach()

  foreach(V IN LISTS LAT_DEFINE_VARS)
    if(DEFINED ${V} AND NOT "${${V}}" STREQUAL "")
      target_compile_definitions(${tgt} PRIVATE ${V}="${${V}}")
    endif()
  endforeach()
endfunction()
