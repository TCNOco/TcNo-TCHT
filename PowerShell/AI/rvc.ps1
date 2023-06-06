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
# 4. Install VCRedist (if missing any)
# 5. Install aria2c to make the model downloads MUCH faster
# 6. Install CUDA and cuDNN
# 7. Check if Conda or Python is installed
# 8. Check if has rvc directory ($TCHT\Retrieval-based-Voice-Conversion-WebUI) (Default C:\TCHT\Retrieval-based-Voice-Conversion-WebUI)
# 9. Download required files/models:
# - Install 7zip
# - Download file
# - Extract file
# 10. Install PyTorch and requirements:
# 11. Create launcher files
# 12. Create shortcuts
# 13. Launch
# ----------------------------------------

Write-Host "---------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's Retrieval-based Voice Conversion WebUI installer!" -ForegroundColor Cyan
Write-Host "RVC as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-06-06]" -ForegroundColor Cyan
Write-Host "`nConsider supporting these install scripts: https://tc.ht/support" -ForegroundColor Cyan
Write-Host "---------------------------------------------------------------------------`n`n" -ForegroundColor Cyan

Set-Variable ProgressPreference SilentlyContinue # Remove annoying yellow progress bars when doing Invoke-WebRequest for this session

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
    Read-Host
}

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")

Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
$TCHT = Get-TCHTPath -Subfolder "Retrieval-based-Voice-Conversion-WebUI"

# If user chose to install this program in another path, create a symlink for easy access and management.
$isSymlink = Sync-ProgramFolder -ChosenPath $TCHT -Subfolder "Retrieval-based-Voice-Conversion-WebUI"

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

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tc.ht)

# 3. Install FFMPEG if not already registered with PATH
Clear-ConsoleScreen
$ffmpegFound = [bool](Get-Command ffmpeg -ErrorAction SilentlyContinue)
if (-not $ffmpegFound) {
    Write-Host "Installing FFMPEG-Full..." -ForegroundColor Cyan
    choco upgrade ffmpeg-full -y
    Write-Host "Done." -ForegroundColor Green
}

# 4. Install VCRedist (if missing any)
Clear-ConsoleScreen
Write-Host "Installing required VCRuntimes..." -ForegroundColor Cyan
choco upgrade vcredist2015 -y

# 5. Install aria2c to make the model downloads MUCH faster
Clear-ConsoleScreen
Write-Host "Installing aria2c (Faster model download)..." -ForegroundColor Cyan
choco upgrade aria2 -y
Update-SessionEnvironment

# 6. Install CUDA and cuDNN
if ((Get-CimInstance Win32_VideoController).Name -like "*Nvidia*") {
    Import-FunctionIfNotExists -Command Install-CudaAndcuDNN -ScriptUri "Install-Cuda.tc.ht"
    Install-CudaAndcuDNN -CudaVersion "11.8" -CudnnOptional $true
}

# 7. Check if Conda or Python is installed
# Check if Conda is installed
Import-FunctionIfNotExists -Command Get-UseConda -ScriptUri "Get-Python.tc.ht"

# Check if Conda is installed
$condaFound = Get-UseConda -Name "RVC" -EnvName "rvc" -PythonVersion "3.10.11"

# Get Python command (eg. python, python3) & Check for compatible version
if ($condaFound) {
    conda activate "rvc"
    $python = "python"
} else {
    $python = Get-Python -PythonRegex 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])' -PythonRegexExplanation "Python version is not between 3.10.6 and 3.10.11." -PythonInstallVersion "3.10.11" -ManualInstallGuide "https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI/blob/main/docs/README.en.md#preparing-the-environment"
    if ($python -eq "miniconda") {
        $python = "python"
        $condaFound = $true
    }
}

# 8. Check if has rvc directory ($TCHT\Retrieval-based-Voice-Conversion-WebUI) (Default C:\TCHT\Retrieval-based-Voice-Conversion-WebUI)
Clear-ConsoleScreen
if ((Test-Path -Path "$TCHT\Retrieval-based-Voice-Conversion-WebUI") -and -not $isSymlink) {
    Write-Host "The 'Retrieval-based-Voice-Conversion-WebUI' folder already exists. We'll pull the latest updates (git pull)" -ForegroundColor Green
    Set-Location "$TCHT\Retrieval-based-Voice-Conversion-WebUI"
    git pull
    if ($LASTEXITCODE -eq 128) {
        Write-Host "Could not find existing git repository. Cloning Retrieval-based-Voice-Conversion-WebUI...`n`n"
        git clone https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI.git .
    }
} else {
    Write-Host "I'll start by installing RVC first, then we'll get to the models...`n`n"
    
    if (!(Test-Path -Path "$TCHT\Retrieval-based-Voice-Conversion-WebUI")) {
        New-Item -ItemType Directory -Path "$TCHT\Retrieval-based-Voice-Conversion-WebUI" | Out-Null
    }
    Set-Location "$TCHT\Retrieval-based-Voice-Conversion-WebUI"

    git clone https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI.git .
}

# 9. Download required files/models:
Import-FunctionIfNotExists -Command Get-Aria2File -ScriptUri "File-DownloadMethods.tc.ht"

# - Install 7zip
$sevenZipFound = [bool](Get-Command 7z -ErrorAction SilentlyContinue)
if (-not $sevenZipFound) {
    Write-Host "Installing 7-Zip..." -ForegroundColor Cyan
    choco upgrade 7zip.install -y
    Write-Host "Done." -ForegroundColor Green
}
Update-SessionEnvironment

# - Download file
Clear-ConsoleScreen
Write-Host "Downloading the latest required models (RVC-beta.7z)" -ForegroundColor Yellow
$url = "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/RVC-beta.7z"
$outputPath = "RVC-beta.7z"
Get-Aria2File -Url $url -OutputPath $outputPath

# - Extract file
Write-Host "Extracting the latest required models (RVC-beta.7z)" -ForegroundColor Yellow
7z x $outputPath -y
$source = (Get-ChildItem -Directory -Filter "RVC-beta*" | Select-Object -Last 1).FullName
$destination = (Get-Location)
# Recursively move files and folders
Write-Host "Moving files..." -ForegroundColor Yellow
Copy-Item $source\* -Destination $destination -Force -Recurse
Write-Host "Deleting duplicate files..." -ForegroundColor Yellow
Remove-Item -Path $source -Recurse -Force

# 10. Install PyTorch and requirements:
if ($condaFound) {
    # For some reason conda NEEDS to be deactivated and reactivated to use pip reliably... Otherwise python and pip are not found.
    conda deactivate
    Update-SessionEnvironment
    #Open-Conda
    conda activate rvc
    conda install -c conda-forge faiss -y
    if ((Get-CimInstance Win32_VideoController).Name -like "*Nvidia*") {
        conda install cudatoolkit -y
    }

    python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    python -m pip install -r requirements.txt
    pip install --upgrade --no-deps --force-reinstall torchcrepe
} else {
    &$python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    &$python -m pip install -r requirements.txt
    &$python -m pip uninstall -y faiss-cpu
    &$python -m pip install faiss-cpu
    &$python -m pip install ffmpeg-python
    &$python -m pip install --upgrade --no-deps --force-reinstall torchcrepe
    Update-SessionEnvironment
}


# 11. Create launcher files
Write-Host "Creating launcher files..." -ForegroundColor Yellow
# - Updater
$OutputFilePath = "update.bat"
$OutputText = "@echo off`ngit pull"
Set-Content -Path $OutputFilePath -Value $OutputText

$InstallLocation = "`"$(Get-Location)`""
$ReinstallCommand = ""
if ($condaFound -and ((Get-CimInstance Win32_VideoController).Name -like "*Nvidia*")) {
    $ReinstallCommand += "conda install cudatoolkit -y`n"
}
$ReinstallCommand += "python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118`npython -m pip install -r requirements.txt`npython -m pip install --upgrade --no-deps --force-reinstall torchcrepe`npython -m pip uninstall faiss-cpu`npython -m pip install faiss-cpu`npython -m pip install ffmpeg-python"
$ProgramName = "Retrieval-based Voice Conversion WebUI"
$RunCommand = "python infer-web.py"
$LauncherName = "run-rvc"

if ($condaFound) {
    # As the Windows Target path can only have 260 chars, we easily hit that limit... (Shortcuts) and some users don't know about running ps1 files.
    $condaPath = "`"$(Get-CondaPath)`""
    $CondaEnvironmentName = "rvc"
    
    New-LauncherWithErrorHandling -ProgramName $ProgramName -InstallLocation $InstallLocation -RunCommand $RunCommand -ReinstallCommand $ReinstallCommand -CondaPath $condaPath -CondaEnvironmentName $CondaEnvironmentName -LauncherName $LauncherName
} else {

    New-LauncherWithErrorHandling -ProgramName $ProgramName -InstallLocation $InstallLocation -RunCommand $RunCommand -ReinstallCommand $ReinstallCommand -LauncherName $LauncherName
}


# 12. Create shortcuts
Clear-ConsoleScreen
Write-Host "Create desktop shortcuts for RVC?" -ForegroundColor Cyan
do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want desktop shortcuts? (y/n) [Default: y]: "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n", "")

if ($shortcuts -in "Y","y", "") {
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading RVC icon (not official)..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/rvc.ico' -OutFile 'rvc.ico'

    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
    $shortcutName = "Retrieval-based Voice Conversion WebUI"
    $targetPath = "run-rvc.bat"
    $IconLocation = 'rvc.ico'
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation
}

# 13. Launch
Clear-ConsoleScreen
Write-Host "Launching Retrieval-based Voice Conversion WebUI!" -ForegroundColor Cyan
./run-rvc.bat
