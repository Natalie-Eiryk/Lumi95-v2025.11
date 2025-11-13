# =============================================================================
# Ensure Git exists (and optionally install it on Windows when LUMI_AUTO_INSTALL=ON)
# Exposes:
#   GIT_EXECUTABLE : FILEPATH (cached)
# =============================================================================
include_guard(GLOBAL)
include(Safeguards--Core)

function(lumi_sg_ensure_git)
  # Step 1: detect
  lumi_sg_detect_exe(
    NAME Git
    OUT_VAR GIT_EXECUTABLE
    # CANDIDATES is optional now; we rely on platform defaults in Core
    REQUIRED
  )

  # If we’re here, either Git exists (preferred) or REQUIRED would have failed.
  if(EXISTS "${GIT_EXECUTABLE}")
    return()
  endif()

  # Step 2: optional auto-install (Windows only)
  if(WIN32 AND LUMI_AUTO_INSTALL)
    lumi_sg_warn("Git missing. Attempting auto-install (Windows). This may prompt elevation.")
    # Try winget, then choco, then scoop
    set(_ps1 "${LUMI_TOOLS_DIR}/install-git.ps1")
    file(WRITE "${_ps1}" [===[
Param()
$ErrorActionPreference = "Stop"

function Try-Tool {
  param($Name, $Test, $Install)
  Write-Host "[Lumi][SG] Probing $Name..." -ForegroundColor Cyan
  if (Get-Command $Test -ErrorAction SilentlyContinue) {
    Write-Host "[Lumi][SG] $Name is available."
    return $true
  }
  Write-Host "[Lumi][SG] Installing $Name..." -ForegroundColor Yellow
  & $Install
  return $?
}

# Winget
$winget = { winget --version >$null 2>&1 }
$winget_install = { winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements }
if (Try-Tool "winget" $winget $winget_install) { return }

# Chocolatey
$choco = { choco --version >$null 2>&1 }
$choco_install = { choco install -y git }
if (Try-Tool "choco" $choco $choco_install) { return }

# Scoop
$scoop = { scoop --version >$null 2>&1 }
$scoop_install = { scoop install git }
Try-Tool "scoop" $scoop $scoop_install | Out-Null
]===])

    # Run the installer script
    execute_process(
      COMMAND powershell -NoProfile -ExecutionPolicy Bypass -File "${_ps1}"
      RESULT_VARIABLE _rc
    )
    if(NOT _rc EQUAL 0)
      lumi_sg_fail("Auto-install of Git failed. Please install Git manually and reconfigure.")
    endif()

    # Re-detect after install
    unset(GIT_EXECUTABLE CACHE)
    lumi_sg_detect_exe(NAME Git OUT_VAR GIT_EXECUTABLE REQUIRED)
  endif()
endfunction()
