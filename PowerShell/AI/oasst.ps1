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
# 2. Ask the user what models they want to download
# 3. Replace commands in the start-webui.bat file
# 4. Create desktop shortcuts
# 5. Run the webui
# ----------------------------------------

Write-Host "Welcome to TroubleChute's OpenAssist (Pythia) installer!" -ForegroundColor Cyan
Write-Host "OpenAssist (Pythia) as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-19]`n`n" -ForegroundColor Cyan

# 1. Check if has oobabooga_windows directory (C:\TCHT\oobabooga_windows)
$toDownload = $True
if (Test-Path -Path "C:\TCHT\oobabooga_windows") {
    Write-Host "The 'oobabooga_windows' folder already exists." -ForegroundColor Green
    do {
        Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want to download it again? (y/n): "
        $downloadAgain = Read-Host
    } while ($downloadAgain -notin "Y", "y", "N", "n")

    if ($downloadAgain -eq "Y" -or $downloadAgain -eq "y") {
        # Perform the download again
        $toDownload = $True
    } else {
        $toDownload = $False
    }
}

if ($toDownload) {
    Write-Host "I'll start by installing Oobabooga first, then we'll get to the model...`n`n"
    
    # Allow importing remote functions
    iex (irm Import-RemoteFunction.tc.ht)
    Import-FunctionIfNotExists -Command Install-Ooba -ScriptUri "Install-Ooba.tc.ht"

    Install-Ooba -skip_model 1 -skip_start 1
    Set-Location "C:\TCHT\oobabooga_windows"

} else {
    # CD into folder anyway
    Set-Location "C:\TCHT\oobabooga_windows"
}

function Get-Oasst-12B-3-5 {
    # Download 12B model
    Write-Host "Downloading 12B OpenAssist SFT Pythia 12B epoch 3.5" -ForegroundColor Yellow
    $blob = "https://huggingface.co/OpenAssistant/oasst-sft-4-pythia-12b-epoch-3.5/resolve/main"
    $outputPath = "text-generation-webui\models\openassistant_oasst-sft-4-pythia-12b-epoch-3.5"
    Write-Host "Downloading: OpenAssistant/oasst-sft-4-pythia-12b-epoch-3.5" -ForegroundColor Cyan
    $files = @(
        "config.json"
        "generation_config.json"
        "pytorch_model-00001-of-00003.bin"
        "pytorch_model-00002-of-00003.bin"
        "pytorch_model-00003-of-00003.bin"
        "pytorch_model.bin.index.json"
        "special_tokens_map.json"
        "tokenizer.json"
        "tokenizer_config.json"
    )

    Get-Aria2Files -Url $blob -OutputPath $outputPath -Files $files
    Write-Host "Done" -ForegroundColor Yellow
}

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-FunctionIfNotExists -Command Get-Aria2File -ScriptUri "File-DownloadMethods.tc.ht"
Get-Oasst-12B-3-5

Write-Host "NOTE: Should you need less memory usage, see: https://github.com/oobabooga/text-generation-webui/wiki/Low-VRAM-guide" -ForegroundColor Green
Write-Host "(These will be added to the .bat you're trying to run in the oobabooga_windows folder)" -ForegroundColor Green


function New-WebUIBat {
    param(
        [string]$model,
        [string]$newBatchFile,
        [string]$otherArgs
    )

    (Get-Content -Path "start_windows.bat") | ForEach-Object {
        ($_ -replace
            'call python webui.py',
            "cd text-generation-webui`npython server.py --auto-devices --chat --model $model $otherArgs")
    } | Set-Content -Path $newBatchFile
}

# 3. Replace commands in the start-webui.bat file
New-WebUIBat -model "openassistant_oasst-sft-4-pythia-12b-epoch-3.5" -newBatchFile "start_oasst-12B.bat" -otherArgs ""

# 4. Create desktop shortcuts

function Deploy-Shortcut {
    param(
        [string]$name,
        [string]$batFile
    )
    New-Shortcut -ShortcutName $name -TargetPath $batFile -IconLocation 'oasst.ico'
}

do {
    Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want desktop shortcuts? (y/n): "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n")


if ($shortcuts -eq "Y" -or $shortcuts -eq "y") {
    iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading OpenAssist icon..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/oasst.ico' -OutFile 'oasst.ico'
    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan

    Deploy-Shortcut -name "OpenAssist 12B 3.5 Oobabooga" -batFile "start_oasst-12B.bat"
}

# 5. Run the webui
    Start-Process ".\start_oasst-12B.bat"