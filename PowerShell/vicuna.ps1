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
# 1. Check if current directory is oobabooga-windows, or oobabooga-windows is in directory
# 2. Run my install script for obabooga/text-generation-webui
# 3. Tells you how to download the vicuna model, and opens the model downloader.
# 4. Run the model downloader
# 5. Replace commands in the start-webui.bat file
# 6. Create desktop shortcuts
# 7. Run the webui
# ----------------------------------------

Write-Host "Welcome to TroubleChute's Vicuna installer!" -ForegroundColor Cyan
Write-Host "Vicuna as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-07]`n`n" -ForegroundColor Cyan

# 1. Check if current directory is oobabooga-windows, or oobabooga-windows is in directory
# If it is, CD back a folder.
$currentDir = (Get-Item -Path ".\" -Verbose).FullName
if ($currentDir -like "*\oobabooga-windows") {
    Set-Location ../
}

$containsFolder = Get-ChildItem -Path ".\" -Directory -Name | Select-String -Pattern "oobabooga-windows"
if ($containsFolder) {
    Write-Host "The 'oobabooga-windows' folder already exists." -ForegroundColor Cyan
    $downloadAgain = Read-Host "Do you want to download it again? (Y/N)"

    if ($downloadAgain -eq "Y" -or $downloadAgain -eq "y") {
        # Perform the download again
        $containsFolder = $False
    }
}

if (-not $containsFolder) {
    Write-Host "I'll start by installing Oobabooga first, then we'll get to the model...`n`n"
    
    $skip_model = 1
    $skip_start = 1
    # 2. Run my install script for obabooga/text-generation-webui
    iex (irm ooba.tb.ag)
} else {
    # CD into folder anyway
    Set-Location "./oobabooga-windows"
}

# 3. Tells you how to download the vicuna model, and opens the model downloader.

Write-Host "`n`nATTENTION:`nCopy the following line by dragging around it and right-clicking." -ForegroundColor Cyan
Write-Host -NoNewline "CPU: " -ForegroundColor Red
Write-Host "eachadea/ggml-vicuna-13b-4bit" -ForegroundColor Green
Write-Host -NoNewline "GPU (eg. Nvidia): " -ForegroundColor Red
Write-Host "anon8231489123/vicuna-13b-GPTQ-4bit-128g" -ForegroundColor Green
Write-Host "When asked what model, select L (none of the above). Then Right-Click when asked for the Hugging Face model, or hit Ctrl+V and Enter." -ForegroundColor Cyan

$downloadAgain = Read-Host "Press any key to continue (or enter "n" to skip downloading a model)..."
if (-not ($downloadAgain -eq "N" -or $downloadAgain -eq "n")) {
    Write-Host "`n`n"
    
    # 4. Run the model downloader
    ./download-model.bat
}

# 5. Replace commands in the start-webui.bat file
# Create CPU and GPU versions
Copy-Item "start-webui.bat" "start-webui-vicuna.bat"

(Get-Content -Path "start-webui-vicuna.bat") | ForEach-Object {
    $_ -replace
        'call python server\.py --auto-devices --cai-chat',
        'call python server.py --auto-devices --cai-chat --model anon8231489123_vicuna-13b-GPTQ-4bit-128g --wbits 4 --groupsize 128'
} | Set-Content -Path "start-webui-vicuna-gpu.bat"

(Get-Content -Path "start-webui-vicuna.bat") | ForEach-Object {
    $_ -replace
        'call python server\.py --auto-devices --cai-chat',
        'call python server.py --auto-devices --cai-chat --model eachadea_ggml-vicuna-13b-4bit'
} | Set-Content -Path "start-webui-vicuna.bat"

# 6. Create desktop shortcuts
Write-Host "`n`nCreate desktop shortcuts for 'Vicuna' and 'Vicuna (CPU)'" -ForegroundColor Cyan
$shortcuts = Read-Host "Do you want desktop shortcuts? (Y/N)"

if ($shortcuts -eq "Y" -or $shortcuts -eq "y") {
    iex (irm Import-RemoteFunction.tb.ag) # Get RemoteFunction importer
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tb.ag" # Import function to create a shortcut
    
    Write-Host "Downloading Vicuna icon..."
    Invoke-WebRequest -Uri 'https://tb.ag/vicuna.ico' -OutFile 'vicuna.ico'

    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
    $shortcutName = "Vicuna oobabooga"
    $targetPath = "start-webui-vicuna-gpu.bat"
    $IconLocation = 'vicuna.ico'
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation
    
    $shortcutName = "Vicuna (CPU) oobabooga"
    $targetPath = "start-webui-vicuna.bat"
    $IconLocation = 'vicuna.ico'
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation
    
}


# 7. Run the webui
# Ask user if they want to launch the CPU or GPU version
Write-Host "`n`nEnter 1 to launch CPU version, or 2 to launch GPU version" -ForegroundColor Cyan

$choice = Read-Host "1 (CPU) or 2 (GPU)"

if ($choice -eq "1") {
    Start-Process ".\start-webui-vicuna.bat"
}
elseif ($choice -eq "2") {
    Start-Process ".\start-webui-vicuna-gpu.bat"
}
else {
    Write-Host "Invalid choice. Please enter 1 or 2."
}
