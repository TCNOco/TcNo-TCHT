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
# 1. Run my install script for obabooga/text-generation-webui
# 2. Tells you how to download the vicuna model, and opens the model downloader.
# 3. Run the model downloader
# 4. Replace commands in the start-webui.bat file
# 5. Run the webui
# ----------------------------------------

Write-Host "Welcome to TroubleChute's Vicuna installer!" -ForegroundColor Cyan
Write-Host "Vicuna as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-07]`n`n" -ForegroundColor Cyan

Write-Host "I'll start by installing Oobabooga first, then we'll get to the model...`n`n"

$skip_model = 1
$skip_start = 1
# 1. Run my install script for obabooga/text-generation-webui
iex (irm ooba.tb.ag)

# 2. Tells you how to download the vicuna model, and opens the model downloader.

Write-Host "`n`nATTENTION:`nCopy the following line by dragging around it and right-clicking." -ForegroundColor Cyan
Write-Host "anon8231489123/vicuna-13b-GPTQ-4bit-128g" -ForegroundColor Green
Write-Host "When asked what model, select L (none of the above). Then Right-Click when asked for the Hugging Face model, or hit Ctrl+V and Enter." -ForegroundColor Cyan

Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

Write-Host "`n`n"

# 3. Run the model downloader
./download-model.bat

# 4. Replace commands in the start-webui.bat file
(Get-Content -Path "start-webui.bat") | ForEach-Object {
    $_ -replace 'call python server\.py --auto-devices --cai-chat', 'call python server.py --auto-devices --cai-chat --wbits 4 --groupsize 128'
} | Set-Content -Path "start-webui.bat"

# 5. Run the webui
./start-webui.bat