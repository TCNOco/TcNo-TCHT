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
# 3. Install aria2c to make the model downloads MUCH faster
# 4. Check if Conda or Python is installed
# 5. Check if has privateGPT directory ($TCHT\privateGPT) (Default C:\TCHT\privateGPT)
# - Clone https://github.com/imartinez/privateGPT
# 6. Download a model
# 7. Set up the models in env:
# 8. Create Launcher files
# 9. Create desktop shortcuts?
# 10. Launch privateGPT
# ----------------------------------------

Write-Host "Welcome to TroubleChute's privateGPT installer!" -ForegroundColor Cyan
Write-Host "privateGPT as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-05-22]`n`n" -ForegroundColor Cyan

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
    Read-Host
}

# 1. Install Chocolatey
Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install or update Git if not already installed
Write-Host "`nInstalling Git..." -ForegroundColor Cyan
iex (irm install-git.tc.ht)

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tc.ht)

# 3. Install aria2c to make the model downloads MUCH faster
Write-Host "`nInstalling aria2c (Faster model download)..." -ForegroundColor Cyan
choco upgrade aria2 -y
Update-SessionEnvironment

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
$TCHT = Get-TCHTPath

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
    Write-Host "`n`nDo you want to install privateGPT in a Conda environment called 'pgpt'?`nYou'll need to use 'conda activate pgpt' before being able to use it?"-ForegroundColor Cyan

    do {
        Write-Host -ForegroundColor Cyan -NoNewline "`n`nUse Conda (y/n): "
        $useConda = Read-Host
    } while ($useConda -notin "Y", "y", "N", "n")
    
    if ($useConda -eq "y" -or $useConda -eq "Y") {
        conda create -n pgpt python=3.10.6 -y
        conda activate pgpt
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
                Write-Host "Alternatively, follow this guide for manual installation: https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs" -ForegroundColor Red
                Read-Host "Process can try to continue, but will likely fail. Press Enter to continue..."
            }
        }
    }
    Catch {
        Write-Host "Python version is not between 3.10.6 - 3.10.11."
        Write-Host "Alternatively, follow this guide for manual installation: https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs..." -ForegroundColor Red
        Read-Host "Process can try to continue, but will likely fail. Press Enter to continue..."
    }
}

# 5. Check if has privateGPT directory ($TCHT\privateGPT) (Default C:\TCHT\privateGPT)
if (Test-Path -Path "$TCHT\privateGPT") {
    Write-Host "The 'privateGPT' folder already exists. We'll pull the latest updates (git pull)" -ForegroundColor Green
    Set-Location "$TCHT\privateGPT"
    git pull
} else {
    Write-Host "I'll start by installing privateGPT first, then we'll get to the model...`n`n"
    
    if (!(Test-Path -Path "$TCHT")) {
        New-Item -ItemType Directory -Path "$TCHT"
    }

    # Then CD into $TCHT\
    Set-Location "$TCHT\"

    # - Clone https://github.com/imartinez/privateGPT
    git clone https://github.com/imartinez/privateGPT
    Set-Location "$TCHT\privateGPT"
}

function Get-VincunaCPU13B {
    # Download Vicuna 13B
    Write-Host "Downloading Vicuna 13B" -ForegroundColor Yellow
    $blob = "https://huggingface.co/eachadea/ggml-vicuna-13b-1.1/resolve/main"
    $outputPath = "models"
    Write-Host "Downloading: eachadea/ggml-vicuna-13b-1.1 (CPU model)" -ForegroundColor Cyan
    $files = @(
        "ggml-vic13b-q5_1.bin"
    )

    Get-Aria2Files -Url $blob -OutputPath $outputPath -Files $files
    Write-Host "Done" -ForegroundColor Yellow
}

function Get-VincunaUncensoredCPU13B {
    # Download Vicuna 13B
    Write-Host "Downloading Vicuna 13B" -ForegroundColor Yellow
    $blob = "https://huggingface.co/eachadea/ggml-vicuna-13b-1.1/resolve/main"
    $outputPath = "models"
    Write-Host "Downloading: eachadea/ggml-vicuna-13b-1.1 (CPU model)" -ForegroundColor Cyan
    $files = @(
        "ggml-vic13b-uncensored-q5_1.bin"
    )

    Get-Aria2Files -Url $blob -OutputPath $outputPath -Files $files
    Write-Host "Done" -ForegroundColor Yellow
}

function Get-VicunaCPU7B {
    # Download Vicuna 7B
    Write-Host "Downloading Vicuna 7B" -ForegroundColor Yellow
    $blob = "https://huggingface.co/eachadea/ggml-vicuna-7b-1.1/resolve/main"
    $outputPath = "models"
    Write-Host "Downloading: eachadea/ggml-vicuna-7b-1.1 (CPU model)" -ForegroundColor Cyan
    $files = @(
        "ggml-vic7b-q5_1.bin"
    )

    Get-Aria2Files -Url $blob -OutputPath $outputPath -Files $files
    Write-Host "Done" -ForegroundColor Yellow
}

function Get-VicunaUncensoredCPU7B {
    # Download Vicuna 7B
    Write-Host "Downloading Vicuna 7B" -ForegroundColor Yellow
    $blob = "https://huggingface.co/eachadea/ggml-vicuna-7b-1.1/resolve/main"
    $outputPath = "models"
    Write-Host "Downloading: eachadea/ggml-vicuna-7b-1.1 (CPU model)" -ForegroundColor Cyan
    $files = @(
        "ggml-vic7b-uncensored-q5_1.bin"
    )

    Get-Aria2Files -Url $blob -OutputPath $outputPath -Files $files
    Write-Host "Done" -ForegroundColor Yellow
}

function Get-KoalaCPU7B {
    # Download Koala 7B
    Write-Host "Downloading Koala 7B" -ForegroundColor Yellow
    $blob = "https://huggingface.co/TheBloke/koala-7B-GGML/resolve/main"
    $outputPath = "models"
    Write-Host "Downloading: TheBloke/koala-7B-GGML(CPU model)" -ForegroundColor Cyan
    $files = @(
        "koala-7B.ggmlv3.q5_1.bin"
    )

    Get-Aria2Files -Url $blob -OutputPath $outputPath -Files $files
    Write-Host "Done" -ForegroundColor Yellow
}

function Get-KoalaCPU13B {
    # Download Koala 7B
    Write-Host "Downloading Koala 13B" -ForegroundColor Yellow
    $blob = "https://huggingface.co/TheBloke/koala-13B-GGML/resolve/main"
    $outputPath = "models"
    Write-Host "Downloading: TheBloke/koala-13B-GGML(CPU model)" -ForegroundColor Cyan
    $files = @(
        "koala-13B.ggmlv3.q5_1.bin"
    )

    Get-Aria2Files -Url $blob -OutputPath $outputPath -Files $files
    Write-Host "Done" -ForegroundColor Yellow
}

function Get-Gpt4All {
    # Download Koala 7B
    Write-Host "Downloading GPT4ALL-J v1.3 (Default model)" -ForegroundColor Yellow
    $url = "https://gpt4all.io/models/ggml-gpt4all-j-v1.3-groovy.bin"
    $outputPath = "models/ggml-gpt4all-j-v1.3-groovy.bin"
    Get-Aria2File -Url $url -OutputPath $outputPath
    Write-Host "Done" -ForegroundColor Yellow
}

# - Install requirements.txt
&$python -m pip install -r requirements.txt
&$python -m pip install requests "urllib3<2"

# Create models folder
if (!(Test-Path -Path "models")) {
    New-Item -ItemType Directory -Path "models"
}

# Rename env file
if (Test-Path "example.env") {
    # Rename the file
    Rename-Item -Path "example.env" -NewName ".env" -Force
}

# 6. Download a model
do {
    Write-Host "Which model would you like to download and use:" -ForegroundColor Cyan
    Write-Host -NoNewline "Vicuna 13B: " -ForegroundColor Red
    Write-Host "1" -ForegroundColor Green
    Write-Host -NoNewline "Vicuna 13B Uncensored: " -ForegroundColor Red
    Write-Host "2" -ForegroundColor Green
    Write-Host -NoNewline "Vicuna 7B: " -ForegroundColor Red
    Write-Host "3" -ForegroundColor Green
    Write-Host -NoNewline "Vicuna 7B Uncensored: " -ForegroundColor Red
    Write-Host "4" -ForegroundColor Green
    Write-Host -NoNewline "Koala 7B: " -ForegroundColor Red
    Write-Host "5" -ForegroundColor Green
    Write-Host -NoNewline "Koala 13B: " -ForegroundColor Red
    Write-Host "6" -ForegroundColor Green
    Write-Host -NoNewline "GPT4ALL-J v1.3: " -ForegroundColor Red
    Write-Host "7" -ForegroundColor Green

    $choice = Read-Host "Enter a number"
} while ($choice -notin "1", "2", "3", "4", "5", "6", "7")

if ($choice -eq "1") {
    Get-VincunaCPU13B
    $modelFile = "ggml-vic13b-q5_1.bin"
} elseif ($choice -eq "2") {
    Get-VincunaUncensoredCPU13B
    $modelFile = "ggml-vic13b-uncensored-q5_1.bin"
} elseif ($choice -eq "3") {
    Get-VicunaCPU7B
    $modelFile = "ggml-vic7b-q5_1.bin"
} elseif ($choice -eq "4") {
    Get-VicunaUncensoredCPU7B
    $modelFile = "ggml-vic7b-uncensored-q5_1.bin"
} elseif ($choice -eq "5") {
    Get-KoalaCPU7B
    $modelFile = "koala-7B.ggmlv3.q5_1.bin"
} elseif ($choice -eq "6") {
    Get-KoalaCPU13B
    $modelFile = "koala-13B.ggmlv3.q5_1.bin"
} elseif ($choice -eq "7") {
    Get-Gpt4All
    $modelFile = "koala-13B.ggmlv3.q5_1.bin"
}

# 7. Set up the models in env:
$filePath = ".env"
$content = Get-Content $filePath
if ($choice -eq "7") {
    $updatedContent = $content | ForEach-Object {
        if ($_ -match "^MODEL_TYPE=") {
            "MODEL_TYPE=GPT4All"
        } elseif ($_ -match "^MODEL_PATH=") {
            "MODEL_PATH=models/ggml-gpt4all-j-v1.3-groovy.bin"
        } else {
            $_
        }
    }
} else {
    $updatedContent = $content | ForEach-Object {
        if ($_ -match "^MODEL_TYPE=") {
            "MODEL_TYPE=LlamaCpp"
        } elseif ($_ -match "^MODEL_PATH=") {
            "MODEL_PATH=models/$modelFile"
        } else {
            $_
        }
    }
}
Set-Content -Path $filePath -Value $updatedContent

# 8. Create Launcher files
# - Updater
$OutputFilePath = "update.bat"
$OutputText = "@echo off`ngit pull"
Set-Content -Path $OutputFilePath -Value $OutputText

if ($condaFound) {
    # As the Windows Target path can only have 260 chars, we easily hit that limit... (Shortcuts) and some users don't know about running ps1 files.
    $condaPath = Get-CondaPath
    # - Ingest
    $OutputFilePath = "ingest.bat"
    $OutputText = "@echo off`npowershell -ExecutionPolicy ByPass -NoExit -File `"ingest.ps1`""
    Set-Content -Path $OutputFilePath -Value $OutputText

    $OutputFilePath = "ingest.ps1"
    $OutputText = "& '$condaPath'`nconda activate pgpt`nSet-Location `"$(Get-Location)`"`npython ingest.py"
    Set-Content -Path $OutputFilePath -Value $OutputText

    # - Run PrivateGPT
    $OutputFilePath = "run-privategpt.bat"
    $OutputText = "@echo off`npowershell -ExecutionPolicy ByPass -NoExit -File `"run-privategpt.ps1`""
    Set-Content -Path $OutputFilePath -Value $OutputText

    $OutputFilePath = "run-privategpt.ps1"
    $OutputText = "& '$condaPath'`nconda activate pgpt`nSet-Location `"$(Get-Location)`"`npython privateGPT.py"
    Set-Content -Path $OutputFilePath -Value $OutputText
} else {
    # - Ingest
    $OutputFilePath = "ingest.bat"
    $OutputText = "@echo off`npython ingest.py"
    Set-Content -Path $OutputFilePath -Value $OutputText

    # - Run PrivateGPT
    $OutputFilePath = "run-privategpt.bat"
    $OutputText = "@echo off`npython privateGPT.py"
    Set-Content -Path $OutputFilePath -Value $OutputText

}

# 9. Create desktop shortcuts?
Write-Host "`n`nCreate desktop shortcuts for privateGPT?" -ForegroundColor Cyan
do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want desktop shortcuts? (y/n): "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n")

if ($shortcuts -eq "Y" -or $shortcuts -eq "y") {
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading privateGPT icon (not official)..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/privateGPT.ico' -OutFile 'privateGPT.ico'

    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
    $shortcutName = "privateGPT"
    $targetPath = "run-privategpt.bat"
    $IconLocation = 'privateGPT.ico'
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation
}

# 10. Launch privateGPT
Write-Host "`n`nLaunching privateGPT!" -ForegroundColor Cyan
./run-privategpt.bat