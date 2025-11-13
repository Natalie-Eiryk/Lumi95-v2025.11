cmake_minimum_required(VERSION 3.21)
project(Lumi VERSION 1.0 LANGUAGES CXX)

# Make modules discoverable
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

# Run preflight
include(Safeguards--Entry)
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

# Example library/target
add_library(MyCore src/my_core.cpp)
lumi_apply_env_to_target(MyCore
  INCLUDE_VARS TENSORRT_INCLUDE_DIRS PHYSX_INCLUDE_DIRS
  LIB_VARS     TENSORRT_LIBRARY_DIRS PHYSX_LIBRARY_DIRS
  DEFINE_VARS  LUMI_RUN_MODE LUMI_ENV
)

add_executable(lumi_app src/main/main.cpp)
target_link_libraries(lumi_app PRIVATE MyCore)

# Optional: use CONFIG packages from vcpkg
find_package(yaml-cpp CONFIG QUIET)
if(yaml-cpp_FOUND)
  target_link_libraries(lumi_app PRIVATE yaml-cpp)
endif()
find_package(nlohmann_json CONFIG QUIET)
if(nlohmann_json_FOUND)
  target_link_libraries(lumi_app PRIVATE nlohmann_json::nlohmann_json)
endif()
find_package(GTest CONFIG QUIET)
if(GTest_FOUND)
  target_link_libraries(lumi_app PRIVATE GTest::gtest)
endif()
find_package(Qt6 COMPONENTS Widgets OpenGL QUIET)
if(Qt6_FOUND)
  target_link_libraries(lumi_app PRIVATE Qt6::Widgets Qt6::OpenGL)
endif()

# Optional SDKs (fallback via our Find*.cmake if config packages missing)
find_package(PhysX5 QUIET)       # our FindPhysX5.cmake
find_package(TensorRT QUIET)     # our FindTensorRT.cmake
if(PhysX5_FOUND)
  target_link_libraries(lumi_app PRIVATE PhysX::PhysX)
endif()
if(TensorRT_FOUND)
  target_link_libraries(lumi_app PRIVATE TensorRT::nvinfer)
  if(TARGET TensorRT::nvinfer_plugin)
    target_link_libraries(lumi_app PRIVATE TensorRT::nvinfer_plugin)
  endif()
endif()

add_subdirectory(src)
