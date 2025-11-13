# =============================================================================
# Multi-Python manager: keep several versions side-by-side in repo
# Strategy:
#   - Prefer system interpreters (3.8..3.12). If missing and on Windows with
#     LUMI_AUTO_INSTALL=ON and online, install via winget (Python.Python.<MAJOR.MINOR>).
#   - Create/maintain per-version venv at: ${LUMI_DEPS_DIR}/python/<ver>
#   - Optionally install requirements file per version:
#       requirements-<ver>.txt (exact), else requirements-<major>.txt, else requirements.txt
# Exposes (functions):
#   lumi_py_resolve(<verHint> <out_exe> <out_venv> [INSTALL_REQS])
#       verHint: "3.8" | "3.10" | "3.11" | "3.12" | "latest" | ">=3.10,<3.12"
#   lumi_py_require(<verHint> <out_exe> [REQ_FILE <path>])
#       resolves + ensures requirements installed
# Global cache vars:
#   LUMI_PY_MANAGED_VERSIONS : list of versions prepared in repo
#   LUMI_PY_VERSION_CANDIDATES: default candidates (3.8;3.9;3.10;3.11;3.12)
# =============================================================================
include_guard(GLOBAL)
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--Core.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--Network.cmake")

if(NOT DEFINED LUMI_PY_VERSION_CANDIDATES)
  set(LUMI_PY_VERSION_CANDIDATES "3.8;3.9;3.10;3.11;3.12" CACHE STRING "Preferred Python versions in order")
endif()
set(LUMI_PY_MANAGED_VERSIONS "" CACHE STRING "Repo-managed Python venv versions" FORCE)

function(_pym_log m)  
message(STATUS   "[Lumi][PYM] ${m}") 
endfunction()
function(_pym_warn m) 
message(WARNING "[Lumi][PYM] ${m}") 
endfunction()

# Parse a version hint to a concrete preferred version string
function(_pym_pick_version VERHINT OUT_VER)
  set(_hint "${VERHINT}")
  if(_hint STREQUAL "latest")
    # choose highest available candidate
    list(GET LUMI_PY_VERSION_CANDIDATES -1 _v)
    set(${OUT_VER} "${_v}" PARENT_SCOPE)
    return()
  endif()

  if(_hint MATCHES "^>=([0-9]+\\.[0-9]+),<([0-9]+\\.[0-9]+)$")
    string(REGEX REPLACE "^>=([0-9]+\\.[0-9]+),<([0-9]+\\.[0-9]+)$" "\\1" _min "${_hint}")
    string(REGEX REPLACE "^>=([0-9]+\\.[0-9]+),<([0-9]+\\.[0-9]+)$" "\\2" _max "${_hint}")
    # pick highest candidate within [min, max)
    set(_picked "")
    foreach(_c ${LUMI_PY_VERSION_CANDIDATES})
      if(_c VERSION_GREATER_EQUAL "${_min}" AND _c VERSION_LESS "${_max}")
        set(_picked "${_c}")
      endif()
    endforeach()
    if(NOT _picked STREQUAL "")
      set(${OUT_VER} "${_picked}" PARENT_SCOPE)
      return()
    endif()
  endif()

  # exact major.minor
  set(${OUT_VER} "${_hint}" PARENT_SCOPE)
endfunction()

# Find a system interpreter for a given major.minor (best-effort)
function(_pym_find_system_py VER OUT_PATH)
  set(_ver "${VER}")
  if(WIN32)
    # py -<x.y> -c "import sys;print(sys.executable)"
    execute_process(COMMAND py -${_ver} -c "import sys;print(sys.executable)"
      OUTPUT_VARIABLE _path OUTPUT_STRIP_TRAILING_WHITESPACE RESULT_VARIABLE _rc)
    if(_rc EQUAL 0 AND EXISTS "${_path}")
      set(${OUT_PATH} "${_path}" PARENT_SCOPE)
      return()
    endif()
    # fallback: python3x in PATH (rare on Win)
    string(REPLACE "." "" _majmin "${_ver}")
    find_program(_cand NAMES python${_majmin}.exe)
    if(_cand)
      set(${OUT_PATH} "${_cand}" PARENT_SCOPE)
      return()
    endif()
  else()
    # typical unix: python3.x
    find_program(_cand NAMES python${_ver} python3.${_ver} python3)
    if(_cand)
      # verify version matches if generic python3
      execute_process(COMMAND "${_cand}" -c "import sys;print('.'.join(map(str,sys.version_info[:2])))"
        OUTPUT_VARIABLE _v OUT_STRIP_TRAILING_WHITESPACE RESULT_VARIABLE _rc)
      if(_rc EQUAL 0 AND (_v STREQUAL _ver))
        set(${OUT_PATH} "${_cand}" PARENT_SCOPE)
        return()
      elseif(_rc EQUAL 0 AND NOT "${_cand}" MATCHES "python3$")
        set(${OUT_PATH} "${_cand}" PARENT_SCOPE)
        return()
      endif()
    endif()
  endif()
  set(${OUT_PATH} "" PARENT_SCOPE)
endfunction()

# Optional install on Windows via winget when allowed and online
function(_pym_try_install_windows VER OUT_OK)
  set(${OUT_OK} OFF PARENT_SCOPE)
  if(NOT WIN32 OR NOT LUMI_AUTO_INSTALL)
    return()
  endif()
  lumi_net_check()
  if(NOT LUMI_NET_ONLINE)
    _pym_warn("Offline; cannot install Python ${VER}.")
    return()
  endif()
  set(_id "Python.Python.${VER}")
  _pym_log("Installing Python ${VER} via winget (${_id}) ...")
  execute_process(COMMAND powershell -NoProfile -ExecutionPolicy Bypass
    -Command "if (Get-Command winget -ErrorAction SilentlyContinue) { winget install --id ${_id} -e --source winget --silent; exit $LASTEXITCODE } else { exit 2 }"
    RESULT_VARIABLE _rc)
  if(_rc EQUAL 0)
    set(${OUT_OK} ON PARENT_SCOPE)
  else()
    _pym_warn("winget install failed rc=${_rc} for ${_id}")
  endif()
endfunction()

# Ensure per-version venv exists and optionally install requirements
function(_pym_ensure_venv PY_EXE VER OUT_EXE OUT_VENV INSTALL_REQS)
  set(_venv "${LUMI_DEPS_DIR}/python/${VER}")
  if(WIN32)
    set(_pybin "${_venv}/Scripts/python.exe")
    set(_pip   "${_venv}/Scripts/pip.exe")
  else()
    set(_pybin "${_venv}/bin/python")
    set(_pip   "${_venv}/bin/pip")
  endif()

  if(NOT EXISTS "${_pybin}")
    _pym_log("Creating venv for ${VER} at '${_venv}'")
    execute_process(COMMAND "${PY_EXE}" -m venv "${_venv}"
      RESULT_VARIABLE _rc OUTPUT_VARIABLE _o ERROR_VARIABLE _e)
    if(NOT _rc EQUAL 0)
      _pym_warn("Failed to create venv with ${PY_EXE}: ${_e}")
      set(${OUT_EXE} "" PARENT_SCOPE)
      set(${OUT_VENV} "" PARENT_SCOPE)
      return()
    endif()
  endif()

  # Upgrade pip
  execute_process(COMMAND "${_pybin}" -m pip install --upgrade pip
    RESULT_VARIABLE _rc OUTPUT_VARIABLE _o ERROR_VARIABLE _e)

  if(INSTALL_REQS)
    # requirements precedence
    set(_req "")
    if(EXISTS "${CMAKE_SOURCE_DIR}/requirements-${VER}.txt")
      set(_req "${CMAKE_SOURCE_DIR}/requirements-${VER}.txt")
    else()
      string(REGEX REPLACE "\\.[0-9]+$" "" _major "${VER}") # 3.10 -> 3
      if(EXISTS "${CMAKE_SOURCE_DIR}/requirements-${_major}.txt")
        set(_req "${CMAKE_SOURCE_DIR}/requirements-${_major}.txt")
      elseif(EXISTS "${CMAKE_SOURCE_DIR}/requirements.txt")
        set(_req "${CMAKE_SOURCE_DIR}/requirements.txt")
      endif()
    endif()

    if(_req)
      _pym_log("Installing requirements for ${VER} from '${_req}'")
      execute_process(COMMAND "${_pybin}" -m pip install -r "${_req}"
        RESULT_VARIABLE _rc OUTPUT_VARIABLE _o ERROR_VARIABLE _e)
      if(NOT _rc EQUAL 0)
        _pym_warn("Failed to install requirements for ${VER}: ${_e}")
      endif()
    endif()
  endif()

  # Persist
  set(${OUT_EXE}  "${_pybin}" PARENT_SCOPE)
  set(${OUT_VENV} "${_venv}"  PARENT_SCOPE)

  # Track managed versions
  set(_list "${LUMI_PY_MANAGED_VERSIONS}")
  list(FIND _list "${VER}" _idx)
  if(_idx EQUAL -1)
    list(APPEND _list "${VER}")
    set(LUMI_PY_MANAGED_VERSIONS "${_list}" CACHE STRING "" FORCE)
  endif()

  _pym_log("Python ${VER} ready: exe='${_pybin}' venv='${_venv}'")
endfunction()

# Public: resolve a Python version and provide repo-venv exe
function(lumi_py_resolve VERHINT OUT_EXE OUT_VENV)
  set(options INSTALL_REQS)
  set(oneValueArgs)
  set(multiValueArgs)
  cmake_parse_arguments(_ "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # ensure repo dirs
  if(NOT LUMI_DEPS_DIR)
    include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--Core.cmake")
  endif()

  _pym_pick_version("${VERHINT}" _want)
  _pym_log("Resolve Python: hint='${VERHINT}' -> want '${_want}'")

  # find or install a system Python for that version
  _pym_find_system_py("${_want}" _sys)
  if(NOT _sys AND WIN32 AND LUMI_AUTO_INSTALL)
    _pym_try_install_windows("${_want}" _ok)
    if(_ok)
      _pym_find_system_py("${_want}" _sys)
    endif()
  endif()

  if(NOT _sys)
    _pym_warn("System Python ${_want} not found. Provide it, or enable LUMI_AUTO_INSTALL (Windows) and reconfigure.")
    set(${OUT_EXE} "" PARENT_SCOPE)
    set(${OUT_VENV} "" PARENT_SCOPE)
    return()
  endif()

  _pym_ensure_venv("${_sys}" "${_want}" _exe _venv ${_.INSTALL_REQS})
  set(${OUT_EXE}  "${_exe}"  PARENT_SCOPE)
  set(${OUT_VENV} "${_venv}" PARENT_SCOPE)
endfunction()

# Public: resolve + enforce requirements (explicit file optional)
function(lumi_py_require VERHINT OUT_EXE)
  set(options)
  set(oneValueArgs REQ_FILE)
  set(multiValueArgs)
  cmake_parse_arguments(_ "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  lumi_py_resolve("${VERHINT}" _exe _venv INSTALL_REQS)
  if(_.REQ_FILE AND EXISTS "${_.REQ_FILE}" AND _exe)
    _pym_log("Installing explicit requirements for ${VERHINT} from '${_.REQ_FILE}'")
    execute_process(COMMAND "${_exe}" -m pip install -r "${_.REQ_FILE}"
      RESULT_VARIABLE _rc OUTPUT_VARIABLE _o ERROR_VARIABLE _e)
    if(NOT _rc EQUAL 0)
      _pym_warn("Explicit requirements failed: ${_e}")
    endif()
  endif()
  set(${OUT_EXE} "${_exe}" PARENT_SCOPE)
endfunction()
