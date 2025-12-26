# Launch script for Lumi286 GUI
# Adds vcpkg Qt6 DLLs to PATH before launching

param(
    [switch]$Debug,
    [switch]$Release
)

Write-Host "[Lumi286 Launcher] Setting up Qt6 environment..." -ForegroundColor Cyan

# Add vcpkg Qt6 binaries to PATH
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$VcpkgBin = Join-Path $ScriptDir "vcpkg_installed\x64-windows\bin"
$env:PATH = "$VcpkgBin;$env:PATH"

# Choose Debug or Release build (default: Release)
$BuildType = "Release"
if ($Debug) { $BuildType = "Debug" }

$ExePath = Join-Path $ScriptDir "build\src\$BuildType\Lumi286.exe"

if (-not (Test-Path $ExePath)) {
    Write-Host "[ERROR] Lumi286.exe not found at: $ExePath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please build the project first:" -ForegroundColor Yellow
    Write-Host "  cmake --build build --config $BuildType" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[Lumi286 Launcher] Launching $BuildType build..." -ForegroundColor Green
Write-Host "[Lumi286 Launcher] Executable: $ExePath" -ForegroundColor Gray
Write-Host "[Lumi286 Launcher] Qt6 DLLs from: $VcpkgBin" -ForegroundColor Gray
Write-Host ""

# Launch the GUI
& $ExePath

# Capture exit code
$ExitCode = $LASTEXITCODE

if ($ExitCode -ne 0) {
    Write-Host ""
    Write-Host "[ERROR] Lumi286 exited with code: $ExitCode" -ForegroundColor Red
    Read-Host "Press Enter to exit"
}

exit $ExitCode
