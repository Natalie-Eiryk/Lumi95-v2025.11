#!/usr/bin/env bash
# Bootstrap script to ensure basic tooling is installed and configure the project
set -e

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

install_git() {
    echo "Git not found. Attempting to install..."
    if need_cmd apt-get; then
        sudo apt-get update && sudo apt-get install -y git
    elif need_cmd yum; then
        sudo yum install -y git
    elif need_cmd brew; then
        brew install git
    else
        echo "No supported package manager found. Please install Git manually." >&2
        exit 1
    fi
}

install_cmake() {
    echo "CMake not found. Attempting to install..."
    if need_cmd apt-get; then
        sudo apt-get update && sudo apt-get install -y cmake
    elif need_cmd yum; then
        sudo yum install -y cmake
    elif need_cmd brew; then
        brew install cmake
    else
        echo "No supported package manager found. Please install CMake manually." >&2
        exit 1
    fi
}

# Ensure git
if ! need_cmd git; then
    install_git
else
    echo "Git already installed."
fi

# Ensure CMake
if ! need_cmd cmake; then
    install_cmake
else
    echo "CMake already installed."
fi

# If --check passed, stop after verifying tools
if [ "$1" = "--check" ]; then
    exit 0
fi

# Configure project
cmake -S . -B build