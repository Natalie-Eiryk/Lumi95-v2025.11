# =============================================================================
# TopLevelInit.cmake
# Project-wide compiler policies, warning levels, LTO/IPO toggles, optional
# sanitizer flags, and CUDA arch hint. No env/vcpkg logic here.
# =============================================================================
include_guard(GLOBAL)

# Policies for modern behavior (as needed)
if(POLICY CMP0091)
  cmake_policy(SET CMP0091 NEW) # MSVC runtime library selection via CMAKE_MSVC_RUNTIME_LIBRARY
endif()
if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()

# C++ standard (you can leave this in root CMakeLists if you prefer one place)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Warnings
if(MSVC)
  add_compile_options(/W4 /permissive- /Zc:preprocessor /Zc:__cplusplus)
else()
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# IPO/LTO toggle
option(LUMI_ENABLE_LTO "Enable link-time optimization if supported" ON)
include(CheckIPOSupported)
if(LUMI_ENABLE_LTO)
  check_ipo_supported(RESULT _ipo_ok OUTPUT _ipo_msg)
  if(_ipo_ok)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
  else()
    message(STATUS "[Lumi][Init] IPO not supported: ${_ipo_msg}")
  endif()
endif()

# Sanitizers (opt-in)
option(LUMI_ENABLE_SANITIZERS "Enable Address/UB sanitizers (non-MSVC)" OFF)
if(LUMI_ENABLE_SANITIZERS AND NOT MSVC)
  add_compile_options(-fsanitize=address,undefined -fno-omit-frame-pointer)
  add_link_options(-fsanitize=address,undefined)
endif()

# CUDA arch hint (override via presets if desired)
if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES AND DEFINED LUMI_HAS_CUDA AND LUMI_HAS_CUDA)
  # Default to Ada (89) if not specified; adjust as needed
  set(CMAKE_CUDA_ARCHITECTURES 89 CACHE STRING "" FORCE)
endif()
