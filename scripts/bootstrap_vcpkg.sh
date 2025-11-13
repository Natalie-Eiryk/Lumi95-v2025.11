#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bootstrap_vcpkg.sh - Convenience script to run the superbuild on Unix
# -----------------------------------------------------------------------------
# This script simply calls CMake on the superbuild project.  Add -i to install
# dependencies immediately.
# -----------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
BUILD_DIR="${ROOT_DIR}/build-superbuild"
RUN_INSTALL=OFF

if [[ "${1:-}" == "-i" ]]; then
  RUN_INSTALL=ON
fi

# Ensure Git exists; install it using the system package manager when possible
if ! command -v git >/dev/null 2>&1; then
  echo "Git not found. Attempting to install..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y git
  elif command -v brew >/dev/null 2>&1; then
    brew install git
  else
    echo "Please install Git manually and re-run this script." >&2
    exit 1
  fi
fi

cmake -S "${ROOT_DIR}/superbuild" -B "${BUILD_DIR}" -DLUMI_RUN_VCPKG=${RUN_INSTALL}