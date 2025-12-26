# install_ollama.ps1 - Auto-install Ollama for Windows
param(
    [string]$Model = "llama3.2"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Ollama Auto-Installer for Luminara" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Ollama is already installed
$ollamaPath = Get-Command ollama -ErrorAction SilentlyContinue

if ($ollamaPath) {
    Write-Host "[OK] Ollama already installed at: $($ollamaPath.Source)" -ForegroundColor Green
} else {
    Write-Host "[*] Downloading Ollama installer..." -ForegroundColor Yellow

    $installerUrl = "https://ollama.com/download/OllamaSetup.exe"
    $installerPath = "$env:TEMP\OllamaSetup.exe"

    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
        Write-Host "[OK] Downloaded Ollama installer" -ForegroundColor Green

        Write-Host "[*] Running installer..." -ForegroundColor Yellow
        Start-Process -FilePath $installerPath -Wait

        Write-Host "[OK] Ollama installed!" -ForegroundColor Green

        # Clean up
        Remove-Item $installerPath -ErrorAction SilentlyContinue

    } catch {
        Write-Host "[ERROR] Failed to download/install Ollama: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please install manually from: https://ollama.com/download" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "[*] Checking if Ollama service is running..." -ForegroundColor Yellow

# Wait for Ollama to start
Start-Sleep -Seconds 2

# Test connection
try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -Method GET -ErrorAction Stop
    Write-Host "[OK] Ollama service is running" -ForegroundColor Green
} catch {
    Write-Host "[*] Starting Ollama service..." -ForegroundColor Yellow
    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 3
}

Write-Host ""
Write-Host "[*] Pulling model: $Model" -ForegroundColor Yellow

# Pull the specified model
try {
    & ollama pull $Model
    Write-Host "[OK] Model '$Model' ready!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to pull model: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Ollama Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Model: $Model" -ForegroundColor Green
Write-Host "Endpoint: http://localhost:11434" -ForegroundColor Green
Write-Host ""
Write-Host "Test it:" -ForegroundColor Yellow
Write-Host "  ollama run $Model" -ForegroundColor White
Write-Host ""
