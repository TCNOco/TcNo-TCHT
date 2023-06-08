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
# This script lets you download and build Spigot/Bukkit/BungeeCord in an even faster, easier way.
# The installation is already super simple, but this is next-level.
# This script:
# 1. Download the Minecraft BuildTools
# 2. Verify Java exists and can run the jar file.
# 3. Does the user want CraftBukkit?
# 4. Create sample server .bat file
# 5. Open a file browser in this folder
# ----------------------------------------

Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's Spigot MC installer!" -ForegroundColor Cyan
Write-Host "Spigot MC will now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-06-08]" -ForegroundColor Cyan
Write-Host "`nThis script is provided AS-IS without warranty of any kind. See https://tc.ht/privacy & https://tc.ht/terms."
Write-Host "Consider supporting these install scripts: https://tc.ht/support" -ForegroundColor Green
Write-Host "--------------------------------------------`n`n" -ForegroundColor Cyan

iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")

# 1. Go to the users' requested folder
Write-Host "The Spigot and Bukkit build process creates a few extra files. These can be deleted afterwards." -ForegroundColor Cyan
Write-Host "Hit Enter to proceed in the current folder ($(Get-Location)\spigot), or type a folder path?" -ForegroundColor Cyan
$answer = Read-Host "Enter, or type a path and press Enter"
if ($answer -eq "") {
    $answer = Join-Path Get-Location "spigot\"
}

if (-not (Test-Path $answer)) {
    New-Item -ItemType Directory -Force -Path $answer
}
Set-Location $answer

# 1. Download the Minecraft BuildTools
Invoke-WebRequest -Uri "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar" -OutFile "./buildtools.jar"

# 2. Verify Java exists and can run the jar file.
Clear-ConsoleScreen
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "It appears Java is not installed." -ForegroundColor Red
    Write-Host "Downloading and setting up Java..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://download.oracle.com/java/20/latest/jdk-20_windows-x64_bin.exe" -OutFile "./jdk-20_windows-x64_bin.exe"

    Write-Host "Installing Java JDK 20" -ForegroundColor Cyan
    jdk-20_windows-x64_bin.exe /s

    # Import function to reload without needing to re-open Powershell
    iex (irm refreshenv.tc.ht)
    Update-SessionEnvironment
    Write-Host "Done installing Java JDK 20!" -ForegroundColor Green
}

# 3. Does the user want CraftBukkit?
Clear-ConsoleScreen
Write-Host "By default only Spigot will be built. You can always run this again later."
do {
    Write-Host -ForegroundColor Cyan -NoNewline "Do you want to build CraftBukkit as well? (y/n) [Default: n]: "
    $answer = Read-Host
} while ($answer -notin "Y", "y", "N", "n", "")

$extraArgs = ""
if ($answer -in "Y", "y") {
    $extraArgs += " --compile craftbukkit"
}

java -jar BuildTools.jar --rev 1.20 $extraArgs

# 4. Create sample server .bat file
Set-Content -Path "start.bat" -Value "@echo off`njava -Xmx2G -jar spigot-1.20.jar nogui`npause"

# 5. Open a file browser in this folder
Write-Host "Everything's done. Opening Explorer in this folder." -ForegroundColor Cyan
explorer.exe .