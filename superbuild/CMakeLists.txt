cmake_minimum_required(VERSION 3.21)

# -----------------------------------------------------------------------------
# Lumi286 Superbuild
# -----------------------------------------------------------------------------
# This miniature project is a helpful sidekick whose only job is to make sure
# all third?party libraries are ready before the main code tries to compile.
# Running this CMake file will download and bootstrap vcpkg and, if requested,
# install the libraries listed in the project's vcpkg.json manifest.
# -----------------------------------------------------------------------------
project(Lumi286Superbuild LANGUAGES NONE)

# Pull in our vcpkg helper
include(../cmake/vcpkg-bootstrap-toolchain.cmake)

# Option to actually run `vcpkg install` – off by default to keep configure fast
option(LUMI_RUN_VCPKG "Run vcpkg install during configuration" ON)
set(LUMI_VCPKG_TRIPLET "x64-windows" CACHE STRING "Target vcpkg triplet")

# Call the bootstrapper; will clone and set the toolchain file.
if(LUMI_RUN_VCPKG)
  lumi_bootstrap_vcpkg(TRIPLET ${LUMI_VCPKG_TRIPLET} RUN_INSTALL)
else()
  lumi_bootstrap_vcpkg(TRIPLET ${LUMI_VCPKG_TRIPLET})
endif()

# A friendly reminder so users know what happened
if(LUMI_RUN_VCPKG)
  message(STATUS "? vcpkg dependencies installed. You can now configure the main project.")
else()
  message(STATUS "??  Configure finished without installing packages. Re-run with\n                   -DLUMI_RUN_VCPKG=ON to fetch dependencies.")
endif()