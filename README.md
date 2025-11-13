# Valkryja

Welcome to **Valkryja**, home of the Lumi286 project.

This repository now includes a small _superbuild_ that fetches third?party
libraries using [vcpkg](https://github.com/microsoft/vcpkg).  The intent is to
make the first-time setup as painless as a guided tour on Ms. Frizzle's school
bus.

## Getting started

1. **Bootstrap vcpkg**
   ```bash
   scripts/bootstrap_vcpkg.sh -i       # add -i to install packages immediately
   ```
   On Windows:
   ```powershell
   .\scripts\bootstrap_vcpkg.ps1 -Install
   ```
   These helper scripts first make sure Git is available—installing it with
   your platform's package manager (winget, Chocolatey, apt or Homebrew) if
   necessary.  They then configure `superbuild/CMakeLists.txt` which will clone
   and optionally install all libraries listed in `vcpkg.json` into `deps/vcpkg`.

2. **Configure the main project**
   ```bash
   cmake -S . -B build
   cmake --build build
   ```
   The top-level CMakeLists uses the vcpkg toolchain automatically once the
   superbuild has run.

3. **Private dependencies**
   Packages such as NVIDIA CUDA, TensorRT and the proprietary PhysX SDK may
   require manual installation or credentials.  Once installed, set environment
   variables like `CUDA_PATH` or `TENSORRT_ROOT` before configuring the project.

For more details consult the comments in the various CMake files—they narrate
what each step is doing in plain language.