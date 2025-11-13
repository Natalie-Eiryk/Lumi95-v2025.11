# =============================================================================
# vcpkg--bootstrap-toolchain.cmake
# Clone/Bootstrap vcpkg into ${VCPKG_ROOT} (defaults to ${SOURCE_DIR}/deps/vcpkg),
# set CMAKE_TOOLCHAIN_FILE to vcpkg.cmake if not already set by presets, and
# optionally run `vcpkg install` for the manifest in ${CMAKE_SOURCE_DIR}/vcpkg.json.
# =============================================================================
include_guard(GLOBAL)

function(_lumi_default VAR VAL)
  if(NOT DEFINED ${VAR} OR "${${VAR}}" STREQUAL "")
    set(${VAR} "${VAL}" PARENT_SCOPE)
  endif()
endfunction()

# Public entry point:
#   lumi_bootstrap_vcpkg(RUN_INSTALL ON|OFF)
function(lumi_bootstrap_vcpkg)
  set(options)
  set(oneValueArgs)
  set(multiValueArgs)
  cmake_parse_arguments(LBVP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # Respect pre-set VCPKG_ROOT; else default to in-repo deps
  if(DEFINED VCPKG_ROOT AND NOT VCPKG_ROOT STREQUAL "")
    set(_vcpkg_root "${VCPKG_ROOT}")
  else()
    set(_vcpkg_root "${CMAKE_SOURCE_DIR}/deps/vcpkg")
    set(VCPKG_ROOT "${_vcpkg_root}" CACHE PATH "vcpkg root" FORCE)
    set(ENV{VCPKG_ROOT} "${_vcpkg_root}")
  endif()

  # Determine triplet if needed (Gather usually handled this)
  if(NOT DEFINED VCPKG_TARGET_TRIPLET OR VCPKG_TARGET_TRIPLET STREQUAL "")
    if(WIN32)
      set(VCPKG_TARGET_TRIPLET "x64-windows" CACHE STRING "" FORCE)
    elseif(APPLE)
      set(VCPKG_TARGET_TRIPLET "arm64-osx" CACHE STRING "" FORCE)
    else()
      set(VCPKG_TARGET_TRIPLET "x64-linux" CACHE STRING "" FORCE)
    endif()
    set(VCPKG_DEFAULT_TRIPLET "${VCPKG_TARGET_TRIPLET}" CACHE STRING "" FORCE)
  endif()

  # Clone vcpkg if missing
  if(NOT EXISTS "${_vcpkg_root}/.git")
    message(STATUS "[Lumi][vcpkg] Cloning vcpkg into ${_vcpkg_root}")
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E make_directory "${_vcpkg_root}"
    )
    execute_process(
      COMMAND git clone --depth 1 https://github.com/microsoft/vcpkg.git "${_vcpkg_root}"
      RESULT_VARIABLE _clone_ec
    )
    if(NOT _clone_ec EQUAL 0)
      message(FATAL_ERROR "[Lumi][vcpkg] git clone failed (${_clone_ec})")
    endif()
  endif()

  # Bootstrap
  if(WIN32)
    set(_bootstrap "${_vcpkg_root}/bootstrap-vcpkg.bat")
  else()
    set(_bootstrap "${_vcpkg_root}/bootstrap-vcpkg.sh")
  endif()
  if(NOT EXISTS "${_bootstrap}")
    message(FATAL_ERROR "[Lumi][vcpkg] bootstrap script missing: ${_bootstrap}")
  endif()

  # Always ensure vcpkg binary exists; if not, run bootstrap
  if(NOT EXISTS "${_vcpkg_root}/vcpkg" AND NOT EXISTS "${_vcpkg_root}/vcpkg.exe")
    message(STATUS "[Lumi][vcpkg] Bootstrapping vcpkg...")
    if(WIN32)
      execute_process(COMMAND "${_bootstrap}" WORKING_DIRECTORY "${_vcpkg_root}" RESULT_VARIABLE _boot_ec)
    else()
      execute_process(COMMAND bash "${_bootstrap}" WORKING_DIRECTORY "${_vcpkg_root}" RESULT_VARIABLE _boot_ec)
    endif()
    if(NOT _boot_ec EQUAL 0)
      message(FATAL_ERROR "[Lumi][vcpkg] bootstrap failed with code ${_boot_ec}")
    endif()
  endif()

  # Toolchain wiring (guard if preset already set)
  if(NOT DEFINED CMAKE_TOOLCHAIN_FILE OR NOT CMAKE_TOOLCHAIN_FILE MATCHES "vcpkg.cmake$")
    set(CMAKE_TOOLCHAIN_FILE "${_vcpkg_root}/scripts/buildsystems/vcpkg.cmake" CACHE FILEPATH "vcpkg toolchain" FORCE)
  endif()

  # Ensure manifests features enabled
  if(NOT DEFINED VCPKG_FEATURE_FLAGS OR VCPKG_FEATURE_FLAGS STREQUAL "")
    set(VCPKG_FEATURE_FLAGS "manifests,versions" CACHE STRING "" FORCE)
  endif()

  # Optional install step (manifest mode uses ${CMAKE_SOURCE_DIR}/vcpkg.json)
  # If you want to skip installs, pass RUN_INSTALL OFF
  if(NOT DEFINED LBVP_UNPARSED_ARGUMENTS)
    set(_do_install ON)
  else()
    # Allow old style usage lumi_bootstrap_vcpkg(RUN_INSTALL ON)
    list(FIND LBVP_UNPARSED_ARGUMENTS "RUN_INSTALL" _idx)
    if(_idx GREATER -1)
      math(EXPR _val_idx "${_idx}+1")
      list(GET LBVP_UNPARSED_ARGUMENTS ${_val_idx} _flag)
      string(TOUPPER "${_flag}" _flag_up)
      set(_do_install ${_flag_up})
    else()
      set(_do_install ON)
    endif()
  endif()

  if(_do_install AND EXISTS "${CMAKE_SOURCE_DIR}/vcpkg.json")
    message(STATUS "[Lumi][vcpkg] Installing manifest dependencies for ${VCPKG_TARGET_TRIPLET} …")
    if(WIN32)
      set(_vcpkg_bin "${_vcpkg_root}/vcpkg.exe")
    else()
      set(_vcpkg_bin "${_vcpkg_root}/vcpkg")
    endif()
    execute_process(
      COMMAND "${_vcpkg_bin}" install --clean-after-build
              --triplet "${VCPKG_TARGET_TRIPLET}"
      WORKING_DIRECTORY "${_vcpkg_root}"
      RESULT_VARIABLE _inst_ec
    )
    if(NOT _inst_ec EQUAL 0)
      message(FATAL_ERROR "[Lumi][vcpkg] install failed with code ${_inst_ec}")
    endif()
  endif()

  message(STATUS "[Lumi][vcpkg] Ready (root='${_vcpkg_root}', triplet='${VCPKG_TARGET_TRIPLET}')")
endfunction()
