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
# 4. Check if Conda or Python is installed (is installed - also is 3.10.6 - 3.10.11)
# 5. Check if has Vladmandic SD.Next directory ($TCHT\vladmandic) (Default C:\TCHT\vladmandic)
# 6. Enable auto-update?
# 7. Create desktop shortcuts?
# 8. Download Stable Diffusion 1.5 model
# 9. Launch SD.Next
# ----------------------------------------

Write-Host "-------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's Vladmandic SD.Next (Automatic) installer!" -ForegroundColor Cyan
Write-Host "Vladmandic SD.Next (Automatic) as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-06-01]" -ForegroundColor Cyan
Write-Host "`nConsider supporting these install scripts: https://tc.ht/support" -ForegroundColor Cyan
Write-Host "-------------------------------------------------------------------`n`n" -ForegroundColor Cyan

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

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tc.ht)
Update-SessionEnvironment

# 4. Check if Conda or Python is installed
# Check if Conda is installed
iex (irm Get-CondaAndPython.tc.ht)

# Check if Conda is installed
$condaFound = Get-UseConda -Name "Vladmandic SD.Next" -EnvName "vlad" -PythonVersion "3.10.11"

# Get Python command (eg. python, python3) & Check for compatible version
$python = Get-Python -PythonRegex 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])' -PythonRegexExplanation "Python version is not between 3.10.6 and 3.10.11." -PythonInstallVersion "3.10.11" -ManualInstallGuide "https://github.com/vladmandic/automatic#install" -condaFound $condaFound


# 5. Check if has Vladmandic SD.Next directory ($TCHT\vladmandic) (Default C:\TCHT\vladmandic)
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


# 6. Enable auto-update?
Clear-ConsoleScreen
do {
    Write-Host -ForegroundColor Cyan -NoNewline "Do you want to enable auto-update? (You can always update manually. This is a Vladmandic SD.Next launch option) (y/n): "
    $answer = Read-Host
} while ($answer -notin "Y", "y", "N", "n")

$extraArgs = ""
if ($answer -eq "y" -or $answer -eq "Y") {
    $extraArgs = $extraArgs + "--upgrade"
}

Set-Content -Path "webui-user.bat" -Value "@echo off`nwebui.bat $extraArgs`npause"
Set-Content -Path "webui-user.sh" -Value "@echo off`n./webui.sh $extraArgs`nread -p `"Press enter to continue`""

# 7. Share with Gradio?

# 7. Create desktop shortcuts?
Clear-ConsoleScreen
Write-Host "Create desktop shortcuts for SD.Next?" -ForegroundColor Cyan
do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want desktop shortcuts? (y/n): "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n")

if ($shortcuts -eq "Y" -or $shortcuts -eq "y") {
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading Vladmandic SD.Next icon..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/vlad.ico' -OutFile 'vlad.ico'

    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
    $shortcutName = "Vladmandic SD.Next"
    $targetPath = "webui-user.bat"
    $IconLocation = 'vlad.ico'
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation
    
}

# 8. Download Stable Diffusion 1.5 model
Clear-ConsoleScreen
Write-Host "Getting started? Do you have models?" -ForegroundColor Cyan
do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want to download the Stable Diffusion 1.5 model? (y/n): "
    $defaultModel = Read-Host
} while ($defaultModel -notin "Y", "y", "N", "n")

if ($defaultModel -eq "Y" -or $defaultModel -eq "y") {
    Import-FunctionIfNotExists -Command Get-Aria2File -ScriptUri "File-DownloadMethods.tc.ht"
    Get-Aria2File -Url "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" -OutputPath "models\Stable-diffusion\v1-5-pruned-emaonly.safetensors"
}

# 9. Launch SD.Next
Write-Host "`n`nLaunching Vladmandic SD.Next!" -ForegroundColor Cyan
./webui-user.bat