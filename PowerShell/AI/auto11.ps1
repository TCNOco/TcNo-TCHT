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
# 5. Check if has AUTOMATIC1111 directory ($TCHT\stable-diffusion-webui) (Default C:\TCHT\stable-diffusion-webui)
# 6. Enable xformers?
# 7. Fix for AMD GPUs (untested)
# 8. Low VRAM
# 9. Share with Gradio?
# 10. Create desktop shortcuts?
# 11. Download Stable Diffusion 1.5 model
# 12. Launch AUTOMATIC1111 Stable Diffusion WebUI
# ----------------------------------------


Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's AUTOMATIC1111 installer!" -ForegroundColor Cyan
Write-Host "AUTOMATIC1111 as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-11]" -ForegroundColor Cyan
Write-Host "`nConsider supporting these install scripts: https://tc.ht/support" -ForegroundColor Cyan
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
$TCHT = Get-TCHTPath -Subfolder "stable-diffusion-webui"

# If user chose to install this program in another path, create a symlink for easy access and management.
$isSymlink = Sync-ProgramFolder -ChosenPath $TCHT -Subfolder "stable-diffusion-webui"

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

# 3. Install aria2c to make the model downloads MUCH faster
Clear-ConsoleScreen
Write-Host "Installing aria2c (Faster model download)..." -ForegroundColor Cyan
choco upgrade aria2 -y

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tc.ht)
Update-SessionEnvironment

# 4. Check if Conda or Python is installed
iex (irm Get-CondaAndPython.tc.ht)

# Check if Conda is installed
$condaFound = Get-UseConda -Name "AUTOMATIC1111 Stable Diffusion WebUI" -EnvName "a11" -PythonVersion "3.10.6"

# Get Python command (eg. python, python3) & Check for compatible version
$python = Get-Python -PythonRegex 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])' -PythonRegexExplanation "Python version is not between 3.10.6 and 3.10.11." -PythonInstallVersion "3.10.11" -ManualInstallGuide "https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs" -condaFound $condaFound

# 5. Check if has AUTOMATIC1111 directory ($TCHT\stable-diffusion-webui) (Default C:\TCHT\stable-diffusion-webui)
Clear-ConsoleScreen
if ((Test-Path -Path "$TCHT\stable-diffusion-webui") -and -not $isSymlink) {
    Write-Host "The 'stable-diffusion-webui' folder already exists. We'll pull the latest updates (git pull)" -ForegroundColor Green
    Set-Location "$TCHT\stable-diffusion-webui"
    git pull
    if ($LASTEXITCODE -eq 128) {
        Write-Host "Could not find existing git repository. Cloning AUTOMATIC1111...`n`n"
        git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git .
    }
} else {
    Write-Host "I'll start by installing AUTOMATIC1111 Stable Diffusion WebUI first, then we'll get to the models...`n`n"
    
    if (!(Test-Path -Path "$TCHT\stable-diffusion-webui")) {
        New-Item -ItemType Directory -Path "$TCHT\stable-diffusion-webui" | Out-Null
    }
    Set-Location "$TCHT\stable-diffusion-webui"

    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git .
}

# 6. Enable xformers?
Clear-ConsoleScreen
do {
    Write-Host -ForegroundColor Cyan -NoNewline "Do you want to enable xformers for extra speed? (Recommended) (y/n): "
    $answer = Read-Host
} while ($answer -notin "Y", "y", "N", "n")

if ($answer -eq "y" -or $answer -eq "Y") {
    (Get-Content webui-user.bat) | Foreach-Object {
        $_ -replace 'set COMMANDLINE_ARGS=', 'set COMMANDLINE_ARGS=--xformers --reinstall-xformers '
    } | Set-Content webui-user.bat
} else {
}

# 7. Fix for AMD GPUs (untested)
if ((Get-CimInstance Win32_VideoController).Name -like "AMD") {
    Write-Host "`n`nAMD GPU is installed. Applying fix (https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-AMD-GPUs#automatic-installation)" -ForegroundColor Cyan
    (Get-Content webui-user.bat) | Foreach-Object {
        $_ -replace 'set COMMANDLINE_ARGS=', 'set COMMANDLINE_ARGS=--precision full --no-half '
    } | Set-Content webui-user.bat
    Write-Host "Please check the link above. You may not need '--precision full --no-half' in webui-user.bat, but other AMD GPUs will not work with SDUI without this. Having this will slow your image generations a LOT." -ForegroundColor Cyan
}

# 8. Low VRAM
Clear-ConsoleScreen
Write-Host "Image generation uses a lot of VRAM. There are tons of optimizations to do." -ForegroundColor Cyan

do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you have 8GB or more VRAM? (y/n): "
    $answer = Read-Host
} while ($answer -notin "Y", "y", "N", "n")

if ($answer -eq "y" -or $answer -eq "Y") {
    Write-Host "Great! You should have enough VRAM. You should check the following pages anyway for more:" -ForegroundColor Cyan
    Write-Host "Optimizations: https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Optimizations" -ForegroundColor Yellow
    Write-Host "Troubleshooting: https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Troubleshooting" -ForegroundColor Yellow
} else {
    
    do {
        Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you have more than 4GB VRAM (Answer no if 4GB and want >512px images)? (y/n): "
        $answer = Read-Host
    } while ($answer -notin "Y", "y", "N", "n")

    if ($answer -eq "y" -or $answer -eq "Y") {
        Write-Host "Applying --medvram optimization" -ForegroundColor Cyan
        (Get-Content webui-user.bat) | Foreach-Object {
            $_ -replace 'set COMMANDLINE_ARGS=', 'set COMMANDLINE_ARGS=--medvram '
        } | Set-Content webui-user.bat
    } else {
        Write-Host "Applying --lowvram optimization" -ForegroundColor Cyan
        (Get-Content webui-user.bat) | Foreach-Object {
            $_ -replace 'set COMMANDLINE_ARGS=', 'set COMMANDLINE_ARGS=--lowvram --always-batch-cond-uncond '
        } | Set-Content webui-user.bat
    }
}

# 9. Share with Gradio?
Clear-ConsoleScreen
Write-Host "Do you want to share your WebUI over the internet? (--share)" -ForegroundColor Cyan
Write-Host "NOTE: If yes, you will likely need to create an antivirus exception (More info provided if yes)." -ForegroundColor Cyan

do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nEnter an answer (y/n): "
    $answer = Read-Host
} while ($answer -notin "Y", "y", "N", "n")

if ($answer -eq "y" -or $answer -eq "Y") {
    Write-Host "To fix the AntiVirus warning see: https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Troubleshooting#--share-non-functional-after-gradio-322-update" -ForegroundColor Cyan
    Write-Host "You may need to restore the file, and run the WebUI again for it to work" -ForegroundColor Yellow

    (Get-Content webui-user.bat) | Foreach-Object {
        $_ -replace 'set COMMANDLINE_ARGS=', 'set COMMANDLINE_ARGS=--share '
    } | Set-Content webui-user.bat
}

# 10. Create desktop shortcuts?
Clear-ConsoleScreen
Write-Host "Create desktop shortcuts for AUTOMATIC1111?" -ForegroundColor Cyan

# Create start bat and ps1 files
if ($condaFound) {
    # As the Windows Target path can only have 260 chars, we easily hit that limit...
    $condaPath = Get-CondaPath
    $OutputFilePath = "start-conda.ps1"
    $OutputText = "& '$condaPath'`nconda activate a11`nSet-Location `"$(Get-Location)`"`nwebui-user.bat"
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
    
    Write-Host "Downloading AUTOMATIC1111 icon (not official)..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/automatic1111.ico' -OutFile 'automatic1111.ico'

    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
    $shortcutName = "AUTOMATIC1111 Stable Diffusion WebUI"
    if ($condaFound) {
        $targetPath = "start-conda.bat"
    }
    else {
        $targetPath = "webui-user.bat"
    }
    $IconLocation = 'automatic1111.ico'
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation
    
}

# 11. Download Stable Diffusion 1.5 model
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

# 12. Launch AUTOMATIC1111 Stable Diffusion WebUI
Clear-ConsoleScreen
Write-Host "Launching AUTOMATIC1111 Stable Diffusion WebUI!" -ForegroundColor Cyan
./webui-user.bat