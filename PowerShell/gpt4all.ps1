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
# 1. Installs git to clone the nomic-ai/gpt4all project. In the future you can run 'git pull' in the project's folder to update it.
# 2. Downloads nomic-ai/gpt4all.
# 3. Installs aria2c for a much faster model download.
# 4. Installs required Microsoft VC Runtimes, which the project will not run without.
# 5. Launches gpt4all.
# 6. (Optional) Create a desktop shortcut
# ----------------------------------------

Write-Host "Welcome to TroubleChute's GPT4All installer!" -ForegroundColor Cyan
Write-Host "GPT4All as well as all of its other dependencies should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-06]`n`n" -ForegroundColor Cyan

# Install or update Git if not already installed
iex (irm https://tcno.co/scripts/install-git.ps1)

# Clone the nomic-ai GPT4All repo
git clone https://github.com/nomic-ai/gpt4all.git

# Import function to reload without needing to re-open Powershell
iex (irm https://tcno.co/scripts/refreshenv.ps1)

# Before downloading the model, we'll install aria2c to make the download MUCH faster
if (Get-Command aria2c -ErrorAction SilentlyContinue) { Write-Host "Aria2 is already installed." } else { iex (irm https://tcno.co/scripts/install-aria2.ps1) }
Update-SessionEnvironment

# Download the GPT4All Lora model
Write-Host "Downloading the GPT4All model. This will take a while" -ForegroundColor Yellow
aria2c -x 8 -s 8 --continue --out="./gpt4all/chat/gpt4all-lora-quantized.bin" https://the-eye.eu/public/AI/models/nomic-ai/gpt4all/gpt4all-lora-quantized.bin

# Install VCRedist (if missing any)
iex (irm https://tcno.co/scripts/install-vcredist.ps1)

iex (irm https://tcno.co/scripts/Import-RemoteFunction.ps1) # Get RemoteFunction importer
Import-RemoteFunction -ScriptUri "https://tcno.co/scripts/New-Shortcut.psm1" # Import function to create a shortcut

# Create a desktop shortcut
$shortcutName = "GPT4All"
$targetPath = "gpt4all\chat\gpt4all-lora-quantized-win64.exe"
$workingDirectory = "gpt4all\chat"

$createShortcut = Read-Host "Do you want a desktop shortcut? (Y/N)"
if ($createShortcut -eq "Y" -or $createShortcut -eq "y") {
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -WorkingDirectory $workingDirectory
}

# Run the gpt4all-lora-quantized-win64 program
Start-Process -FilePath 'gpt4all\chat\gpt4all-lora-quantized-win64.exe' -WorkingDirectory 'gpt4all\chat'