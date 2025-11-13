# =============================================================================
# EnvVars--SetLumiEnv.cmake
# Shape-only helpers: derive include/lib directories from *_ROOT hints gathered
# earlier. No discovery, no dir creation, no vcpkg logic here.
# =============================================================================
include_guard(GLOBAL)

# TensorRT
if(TENSORRT_ROOT AND NOT TARGET TensorRT::nvinfer)
  set(TENSORRT_INCLUDE_DIRS "${TENSORRT_ROOT}/include" CACHE PATH "TensorRT includes" FORCE)
  # libs usually under lib or lib64 depending on platform
  if(EXISTS "${TENSORRT_ROOT}/lib64")
    set(TENSORRT_LIBRARY_DIRS "${TENSORRT_ROOT}/lib64" CACHE PATH "TensorRT libs" FORCE)
  else()
    set(TENSORRT_LIBRARY_DIRS "${TENSORRT_ROOT}/lib" CACHE PATH "TensorRT libs" FORCE)
  endif()
endif()

# PhysX (local layout may vary; adjust if needed)
if(PHYSX_ROOT AND NOT TARGET PhysX::PhysX)
  # Common built trees place headers under include; lib under lib
  set(PHYSX_INCLUDE_DIRS "${PHYSX_ROOT}/include" CACHE PATH "PhysX includes" FORCE)
  if(EXISTS "${PHYSX_ROOT}/lib64")
    set(PHYSX_LIBRARY_DIRS "${PHYSX_ROOT}/lib64" CACHE PATH "PhysX libs" FORCE)
  else()
    set(PHYSX_LIBRARY_DIRS "${PHYSX_ROOT}/lib" CACHE PATH "PhysX libs" FORCE)
  endif()
endif()
