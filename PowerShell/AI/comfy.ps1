# Copyright (C) 2024 TroubleChute (Wesley Pyburn)
# Licensed under the GNU General Public License v3.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.gnu.org/licenses/gpl-3.0.en.html
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#    
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ----------------------------------------
# This script:
# 1. Install Chocolatey
# 2. Install or update Git if not already installed
# 3. Install aria2c to make the download MUCH faster
# 4. Check if Conda or Python is installed (is installed - also is 3.10.6 - 3.10.11)
# 5. Install CUDA and cuDNN
# 6. Check if has ComfyUI directory ($TCHT\comfyui) (Default C:\TCHT\comfyui)
# 7. Create desktop shortcuts?
# 8. Launch ComfyUI Stable Diffusion WebUI
# ----------------------------------------


Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's ComfyUI installer!" -ForegroundColor Cyan
Write-Host "ComfyUI as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2024-06-21]" -ForegroundColor Cyan
Write-Host "`nThis script is provided AS-IS without warranty of any kind. See https://tc.ht/privacy & https://tc.ht/terms."
Write-Host "Consider supporting these install scripts: https://tc.ht/support" -ForegroundColor Green
Write-Host "--------------------------------------------------`n`n" -ForegroundColor Cyan

Set-Variable ProgressPreference SilentlyContinue # Remove annoying yellow progress bars when doing Invoke-WebRequest for this session

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
    Read-Host
}

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")

Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
$TCHT = Get-TCHTPath -Subfolder "comfyui"

# If user chose to install this program in another path, create a symlink for easy access and management.
$isSymlink = Sync-ProgramFolder -ChosenPath $TCHT -Subfolder "comfyui"

# Then CD into $TCHT\
Set-Location "$TCHT\"

# 1. Install Chocolatey
Clear-ConsoleScreen
Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install or update Git if not already installed
Clear-ConsoleScreen
Write-Host "Installing Git..." -ForegroundColor Cyan
iex (irm install-git.tc.ht)

# 3. Install aria2c to make the download MUCH faster
Clear-ConsoleScreen
Write-Host "Installing aria2c (Faster model download)..." -ForegroundColor Cyan
choco upgrade aria2 -y

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tc.ht)
Update-SessionEnvironment

# 4. Check if Conda or Python is installed
Import-FunctionIfNotExists -Command Get-UseConda -ScriptUri "Get-Python.tc.ht"

# 5. Install CUDA and cuDNN
$isNvidia = (Get-CimInstance Win32_VideoController).Name -like "*Nvidia*"
if ($isNvidia) {
    Import-FunctionIfNotExists -Command Install-CudaAndcuDNN -ScriptUri "Install-Cuda.tc.ht"
    Install-CudaAndcuDNN -CudaVersion "12.5" -CudnnOptional $true
}

# Check if Conda is installed
$condaFound = Get-UseConda -Name "ComfyUI" -EnvName "comfyui" -PythonVersion "3.10.10"

# Get Python command (eg. python, python3) & Check for compatible version
if ($condaFound) {
    conda activate "comfyui"
    $python = "python"
} else {
    $python = Get-Python -PythonRegex 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])' -PythonRegexExplanation "Python version is not between 3.10.6 and 3.10.11." -PythonInstallVersion "3.10.11" -ManualInstallGuide "https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs"
    if ($python -eq "miniconda") {
        $python = "python"
        $condaFound = $true
    }
}

# 6. Check if has ComfyUI directory ($TCHT\comfyui) (Default C:\TCHT\comfyui)
Clear-ConsoleScreen
Write-Host "I'll start by installing ComfyUI first, then we'll get to the models...`n`n"

if (!(Test-Path -Path "$TCHT\comfyui")) {
    New-Item -ItemType Directory -Path "$TCHT\comfyui" | Out-Null
}
Set-Location "$TCHT\comfyui"


# - Install 7zip
$sevenZipFound = [bool](Get-Command 7z -ErrorAction SilentlyContinue)
if (-not $sevenZipFound) {
    Write-Host "Installing 7-Zip..." -ForegroundColor Cyan
    choco upgrade 7zip.install -y
    Write-Host "Done." -ForegroundColor Green
}
Update-SessionEnvironment

# - Download file
Import-FunctionIfNotExists -Command Get-Aria2File -ScriptUri "File-DownloadMethods.tc.ht"
Write-Host "Downloading the latest release of ComfyUI from GitHub" -ForegroundColor Yellow
$url = "https://github.com/comfyanonymous/ComfyUI/releases/download/latest/ComfyUI_windows_portable_nvidia_cu121_or_cpu.7z"
$outputPath = "ComfyUI_windows_portable_nvidia_cu121_or_cpu.7z"
Get-Aria2File -Url $url -OutputPath $outputPath

# - Extract file
Write-Host "Extracting the latest ComfyUI" -ForegroundColor Yellow
7z x "$outputPath" "ComfyUI_windows_portable" -o"temp"
$destination = (Get-Location)
# Recursively move files and folders
Write-Host "Moving files..." -ForegroundColor Yellow
Move-Item -Path temp/ComfyUI_windows_portable/* -Destination $destination -Force
# Delete temp folder
Remove-Item -Path "temp" -Recurse -Force
# Delete 7z  file
Remove-Item -Path $outputPath -Force


# 7. Create desktop shortcuts?
Clear-ConsoleScreen
Write-Host "Create desktop shortcuts for ComfyUI?" -ForegroundColor Cyan

# Create start bat and ps1 files
if ($condaFound) {
    if ($isNvidia) {
        conda install cudatoolkit -y
    }
    
    # As the Windows Target path can only have 260 chars, we easily hit that limit...
    $condaPath = Get-CondaPath
    $OutputFilePath = "start-conda.ps1"
    $OutputText = "& '$condaPath'`nconda activate comfyui`nSet-Location `"$(Get-Location)`"`nrun_nvidia_gpu.bat"
    Set-Content -Path $OutputFilePath -Value $OutputText
    
    $OutputFilePath = "start-conda.bat"
    $OutputText = "@echo off`npowershell -ExecutionPolicy ByPass -NoExit -File `"start-conda.ps1`""
    Set-Content -Path $OutputFilePath -Value $OutputText
}


do {
    Clear-ConsoleScreen
    Write-Host -ForegroundColor Cyan -NoNewline "Do you want desktop shortcuts? (y/n) [Default: y]: "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n", "")

if ($shortcuts -in "Y","y", "") {
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading ComfyUI icon (not official)..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/comfyui.ico' -OutFile 'comfyui.ico'

    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
    $shortcutName = "ComfyUI"
    if ($condaFound) {
        $targetPath = "start-conda.bat"
    }
    else {
        $targetPath = "run_nvidia_gpu.bat"
    }
    $IconLocation = 'comfyui.ico'
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation
    
}

# 8. Launch ComfyUI Stable Diffusion WebUI
Clear-ConsoleScreen
Write-Host "Launching ComfyUI!" -ForegroundColor Cyan

if ($isNvidia) {
    ./run_nvidia_gpu.bat
} else {
    ./run_cpu.bat
}