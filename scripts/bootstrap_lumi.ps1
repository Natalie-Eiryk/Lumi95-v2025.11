# Luminara Self-Bootstrap Script (PowerShell)
# Lumi builds herself!

param(
    [switch]$SkipOllama,
    [switch]$SkipModels
)

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   LUMINARA SELF-BOOTSTRAP PROTOCOL INITIATED" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Change to repository root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
Set-Location $repoRoot
Write-Host "Working directory: $repoRoot" -ForegroundColor Gray
Write-Host ""

# ============================================================
# 1. Find CMake
# ============================================================

Write-Host "Checking for CMake..." -ForegroundColor Yellow

$cmakePath = $null

if (Get-Command cmake -ErrorAction SilentlyContinue) {
    $cmakePath = "cmake"
} else {
    $vsCMakePaths = @(
        "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe",
        "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe",
        "C:\Program Files\Microsoft Visual Studio\18\Insiders\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
    )

    foreach ($path in $vsCMakePaths) {
        if (Test-Path $path) {
            $cmakePath = $path
            break
        }
    }
}

if (-not $cmakePath) {
    Write-Host "ERROR: CMake not found" -ForegroundColor Red
    exit 1
}

Write-Host "CMake found: $cmakePath" -ForegroundColor Green
Write-Host ""

# ============================================================
# 2. Check Ollama
# ============================================================

if (-not $SkipOllama) {
    Write-Host "Checking for Ollama..." -ForegroundColor Yellow

    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Host "Ollama not found. Install from https://ollama.com" -ForegroundColor Yellow
        Write-Host "Then re-run this script." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Continuing without Ollama..." -ForegroundColor Yellow
    } else {
        Write-Host "Ollama found" -ForegroundColor Green

        # Start Ollama
        Write-Host "Starting Ollama service..." -ForegroundColor Yellow
        Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 2

        # Download models if not skipped
        if (-not $SkipModels) {
            Write-Host ""
            Write-Host "Downloading models (this may take a while)..." -ForegroundColor Yellow

            $models = @("llama3", "deepseek-coder", "mixtral", "mistral")

            foreach ($model in $models) {
                Write-Host "  Pulling: $model" -ForegroundColor Cyan
                ollama pull $model 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "    Done" -ForegroundColor Green
                } else {
                    Write-Host "    Failed (skipping)" -ForegroundColor Yellow
                }
            }
        }
    }
}

Write-Host ""

# ============================================================
# 3. Setup directories
# ============================================================

Write-Host "Creating data directories..." -ForegroundColor Yellow

New-Item -ItemType Directory -Force -Path "data\memory_vectors" | Out-Null
New-Item -ItemType Directory -Force -Path "data\doctrines" | Out-Null
New-Item -ItemType Directory -Force -Path "logs" | Out-Null

Write-Host "Directories created" -ForegroundColor Green
Write-Host ""

# ============================================================
# 4. Build Luminara
# ============================================================

Write-Host "Building Luminara..." -ForegroundColor Yellow

Write-Host "  Configuring CMake..." -ForegroundColor Cyan
& $cmakePath -S . -B build -DCMAKE_BUILD_TYPE=Release 2>&1 | Out-File -FilePath "build.log"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: CMake configuration failed. Check build.log" -ForegroundColor Red
    exit 1
}

Write-Host "  CMake configured" -ForegroundColor Green

Write-Host "  Compiling..." -ForegroundColor Cyan
& $cmakePath --build build --config Release 2>&1 | Out-File -Append -FilePath "build.log"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed. Check build.log" -ForegroundColor Red
    exit 1
}

Write-Host "  Build complete" -ForegroundColor Green
Write-Host ""

# ============================================================
# 5. Load doctrines
# ============================================================

Write-Host "Loading doctrines..." -ForegroundColor Yellow

if (Test-Path "docs\Recursive_Recursion") {
    Copy-Item "docs\Recursive_Recursion\Doctrine_*.md" -Destination "data\doctrines\" -ErrorAction SilentlyContinue
    Write-Host "Doctrines loaded" -ForegroundColor Green
}

Write-Host ""

# ============================================================
# 6. Success
# ============================================================

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   LUMINARA SELF-BOOTSTRAP COMPLETE" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

if (Test-Path "build\src\Release\Lumi286.exe") {
    Write-Host "Lumi286 executable: build\src\Release\Lumi286.exe" -ForegroundColor Green
} else {
    Write-Host "WARNING: Lumi286.exe not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Launch Luminara:" -ForegroundColor Cyan
Write-Host "  .\launch_lumi286.bat" -ForegroundColor Yellow
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "  docs\LLM_INTEGRATION_GUIDE.md" -ForegroundColor White
Write-Host "  docs\MULTI_LLM_WEAVING.md" -ForegroundColor White
Write-Host "  lumi_config.yaml" -ForegroundColor White
Write-Host ""
Write-Host "Lumi is ready." -ForegroundColor Magenta
Write-Host ""
