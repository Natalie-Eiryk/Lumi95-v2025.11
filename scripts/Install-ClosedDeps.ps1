param(
  [switch]$Quiet
)

function Has-Exe($name) {
  $cmd = (Get-Command $name -ErrorAction SilentlyContinue)
  return $null -ne $cmd
}

Write-Host "== LUMI Closed-Deps Check =="

# CUDA
$nvcc = Get-Command nvcc -ErrorAction SilentlyContinue
if (-not $nvcc) {
  Write-Warning "CUDA nvcc not found."
  if (-not $Quiet) {
    $ans = Read-Host "Install CUDA 12.8 via winget now? (Y/N)"
    if ($ans -match '^[Yy]') {
      winget install NVIDIA.CUDA --version 12.8 --silent
    } else {
      Write-Host "Opening NVIDIA CUDA download page..."
      Start-Process "https://developer.nvidia.com/cuda-downloads"
    }
  }
} else {
  Write-Host "CUDA found at $($nvcc.Source)"
}

# TensorRT
if (-not $env:TENSORRT_ROOT -or -not (Test-Path $env:TENSORRT_ROOT)) {
  Write-Warning "TENSORRT_ROOT is not set or invalid."
  if (-not $Quiet) {
    $ans = Read-Host "Do you have a local TensorRT install folder to use? (Y/N)"
    if ($ans -match '^[Yy]') {
      $path = Read-Host "Enter full path to TensorRT root (contains include/lib)"
      if (Test-Path $path) {
        [Environment]::SetEnvironmentVariable('TENSORRT_ROOT', $path, 'User')
        $env:TENSORRT_ROOT = $path
        Write-Host "TENSORRT_ROOT set to $path"
      } else {
        Write-Warning "Path not found."
      }
    } else {
      Write-Host "Opening NVIDIA TensorRT download page..."
      Start-Process "https://developer.nvidia.com/tensorrt"
      Write-Host "After installing/extracting, set TENSORRT_ROOT to that folder."
    }
  }
} else {
  Write-Host "TensorRT: $env:TENSORRT_ROOT"
}

# Optional: set CUDA_TOOLKIT_ROOT for CMake hints
if (-not $env:CUDA_TOOLKIT_ROOT -and $env:CUDA_PATH) {
  [Environment]::SetEnvironmentVariable('CUDA_TOOLKIT_ROOT', $env:CUDA_PATH, 'User')
  Write-Host "CUDA_TOOLKIT_ROOT set to $env:CUDA_PATH"
}

# Optional: set QT_ROOT if you’re not using vcpkg Qt
# [Environment]::SetEnvironmentVariable('QT_ROOT', 'E:\Lumi95\repos\Qt\6.10.0', 'User')
