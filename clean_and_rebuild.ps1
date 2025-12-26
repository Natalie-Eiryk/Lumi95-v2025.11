# Clean build script - Run this AFTER closing Visual Studio

Write-Host "Cleaning PhysX buildtrees..." -ForegroundColor Yellow
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "F:\Lumi95\deps\vcpkg\buildtrees\physx"

Write-Host "Cleaning main build directory..." -ForegroundColor Yellow
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "F:\Lumi95\out\build\lumi-first-time"

Write-Host "`nCleaning complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Open Visual Studio"
Write-Host "2. Right-click CMakeLists.txt -> Configure Cache"
Write-Host "3. The build should now use 'Visual Studio 17 2022' generator"
Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
