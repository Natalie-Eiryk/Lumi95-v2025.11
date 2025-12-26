# Visual Studio Insiders Build Fix

## Problem
VS 2022 Insiders (version 18.x) was incorrectly mapped to "Visual Studio 18 2026" generator which doesn't exist.

## Root Cause
vcpkg's generator detection in `deps/vcpkg/scripts/cmake/vcpkg_configure_cmake.cmake` assumed:
- Version 18.x = VS 2026 (incorrect!)
- Reality: VS Insiders 18.x is still VS 2022 and uses "Visual Studio 17 2022" generator

## Solution Applied
Fixed line 46 to map version 18.x → "Visual Studio 17 2022"

## How to Apply the Fix

### Method 1: Clean Build (Recommended)
1. **Close Visual Studio completely**
2. Run: `.\clean_and_rebuild.ps1`
3. Reopen VS and reconfigure

### Method 2: Build Without PhysX (Quick Alternative)
If PhysX keeps failing:
1. Backup: `copy vcpkg.json vcpkg.json.bak`
2. Use PhysX-free version: `copy vcpkg_no_physx.json vcpkg.json`
3. Reconfigure and build
4. Add PhysX back later when needed

### Method 3: Use Ninja Instead of MSBuild
Set environment variable before CMake:
```powershell
$env:CMAKE_GENERATOR = "Ninja"
cmake -S . -B out/build
```

## Verification
After reconfiguring, check the output for:
- ✅ "Using generator: Visual Studio 17 2022"
- ❌ NOT "Visual Studio 18 2026"

## Files Modified
- `deps/vcpkg/scripts/cmake/vcpkg_configure_cmake.cmake` (line 46)
- Created: `vcpkg_no_physx.json` (PhysX-free alternative)
- Created: `clean_and_rebuild.ps1` (cleanup script)
- Created: `fix_generator.ps1` (generator fix script)
