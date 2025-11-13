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
# =============================================================================
# Multi-Python manager: keep several versions side-by-side in repo
# Strategy:
#   - Prefer system interpreters (3.8..3.12). No reuse of Git candidates.
#   - Create/maintain per-version venv at: ${LUMI_DEPS_DIR}/python/<ver>
#   - Optionally install requirements file per version:
#       requirements-<ver>.txt (exact), else requirements-<major>.txt, else requirements.txt
# Exposes (functions):
#   lumi_py_resolve(<verHint> <out_exe> <out_venv> [INSTALL_REQS])
#       verHint: "3.8" | "3.10" | "3.11" | "3.12" | "latest"
#   lumi_py_write_shim(<verHint> <name>)
#   lumi_py_require(<verHint> <out_exe> [REQ_FILE <path>])
# Global cache vars:
#   LUMI_PY_MANAGED_VERSIONS : list of versions prepared in repo
#   LUMI_PY_VERSION_CANDIDATES: default candidates (3.8;3.9;3.10;3.11;3.12)
# =============================================================================
include_guard(GLOBAL)
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--Core.cmake")

# Defaults
if(NOT LUMI_PY_VERSION_CANDIDATES)
  set(LUMI_PY_VERSION_CANDIDATES "3.8;3.9;3.10;3.11;3.12"
      CACHE STRING "Candidate Python versions" FORCE)
endif()

# --- local logging wrappers ---------------------------------------------------
function(_pym_log m)
  lumi_sg_log("[py] ${m}")
endfunction()

function(_pym_warn m)
  lumi_sg_warn("[py] ${m}")
endfunction()

# --- find a system python for a given MAJOR.MINOR hint -----------------------
# _pym_find_python_for_ver("3.11" OUT_EXE)
function(_pym_find_python_for_ver VER OUT_EXE)
  set(_ver "${VER}")

  # Basic names; we deliberately DO NOT use lumi_sg_detect_exe to avoid
  # any Git-specific candidates ever leaking in here.
  set(_names python3 python)

  find_program(_cand NAMES ${_names})
  if(NOT _cand)
    _pym_warn("No python executable on PATH for hint '${_ver}'")
    set(${OUT_EXE} "" PARENT_SCOPE)
    return()
  endif()

  # Check version (best-effort; we still accept mismatches but warn)
  execute_process(
    COMMAND "${_cand}" -c "import sys; print('.'.join(map(str, sys.version_info[:2])))"
    RESULT_VARIABLE _rc
    OUTPUT_VARIABLE _out
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE _err
    ERROR_STRIP_TRAILING_WHITESPACE
  )

  if(NOT _rc EQUAL 0)
    _pym_warn("Version probe for '${_cand}' failed (rc=${_rc}): ${_err}")
    set(${OUT_EXE} "" PARENT_SCOPE)
    return()
  endif()

  if(NOT _out STREQUAL _ver)
    _pym_warn("Found python='${_cand}' with version '${_out}', not '${_ver}' (using anyway).")
  else()
    _pym_log("Found python '${_cand}' for version '${_ver}'")
  endif()

  set(${OUT_EXE} "${_cand}" PARENT_SCOPE)
endfunction()

# --- resolve & prepare a Python + venv ---------------------------------------
# lumi_py_resolve(<verHint> <out_exe> <out_venv> [INSTALL_REQS])
function(lumi_py_resolve VERHINT OUT_EXE OUT_VENV)
  set(options INSTALL_REQS)
  cmake_parse_arguments(LPR "${options}" "" "" ${ARGN})

  # Ensure repo dirs are set (Core does this once, but be defensive)
  if(NOT LUMI_DEPS_DIR)
    set(LUMI_DEPS_DIR "${CMAKE_SOURCE_DIR}/deps" CACHE PATH "" FORCE)
  endif()
  if(NOT LUMI_TOOLS_DIR)
    set(LUMI_TOOLS_DIR "${LUMI_DEPS_DIR}/tools" CACHE PATH "" FORCE)
  endif()

  set(_verhint "${VERHINT}")

  # Resolve "latest" to last candidate
  set(_ver "")
  if(_verhint STREQUAL "latest")
    set(_cands "${LUMI_PY_VERSION_CANDIDATES}")
    list(LENGTH _cands _len)
    if(_len GREATER 0)
      list(GET _cands -1 _ver)
    endif()
  else()
    set(_ver "${_verhint}")
  endif()

  if(NOT _ver)
    _pym_warn("No version resolved from hint '${_verhint}'")
    set(${OUT_EXE} "" PARENT_SCOPE)
    set(${OUT_VENV} "" PARENT_SCOPE)
    return()
  endif()

  # Try to find a system interpreter
  _pym_find_python_for_ver("${_ver}" _py_sys)
  if(NOT _py_sys)
    _pym_warn("No suitable Python found for '${_ver}'. Tools may not run.")
    set(${OUT_EXE} "" PARENT_SCOPE)
    set(${OUT_VENV} "" PARENT_SCOPE)
    return()
  endif()

  # venv location
  set(_venv "${LUMI_DEPS_DIR}/python/${_ver}")
  file(MAKE_DIRECTORY "${_venv}")

  if(WIN32)
    set(_pybin "${_venv}/Scripts/python.exe")
  else()
    set(_pybin "${_venv}/bin/python")
  endif()

  # Create venv if needed
  if(NOT EXISTS "${_pybin}")
    _pym_log("Creating Python venv for ${_ver} at '${_venv}' (base='${_py_sys}')")
    execute_process(
      COMMAND "${_py_sys}" -m venv "${_venv}"
      RESULT_VARIABLE _rc
      OUTPUT_VARIABLE _o
      ERROR_VARIABLE  _e
    )
    if(NOT _rc EQUAL 0)
      _pym_warn("Failed to create venv with '${_py_sys}'. rc=${_rc} stderr=${_e}")
      set(${OUT_EXE} "" PARENT_SCOPE)
      set(${OUT_VENV} "" PARENT_SCOPE)
      return()
    endif()
  endif()

  # Optionally install requirements
  if(LPR_INSTALL_REQS)
    # requirements-<full>.txt -> requirements-<major>.txt -> requirements.txt
    set(_req "")
    string(REGEX MATCH "^([0-9]+)" _major "${_ver}")
    set(_candidates
      "${CMAKE_SOURCE_DIR}/requirements-${_ver}.txt"
      "${CMAKE_SOURCE_DIR}/requirements-${_major}.txt"
      "${CMAKE_SOURCE_DIR}/requirements.txt"
    )
    foreach(r IN LISTS _candidates)
      if(EXISTS "${r}")
        set(_req "${r}")
        break()
      endif()
    endforeach()

    if(_req)
      _pym_log("Installing requirements for ${_ver} from '${_req}'")
      execute_process(
        COMMAND "${_pybin}" -m pip install -r "${_req}"
        RESULT_VARIABLE _rc
        OUTPUT_VARIABLE _o
        ERROR_VARIABLE  _e
      )
      if(NOT _rc EQUAL 0)
        _pym_warn("requirements install failed for ${_ver}: ${_e}")
      endif()
    else()
      _pym_log("No requirements file found for ${_ver} (skipping pip install)")
    endif()
  endif()

  # Track managed versions
  set(_list "${LUMI_PY_MANAGED_VERSIONS}")
  list(APPEND _list "${_ver}")
  list(REMOVE_DUPLICATES _list)
  set(LUMI_PY_MANAGED_VERSIONS "${_list}" CACHE STRING "Managed Python versions" FORCE)

  set(${OUT_EXE}  "${_pybin}" PARENT_SCOPE)
  set(${OUT_VENV} "${_venv}"  PARENT_SCOPE)
endfunction()

# --- write a small shim script for tooling -----------------------------------
# lumi_py_write_shim("3.11" "gen")
function(lumi_py_write_shim VERHINT NAME)
  lumi_py_resolve("${VERHINT}" _exe _venv)
  if(NOT _exe)
    _pym_warn("Cannot write Python shim '${NAME}': no interpreter for '${VERHINT}'")
    return()
  endif()

  if(NOT LUMI_TOOLS_DIR)
    set(LUMI_TOOLS_DIR "${LUMI_DEPS_DIR}/tools" CACHE PATH "" FORCE)
  endif()
  file(MAKE_DIRECTORY "${LUMI_TOOLS_DIR}")

  if(WIN32)
    set(_shim "${LUMI_TOOLS_DIR}/py-${NAME}.cmd")
    file(WRITE "${_shim}" "@echo off\r\n\"${_exe}\" %*\r\n")
  else()
    set(_shim "${LUMI_TOOLS_DIR}/py-${NAME}")
    file(WRITE "${_shim}" "#!/usr/bin/env bash\n\"${_exe}\" \"$@\"\n")
    # Best-effort chmod
    if(NOT WIN32)
      execute_process(COMMAND "${CMAKE_COMMAND}" -E chmod a+rx "${_shim}")
    endif()
  endif()

  _pym_log("Wrote Python shim '${NAME}' at '${_shim}' -> ${_exe}")
endfunction()

# --- convenience: resolve + explicit requirements file -----------------------
# lumi_py_require("3.11" LUMI_PY311_EXE REQ_FILE "${CMAKE_SOURCE_DIR}/tools/req.txt")
function(lumi_py_require VERHINT OUT_EXE)
  set(options)
  set(oneValueArgs REQ_FILE)
  set(multiValueArgs)
  cmake_parse_arguments(_ "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  lumi_py_resolve("${VERHINT}" _exe _venv INSTALL_REQS)
  if(_.REQ_FILE AND EXISTS "${_.REQ_FILE}" AND _exe)
    _pym_log("Installing explicit requirements for ${VERHINT} from '${_.REQ_FILE}'")
    execute_process(
      COMMAND "${_exe}" -m pip install -r "${_.REQ_FILE}"
      RESULT_VARIABLE _rc
      OUTPUT_VARIABLE _o
      ERROR_VARIABLE  _e
    )
    if(NOT _rc EQUAL 0)
      _pym_warn("Explicit requirements failed: ${_e}")
    endif()
  endif()

  set(${OUT_EXE} "${_exe}" PARENT_SCOPE)
endfunction()
