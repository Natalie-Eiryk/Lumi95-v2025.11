# =============================================================================
# Ensures repo-local vcpkg clone + bootstrap + manifest install.
# Respects LUMI_AUTO_INSTALL.
# Variables:
#   LUMI_VCPKG_DIR  (default: ${LUMI_DEPS_DIR}/vcpkg)
#   VCPKG_TARGET_TRIPLET (default: x64-windows on Win, x64-linux on Linux, x64-osx on macOS)
#   VCPKG_FEATURE_FLAGS (default: manifests,versions)
# =============================================================================
include_guard(GLOBAL)
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--Core.cmake")

if(NOT DEFINED VCPKG_FEATURE_FLAGS)
  set(VCPKG_FEATURE_FLAGS "manifests,versions" CACHE STRING "vcpkg feature flags")
endif()

if(NOT DEFINED VCPKG_TARGET_TRIPLET)
  if(WIN32)
    set(_trip "x64-windows")
  elseif(APPLE)
    set(_trip "x64-osx")
  else()
    set(_trip "x64-linux")
  endif()
  set(VCPKG_TARGET_TRIPLET "${_trip}" CACHE STRING "vcpkg triplet")
endif()

function(lumi_sg_ensure_vcpkg)
    if(NOT DEFINED LUMI_VCPKG_DIR)
    set(LUMI_VCPKG_DIR "${LUMI_DEPS_DIR}/vcpkg" CACHE PATH "Repo-local vcpkg directory" FORCE)
  endif()

  # 1) Ensure Git present
  include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--EnsureGit.cmake")
  lumi_sg_ensure_git()

  # 2) Clone or update vcpkg registry
  if(NOT EXISTS "${LUMI_VCPKG_DIR}/.git")
    if(NOT LUMI_AUTO_INSTALL)
      lumi_sg_warn("vcpkg missing at '${LUMI_VCPKG_DIR}'. Reconfigure with -DLUMI_AUTO_INSTALL=ON to auto-clone, or clone manually.")
      return()
    endif()
    lumi_sg_log("Cloning vcpkg to '${LUMI_VCPKG_DIR}' ...")
    execute_process(COMMAND "${GIT_EXECUTABLE}" clone https://github.com/microsoft/vcpkg.git "${LUMI_VCPKG_DIR}"
      RESULT_VARIABLE _rc OUTPUT_VARIABLE _o ERROR_VARIABLE _e)
    if(NOT _rc EQUAL 0)
      lumi_sg_warn("git clone vcpkg failed: ${_e}")
      return()
    endif()
  else()
    lumi_sg_log("Updating vcpkg registry ...")
    set(_have_net TRUE)
    if(DEFINED LUMI_NET_ONLINE)
      set(_have_net ${LUMI_NET_ONLINE})
    endif()
    if(NOT _have_net)
      lumi_sg_log("Host reported offline; skipping vcpkg fetch/reset and using existing registry state.")
    else()
      execute_process(COMMAND "${GIT_EXECUTABLE}" -C "${LUMI_VCPKG_DIR}" fetch --all --tags
        RESULT_VARIABLE _rc1 OUTPUT_VARIABLE _o1 ERROR_VARIABLE _e1)
      if(NOT _rc1 EQUAL 0)
        lumi_sg_warn("git fetch for vcpkg failed: ${_e1}")
      endif()
      execute_process(COMMAND "${GIT_EXECUTABLE}" -C "${LUMI_VCPKG_DIR}" reset --hard origin/master
        RESULT_VARIABLE _rc2 OUTPUT_VARIABLE _o2 ERROR_VARIABLE _e2)
      if(NOT _rc2 EQUAL 0)
        lumi_sg_warn("git reset for vcpkg failed: ${_e2}")
      endif()
    endif()
  endif()

  # 3) Bootstrap vcpkg (if needed)
  if(WIN32)
    set(_bootstrap "${LUMI_VCPKG_DIR}/bootstrap-vcpkg.bat")
    set(_vcpkg_bin "${LUMI_VCPKG_DIR}/vcpkg.exe")
  else()
    set(_bootstrap "${LUMI_VCPKG_DIR}/bootstrap-vcpkg.sh")
    set(_vcpkg_bin "${LUMI_VCPKG_DIR}/vcpkg")
  endif()

  if(NOT EXISTS "${_vcpkg_bin}")
    if(NOT LUMI_AUTO_INSTALL)
      lumi_sg_warn("vcpkg not bootstrapped. Reconfigure with -DLUMI_AUTO_INSTALL=ON to bootstrap, or run '${_bootstrap}'.")
      return()
    endif()
    lumi_sg_log("Bootstrapping vcpkg ...")
    if(WIN32)
      execute_process(COMMAND "${_bootstrap}" RESULT_VARIABLE _rc)
    else()
      execute_process(COMMAND bash "${_bootstrap}" -disableMetrics RESULT_VARIABLE _rc)
    endif()
    if(NOT _rc EQUAL 0)
      lumi_sg_warn("vcpkg bootstrap failed (rc=${_rc}).")
      return()
    endif()
  endif()

  # 4) Ensure manifest baseline is sane (optional but recommended)
  set(_vcpkg_json "${CMAKE_SOURCE_DIR}/vcpkg.json")
  if(EXISTS "${_vcpkg_json}")
    set(_have_net TRUE)
    if(DEFINED LUMI_NET_ONLINE)
      set(_have_net ${LUMI_NET_ONLINE})
    endif()
    if(NOT _have_net)
      lumi_sg_log("Skipping builtin-baseline refresh (offline mode).")
    else()
       lumi_sg_log("Refreshing builtin-baseline for vcpkg.json ...")
      execute_process(COMMAND "${_vcpkg_bin}" x-update-baseline --dry-run
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        RESULT_VARIABLE _rc OUTPUT_VARIABLE _o ERROR_VARIABLE _e)
      if(_rc EQUAL 0)
        string(REGEX MATCH "\"builtin-baseline\"[^\n]*" _line "${_o}")
        if(_line)
          lumi_sg_log("Suggested ${_line}")
        endif()
      else()
        lumi_sg_warn("x-update-baseline failed: ${_e} (you may need to set the baseline manually)")
      endif()
    endif()
  endif()

  # 5) Install manifest deps to the repo-local vcpkg instance
  lumi_sg_log("Installing vcpkg manifest dependencies (triplet=${VCPKG_TARGET_TRIPLET})")
  execute_process(
    COMMAND "${_vcpkg_bin}" install --clean-after-build --triplet "${VCPKG_TARGET_TRIPLET}"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    RESULT_VARIABLE _irc
    OUTPUT_VARIABLE _o
    ERROR_VARIABLE  _e
  )
  if(NOT _irc EQUAL 0)
    lumi_sg_warn("vcpkg install failed rc=${_irc}\n${_e}")
  endif()

  # 6) Export toolchain file for CMake to pick up later
  if(WIN32)
    set(_toolchain "${LUMI_VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake")
  else()
    set(_toolchain "${LUMI_VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake")
  endif()
  set(CMAKE_TOOLCHAIN_FILE "${_toolchain}" CACHE FILEPATH "vcpkg toolchain" FORCE)
  set(VCPKG_ROOT "${LUMI_VCPKG_DIR}" CACHE PATH "vcpkg root" FORCE)

  lumi_sg_log("vcpkg ready. toolchain='${CMAKE_TOOLCHAIN_FILE}'")
endfunction()
