# -----------------------------------------------------------------------------
# bootstrap_vcpkg.ps1 - Convenience script to run the superbuild on Windows
# -----------------------------------------------------------------------------
param(
    [switch]$Install
)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Join-Path $root ".."
$build = Join-Path $root "build-superbuild"
$runInstall = if ($Install) { "ON" } else { "OFF" }

# Ensure Git exists; install via winget or Chocolatey when available
if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Attempting to install..."
    if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
        winget install -e --id Git.Git --silent --accept-package-agreements --accept-source-agreements
    } elseif (Get-Command choco.exe -ErrorAction SilentlyContinue) {
        choco install git -y | Out-Null
    } else {
        Write-Error "Neither winget nor Chocolatey is available. Please install Git manually and re-run this script."
        exit 1
    }
}

cmake -S (Join-Path $root "superbuild") -B $build -DLUMI_RUN_VCPKG=$runInstall