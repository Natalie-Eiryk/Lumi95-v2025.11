# =============================================================================
# vcpkg--LumiVcpkg.cmake
# Optional thin wrappers around bootstrap; safe to delete if not needed.
# =============================================================================
include_guard(GLOBAL)

include("${CMAKE_SOURCE_DIR}/cmake/vcpkg--bootstrap-toolchain.cmake")

function(lumi_vcpkg_ensure)
  if(NOT EXISTS "${VCPKG_ROOT}/vcpkg" AND NOT EXISTS "${VCPKG_ROOT}/vcpkg.exe")
    lumi_bootstrap_vcpkg(RUN_INSTALL ON)
  endif()
endfunction()
