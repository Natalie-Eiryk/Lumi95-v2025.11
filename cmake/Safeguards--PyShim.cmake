# =============================================================================
# Create light "shims" to invoke the right Python for tools/pipelines.
# Exposes:
#   lumi_py_write_shim(<verHint> <name>)
#     -> writes ${LUMI_TOOLS_DIR}/py-<name>.cmd/.ps1 (Win) or .sh (*nix)
#        that invokes the chosen interpreter.
# =============================================================================
include_guard(GLOBAL)
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--Core.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--EnsurePythonMulti.cmake")

function(lumi_py_write_shim VERHINT NAME)
  if(NOT NAME)
    message(FATAL_ERROR "[Lumi][PYSHIM] NAME is required")
  endif()
  lumi_py_resolve("${VERHINT}" _exe _venv)

  if(NOT _exe)
    message(FATAL_ERROR "[Lumi][PYSHIM] Could not resolve Python for '${VERHINT}'")
  endif()

  if(WIN32)
    set(_cmd "${LUMI_TOOLS_DIR}/py-${NAME}.cmd")
    file(WRITE "${_cmd}" "@echo off\r\n\"${_exe}\" %*\r\n")
    set(_ps1 "${LUMI_TOOLS_DIR}/py-${NAME}.ps1")
    file(WRITE "${_ps1}" "param([Parameter(ValueFromRemainingArguments=\$true)][string[]]\$Args)\n& \"${_exe}\" \$Args\n")
    message(STATUS "[Lumi][PYSHIM] Wrote '${_cmd}' and '${_ps1}'")
  else()
    set(_sh "${LUMI_TOOLS_DIR}/py-${NAME}.sh")
    file(WRITE "${_sh}" "#!/usr/bin/env bash\n\"${_exe}\" \"$@\"\n")
    file(CHMOD "${_sh}" PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    message(STATUS "[Lumi][PYSHIM] Wrote '${_sh}'")
  endif()
endfunction()
