# =============================================================================
# FindPhysX5.cmake
# Tries config mode first (vcpkg provides physx CONFIG). Falls back to PHYSX_ROOT
# and creates an imported target PhysX::PhysX if needed.
# =============================================================================

# Try config package (preferred)
find_package(physx CONFIG QUIET)
if(physx_FOUND)
  # Typically defines PhysX::PhysX (and others). Done.
  set(PhysX5_FOUND TRUE)
  return()
endif()

# Fallback to a manual find using PHYSX_ROOT
if(NOT PHYSX_ROOT)
  set(PhysX5_FOUND FALSE)
  if(NOT PhysX5_FIND_QUIETLY)
    message(STATUS "[FindPhysX5] PHYSX_ROOT not set; config package not found.")
  endif()
  return()
endif()

# Headers
find_path(PHYSX5_INCLUDE_DIR
  NAMES PxConfig.h PxPhysicsAPI.h
  HINTS "${PHYSX_ROOT}/include" "${PHYSX_ROOT}/sdk/include"
)

# Lib dir
set(_PHYSX_LIB_DIRS
  "${PHYSX_ROOT}/lib"
  "${PHYSX_ROOT}/lib64"
  "${PHYSX_ROOT}/lib/vc16win64"
  "${PHYSX_ROOT}/sdk/bin/win.x86_64.vc142.mt/debug"
  "${PHYSX_ROOT}/sdk/bin/win.x86_64.vc142.mt/release"
)
find_library(PHYSX5_CORE_LIB
  NAMES PhysX_64 PhysX PhysX_static_64
  HINTS ${_PHYSX_LIB_DIRS}
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(PhysX5
  REQUIRED_VARS PHYSX5_INCLUDE_DIR PHYSX5_CORE_LIB
)

if(PhysX5_FOUND AND NOT TARGET PhysX::PhysX)
  add_library(PhysX::PhysX UNKNOWN IMPORTED)
  set_target_properties(PhysX::PhysX PROPERTIES
    IMPORTED_LOCATION "${PHYSX5_CORE_LIB}"
    INTERFACE_INCLUDE_DIRECTORIES "${PHYSX5_INCLUDE_DIR}"
  )
endif()
