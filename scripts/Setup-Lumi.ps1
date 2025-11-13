Write-Host "== LUMI Setup =="

# 1) Guide CUDA/TensorRT first
.\scripts\Install-ClosedDeps.ps1

# 2) Show detected config
Write-Host "CUDA_TOOLKIT_ROOT = $env:CUDA_TOOLKIT_ROOT"
Write-Host "TENSORRT_ROOT     = $env:TENSORRT_ROOT"

# 3) Optionally ask about building PhysX from source
$buildPhysX = Read-Host "Build PhysX (Omniverse) from source now? (Y/N)"
$pxFlag = if ($buildPhysX -match '^[Yy]') { "-DLUMI_BUILD_PHYSX_FROM_SOURCE=ON" } else { "" }

# 4) Kick superbuild
$cfgDir = "out\superbuild"
New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
cmake -S superbuild -B $cfgDir $pxFlag
# build happens inside superbuild automatically
