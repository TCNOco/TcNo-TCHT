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
# 1. Install Chocolatey
# 2. Install or update Git if not already installed
# 3. Download kohya_ss
# 4. Check if Conda or Python is installed
# 5. Optional: CUDNN
# 6. Create desktop shortcuts?
# 7. Launch!
# ----------------------------------------

Write-Host "---------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's kohya_ss installer!" -ForegroundColor Cyan
Write-Host "kohya_ss as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-28]" -ForegroundColor Cyan
Write-Host "`nConsider supporting these install scripts: https://tc.ht/support" -ForegroundColor Cyan
Write-Host "---------------------------------------------`n`n" -ForegroundColor Cyan

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
    Read-Host
}

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")

Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
$TCHT = Get-TCHTPath -Subfolder "kohya_ss"

# If user chose to install this program in another path, create a symlink for easy access and management.
$isSymlink = Sync-ProgramFolder -ChosenPath $TCHT -Subfolder "kohya_ss"

# Then CD into $TCHT\
Set-Location "$TCHT\"

# 1. Install Chocolatey
Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install or update Git if not already installed
Write-Host "`nInstalling Git..." -ForegroundColor Cyan
iex (irm install-git.tc.ht)

# 3. Download kohya_ss
git clone https://github.com/bmaltais/kohya_ss.git
cd kohya_ss

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tc.ht)


# 4. Check if Conda or Python is installed
# Check if Conda is installed
iex (irm Get-CondaAndPython.tc.ht)

# Check if Conda is installed
$condaFound = Get-UseConda -Name "Kohya_ss" -EnvName "kss" -PythonVersion "3.10.11"

# Get Python command (eg. python, python3) & Check for compatible version
$python = Get-Python -PythonRegex 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])' -PythonRegexExplanation "Python version is not between 3.10.6 and 3.10.11." -PythonInstallVersion "3.10.11" -ManualInstallGuide "https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs" -condaFound $condaFound


# 5. Optional: CUDNN
do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want to download CUDNN (~700MB)? You will need an Nvidia account. (y/n): "
    $cudnn = Read-Host
} while ($cudnn -notin "Y", "y", "N", "n")

if ($cudnn -in "Y","y") {
    Write-Host "Please:`n1. Open: https://developer.nvidia.com/rdp/cudnn-download`n2. Log in.`n3. Expand the latest cuDNN (matching your CUDA version)`n4. Click 'Local Installer for Windows (Zip)'`n5. Rename the zip to 'cudnn.zip'`n6. Move to $TCHT\kohya_ss (This folder should auto-open in Explorer)`nYou can do nothing and continue to cancel this operation." -ForegroundColor Cyan
    explorer $TCHT\kohya_ss
    Read-Host "Press Enter to continue..."


    $zipFilePath = "cudnn.zip"
    if (Test-Path $zipFilePath) {
        Write-Host "Extracting..." -ForegroundColor Green
        # Set the path to the ZIP file and the destination folder
        $destinationFolder = "cudnn_windows"

        # Create the destination folder if it does not exist
        if (-not (Test-Path -Path $destinationFolder -PathType Container)) {
            New-Item -ItemType Directory -Path $destinationFolder | Out-Null
        }

        $destinationFolder = (Resolve-Path "cudnn_windows").Path
        $zipFilePath = (Resolve-Path "cudnn.zip").Path

        # Extract every .dll file from the ZIP file and copy it to the destination folder
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::OpenRead($zipFilePath).Entries `
            | Where-Object { $_.Name -like '*.dll' } `
            | ForEach-Object {
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$destinationFolder\$($_.Name)", $true)
            }

        Write-Host "Done!`n`nYou can now delete cudnn.zip (You may want to use it elsewhere so I won't auto-delete)`n`n"

        ./activate.ps1
        python .\tools\cudann_1.8_install.py
    } else {
        Write-Host "CUDNN download cancelled."
    }
}

# Continue with installation
./setup.bat

# Delete setup.bat
Remove-Item setup.bat

# 6. Create desktop shortcuts?
do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want desktop shortcuts? (y/n): "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n")

iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
if ($shortcuts -in "Y","y") {
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading kohya_ss icon (not official)..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/kohya.ico' -OutFile 'kohya.ico'

    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
    $shortcutName = "kohya_ss"
    $targetPath = "gui-user.bat"
    $IconLocation = 'kohya.ico'
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation
}

# 7. Launch!
./gui-user.bat