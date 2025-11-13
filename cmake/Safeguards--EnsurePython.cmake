# =============================================================================
# Ensures a default repo-local Python is available.
# Wraps the multi-Python manager (lumi_py_resolve).
# Variables:
#   LUMI_PY_VERSION_HINT   (default 3.11)
#   LUMI_PY_REQUIREMENTS   (optional explicit requirements file; otherwise
#                           multi-manager falls back to its own rules)
# Exports:
#   LUMI_PYTHON_EXE
#   LUMI_PYTHON_VENV
# =============================================================================
include_guard(GLOBAL)
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--Core.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--EnsurePythonMulti.cmake")

if(NOT DEFINED LUMI_PY_VERSION_HINT)
  set(LUMI_PY_VERSION_HINT "3.11" CACHE STRING "Preferred default Python version")
endif()

# Optional explicit requirements override
if(NOT LUMI_PY_REQUIREMENTS)
  set(_default_req "${CMAKE_SOURCE_DIR}/requirements.txt")
  if(EXISTS "${_default_req}")
    set(LUMI_PY_REQUIREMENTS "${_default_req}" CACHE FILEPATH "Default requirements.txt" FORCE)
  endif()
endif()

function(lumi_sg_ensure_python)
  # If already set and exists, trust cache
  if(LUMI_PYTHON_EXE AND EXISTS "${LUMI_PYTHON_EXE}")
    lumi_sg_log("Python already configured: '${LUMI_PYTHON_EXE}'")
    return()
  endif()

  # Ensure one default Python via multi-manager
  lumi_py_resolve("${LUMI_PY_VERSION_HINT}" _exe _venv INSTALL_REQS)

  if(NOT _exe)
    lumi_sg_warn("Unable to establish repo-local Python for '${LUMI_PY_VERSION_HINT}'.")
    return()
  endif()

  # If an explicit requirements file is set, layer it on top
  if(LUMI_PY_REQUIREMENTS AND EXISTS "${LUMI_PY_REQUIREMENTS}")
    lumi_sg_log("Installing explicit requirements from '${LUMI_PY_REQUIREMENTS}'")
    execute_process(
      COMMAND "${_exe}" -m pip install -r "${LUMI_PY_REQUIREMENTS}"
      RESULT_VARIABLE _rc
      OUTPUT_VARIABLE _o
      ERROR_VARIABLE  _e
    )
    if(NOT _rc EQUAL 0)
      lumi_sg_warn("Explicit requirements install failed: ${_e}")
    endif()
  endif()

  set(LUMI_PYTHON_VENV "${_venv}" CACHE PATH "Repo-local Python venv" FORCE)
  set(LUMI_PYTHON_EXE  "${_exe}"  CACHE FILEPATH "Repo-local Python exe" FORCE)

  lumi_sg_log("Default Python ready: exe='${LUMI_PYTHON_EXE}' venv='${LUMI_PYTHON_VENV}'")
endfunction()
