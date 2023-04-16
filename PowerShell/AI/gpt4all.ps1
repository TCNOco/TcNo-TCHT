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
# 1. Installs Chocolatey (for installing VCRuntimes and aria2) - https://chocolatey.org/install.
# 2. Installs git to clone the nomic-ai/gpt4all project. In the future you can run 'git pull' in the project's folder to update it.
# 3. Downloads nomic-ai/gpt4all
# 4. Installs aria2c for a much faster model download using Choco.
# 5. Installs required Microsoft VC Runtimes, which the project will not run without, using Choco.
# 6. Launches gpt4all.
# 7. (Optional) Create a desktop shortcut
# ----------------------------------------

Write-Host "Welcome to TroubleChute's GPT4All installer!" -ForegroundColor Cyan
Write-Host "GPT4All as well as all of its other dependencies should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-06 (version 2)]`n`n" -ForegroundColor Cyan

# 1. Install Chocolatey
Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install or update Git if not already installed
Write-Host "`nInstalling Git..." -ForegroundColor Cyan
iex (irm install-git.tc.ht)

# 3. Clone the nomic-ai GPT4All repo
Write-Host "`nCloning the nomic-ai GPT4All repo..." -ForegroundColor Cyan
git clone https://github.com/nomic-ai/gpt4all.git

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tc.ht)

# 4. Before downloading the model, we'll install aria2c to make the download MUCH faster
Write-Host "`nInstalling aria2c (Faster model download)..." -ForegroundColor Cyan
choco install aria2 -y
Update-SessionEnvironment

# 5. Download the GPT4All Lora model
Write-Host "`nDownloading the GPT4All model. This will take a while" -ForegroundColor Cyan
aria2c -x 8 -s 8 --continue --out="./gpt4all/chat/gpt4all-lora-quantized.bin" https://the-eye.eu/public/AI/models/nomic-ai/gpt4all/gpt4all-lora-quantized.bin

# 6. Install VCRedist (if missing any)
Write-Host "`nInstalling required VCRuntimes..." -ForegroundColor Cyan
choco install vcredist2015 -y

iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
Import-RemoteFunction -ScriptUri "New-Shortcut.tc.ht" # Import function to create a shortcut

# 7. Create a desktop shortcut
Write-Host "`nCreating shortcut on desktop..." -ForegroundColor Cyan
$shortcutName = "GPT4All"
$targetPath = "gpt4all\chat\gpt4all-lora-quantized-win64.exe"
$workingDirectory = "gpt4all\chat"

do {
    $createShortcut = Read-Host "Do you want a desktop shortcut? (Y/N)"
} while ($createShortcut -notin "Y", "y", "N", "n")

if ($createShortcut -eq "Y" -or $createShortcut -eq "y") {
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -WorkingDirectory $workingDirectory
}

# 8. Run the gpt4all-lora-quantized-win64 program
Write-Host "`nRunning GPT4All" -ForegroundColor Cyan
Start-Process -FilePath 'gpt4all\chat\gpt4all-lora-quantized-win64.exe' -WorkingDirectory 'gpt4all\chat'