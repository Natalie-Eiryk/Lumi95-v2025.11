cmake_minimum_required(VERSION 3.21)
project(Lumi VERSION 1.0 LANGUAGES CXX)

# Make modules discoverable
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

# Run preflight
include(Safeguards--Entry)
include(Safeguards--EnsureOllama)
lumi_safeguards_prerun()

# Optional: turn ON to allow actual installs (safe default is OFF)
# cmake -DLUMI_AUTO_INSTALL=ON -S . -B out/build/lumi-win-msvc
option(LUMI_AUTO_INSTALL "Allow safeguards to install missing prerequisites" ON)




# 1) Gather environment first
include(EnvVars--GatherLumiEnv)
lumi_collect_env(
  PREFIXES       LUMI CUDA TENSORRT PHYSX QT VCPKG
  DEFAULT_ROOTS
    VCPKG    "${CMAKE_SOURCE_DIR}/deps/vcpkg"
    TENSORRT "${CMAKE_SOURCE_DIR}/deps/tensorrt"
    PHYSX    "${CMAKE_SOURCE_DIR}/deps/physx"
    QT       "${CMAKE_SOURCE_DIR}/deps/qt"
  OPTIONAL_PATHS QT_DIR CUDA_PATH
  AS_DEFINES     LUMI_ENV LUMI_RUN_MODE
  WRITE_HEADER   "${CMAKE_BINARY_DIR}/generated/LumiEnvConfig.h"
  AUGMENT_MODULE_PATH
)

# 2) Build init flags/policies
include(Compiler--Initialize)

# 3) Shape env-derived include/lib dirs
include(EnvVars--SetLumiEnv)

# 4) Bootstrap vcpkg and wire toolchain (manifest mode)
include(vcpkg--bootstrap-toolchain)
lumi_bootstrap_vcpkg(RUN_INSTALL ON)

# Set CMake policy for PHYSX_ROOT and TENSORRT_ROOT usage
cmake_policy(SET CMP0144 NEW)

# Ensure vcpkg_installed is in CMAKE_PREFIX_PATH (for manifest mode)
list(APPEND CMAKE_PREFIX_PATH "${CMAKE_SOURCE_DIR}/vcpkg_installed/${VCPKG_TARGET_TRIPLET}")

# Find required packages from vcpkg
find_package(yaml-cpp CONFIG QUIET)
find_package(nlohmann_json CONFIG QUIET)
find_package(GTest CONFIG QUIET)
find_package(Qt6 COMPONENTS Widgets OpenGL QUIET)

# Find optional SDKs (fallback via our Find*.cmake if config packages missing)
find_package(PhysX5 QUIET)       # our FindPhysX5.cmake
find_package(TensorRT QUIET)     # our FindTensorRT.cmake

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/CMakeLists.txt")
  add_subdirectory(src)
else()
  message(WARNING "[Lumi] src/CMakeLists.txt missing; skipping src subtree")
endif()
