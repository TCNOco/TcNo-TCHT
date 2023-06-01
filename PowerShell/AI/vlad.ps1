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
Write-Host "Consider supporting these install scripts: https://tc.ht/support" -ForegroundColor Cyan
Write-Host "[Version 2023-06-01]" -ForegroundColor Cyan
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
Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
$TCHT = Get-TCHTPath

# Then CD into $TCHT\
Set-Location "$TCHT\"

# 2. Install or update Git if not already installed
Clear-ConsoleScreen
Write-Host "`nInstalling Git..." -ForegroundColor Cyan
iex (irm install-git.tc.ht)

# 3. Install aria2c to make the model downloads MUCH faster
Clear-ConsoleScreen
Write-Host "`nInstalling aria2c (Faster model download)..." -ForegroundColor Cyan
choco upgrade aria2 -y

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tc.ht)
Update-SessionEnvironment

# 4. Check if Conda or Python is installed
# Check if Conda is installed
$condaFound = Get-Command conda -ErrorAction SilentlyContinue
iex (irm Get-CondaPath.tc.ht)
if (-not $condaFound) {
    # Try checking if conda is installed a little deeper... (May not always be activated for user)
    $condaFound = Open-Conda # This checks for Conda, returns true if conda is hoooked
    Update-SessionEnvironment
}

# If conda found: create environment
Clear-ConsoleScreen
if ($condaFound) {
    Write-Host "Do you want to install Vladmandic SD.Next in a Conda environment called 'vlad'?`nYou'll need to use 'conda activate vlad' before being able to use it?"-ForegroundColor Cyan

    do {
        Write-Host -ForegroundColor Cyan -NoNewline "`n`nUse Conda (y/n): "
        $useConda = Read-Host
    } while ($useConda -notin "Y", "y", "N", "n")
    
    if ($useConda -eq "y" -or $useConda -eq "Y") {
        conda create -n vlad python=3.10.11 -y
        conda activate vlad
    } else {
        $condaFound = $false
        Write-Host "Checking for Python instead..."
    }
}

$python = "python"
if (-not ($condaFound)) {
    # Try Python instead
    # Check if Python returns anything (is installed - also is 3.10.6 - 3.10.11)
    Try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])') {
            Write-Host "Python version $($matches[1]) is installed." -ForegroundColor Green
        }
    }
    Catch {
        Write-Host "Python is not installed." -ForegroundColor Yellow
        Write-Host "`nInstalling Python 3.10.11." -ForegroundColor Cyan
        choco install python --version=3.10.11 -y
        Update-SessionEnvironment
    }

    # Verify Python install
    Try {
        $pythonVersion = &$python --version 2>&1
        if ($pythonVersion -match 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])') {
            Write-Host "Python version $($matches[1]) is installed." -ForegroundColor Green
        }
        else {
            Write-Host "Python version is not between 3.10.6 and 3.10.11." -ForegroundColor Yellow
            Write-Host "Assuming you've installed the correct version, please enter the comand you use to access Python 3.9/3.10." -ForegroundColor Yellow
        
            $pythonProgramName = Read-Host "Enter the Python program name (e.g. python3, python310)"
            $pythonVersion = &$pythonProgramName --version 2>&1
            if ($pythonVersion -match 'Python([3].[1][0-1].[6-9]|3.10.1[0-1])') {
                Write-Host "Python version $($matches[1]) is installed."
                $python = $pythonProgramName
            } else {
                Write-Host "Python version is not between 3.10.6 and 3.10.11."
                Write-Host "Alternatively, follow this guide for manual installation: https://github.com/vladmandic/automatic#install" -ForegroundColor Red
                Read-Host "Process can try to continue, but will likely fail. Press Enter to continue..."
            }
        }
    }
    Catch {
        Write-Host "Python version is not between 3.10.6 - 3.10.11."
        Write-Host "Alternatively, follow this guide for manual installation: https://github.com/vladmandic/automatic#install..." -ForegroundColor Red
        Read-Host "Process can try to continue, but will likely fail. Press Enter to continue..."
    }
}


# 5. Check if has Vladmandic SD.Next directory ($TCHT\vladmandic) (Default C:\TCHT\vladmandic)
Clear-ConsoleScreen
if (Test-Path -Path "$TCHT\vladmandic") {
    Write-Host "The 'vladmandic' folder already exists. We'll pull the latest updates (git pull)" -ForegroundColor Green
    Set-Location "$TCHT\vladmandic"
    git pull
} else {
    Write-Host "I'll start by installing Vladmandic SD.Next first, then we'll get to the models...`n`n"
    
    if (!(Test-Path -Path "$TCHT")) {
        New-Item -ItemType Directory -Path "$TCHT"
    }

    # Then CD into $TCHT\
    Set-Location "$TCHT\"

    # - Clone https://github.com/vladmandic/automatic
    git clone https://github.com/vladmandic/automatic.git vladmandic
    Set-Location "$TCHT\vladmandic"
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

Set-Content -Path "webui-user.bat" -Value "@echo off`n./webui.bat $extraArgs`npause"
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
    
    Write-Host "Downloading Vladmandic SD.Next icon (not official)..."
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