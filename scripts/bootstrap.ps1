<#
    Bootstrap script to ensure Git and CMake are installed and configure the project.
    Use the optional --check flag to only verify tools.
#>

function Ensure-Command($Name, $WingetId) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Host "$Name not found. Attempting to install..."
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install --id $WingetId -e --silent
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install $Name -y
        } else {
            throw "No supported package manager found. Please install $Name manually."
        }
    } else {
        Write-Host "$Name already installed."
    }
}

Ensure-Command git "Git.Git"
Ensure-Command cmake "Kitware.CMake"

if (-not $args.Contains("--check")) {
    cmake -S . -B build
}