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
# This script:
# 1. Install Chocolatey
# 2. Install or update Git if not already installed
# 3. Install FFMPEG if not already registered with PATH
# 4. Install aria2c to make the model downloads MUCH faster
# 5. Check if Conda or Python is installed
# 6. Check if has roop directory ($TCHT\roop) (Default C:\TCHT\roop)
# 7. Download model
# 8. Install PyTorch and requirements:
# 9. Create launcher files
# 10. Create shortcuts
# 11. Launch
# ----------------------------------------

Write-Host "---------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's Roop installer!" -ForegroundColor Cyan
Write-Host "Roop as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-06-04]" -ForegroundColor Cyan
Write-Host "`nConsider supporting these install scripts: https://tc.ht/support" -ForegroundColor Cyan
Write-Host "---------------------------------------------------------------------------`n`n" -ForegroundColor Cyan

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
    Read-Host
}

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")

Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
$TCHT = Get-TCHTPath -Subfolder "roop"

# If user chose to install this program in another path, create a symlink for easy access and management.
$isSymlink = Sync-ProgramFolder -ChosenPath $TCHT -Subfolder "roop"

# Then CD into $TCHT\
Set-Location "$TCHT\"

# 1. Install Chocolatey
Clear-ConsoleScreen
Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install or update Git if not already installed
Clear-ConsoleScreen
Write-Host "`nInstalling Git..." -ForegroundColor Cyan
iex (irm install-git.tc.ht)

# 3. Install FFMPEG if not already registered with PATH
Clear-ConsoleScreen
$ffmpegFound = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpegFound) {
    Write-Host "Installing FFMPEG-Full..." -ForegroundColor Cyan
    choco upgrade ffmpeg-full -y
    Write-Host "Done." -ForegroundColor Green
}

# 4. Install aria2c to make the model downloads MUCH faster
Clear-ConsoleScreen
Write-Host "`nInstalling aria2c (Faster model download)..." -ForegroundColor Cyan
choco upgrade aria2 -y
Update-SessionEnvironment

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tc.ht)

# 5. Check if Conda or Python is installed
# Check if Conda is installed
iex (irm Get-CondaAndPython.tc.ht)

# Check if Conda is installed
$condaFound = Get-UseConda -Name "Roop" -EnvName "roop" -PythonVersion "3.10.11"

# Get Python command (eg. python, python3) & Check for compatible version
$python = Get-Python -PythonRegex 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])' -PythonRegexExplanation "Python version is not between 3.10.6 and 3.10.11." -PythonInstallVersion "3.10.11" -ManualInstallGuide "https://github.com/s0md3v/roop/wiki/1.-Installation" -condaFound $condaFound

# 6. Check if has roop directory ($TCHT\roop) (Default C:\TCHT\roop)
Clear-ConsoleScreen
if ((Test-Path -Path "$TCHT\roop") -and -not $isSymlink) {
    Write-Host "The 'roop' folder already exists. We'll pull the latest updates (git pull)" -ForegroundColor Green
    Set-Location "$TCHT\roop"
    git pull
} else {
    Write-Host "Cloning Roop...`n`n"
    
    if (!(Test-Path -Path "$TCHT\roop")) {
        New-Item -ItemType Directory -Path "$TCHT\roop" | Out-Null
    }
    Set-Location "$TCHT\roop"

    git clone https://github.com/s0md3v/roop .
}

# 7. Download model
Import-FunctionIfNotExists -Command Get-Aria2File -ScriptUri "File-DownloadMethods.tc.ht"

Clear-ConsoleScreen
Write-Host "Downloading the latest required model (inswapper_128.onnx)" -ForegroundColor Yellow
$url = "https://civitai.com/api/download/models/85159"
$outputPath = "inswapper_128.onnx"
Get-Aria2File -Url $url -OutputPath $outputPath

# 8. Install PyTorch and requirements:
if ($condaFound) {
    # For some reason conda NEEDS to be deactivated and reactivated to use pip reliably... Otherwise python and pip are not found.
    conda deactivate
    Update-SessionEnvironment
    #Open-Conda
    conda activate roop
    conda install -c conda-forge -y
    python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    python -m pip install -r requirements.txt
    conda install cudatoolkit
} else {
    python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    &$python -m pip install -r requirements.txt

    Write-Host "If you don't have the NVIDIA CUDA Toolkit installed, then install it here: https://developer.nvidia.com/cuda-11-8-0-download-archive" -ForegroundColor Cyan
    Write-Host "After installing, press any key to continue..." -ForegroundColor Cyan
    Read-Host

    Update-SessionEnvironment
}

# 9. Create launcher files
Write-Host "Creating launcher files..." -ForegroundColor Yellow
# - Updater
$OutputFilePath = "update.bat"
$OutputText = "@echo off`ngit pull"
Set-Content -Path $OutputFilePath -Value $OutputText

$condaPath = "`"$(Get-CondaPath)`""
$CondaEnvironmentName = "roop"
$InstallLocation = "`"$(Get-Location)`""

# Create Roop launchers (GPU):
$ProgramName = "Roop"
$RunCommand = "python run.py --gpu"
$LauncherName = "run-roop"

if ($condaFound) {
    $ReinstallCommand = "conda install cudatoolkit`npython -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118`npython -m pip install -r requirements.txt"
    New-LauncherWithErrorHandling -ProgramName $ProgramName -InstallLocation $InstallLocation -RunCommand $RunCommand -ReinstallCommand $ReinstallCommand -CondaPath $condaPath -CondaEnvironmentName $CondaEnvironmentName -LauncherName $LauncherName
} else {
    $ReinstallCommand = "python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118`npython -m pip install -r requirements.txt"
    New-LauncherWithErrorHandling -ProgramName $ProgramName -InstallLocation $InstallLocation -RunCommand $RunCommand -ReinstallCommand $ReinstallCommand -LauncherName $LauncherName
}

# Now the same for CPU-only
$ProgramName = "Roop CPU-Only"
$RunCommand = "python run.py"
$LauncherName = "run-roop-cpu"

if ($condaFound) {
    $ReinstallCommand = "conda install cudatoolkit`npython -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118`npython -m pip install -r requirements.txt"
    New-LauncherWithErrorHandling -ProgramName $ProgramName -InstallLocation $InstallLocation -RunCommand $RunCommand -ReinstallCommand $ReinstallCommand -CondaPath $condaPath -CondaEnvironmentName $CondaEnvironmentName -LauncherName $LauncherName
} else {
    $ReinstallCommand = "python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118`npython -m pip install -r requirements.txt"
    New-LauncherWithErrorHandling -ProgramName $ProgramName -InstallLocation $InstallLocation -RunCommand $RunCommand -ReinstallCommand $ReinstallCommand -LauncherName $LauncherName
}

# 10. Create shortcuts
Clear-ConsoleScreen
Write-Host "Create desktop shortcuts for Roop?" -ForegroundColor Cyan
do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want desktop shortcuts? (y/n): "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n")

if ($shortcuts -eq "Y" -or $shortcuts -eq "y") {
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading Roop icon (not official)..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/roop.ico' -OutFile 'roop.ico'

    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
    $shortcutName = "Roop"
    $targetPath = "run-roop.bat"
    $IconLocation = 'roop.ico'
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation

    
    $shortcutName = "Roop CPU-Only"
    $targetPath = "run-roop-cpu.bat"
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation
}

# 11. Launch
Clear-ConsoleScreen
Write-Host "There are more launch options you can add, such as max memory. Add these to the start powershell files. See here: https://github.com/s0md3v/roop#how-do-i-use-it"

Write-Host "Launching Roop!" -ForegroundColor Cyan
./run-roop.bat
