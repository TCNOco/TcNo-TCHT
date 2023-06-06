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
# This function:
# 1. Downloads and extracts the latest oobabooga/text-generation-webui
# 2. Ask user about installation and create a modified installer
# 3. Run the modified installer
# 4. Delete the modified installer
# 5. Ask the user if they want Desktop shortcuts
# ----------------------------------------

function Install-Ooba {
    param(
        [int]$skip_start,
        [int]$skip_model
    )
    Set-Variable ProgressPreference SilentlyContinue # Remove annoying yellow progress bars when doing Invoke-WebRequest for this session

    if ($skip_start -eq 1) {
        Write-Host "Not starting Ooba after installation"
    }
    if ($skip_model -eq 1) {
        Write-Host "Skipping model download"
    }

    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
        Read-Host
    }
    
    # Allow importing remote functions
    iex (irm Import-RemoteFunction.tc.ht)
    Import-RemoteFunction("Get-GeneralFuncs.tc.ht")

    Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
    $TCHT = Get-TCHTPath -Subfolder "oobabooga_windows"

    # If user chose to install this program in another path, create a symlink for easy access and management.
    $isSymlink = Sync-ProgramFolder -ChosenPath $TCHT -Subfolder "oobabooga_windows"

    # Since the latest update, this program is unhappy with paths with a space in them.
    # The program will be installed to $TCHT\Ooba
    # So, we'll create $TCHT\Ooba if it doesn't already exist:
    if (!(Test-Path -Path "$TCHT")) {
        New-Item -ItemType Directory -Path "$TCHT" | Out-Null
    }

    # Then CD into $TCHT\
    Set-Location "$TCHT\"

    # 1. Downloads and extracts the latest oobabooga/text-generation-webui release
    # Download file
    Invoke-WebRequest -Uri "https://github.com/oobabooga/text-generation-webui/releases/download/installers/oobabooga_windows.zip" -OutFile "./oobabooga_windows.zip"

    # Extract file
    Expand-Archive "./oobabooga_windows.zip" -DestinationPath "./" -Force

    # Delete zip file
    Remove-Item "./oobabooga_windows.zip"
    Set-Location "./oobabooga_windows"

    # 2. Ask user about installation and create a modified installer
    Write-Host "What version do you want to install?" -ForegroundColor Cyan
    if ((Get-CimInstance Win32_VideoController).Name -match "NVIDIA") {
        Write-Host "A) NVIDIA (Detected)" -ForegroundColor Cyan
    } else {
        Write-Host "A) NVIDIA" -ForegroundColor Cyan
    }
    
    if ((Get-CimInstance Win32_VideoController).Name -match "AMD") {
        Write-Host "B) AMD (Detected)"
    } else {
        Write-Host "B) AMD" -ForegroundColor Cyan
    }

    Write-Host "C) Apple M Series" -ForegroundColor Cyan
    Write-Host "D) CPU-Only mode" -ForegroundColor Cyan

    do {
        $choice = Read-Host "Answer (A/B/C/D)"
    } while ($choice -notin "A", "a", "B", "b", "C", "c", "D", "d")


    (Get-Content -Path start_windows.bat) | 
        ForEach-Object { $_ -replace "call python webui.py", "call python webui-modified.py" } | 
    Set-Content -Path start_windows-modified.bat

    $filePath = "webui-modified.py"
    
    # Replace `gpuchoice = input("Input> ").lower()`1 in webui.py with `gpuchoice = $choice`, but choice is lower case
    (Get-Content -Path webui.py) | 
        ForEach-Object { $_ -replace 'gpuchoice = input\("Input> "\)\.lower\(\)', "gpuchoice = `"$choice`".lower()" } | 
    Set-Content -Path $filePath

    
    if ($skip_start -eq 1) {
        (Get-Content $filePath) -replace "def run_model\(\):", "def run_model():`n    return" | Set-Content $filePath
        (Get-Content start_windows-modified.bat) -replace "pause", "" | Set-Content start_windows-modified.bat
    }
    
    if ($skip_model -eq 1) {
        (Get-Content $filePath) -replace "def download_model\(\):", "def download_model():`n    return" | Set-Content $filePath
    }

    # 3. Run the modified installer
    ./start_windows-modified.bat

    # 4. Delete the modified installer
    Remove-Item "./webui-modified.py"
    Remove-Item "./start_windows-modified.bat"

    # 5. Ask the user if they want Desktop shortcuts
    do {
        Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want desktop shortcuts for Oobabooga? (y/n): "
        $shortcuts = Read-Host
    } while ($shortcuts -notin "Y", "y", "N", "n")

    if ($shortcuts -eq "Y" -or $shortcuts -eq "y") {
        iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
        Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
        
        Write-Host "Downloading Oobabooga icon..."
        Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/ooba.ico' -OutFile 'ooba.ico'
        Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
        
        New-Shortcut -ShortcutName "Oobabooga WebUI" -TargetPath "start_windows.bat" -IconLocation 'ooba.ico'
    }
}

function Install-OobaCuda {
    if (-not (Get-Command Import-RemoteFunction -ErrorAction SilentlyContinue)){
        iex (irm Import-RemoteFunction.tc.ht)
    }

    if ((Get-CimInstance Win32_VideoController).Name -like "*Nvidia*") {
        Import-FunctionIfNotExists -Command Install-CudaAndcuDNN -ScriptUri "Install-Cuda.tc.ht"
        Install-CudaAndcuDNN -CudaVersion "11.8" -CudnnOptional $true
    }
}