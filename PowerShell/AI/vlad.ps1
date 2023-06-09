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
# 3. Install aria2c to make the download models MUCH faster
# 4. Install CUDA and cuDNN
# 5. Check if Conda or Python is installed (is installed - also is 3.10.6 - 3.10.11)
# 6. Check if has Vladmandic SD.Next directory ($TCHT\vladmandic) (Default C:\TCHT\vladmandic)
# 7. Enable auto-update?
# 8. Create desktop shortcuts?
# 9. Download Stable Diffusion 1.5 model
# 10. Launch SD.Next
# ----------------------------------------

Write-Host "-------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's Vladmandic SD.Next (Automatic) installer!" -ForegroundColor Cyan
Write-Host "Vladmandic SD.Next (Automatic) as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-06-06]" -ForegroundColor Cyan
Write-Host "`nThis script is provided AS-IS without warranty of any kind. See https://tc.ht/privacy & https://tc.ht/terms."
Write-Host "Consider supporting these install scripts: https://tc.ht/support" -ForegroundColor Green
Write-Host "-------------------------------------------------------------------`n`n" -ForegroundColor Cyan

Set-Variable ProgressPreference SilentlyContinue # Remove annoying yellow progress bars when doing Invoke-WebRequest for this session

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
    Read-Host
}

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")

# 1. Install Chocolatey
Clear-ConsoleScreen
Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
$TCHT = Get-TCHTPath -Subfolder "vladmandic"

# If user chose to install this program in another path, create a symlink for easy access and management.
$isSymlink = Sync-ProgramFolder -ChosenPath $TCHT -Subfolder "vladmandic"

# Then CD into $TCHT\
Set-Location "$TCHT\"

# 2. Install or update Git if not already installed
Clear-ConsoleScreen
Write-Host "Installing Git..." -ForegroundColor Cyan
iex (irm install-git.tc.ht)

# 3. Install aria2c to make the model downloads MUCH faster
Clear-ConsoleScreen
Write-Host "Installing aria2c (Faster model download)..." -ForegroundColor Cyan
choco upgrade aria2 -y

# 4. Install CUDA and cuDNN
if ((Get-CimInstance Win32_VideoController).Name -like "*Nvidia*") {
    Import-FunctionIfNotExists -Command Install-CudaAndcuDNN -ScriptUri "Install-Cuda.tc.ht"
    Install-CudaAndcuDNN -CudaVersion "11.8" -CudnnOptional $true
}

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tc.ht)
Update-SessionEnvironment

# 5. Check if Conda or Python is installed
# Check if Conda is installed
Import-FunctionIfNotExists -Command Get-UseConda -ScriptUri "Get-Python.tc.ht"

# Check if Conda is installed
$condaFound = Get-UseConda -Name "Vladmandic SD.Next" -EnvName "vlad" -PythonVersion "3.10.11"

# Get Python command (eg. python, python3) & Check for compatible version
if ($condaFound) {
    conda activate "vlad"
    $python = "python"
} else {
    $python = Get-Python -PythonRegex 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])' -PythonRegexExplanation "Python version is not between 3.10.6 and 3.10.11." -PythonInstallVersion "3.10.11" -ManualInstallGuide "https://github.com/vladmandic/automatic#install" 
    if ($python -eq "miniconda") {
        $python = "python"
        $condaFound = $true
    }
}


# 6. Check if has Vladmandic SD.Next directory ($TCHT\vladmandic) (Default C:\TCHT\vladmandic)
Clear-ConsoleScreen
if ((Test-Path -Path "$TCHT\vladmandic") -and -not $isSymlink) {
    Write-Host "The 'vladmandic' folder already exists. We'll pull the latest updates (git pull)" -ForegroundColor Green
    Set-Location "$TCHT\vladmandic"
    git pull
    if ($LASTEXITCODE -eq 128) {
        Write-Host "Could not find existing git repository. Cloning Retrieval-based-Voice-Conversion-WebUI...`n`n"
        git clone https://github.com/vladmandic/automatic.git .
    }
} else {
    Write-Host "I'll start by installing Vladmandic SD.Next first, then we'll get to the models...`n`n"
    
    if (!(Test-Path -Path "$TCHT\vladmandic")) {
        New-Item -ItemType Directory -Path "$TCHT\vladmandic" | Out-Null
    }
    Set-Location "$TCHT\vladmandic"

    git clone https://github.com/vladmandic/automatic.git .
}

if ($condaFound) {
    python -m venv ./venv
    ./venv/Scripts/python.exe -m pip install --upgrade pip
    ./venv/Scripts/python.exe -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    ./venv/Scripts/python.exe -m pip install -r requirements.txt
    ./venv/Scripts/python.exe -m pip install clip_interrogator sqlalchemy rembg timm transformers==4.26.1
}


# 7. Enable auto-update?
Clear-ConsoleScreen
do {
    Write-Host -ForegroundColor Cyan -NoNewline "Do you want to enable auto-update?`n(You can always update manually. This is a Vladmandic SD.Next launch option)`nAnswer: (y/n) [Default: y]: "
    $answer = Read-Host
} while ($answer -notin "Y", "y", "N", "n", "")

$extraArgs = ""
if ($answer -in "Y", "y", "") {
    $extraArgs += " --upgrade"
}

# 7. Share with Gradio?
Clear-ConsoleScreen
Write-Host "Do you want to share your WebUI over the internet? (--share)" -ForegroundColor Cyan
Write-Host "NOTE: If yes, you will likely need to create an antivirus exception (More info provided if yes)." -ForegroundColor Cyan

do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nEnter an answer (y/n) [Default: n]: "
    $answer = Read-Host
} while ($answer -notin "Y", "y", "N", "n", "")

if ($answer  -in "Y", "y") {
    Write-Host "To fix the AntiVirus warning see: https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Troubleshooting#--share-non-functional-after-gradio-322-update" -ForegroundColor Cyan
    Write-Host "You may need to restore the file, and run the WebUI again for it to work" -ForegroundColor Yellow

    $extraArgs += " --share"
}

Set-Content -Path "webui-user.bat" -Value "@echo off`nwebui.bat$extraArgs`npause"
Set-Content -Path "webui-user.sh" -Value "@echo off`n./webui.sh$extraArgs`nread -p `"Press enter to continue`""

# 8. Create desktop shortcuts?
Clear-ConsoleScreen
Write-Host "Create desktop shortcuts for SD.Next?" -ForegroundColor Cyan
do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want desktop shortcuts? (y/n) [Default: y]: "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n", "")

if ($shortcuts -in "Y","y", "") {
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading Vladmandic SD.Next icon..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/vlad.ico' -OutFile 'vlad.ico'

    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
    $shortcutName = "Vladmandic SD.Next"
    $targetPath = "webui-user.bat"
    $IconLocation = 'vlad.ico'
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation
    
}

# 9. Download Stable Diffusion 1.5 model
Clear-ConsoleScreen
Write-Host "Getting started? Do you have models?" -ForegroundColor Cyan
do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want to download the Stable Diffusion 1.5 model? (y/n) [Default: n]: "
    $defaultModel = Read-Host
} while ($defaultModel -notin "Y", "y", "N", "n", "")

if ($defaultModel -eq "Y" -or $defaultModel -eq "y") {
    Import-FunctionIfNotExists -Command Get-Aria2File -ScriptUri "File-DownloadMethods.tc.ht"
    Get-Aria2File -Url "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" -OutputPath "models\Stable-diffusion\v1-5-pruned-emaonly.safetensors"
}

# 10. Launch SD.Next
Write-Host "`n`nLaunching Vladmandic SD.Next!" -ForegroundColor Cyan
./webui.bat