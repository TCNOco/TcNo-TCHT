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
# 5. Install Build Tools
# 6. Install CUDA and cuDNN
# 7. Check if Conda or Python is installed
# 8. Clone Roop ($TCHT\roop) (Default C:\TCHT\roop)
# 9. Download model
# 10. Install PyTorch and requirements:
# 11. Create launcher files
# 12. Create shortcuts
# 13. Launch
# ----------------------------------------

Write-Host "---------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's Roop installer!" -ForegroundColor Cyan
Write-Host "Roop as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
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
Set-Variable ProgressPreference SilentlyContinue # Remove annoying yellow progress bars when doing Invoke-WebRequest for this session

Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
$TCHT = Get-TCHTPath -Subfolder "roop"

# If user chose to install this program in another path, create a symlink for easy access and management.
$isSymlink = Sync-ProgramFolder -ChosenPath $TCHT -Subfolder "roop"

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

# 3. Install FFMPEG if not already registered with PATH
Clear-ConsoleScreen
$ffmpegFound = [bool](Get-Command ffmpeg -ErrorAction SilentlyContinue)
if (-not $ffmpegFound) {
    Write-Host "Installing FFMPEG-Full..." -ForegroundColor Cyan
    choco upgrade ffmpeg-full -y
    Write-Host "Done." -ForegroundColor Green
}

# 4. Install aria2c to make the model downloads MUCH faster
Clear-ConsoleScreen
Write-Host "Installing aria2c (Faster model download)..." -ForegroundColor Cyan
choco upgrade aria2 -y
Update-SessionEnvironment

# 5. Install Build Tools
Clear-ConsoleScreen
Write-Host "Installing Microsoft Build Tools..." -ForegroundColor Cyan
iex (irm buildtools.tc.ht)

# 6. Install CUDA and cuDNN
if ((Get-CimInstance Win32_VideoController).Name -like "*Nvidia*") {
    Import-FunctionIfNotExists -Command Install-CudaAndcuDNN -ScriptUri "Install-Cuda.tc.ht"
    Install-CudaAndcuDNN -CudaVersion "11.8" -CudnnOptional $true
}

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tc.ht)

# 7. Check if Conda or Python is installed
# Check if Conda is installed
iex (irm Get-CondaAndPython.tc.ht)

# Check if Conda is installed
$condaFound = Get-UseConda -Name "Roop" -EnvName "roop" -PythonVersion "3.10.11"

# Get Python command (eg. python, python3) & Check for compatible version
if ($condaFound) {
    conda activate "roop"
    $python = "python"
} else {
    $python = Get-Python -PythonRegex 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])' -PythonRegexExplanation "Python version is not between 3.10.6 and 3.10.11." -PythonInstallVersion "3.10.11" -ManualInstallGuide "https://github.com/s0md3v/roop/wiki/1.-Installation"
    if ($python -eq "miniconda") {
        $python = "python"
        $condaFound = $true
    }
}

# 8. Clone Roop ($TCHT\roop) (Default C:\TCHT\roop)
Clear-ConsoleScreen
Sync-GitRepo -ProjectFolder "$TCHT\roop" -ProjectName "Roop" -IsSymlink $isSymlink -GitUrl "https://github.com/s0md3v/roop.git"

# 9. Download model
Import-FunctionIfNotExists -Command Get-Aria2File -ScriptUri "File-DownloadMethods.tc.ht"

Clear-ConsoleScreen
Write-Host "Downloading the latest required model (inswapper_128.onnx)" -ForegroundColor Yellow
$url = "https://civitai.com/api/download/models/85159"
$outputPath = "inswapper_128.onnx"
Get-Aria2File -Url $url -OutputPath $outputPath

# 10. Install PyTorch and requirements:
if ($condaFound) {
    # For some reason conda NEEDS to be deactivated and reactivated to use pip reliably... Otherwise python and pip are not found.
    conda deactivate
    Update-SessionEnvironment
    #Open-Conda
    conda activate roop
    conda install mamba -c conda-forge -y

    if ((Get-CimInstance Win32_VideoController).Name -like "*Nvidia*") {
        conda install cudatoolkit -y
    }
}

&$python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

&$python -m pip install -r requirements.txt

Update-SessionEnvironment

# 11. Create launcher files
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

$ReinstallCommand = ""
if ((Get-CimInstance Win32_VideoController).Name -like "*Nvidia*") {
    if ($condaFound) {
        $ReinstallCommand += "conda install cudatoolkit -y`n"
    }
}

$ReinstallCommand += "python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118`npython -m pip install -r requirements.txt"

if ($condaFound) {
    New-LauncherWithErrorHandling -ProgramName $ProgramName -InstallLocation $InstallLocation -RunCommand $RunCommand -ReinstallCommand $ReinstallCommand -CondaPath $condaPath -CondaEnvironmentName $CondaEnvironmentName -LauncherName $LauncherName
} else {
    New-LauncherWithErrorHandling -ProgramName $ProgramName -InstallLocation $InstallLocation -RunCommand $RunCommand -ReinstallCommand $ReinstallCommand -LauncherName $LauncherName
}

# Now the same for CPU-only
$ProgramName = "Roop CPU-Only"
$RunCommand = "python run.py"
$LauncherName = "run-roop-cpu"

if ($condaFound) {
    New-LauncherWithErrorHandling -ProgramName $ProgramName -InstallLocation $InstallLocation -RunCommand $RunCommand -ReinstallCommand $ReinstallCommand -CondaPath $condaPath -CondaEnvironmentName $CondaEnvironmentName -LauncherName $LauncherName
} else {
    New-LauncherWithErrorHandling -ProgramName $ProgramName -InstallLocation $InstallLocation -RunCommand $RunCommand -ReinstallCommand $ReinstallCommand -LauncherName $LauncherName
}

# 12. Create shortcuts
Clear-ConsoleScreen
Write-Host "Create desktop shortcuts for Roop?" -ForegroundColor Cyan
do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want desktop shortcuts? (y/n) [Default: y]: "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n", "")

if ($shortcuts -in "Y","y", "") {
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

# 13. Launch
Clear-ConsoleScreen
Write-Host "There are more launch options you can add, such as max memory. Add these to the start powershell files. See here: https://github.com/s0md3v/roop#how-do-i-use-it"

Write-Host "Launching Roop!" -ForegroundColor Cyan
if ((Get-CimInstance Win32_VideoController).Name -like "*Nvidia*") {
    ./run-roop.bat
} else {
    Write-Host "An Nvidia Graphics Card was not detected. Launching in CPU-only mode..."
    ./run-roop-cpu.bat
}
