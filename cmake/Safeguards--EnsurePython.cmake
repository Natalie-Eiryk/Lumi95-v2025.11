# =============================================================================
# Ensures a repo-local Python is available (prefers system python, then winget).
# Creates a venv under deps/python if possible and installs requirements.txt.
# Variables:
#   LUMI_PY_VERSION_HINT   (default 3.11)
#   LUMI_PY_REQUIREMENTS   (default ${CMAKE_SOURCE_DIR}/requirements.txt if exists)
# =============================================================================
include_guard(GLOBAL)
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--Core.cmake")

if(NOT DEFINED LUMI_PY_VERSION_HINT)
  set(LUMI_PY_VERSION_HINT "3.11" CACHE STRING "Preferred Python version")
endif()

set(_default_req "${CMAKE_SOURCE_DIR}/requirements.txt")
if(EXISTS "${_default_req}")
  set(LUMI_PY_REQUIREMENTS "${_default_req}" CACHE FILEPATH "Python requirements file" FORCE)
else()
  set(LUMI_PY_REQUIREMENTS "" CACHE FILEPATH "Python requirements file")
endif()

function(lumi_sg_ensure_python)
  # Try python on PATH
if(WIN32)
  lumi_sg_detect_exe(
    NAME    Python
    OUT_VAR PY_EXE
    NAMES   py python
    REQUIRED
  )
else()
  lumi_sg_detect_exe(
    NAME    Python
    OUT_VAR PY_EXE
    NAMES   python3 python
    REQUIRED
  )
endif()

  # 2) If missing and allowed, try winget on Windows
  if(NOT PY_EXE AND WIN32 AND LUMI_AUTO_INSTALL)
    lumi_sg_log("Attempting Python ${LUMI_PY_VERSION_HINT} via winget...")
    set(_id "Python.Python.${LUMI_PY_VERSION_HINT}")
    lumi_sg_ps(-Command "if (Get-Command winget -ErrorAction SilentlyContinue) { winget install --id ${_id} -e --source winget --silent; exit $LASTEXITCODE } else { exit 2 }")
    if(LUMI_SG_LAST_RC EQUAL 0)
      # try again
      lumi_sg_detect_exe(PY_EXE PY_VER "Python" py python python3)
    endif()
  endif()

  if(NOT PY_EXE)
    lumi_sg_warn("Python not found. Please install Python ${LUMI_PY_VERSION_HINT} and reconfigure.")
    return()
  endif()

  # 3) Create a repo-local venv under deps/python
  set(_venv "${LUMI_DEPS_DIR}/python")
  if(WIN32)
    set(_pip "${_venv}/Scripts/pip.exe")
    set(_pybin "${_venv}/Scripts/python.exe")
  else()
    set(_pip "${_venv}/bin/pip")
    set(_pybin "${_venv}/bin/python")
  endif()

  if(NOT EXISTS "${_pybin}")
    lumi_sg_log("Creating Python venv at '${_venv}'")
    execute_process(COMMAND "${PY_EXE}" -m venv "${_venv}"
      RESULT_VARIABLE _rc OUTPUT_VARIABLE _o ERROR_VARIABLE _e)
    if(NOT _rc EQUAL 0)
      lumi_sg_warn("Failed to create venv with '${PY_EXE}'. stdout=${_o} stderr=${_e}")
      return()
    endif()
  endif()

  # 4) Upgrade pip and install requirements (if provided)
  execute_process(COMMAND "${_pybin}" -m pip install --upgrade pip
    RESULT_VARIABLE _rc OUTPUT_VARIABLE _o ERROR_VARIABLE _e)
  if(NOT _rc EQUAL 0)
    lumi_sg_warn("pip upgrade failed: ${_e}")
  endif()

  if(LUMI_PY_REQUIREMENTS AND EXISTS "${LUMI_PY_REQUIREMENTS}")
    lumi_sg_log("Installing requirements from '${LUMI_PY_REQUIREMENTS}'")
    execute_process(COMMAND "${_pybin}" -m pip install -r "${LUMI_PY_REQUIREMENTS}"
      RESULT_VARIABLE _rc OUTPUT_VARIABLE _o ERROR_VARIABLE _e)
    if(NOT _rc EQUAL 0)
      lumi_sg_warn("requirements install failed: ${_e}")
    endif()
  endif()

  # Export for other modules
  set(LUMI_PYTHON_VENV "${_venv}" CACHE PATH "Repo-local Python venv" FORCE)
  set(LUMI_PYTHON_EXE  "${_pybin}" CACHE FILEPATH "Repo-local Python exe" FORCE)

  lumi_sg_log("Python ready: exe='${LUMI_PYTHON_EXE}' venv='${LUMI_PYTHON_VENV}'")
endfunction()
