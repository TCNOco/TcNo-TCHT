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
# This script lets you install ViveTool in an even faster, easier way.
# This script:
# 1. Ask the user if they want the GUI or CLI version of ViveTool.
# 2. Install ViveTool or ViveTool-GUI
# 3. Create desktop shortcuts? (For ViveTool-GUI only)
# 4. Launch ViveTool-GUI (For ViveTool-GUI only)
# ----------------------------------------

Write-Host "Welcome to TroubleChute's ViveTool installer!" -ForegroundColor Cyan
Write-Host "ViveTool will now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-05-31]`n`n" -ForegroundColor Cyan

iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")

# 1. Ask the user if they want the GUI or CLI version of ViveTool.
$vivetool = ""
do {
    Clear-ConsoleScreen
    Write-Host "Which ViveTool would you like to install?" -ForegroundColor Cyan
    Write-Host -NoNewline "- ViveTool: " -ForegroundColor Red
    Write-Host "1" -ForegroundColor Green
    Write-Host -NoNewline "- ViveTool-GUI: " -ForegroundColor Red
    Write-Host "2" -ForegroundColor Green
    $vivetool = Read-Host "Enter your choice"
} while ($vivetool -notin "1", "2")

# Set up install directory
Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
$TCHT = Get-TCHTPath

# 2. Install ViveTool or ViveTool-GUI
if ($vivetool -eq "1") {
    if (!(Test-Path -Path "$TCHT\ViVeTool")) {
        New-Item -ItemType Directory -Path "$TCHT\ViVeTool" | Out-Null
    }
    
    # Then CD into $TCHT\
    Set-Location "$TCHT\ViVeTool"
    
    # Download the latest CLI version:
    Write-Host "Getting the latest ViVeTool download link."
    $repo = "thebookisclosed/ViVe"
    $latestRelease = Invoke-WebRequest -Uri "https://api.github.com/repos/$repo/releases/latest"
    
    $releaseData = $latestRelease | ConvertFrom-Json
    
    # Find the asset without 'arm64' in its name
    $nonArm64Asset = $releaseData.assets | Where-Object { $_.name -notlike '*arm64*' }
    $downloadUrl = $nonArm64Asset.browser_download_url
    
    # Download the zip:
    Write-Host "Downloading..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile "ViveTool.zip"
    
    Write-Host "Unzipping..."
    Expand-Archive -Path "ViveTool.zip" -DestinationPath ./ -Force
    Remove-Item -Path "ViveTool.zip"

    # Add the current folder to PATH if not already exists:
    try {
        Write-Host "Adding to system PATH..."
        $path = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
        if ($path -notlike "*$TCHT\ViVeTool*") {
            [Environment]::SetEnvironmentVariable("Path", $path + ";$TCHT\ViVeTool", [System.EnvironmentVariableTarget]::Machine)
        }
    }
    catch [ System.Management.Automation.MethodInvocationException] {
        Write-Host "Failed! Adding to User PATH instead..."

        $path = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
        if ($path -notlike "*$TCHT\ViVeTool*") {
            [Environment]::SetEnvironmentVariable("Path", $path + ";$TCHT\ViVeTool", [System.EnvironmentVariableTarget]::User)
        }
    }
    catch {
         "An error occurred that could not be resolved."
    }

    # Import function to reload without needing to re-open Powershell
    iex (irm refreshenv.tc.ht)
    Update-SessionEnvironment

    & ViVeTool

    Write-Host "`nThe above was returned after running 'vivetool'" -ForegroundColor Green
    Write-Host "You should now be able to use 'vivetool' anywhere on your computer." -ForegroundColor Green
    Write-Host "To update in the future, you can run this install script again, or update in-app." -ForegroundColor Cyan
    Write-Host "Your ViVeTool is located HERE: $TCHT\ViVeTool" -ForegroundColor Cyan

    Read-Host "`nPress any key to exit..."
    exit
} elseif ($vivetool -eq "2") {
    if (!(Test-Path -Path "$TCHT\ViVeTool-GUI")) {
        New-Item -ItemType Directory -Path "$TCHT\ViVeTool-GUI" | Out-Null
    }
    
    # Then CD into $TCHT\
    Set-Location "$TCHT\ViVeTool-GUI"

    # Download the latest CLI version:
    Write-Host "Getting the latest ViVeTool-GUI download link."
    $repo = "PeterStrick/ViVeTool-GUI"
    $latestRelease = Invoke-WebRequest -Uri "https://api.github.com/repos/$repo/releases/latest"
    
    $releaseData = $latestRelease | ConvertFrom-Json
    
    # Find the asset with '.zip' in its name (portable [no installer] edition)
    $portableAsset = $releaseData.assets | Where-Object { $_.name -like '*.zip*' }
    $downloadUrl = $portableAsset.browser_download_url
    
    # Download the zip:
    Write-Host "Downloading..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile "ViveTool-GUI.zip"
    
    Write-Host "Unzipping..."
    Expand-Archive -Path "ViveTool-GUI.zip" -DestinationPath ./ -Force
    Remove-Item -Path "ViveTool-GUI.zip"

    # 3. Create desktop shortcuts?
    Clear-ConsoleScreen
    Write-Host "Create desktop shortcuts for ViVeTool-GUI?" -ForegroundColor Cyan
    do {
        Write-Host -ForegroundColor Cyan -NoNewline "Do you want desktop shortcuts? (y/n): "
        $shortcuts = Read-Host
    } while ($shortcuts -notin "Y", "y", "N", "n")

    if ($shortcuts -eq "Y" -or $shortcuts -eq "y") {
        Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut

        Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
        $shortcutName = "ViVeTool GUI"
        $targetPath = "ViVeTool_GUI.exe"
        New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath
        
        Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
        $shortcutName = "ViVeTool GUI Feature Scanner"
        $targetPath = "ViVeTool_GUI.FeatureScanner.exe"
        New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath
    }

    # 4. Launch ViveTool-GUI
    Clear-ConsoleScreen

    Write-Host "`nViVeTool-GUI is now installed!" -ForegroundColor Green
    Write-Host "You can uninstall by deleting any shortcuts as well as $TCHT\ViVeTool-GUI" -ForegroundColor Green
    Write-Host "To update in the future, you can run this install script again, or update in-app." -ForegroundColor Cyan

    do {
        Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want to launch ViVeTool-GUI? (y/n): "
        $launch = Read-Host
    } while ($launch -notin "Y", "y", "N", "n")

    if ($launch -in "Y", "y") {
        Write-Host "Launching ViVeTool-GUI!" -ForegroundColor Cyan
        ./ViVeTool_GUI.exe
    }

    Read-Host "`nPress any key to exit..."
    exit
}