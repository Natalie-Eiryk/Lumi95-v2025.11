# Navigate to your project root
Set-Location "C:\Lumi95\Lumi286"

# Remove stale CMake and VS metadata
Write-Host "🧹 Cleaning old build artifacts..."
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue `
    ".vs", "CMakeFiles", "CMakeCache.txt", `
    "out/build", "build", "build-rel", "cmake-build-release", "*.sln", "*.vcxproj", "*.vcxproj.filters"

# Run the release preset
Write-Host "`n⚙️  Running CMake with preset: Lumi286-Release-CUDA128-CXX20-sm89-VS2022"
cmake --preset=Lumi286-Release-CUDA128-CXX20-sm89-VS2022

# Optional: Launch VS if needed
$sln = Get-ChildItem -Path . -Filter *.sln -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($sln) {
    Write-Host "`n🚀 Opening Visual Studio project..."
    Start-Process "devenv.exe" $sln.FullName
} else {
    Write-Host "`n✅ CMake configuration complete. No .sln file found to launch."
}
