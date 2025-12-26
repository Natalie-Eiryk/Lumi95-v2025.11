# PowerShell script to fix the Visual Studio generator issue
$file = "F:\Lumi95\deps\vcpkg\scripts\cmake\vcpkg_configure_cmake.cmake"
$content = Get-Content $file -Raw
$content = $content -replace 'set\(generator "Visual Studio 18 2026"\)', 'set(generator "Visual Studio 17 2022")'
Set-Content -Path $file -Value $content -NoNewline
Write-Host "Fixed vcpkg_configure_cmake.cmake"
