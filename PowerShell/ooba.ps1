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
# 1. Downloads and extracts the latest oobabooga/text-generation-webui
# 2. Run install script (Unless )
# 3. Run the model downloader script
# ----------------------------------------

Write-Host "Welcome to TroubleChute's Oobabooga installer!" -ForegroundColor Cyan
Write-Host "Oobabooga should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-07]`n`n" -ForegroundColor Cyan

# 1. Downloads and extracts the latest oobabooga/text-generation-webui release
# Download file
Invoke-WebRequest -Uri "https://github.com/oobabooga/text-generation-webui/releases/download/installers/oobabooga-windows.zip" -OutFile "./oobabooga-windows.zip"

# Extract file
Expand-Archive "./oobabooga-windows.zip" -DestinationPath "./" -Force

# Delete zip file
Remove-Item "./oobabooga-windows.zip"

# 2. Run install.bat
Set-Location "./oobabooga-windows"
./install.bat

if (-not ($skip_model -eq 1)) {
    # 3. Run the model downloader 
    ./download-model.bat
}

if (-not ($skip_start -eq 1)) {
    # 4. Run the webui
    ./start-webui.bat
}