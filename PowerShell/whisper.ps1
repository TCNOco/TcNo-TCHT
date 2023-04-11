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
# 1. Installs Chocolatey (for installing Python and FFMPEG) - https://chocolatey.org/install
# 2. Install or update Git if not already installed
# 3. Installs Python using Choco (if Python not already detected)
# 4. Installs FFMPEG using Choco (if FFMPEG not already detected)
# 5. Install CUDA using Choco (if CUDA not already detected)
# 6. Install Pytorch if not already installed, or update. Installs either GPU version if CUDA found, or CPU-only version
# 7. Verify that Whisper is installed.
# ----------------------------------------

Write-Host "Welcome to TroubleChute's Whisper installer!" -ForegroundColor Cyan
Write-Host "Whisper as well as all of its other dependencies should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-06]`n`n" -ForegroundColor Cyan

# 1. Install Chocolatey
Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tb.ag)

# 2. Install or update Git if not already installed
Write-Host "`nInstalling Git..." -ForegroundColor Cyan
iex (irm install-git.tb.ag)

# 3. Check if Python returns anything (is installed - also between 3.9.9 & 3.10.10)
Try {
    $pythonVersion = python --version 2>&1
    if ($pythonVersion -match 'Python ([3].[9].[9-9]\d*|3.10.(0|10))') {
        Write-Host "Python version $($matches[1]) is installed." -ForegroundColor Green
    }
}
Catch {
    Write-Host "Python is not installed." -ForegroundColor Yellow
    Write-Host "`nInstalling Python 3.10.10." -ForegroundColor Cyan
    choco install python --version=3.10.10 -y
    Update-SessionEnvironment
}

# Verify Python install
$python = "python"
Try {
    $pythonVersion = &$python --version 2>&1
    if ($pythonVersion -match 'Python ([3].[9].[9-9]\d*|3.10.(0|10))') {
        Write-Host "Python version $($matches[1]) is installed." -ForegroundColor Green
    }
    else {
        Write-Host "Python version is not between 3.9.9 and 3.10.10." -ForegroundColor Yellow
        Write-Host "Assuming you've installed the correct version, please enter the comand you use to access Python 3.9/3.10." -ForegroundColor Yellow
    
        $pythonProgramName = Read-Host "Enter the Python program name (e.g. python3, python310):"
        $pythonVersion = &$pythonProgramName --version 2>&1
        if ($pythonVersion -match 'Python ([3].[9].[9-9]\d*|3.10.(0|10))') {
            Write-Host "Python version $($matches[1]) is installed."
            $python = $pythonProgramName
        } else {
            Write-Host "Python version is not between 3.9.9 and 3.10.10."
            Write-Host "Alternatively, follow this guide for manual installation: https://hub.tcno.co/ai/whisper/install/" -ForegroundColor Red
            Read-Host "Process can not continue. The program will exit when you press any key to continue..."
            Exit
        }
    }
}
Catch {
    Write-Host "Python version is not between 3.9.9 and 3.10.10."
    Write-Host "Alternatively, follow this guide for manual installation: https://hub.tcno.co/ai/whisper/install/" -ForegroundColor Red
    Read-Host "Process can not continue. The program will exit when you press any key to continue..."
    Exit
}

# 4. Install FFMPEG with Choco if not already installed.
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "`nFFMPEG is not installed. Installing..." -ForegroundColor Cyan

    choco install ffmpeg -y
    Update-SessionEnvironment
}

if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
    Write-Host "FFmpeg is installed." -ForegroundColor Green
}
else {
    Write-Host "FFmpeg is not installed. Please add FFMPEG to PATH (install ffmpeg) and run this script again." -ForegroundColor Red
    Write-Host "Alternatively, follow this guide for manual installation: https://hub.tcno.co/ai/whisper/install/" -ForegroundColor Red
    Read-Host "Process can not continue. The program will exit when you press any key to continue..."
    Exit
}

# 5. Install CUDA using Choco if not already installed.
try {
    $nvidiaSmiOutput = & nvidia-smi
    if ($LASTEXITCODE -eq 0) {
        if ($nvidiaSmiOutput -match "NVIDIA-SMI") {
            # Nvidia CUDA can be installed.

            # Check if CUDA is already installed
            if (-not (Get-Command nvcc -ErrorAction SilentlyContinue)) {
                Write-Host "`nCUDA is not installed. Installing..." -ForegroundColor Cyan
            
                choco install cuda -y
                Update-SessionEnvironment
            }
        }
    }
}
catch {
    Write-Host "An error occurred while checking for NVIDIA graphics card." -ForegroundColor Red
}


if (Get-Command nvcc -ErrorAction SilentlyContinue) {
    Write-Host "Nvidia CUDA installed." -ForegroundColor Green

    # 6. Install Pytorch if not already installed, or update.
    Write-Host "`nInstalling or updating PyTorch (With GPU support)..." -ForegroundColor Cyan
    &$python -m pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    &$python -m pip install --upgrade setuptools-rust
}
else {
    Write-Host "Nvidia CUDA is not installed. Please install the latest Nvidia CUDA Toolkit and run this script again." -ForegroundColor Red
    Write-Host "For now the script will proceed with installing CPU-only PyTorch. Whisper will still run when it's done." -ForegroundColor Red
    
    # 6. Install Pytorch if not already installed, or update.
    Write-Host "`nInstalling or updating PyTorch (CPU-only)..." -ForegroundColor Cyan
    &$python -m pip3 install torch torchvision torchaudio
    &$python -m pip install --upgrade setuptools-rust
}


Write-Host "`nInstalling or updating Whisper..." -ForegroundColor Cyan
&$python -m pip install git+https://github.com/openai/whisper.git

Update-SessionEnvironment

# 7. Verify that Whisper is installed.

if (Get-Command whisper -ErrorAction SilentlyContinue) {
    Write-Host "`n`nWhisper is installed!" -ForegroundColor Green
    Write-Host "You can now use whisper --help for more information in this PowerShell window, CMD or another program!" -ForegroundColor Green
}
else {
    Write-Host "`n`nWhisper is not installed. Please follow this guide for manual installation: https://hub.tcno.co/ai/whisper/install/" -ForegroundColor Red
    Read-Host "Process can not continue. The program will exit when you press any key to continue..."
    Exit
}
