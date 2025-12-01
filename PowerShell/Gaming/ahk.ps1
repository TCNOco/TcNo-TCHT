# Copyright (C) 2025 TroubleChute (Wesley Pyburn)
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
# 1. Downloads and runs the latest release from: https://github.com/TCNOco/AutoHotkey-Finder
# ----------------------------------------

Write-Host "---------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's TroubleChute AHK Finder!" -ForegroundColor Cyan
Write-Host "`nThis script is provided AS-IS without warranty of any kind. See https://tc.ht/privacy & https://tc.ht/terms."
Write-Host "---------------------------------------------------------------------------`n`n" -ForegroundColor Cyan

Set-Variable ProgressPreference SilentlyContinue # Remove annoying yellow progress bars when doing Invoke-WebRequest for this session

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")

# Download and run the latest Autohotkey.Finder.exe from GitHub
$repo = "TCNOco/AutoHotkey-Finder"
$apiUrl = "https://api.github.com/repos/$repo/releases/latest"
$tempPath = [System.IO.Path]::GetTempPath()

try {
    Write-Host "Fetching latest release info from GitHub..." -ForegroundColor Yellow
    $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ 'User-Agent' = 'TcNo-TCHT-Script' }
    $tagName = $release.tag_name
    
    $asset = $release.assets | Where-Object { $_.name -eq 'Autohotkey.Finder.exe' } | Select-Object -First 1
    if (-not $asset) {
        Write-Host "Could not find Autohotkey.Finder.exe in the latest release assets." -ForegroundColor Red
        exit 1
    }
    
    # Create filename with tag_name appended
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($asset.name)
    $extension = [System.IO.Path]::GetExtension($asset.name)
    $versionedName = "$baseName-$tagName$extension"
    $outFile = Join-Path $tempPath $versionedName
    
    # Check if file already exists and is valid
    $needsDownload = $true
    if (Test-Path $outFile) {
        $fileInfo = Get-Item $outFile
        if ($fileInfo.Length -gt 0) {
            Write-Host "Found existing version $tagName at $outFile. Skipping download." -ForegroundColor Green
            $needsDownload = $false
        } else {
            Write-Host "Existing file is invalid (zero size). Will re-download." -ForegroundColor Yellow
        }
    }
    
    if ($needsDownload) {
        $downloadUrl = $asset.browser_download_url
        Write-Host "Downloading $($asset.name) (version $tagName) to $outFile..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outFile -UseBasicParsing
        Write-Host "Download complete." -ForegroundColor Green
    }
    
    Write-Host "Running Autohotkey.Finder.exe in this window...`n`n`n" -ForegroundColor Green
    Clear-ConsoleScreen
    & $outFile
} catch {
    Write-Host "Failed to download or run Autohotkey.Finder.exe: $_" -ForegroundColor Red
    exit 1
}

