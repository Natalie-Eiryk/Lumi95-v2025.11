# =============================================================================
# FindTensorRT.cmake
# Tries config mode first (if available). Otherwise uses TENSORRT_ROOT to locate
# headers and libraries. Exposes imported targets:
#   TensorRT::nvinfer
#   TensorRT::nvinfer_plugin   (optional)
# =============================================================================

# Some vcpkg ports provide CONFIG; try it quietly first.
find_package(TensorRT CONFIG QUIET)
if(TensorRT_FOUND)
  # Targets: TensorRT::nvinfer, TensorRT::nvinfer_plugin
  return()
endif()

if(NOT TENSORRT_ROOT)
  if(NOT TensorRT_FIND_QUIETLY)
    message(STATUS "[FindTensorRT] TENSORRT_ROOT not set; config package not found.")
  endif()
  set(TensorRT_FOUND FALSE)
  return()
endif()

# Headers
find_path(TENSORRT_INCLUDE_DIR
  NAMES NvInfer.h NvInferVersion.h
  HINTS "${TENSORRT_ROOT}/include"
)

# Libs: platform variants
set(_TRT_LIB_DIRS
  "${TENSORRT_ROOT}/lib64"
  "${TENSORRT_ROOT}/lib"
  "${TENSORRT_ROOT}/targets/x86_64-linux-gnu/lib"
)
find_library(TENSORRT_LIB_NVINFER
  NAMES nvinfer
  HINTS ${_TRT_LIB_DIRS}
)
find_library(TENSORRT_LIB_NVINFER_PLUGIN
  NAMES nvinfer_plugin
  HINTS ${_TRT_LIB_DIRS}
)

include(FindPackageHandleStandardArgs)
# Require core nvinfer; plugin optional
find_package_handle_standard_args(TensorRT
  REQUIRED_VARS TENSORRT_INCLUDE_DIR TENSORRT_LIB_NVINFER
)

if(TensorRT_FOUND)
  if(NOT TARGET TensorRT::nvinfer)
    add_library(TensorRT::nvinfer UNKNOWN IMPORTED)
    set_target_properties(TensorRT::nvinfer PROPERTIES
      IMPORTED_LOCATION "${TENSORRT_LIB_NVINFER}"
      INTERFACE_INCLUDE_DIRECTORIES "${TENSORRT_INCLUDE_DIR}"
    )
  endif()

  if(TENSORRT_LIB_NVINFER_PLUGIN AND NOT TARGET TensorRT::nvinfer_plugin)
    add_library(TensorRT::nvinfer_plugin UNKNOWN IMPORTED)
    set_target_properties(TensorRT::nvinfer_plugin PROPERTIES
      IMPORTED_LOCATION "${TENSORRT_LIB_NVINFER_PLUGIN}"
      INTERFACE_INCLUDE_DIRECTORIES "${TENSORRT_INCLUDE_DIR}"
    )
  endif()
endif()
