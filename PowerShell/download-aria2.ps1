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
# This script downloads and places aria2 in the current directory.
# ----------------------------------------

function Install-Aria2() {
    Write-Host "Downloading Aria2 (For faster downloads - Only needs to be done once)" -ForegroundColor Yellow
    # Set download URL and destination folder
    $downloadUrl = "https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0-win-64bit-build1.zip"
    $aria2ZipPath = "aria2.zip"

    # Download the aria2 zip file
    Invoke-WebRequest -Uri $downloadUrl -OutFile $aria2ZipPath

    # Load assembly for ZipFile
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    # Extract only aria2c.exe from the zip file
    $zip = [System.IO.Compression.ZipFile]::OpenRead($aria2ZipPath)
    $aria2cExe = $zip.Entries | Where-Object { $_.FullName -eq "aria2-1.36.0-win-64bit-build1/aria2c.exe" }
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($aria2cExe, "aria2c.exe", $true)
    $zip.Dispose()

    # Remove the downloaded zip file
    Remove-Item -Path $aria2ZipPath -Force
}

# Check if aria2c is installed
try {
    $aria2cCommand = Get-Command .\aria2c -ErrorAction Stop
    Write-Host "Aria2 is already installed." -ForegroundColor Yellow
} catch {
    Write-Host "Aria2 is not installed. Installing..." -ForegroundColor Yellow
    Install-Aria2
}