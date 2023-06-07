# Copyright (C) 2023 TroubleChute (Wesley Pyburn)
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
# 1. Install Chocolatey
# 2. Install or update Git if not already installed
# 3. Install CUDA and cuDNN
# 4. Download kohya_ss
# 5. Check if Conda or Python is installed
# 6. Create desktop shortcuts?
# 7. Launch!
# ----------------------------------------

Write-Host "---------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's kohya_ss installer!" -ForegroundColor Cyan
Write-Host "kohya_ss as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-06-06]" -ForegroundColor Cyan
Write-Host "`nThis script is provided AS-IS without warranty of any kind. See https://tc.ht/privacy & https://tc.ht/terms."
Write-Host "`nConsider supporting these install scripts: https://tc.ht/support" -ForegroundColor Green
Write-Host "---------------------------------------------`n`n" -ForegroundColor Cyan

Set-Variable ProgressPreference SilentlyContinue # Remove annoying yellow progress bars when doing Invoke-WebRequest for this session

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
    Read-Host
}

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")

Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
$TCHT = Get-TCHTPath -Subfolder "kohya_ss"

# If user chose to install this program in another path, create a symlink for easy access and management.
$isSymlink = Sync-ProgramFolder -ChosenPath $TCHT -Subfolder "kohya_ss"

# Then CD into $TCHT\
Set-Location "$TCHT\"

# 1. Install Chocolatey
Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install or update Git if not already installed
Write-Host "`nInstalling Git..." -ForegroundColor Cyan
iex (irm install-git.tc.ht)

# 3. Install CUDA and cuDNN
if ((Get-CimInstance Win32_VideoController).Name -like "*Nvidia*") {
    Import-FunctionIfNotExists -Command Install-CudaAndcuDNN -ScriptUri "Install-Cuda.tc.ht"
    Install-CudaAndcuDNN -CudaVersion "11.8" -CudnnOptional $true
}

# 4. Download kohya_ss
git clone https://github.com/bmaltais/kohya_ss.git
cd kohya_ss

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tc.ht)


# 5. Check if Conda or Python is installed
# Check if Conda is installed
Import-FunctionIfNotExists -Command Get-UseConda -ScriptUri "Get-Python.tc.ht"

# Check if Conda is installed
$condaFound = Get-UseConda -Name "Kohya_ss" -EnvName "kss" -PythonVersion "3.10.11"

# Get Python command (eg. python, python3) & Check for compatible version
if ($condaFound) {
    conda activate "kss"
    $python = "python"
} else {
    $python = Get-Python -PythonRegex 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])' -PythonRegexExplanation "Python version is not between 3.10.6 and 3.10.11." -PythonInstallVersion "3.10.11" -ManualInstallGuide "https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs"
    if ($python -eq "miniconda") {
        $python = "python"
        $condaFound = $true
    }
}

# Continue with installation
./setup.bat

# Delete setup.bat
Remove-Item setup.bat

# 6. Create desktop shortcuts?
do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want desktop shortcuts? (y/n) [Default: y]: "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n", "")

iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
if ($shortcuts -in "Y","y", "") {
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading kohya_ss icon (not official)..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/kohya.ico' -OutFile 'kohya.ico'

    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
    $shortcutName = "kohya_ss"
    $targetPath = "gui-user.bat"
    $IconLocation = 'kohya.ico'
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation
}

# 7. Launch!
./gui-user.bat