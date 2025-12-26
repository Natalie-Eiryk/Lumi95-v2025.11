@echo off
REM Launch script for Lumi286 GUI
REM Adds vcpkg Qt6 DLLs to PATH before launching

echo [Lumi286 Launcher] Setting up Qt6 environment...

REM Add vcpkg Qt6 binaries to PATH
set "VCPKG_BIN=%~dp0vcpkg_installed\x64-windows\bin"
set "PATH=%VCPKG_BIN%;%PATH%"

REM Choose Debug or Release build (default: Release)
set "BUILD_TYPE=Release"
if "%1"=="debug" set "BUILD_TYPE=Debug"
if "%1"=="--debug" set "BUILD_TYPE=Debug"

set "EXE_PATH=%~dp0build\src\%BUILD_TYPE%\Lumi286.exe"

if not exist "%EXE_PATH%" (
    echo [ERROR] Lumi286.exe not found at: %EXE_PATH%
    echo.
    echo Please build the project first:
    echo   cmake --build build --config %BUILD_TYPE%
    echo.
    pause
    exit /b 1
)

echo [Lumi286 Launcher] Launching %BUILD_TYPE% build...
echo [Lumi286 Launcher] Executable: %EXE_PATH%
echo [Lumi286 Launcher] Qt6 DLLs from: %VCPKG_BIN%
echo.

REM Launch the GUI
"%EXE_PATH%"

REM Capture exit code
set EXIT_CODE=%ERRORLEVEL%

if %EXIT_CODE% NEQ 0 (
    echo.
    echo [ERROR] Lumi286 exited with code: %EXIT_CODE%
    pause
)

exit /b %EXIT_CODE%
