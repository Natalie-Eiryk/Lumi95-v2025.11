# Set-LumiEnv.ps1
# Lumi System Environment Setup - Session + Machine + Verification

param(
    [string]$BaseCD = "F:\Lumi95",
    [string]$Base   = "F:\Lumi95\repos"
)

# ----- Helpers -------------------------------------------------------------

function Assert-Dir {
    param([Parameter(Mandatory)][string]$Path,
          [Parameter(Mandatory)][string]$Name)
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Warning ("Missing path for {0}: {1}" -f $Name, $Path)
    }
}

function Set-LumiEnvVar {
    param([Parameter(Mandatory)][string]$Name,
          [Parameter(Mandatory)][string]$Value)

    # 1) Session (immediate in this shell and child processes)
    Set-Item -Path ("Env:{0}" -f $Name) -Value $Value

    # 2) Machine (persistent; requires admin)
    try {
        [Environment]::SetEnvironmentVariable($Name, $Value, 'Machine')
        Write-Host ("OK {0} = {1}" -f $Name, $Value)
    }
    catch {
        Write-Warning ("Machine-level set failed for {0}: {1}" -f $Name, $_.Exception.Message)
    }
}

function Show-MachineVar {
    param([Parameter(Mandatory)][string]$Name)
    $v = [Environment]::GetEnvironmentVariable($Name, 'Machine')
    if ([string]::IsNullOrWhiteSpace($v)) { $v = "<not set>" }
    "{0,-32} = {1}" -f $Name, $v
}

# Warn if not elevated (machine writes will fail)
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Warning "Not running as Administrator. Machine-level changes may not apply."
}

# ----- Sanity checks -------------------------------------------------------

Assert-Dir $BaseCD "Base (checkout)"
Assert-Dir $Base   "Base repo"
Assert-Dir ("{0}\TensorRT_10_13_0_35"       -f $Base) "TensorRT"
Assert-Dir ("{0}\Qt\6.10.0"                 -f $Base) "Qt"
Assert-Dir ("{0}\PhysX_5_6_dir"             -f $Base) "PhysX build"
Assert-Dir ("{0}\googletest"                -f $Base) "GoogleTest"
Assert-Dir ("{0}\yaml-cpp"                  -f $Base) "yaml-cpp"
Assert-Dir ("{0}\nlohmann_json"             -f $Base) "nlohmann_json"
Assert-Dir ("{0}\Lumi286\core\Lumi_Headers" -f $Base) "Lumi core headers"
Assert-Dir ("{0}\Lumi_PhysX"                -f $Base) "Lumi PhysX Build"

# ----- Set variables -------------------------------------------------------

# CUDA (comes from NVIDIA installer)
Set-LumiEnvVar "CUDA_TOOLKIT_ROOT"            "$Env:CUDA_PATH"

# Lumi repos
Set-LumiEnvVar "TENSORRT_10_11_ROOT_DIR_SYS"  ("{0}\TensorRT_10_13_0_35"       -f $Base)
Set-LumiEnvVar "QT_10_ROOT_DIR_SYS"           ("{0}\Qt\6.10.0"                 -f $Base)
Set-LumiEnvVar "LUMI_PHYSX_5_6_BUILD_DIR_SYS" ("{0}\PhysX_5_6_dir"             -f $Base)
Set-LumiEnvVar "GTEST_ROOT_DIR_SYS"           ("{0}\googletest"                -f $Base)
Set-LumiEnvVar "YAML_CPP_ROOT_DIR_SYS"        ("{0}\yaml-cpp"                  -f $Base)
Set-LumiEnvVar "NLOHMANN_JSON_HPP_DIR_SYS"    ("{0}\nlohmann_json"             -f $Base)
Set-LumiEnvVar "LUMI_CORE_HEADER_DIR"         ("{0}\Lumi286\core\Lumi_Headers" -f $Base)
Set-LumiEnvVar "LUMI_PHYSX_BLD"               ("{0}\Lumi_PhysX"               -f $Base)


# ----- Verification: session values ---------------------------------------

$vars = @(
    'CUDA_TOOLKIT_ROOT',
    'TENSORRT_10_11_ROOT_DIR_SYS',
    'QT_10_ROOT_DIR_SYS',
    'LUMI_PHYSX_5_6_BUILD_DIR_SYS',
    'GTEST_ROOT_DIR_SYS',
    'YAML_CPP_ROOT_DIR_SYS',
    'NLOHMANN_JSON_HPP_DIR_SYS',
    'LUMI_CORE_HEADER_DIR',
    'LUMI_PHYSX_BLD'
)

Write-Host ""
Write-Host "Session values (current shell):"
foreach ($n in $vars) {
    $val = (Get-Item -Path ("Env:{0}" -f $n) -ErrorAction SilentlyContinue).Value
    if ([string]::IsNullOrWhiteSpace($val)) { $val = "<not set>" }
    Write-Host ("{0,-32} = {1}" -f $n, $val)
}

# ----- Verification: machine values (registry) -----------------------------

Write-Host ""
Write-Host "Machine values (persisted):"
foreach ($n in $vars) {
    Write-Host (Show-MachineVar $n)
}

Write-Host ""
Write-Host "Done. Restart Visual Studio or terminals to load machine-level values."
Write-Host "If CMake cached older paths, delete CMakeCache.txt and re-configure."
