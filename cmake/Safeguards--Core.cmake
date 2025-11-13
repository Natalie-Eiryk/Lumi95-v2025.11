# =============================================================================
# Lumi Safeguards - Core helpers
# -----------------------------------------------------------------------------
# Provides: 
#   - lumi_sg_repo_dirs(...)      -> establish repo-local dirs (deps, logs, tools)
#   - lumi_sg_write_ps(name code) -> write a PowerShell helper to ${LUMI_TOOLS_DIR}
#   - lumi_sg_ps(args...)         -> run PowerShell (NoProfile, Bypass)
#   - lumi_sg_detect_exe(var name candidates...) -> find executable and version
#   - lumi_sg_log(msg)            -> consistent status logging
#   - lumi_sg_warn(msg)           -> consistent warning logging
# Flags:
#   -DLUMI_AUTO_INSTALL=ON         -> enable installations (default OFF)
# =============================================================================

# =============================================================================
# Safeguards Core helpers (logging, path detection, run cmd)
# =============================================================================
include_guard(GLOBAL)

# --- logging ---------------------------------------------------------------
function(lumi_sg_log m)   
message(STATUS   "[Lumi][SG] ${m}") 
endfunction()

function(lumi_sg_warn m)  
message(WARNING "[Lumi][SG] ${m}") 
endfunction()
function(lumi_sg_fail m)  
message(FATAL_ERROR "[Lumi][SG] ${m}")
endfunction()

# --- once-only repo dirs banner -------------------------------------------
if(NOT DEFINED _LUMI_SG_BANNER)
  set(_LUMI_SG_BANNER ON CACHE INTERNAL "")
  # Workspace layout (already created by entry)
  if(NOT LUMI_DEPS_DIR)  
  set(LUMI_DEPS_DIR  
  "${CMAKE_SOURCE_DIR}/deps"   CACHE PATH "" FORCE) 
  endif()
  if(NOT LUMI_TOOLS_DIR) 
  set(LUMI_TOOLS_DIR 
  "${LUMI_DEPS_DIR}/tools"      CACHE PATH "" FORCE) 
  endif()
  if(NOT LUMI_LOG_DIR)   
  set(LUMI_LOG_DIR  
  "${CMAKE_BINARY_DIR}/_logs"   CACHE PATH "" FORCE) 
  endif()
  file(MAKE_DIRECTORY "${LUMI_DEPS_DIR}" "${LUMI_TOOLS_DIR}" "${LUMI_LOG_DIR}")
  lumi_sg_log("Repo dirs: deps='${LUMI_DEPS_DIR}', tools='${LUMI_TOOLS_DIR}', logs='${LUMI_LOG_DIR}'")
endif()

# --- utility: normalize a list (filter empty, make unique, keep order) ----
function(lumi_sg_filter_paths OUT)
  set(_accum "")
  foreach(p IN LISTS ARGN)
    if(NOT p STREQUAL "" AND EXISTS "${p}")
      list(APPEND _accum "${p}")
    endif()
  endforeach()
  if(_accum)
    list(REMOVE_DUPLICATES _accum)
  endif()
  set(${OUT} "${_accum}" PARENT_SCOPE)
endfunction()

# --- utility: detect executable with built-in defaults ---------------------
# Usage:
#   lumi_sg_detect_exe(
#     NAME Git
#     OUT_VAR GIT_EXE
#     CANDIDATES <list...>        # optional; if omitted, uses platform defaults
#     HINTS <list...>             # optional extra dirs to probe
#     NAMES git.exe git           # optional alternative names
#     REQUIRED                    # optional; fatal if not found
#   )
function(lumi_sg_detect_exe)
  cmake_parse_arguments(LSDE "REQUIRED" "NAME;OUT_VAR" "CANDIDATES;HINTS;NAMES" ${ARGN})

  if(NOT LSDE_NAME)
    lumi_sg_fail("lumi_sg_detect_exe: missing NAME")
  endif()
  if(NOT LSDE_OUT_VAR)
    lumi_sg_fail("lumi_sg_detect_exe: missing OUT_VAR")
  endif()

  # 1) user-supplied candidates (may be empty)
  set(_cands ${LSDE_CANDIDATES})

  # 2) platform defaults if not provided
  if(NOT _cands)
    if(WIN32)
      set(_cands
        "$ENV{GIT_EXE}"
        "$ENV{ProgramFiles}/Git/bin/git.exe"
        "$ENV{ProgramFiles}/Git/cmd/git.exe"
        "$ENV{ProgramFiles\(x86\)}/Git/bin/git.exe"
        "$ENV{ProgramFiles\(x86\)}/Git/cmd/git.exe"
        # Visual Studio bundled Git (Community/Professional/Enterprise)
        "$ENV{ProgramFiles}/Microsoft Visual Studio/2022/Community/Common7/IDE/CommonExtensions/Microsoft/TeamFoundation/Team Explorer/Git/cmd/git.exe"
        "$ENV{ProgramFiles}/Microsoft Visual Studio/2022/Professional/Common7/IDE/CommonExtensions/Microsoft/TeamFoundation/Team Explorer/Git/cmd/git.exe"
        "$ENV{ProgramFiles}/Microsoft Visual Studio/2022/Enterprise/Common7/IDE/CommonExtensions/Microsoft/TeamFoundation/Team Explorer/Git/cmd/git.exe"
        # VS Installer Git (Preview paths included)
        "$ENV{ProgramFiles}/Microsoft Visual Studio/2022/Preview/Common7/IDE/CommonExtensions/Microsoft/TeamFoundation/Team Explorer/Git/cmd/git.exe"
      )
      # PATH probe as a last resort
      find_program(_git_from_path git)
      if(_git_from_path)
        list(APPEND _cands "${_git_from_path}")
      endif()
    elseif(APPLE)
      set(_cands
        "/usr/local/bin/git" "/opt/homebrew/bin/git" "/usr/bin/git"
      )
      find_program(_git_from_path git)
      if(_git_from_path) 
      list(APPEND _cands "${_git_from_path}") 
      endif()
    else() # Linux/Unix
      set(_cands "/usr/bin/git" "/usr/local/bin/git")
      find_program(_git_from_path git)
      if(_git_from_path) 
      list(APPEND _cands "${_git_from_path}") 
      endif()
    endif()
  endif()

  # 3) extra hints
  if(LSDE_HINTS)
    list(APPEND _cands ${LSDE_HINTS})
  endif()

  # 4) alternate names (if user supplied)
  set(_names git)
  if(LSDE_NAMES)
    set(_names ${LSDE_NAMES})
  endif()

  # 5) resolve list
  set(_hits "")
  foreach(c IN LISTS _cands)
    if(EXISTS "${c}")
      list(APPEND _hits "${c}")
    else()
      # Try combining candidate directories with alt names if c looks like a dir
      if(IS_DIRECTORY "${c}")
        foreach(n IN LISTS _names)
          if(EXISTS "${c}/${n}")
            list(APPEND _hits "${c}/${n}")
          endif()
        endforeach()
      endif()
    endif()
  endforeach()

  if(_hits)
    list(GET _hits 0 _pick)
    set(${LSDE_OUT_VAR} "${_pick}" CACHE FILEPATH "${LSDE_NAME} executable" FORCE)
    lumi_sg_log("${LSDE_NAME} found: ${_pick}")
    return()
  endif()

  if(LSDE_REQUIRED)
    lumi_sg_fail("lumi_sg_detect_exe: ${LSDE_NAME} not found. Candidates probed: ${_cands}")
  else()
    set(${LSDE_OUT_VAR} "" CACHE FILEPATH "${LSDE_NAME} executable" FORCE)
    lumi_sg_warn("${LSDE_NAME} not found (optional).")
  endif()
endfunction()

# --- run a command and capture stdout/stderr -------------------------------
# lumi_sg_run(NAME "Git" CMD <git> ARGS <...> OUT_VAR <var> [ALLOW_FAIL])
function(lumi_sg_run)
  cmake_parse_arguments(LSR "ALLOW_FAIL" "NAME;CMD;OUT_VAR" "ARGS" ${ARGN})
  if(NOT LSR_CMD)     
  lumi_sg_fail("lumi_sg_run: missing CMD")       
  endif()
  if(NOT LSR_NAME)    
  set(LSR_NAME "cmd")                            
  endif()
  if(NOT LSR_OUT_VAR) 
  set(LSR_OUT_VAR "_OUT")                        
  endif()
  execute_process(COMMAND "${LSR_CMD}" ${LSR_ARGS}
    RESULT_VARIABLE _rc
    OUTPUT_VARIABLE _out
    ERROR_VARIABLE  _err
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
  )
  if(NOT _rc EQUAL 0 AND NOT LSR_ALLOW_FAIL)
    lumi_sg_fail("${LSR_NAME} failed (rc=${_rc}). stderr: ${_err}")
  endif()
  set(${LSR_OUT_VAR} "${_out}" PARENT_SCOPE)
endfunction()
