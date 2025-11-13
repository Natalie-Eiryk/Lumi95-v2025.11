# =============================================================================
# One-stop entry to perform preflight checks:
#   - Detect repo dirs
#   - Ensure Git
#   - Ensure Python + venv + requirements
#   - Ensure VS (Windows MSVC)
#   - Ensure vcpkg clone/bootstrap/install + set toolchain
# Call: lumi_safeguards_prerun()
# =============================================================================
include_guard(GLOBAL)
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--Core.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--EnsureGit.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--EnsurePython.cmake")
if(WIN32)
  include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--EnsureVS.cmake")
endif()
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--EnsureVcpkg.cmake")

function(lumi_safeguards_prerun)
   # New modules
include(Safeguards--HostProbe)
lumi_probe_host()
  # Git (detect / install)
  lumi_sg_ensure_git()
include(Safeguards--Network)
lumi_net_check()
include(Safeguards--EnsureCUDA)
lumi_sg_ensure_cuda(ARCHS "86;89") # or add REQUIRED if you want hard fail
include(Safeguards--EnsurePythonMulti)
include(Safeguards--PyShim)
  # Host banner (useful in logs)
  message(STATUS "[Lumi][SG] Host=${CMAKE_HOST_SYSTEM_NAME}/${CMAKE_HOST_SYSTEM_PROCESSOR}  CMake=${CMAKE_VERSION}  Generator='${CMAKE_GENERATOR}'")

  
  lumi_sg_ensure_python()
  if(WIN32)
    lumi_sg_ensure_vs()
  endif()
  lumi_sg_ensure_vcpkg()
endfunction()





# Prepare multiple Pythons (creates venvs and installs reqs)
# You can call these only when needed, or upfront:
#lumi_py_resolve("3.10" LUMI_PY310_EXE LUMI_PY310_VENV INSTALL_REQS)
#lumi_py_resolve("3.11" LUMI_PY311_EXE LUMI_PY311_VENV INSTALL_REQS)
# Write shims for tool pipelines
#lumi_py_write_shim("3.10" "build")
#lumi_py_write_shim("3.11" "gen")

# Later you can run Python steps reliably, e.g.:
# add_custom_target(lumi_codegen
#   COMMAND "${LUMI_PY311_EXE}" "${CMAKE_SOURCE_DIR}/tools/codegen.py" --out "${CMAKE_BINARY_DIR}/generated"
#   BYPRODUCTS "${CMAKE_BINARY_DIR}/generated/stubs.hpp"
#   COMMENT "[Lumi] Running code generator (py311)")