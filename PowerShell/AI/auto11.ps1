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
# 5. Download AUTOMATIC1111 repo
# 6. Enable xformers?
# 7. Fix for AMD GPUs (untested)
# 8. Low VRAM
# 9. Share with Gradio?
# 10. Create desktop shortcuts?
# 11. Download Stable Diffusion 1.5 model
# 12. Launch AUTOMATIC1111 Stable Diffusion WebUI
# ----------------------------------------


Write-Host "Welcome to TroubleChute's AUTOMATIC1111 installer!" -ForegroundColor Cyan
Write-Host "AUTOMATIC1111 as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-11]`n`n" -ForegroundColor Cyan

# 1. Install Chocolatey
Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install or update Git if not already installed
Write-Host "`nInstalling Git..." -ForegroundColor Cyan
iex (irm install-git.tc.ht)

# 3. Install aria2c to make the download models MUCH faster
Write-Host "`nInstalling aria2c (Faster model download)..." -ForegroundColor Cyan
choco install aria2 -y
Update-SessionEnvironment

# 4. Check if Conda or Python is installed
# Check if Conda is installed
$condaFound = Get-Command conda -ErrorAction SilentlyContinue
if (-not $condaFound) {
    # Try checking if conda is installed a little deeper... (May not always be activated for user)
    # Allow importing remote functions
    iex (irm Get-CondaPath.tc.ht)
    $condaFound = Open-Conda # This checks for Conda, returns true if conda is hoooked
    Update-SessionEnvironment
}

# If conda found: create environment
if ($condaFound) {
    Write-Host "`n`nDo you want to install AUTOMATIC1111 Stable Diffusion WebUI in a Conda environment called 'a11'?`nYou'll need to use 'conda activate a11' before being able to use it?"-ForegroundColor Cyan

    do {
        Write-Host -ForegroundColor Cyan -NoNewline "`n`nUse Conda (y/n): "
        $installWhisper = Read-Host
    } while ($installWhisper -notin "Y", "y", "N", "n")
    
    if ($installWhisper -eq "y" -or $installWhisper -eq "Y") {
        conda create -n a11 python=3.10.6 -y
        conda activate a11
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
        
            $pythonProgramName = Read-Host "Enter the Python program name (e.g. python3, python310):"
            $pythonVersion = &$pythonProgramName --version 2>&1
            if ($pythonVersion -match 'Python([3].[1][0-1].[6-9]|3.10.1[0-1])') {
                Write-Host "Python version $($matches[1]) is installed."
                $python = $pythonProgramName
            } else {
                Write-Host "Python version is not between 3.10.6 and 3.10.11."
                Write-Host "Alternatively, follow this guide for manual installation: https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs" -ForegroundColor Red
                Read-Host "Process can try to continue, but will likely fail. Press any key to continue..."
            }
        }
    }
    Catch {
        Write-Host "Python version is not between 3.10.6 - 3.10.11."
        Write-Host "Alternatively, follow this guide for manual installation: https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs..." -ForegroundColor Red
        Read-Host "Process can try to continue, but will likely fail. Press any key to continue..."
    }
}



# 5. Download AUTOMATIC1111 repo (but also find out where it is, incase we're in the folder already)
$currentDir = (Get-Item -Path ".\" -Verbose).FullName
if ($currentDir -like "*\stable-diffusion-webui") {
    Set-Location ../
}

git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git # Download A1 SDUI if not already here
Set-Location stable-diffusion-webui
git pull # Update A1 SDUI

# 6. Enable xformers?

do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want to enable xformers for extra speed? (Recommended) (y/n): "
    $answer = Read-Host
} while ($answer -notin "Y", "y", "N", "n")

if ($answer -eq "y" -or $answer -eq "Y") {
    (Get-Content webui-user.bat) | Foreach-Object {
        $_ -replace 'set COMMANDLINE_ARGS=', 'set COMMANDLINE_ARGS=--xformers --reinstall-xformers '
    } | Set-Content webui-user.bat
} else {
}

# 7. Fix for AMD GPUs (untested)
if ((Get-WmiObject Win32_VideoController).Name -like "AMD") {
    Write-Host "`n`nAMD GPU is installed. Applying fix (https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-AMD-GPUs#automatic-installation)" -ForegroundColor Cyan
    (Get-Content webui-user.bat) | Foreach-Object {
        $_ -replace 'set COMMANDLINE_ARGS=', 'set COMMANDLINE_ARGS=--precision full --no-half '
    } | Set-Content webui-user.bat
    Write-Host "Please check the link above. You may not need '--precision full --no-half' in webui-user.bat, but other AMD GPUs will not work with SDUI without this. Having this will slow your image generations a LOT." -ForegroundColor Cyan
}

# 8. Low VRAM
Write-Host "`n`nImage generation uses a lot of VRAM. There are tons of optimizations to do." -ForegroundColor Cyan

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
Write-Host "`n`nDo you want to share your WebUI over the internet? (--share)" -ForegroundColor Cyan
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
Write-Host "`n`nCreate desktop shortcuts for AUTOMATIC1111?" -ForegroundColor Cyan

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
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want desktop shortcuts? (y/n): "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n")

iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
if ($shortcuts -eq "Y" -or $shortcuts -eq "y") {
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
Import-FunctionIfNotExists -Command Get-Aria2File -ScriptUri "File-DownloadMethods.tc.ht"
Get-Aria2File -Url "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" -OutputPath "models\Stable-diffusion\v1-5-pruned-emaonly.safetensors"

# 12. Launch AUTOMATIC1111 Stable Diffusion WebUI
Write-Host "`n`nLaunching AUTOMATIC1111 Stable Diffusion WebUI!" -ForegroundColor Cyan
./webui-user.bat