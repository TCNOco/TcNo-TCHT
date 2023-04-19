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

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-FunctionIfNotExists -Command Get-Aria2File -ScriptUri "File-DownloadMethods.tc.ht"
Import-FunctionIfNotExists -Command Get-HuggingFaceRepo -ScriptUri "Get-HuggingFace.tc.ht"

Write-Host "`nNOTE: (SFT: Supervised Fine-Tuning, RM: Reward Model)`n"  -ForegroundColor Cyan
$selectedNumbers = @()
$num = ""
do {
    # Ask user what model they want
    Write-Host "`n`nWhat model do you wan to download?" -ForegroundColor Cyan
    if ("1" -in $selectedNumbers){ Write-Host -NoNewline "[DONE] " -ForegroundColor Green }
    Write-Host -NoNewline "- [11 Apr '23] Pythia SFT-4 12B epoch 3.5 (~24GB): " -ForegroundColor Red
    Write-Host "1" -ForegroundColor Green

    if ("2" -in $selectedNumbers){ Write-Host -NoNewline "[DONE] " -ForegroundColor Green }
    Write-Host -NoNewline "- [11 Mar '23] Pythia SFT-1 12B 7B (~24GB): " -ForegroundColor Red
    Write-Host "2" -ForegroundColor Green
    
    do {
        $num = Read-Host "Enter a number"
    } while ($num -notin "1", "2")
    
    switch ($num) {
        "1" {
            Write-Host "Downloading Open-Assistant SFT-4 12B Model Epoch 3.5" -ForegroundColor Yellow
            Get-HuggingFaceRepo -Model "OpenAssistant/oasst-sft-4-pythia-12b-epoch-3.5" -OutputPath "text-generation-webui\models\openassistant_oasst-sft-4-pythia-12b-epoch-3.5"
        }
        "2" {
            Write-Host "Downloading Open-Assistant SFT-1 12B Model" -ForegroundColor Yellow
            Get-HuggingFaceRepo -Model "OpenAssistant/oasst-sft-1-pythia-12b" -OutputPath "text-generation-webui\models\openassistant_oasst-sft-1-pythia-12b"
        }
    }

    $selectedNumbers += $num
    Write-Host "Done downloading model`n`n" -ForegroundColor Yellow

    $again = Read-Host "Do you want to download another model? (y/n)"
} while ($again -notin "N", "n")


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
foreach ($number in $selectedNumbers) {
    Write-Host "Creating launcher: $number"
    switch ($number) {
        "1" {
            New-WebUIBat -model "openassistant_oasst-sft-4-pythia-12b-epoch-3.5" -newBatchFile "start_oasst-sft-4-12b.bat" -otherArgs ""
        }
        "2" {
            New-WebUIBat -model "openassistant_oasst-sft-1-pythia-12b" -newBatchFile "start_oasst-sft-1-12b.bat" -otherArgs ""
        }
    }
}

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

    foreach ($number in $selectedNumbers) {
        Write-Host "Creating shortcut: $number"
        switch ($number) {
            "1" {
                Deploy-Shortcut -name "Open-Assistant SFT-4 12B - Oobabooga" -batFile "start_oasst-sft-4-12b.bat"
            }
            "2" {
                Deploy-Shortcut -name "Open-Assistant SFT-1 12B - Oobabooga" -batFile "start_oasst-sft-1-12b.bat"
            }
        }
    }
}

# 5. Run the webui
if ($selectedNumbers.Count -eq 1) {
    if ("1" -in $selectedNumbers) {
        Start-Process ".\start_oasst-sft-4-12b.bat"
    } elseif ("2" -in $selectedNumbers) {
        Start-Process ".\start_oasst-sft-1-12b.bat"
    }
} else {
    Write-Host "`nWhich model would you like to launch?" -ForegroundColor Cyan
    foreach ($number in $selectedNumbers) {
        switch ($number) {
            "1" {
                Write-Host -NoNewline "- [11 Apr '23] Pythia SFT-4 12B epoch 3.5 (~24GB): " -ForegroundColor Red
                Write-Host "1" -ForegroundColor Green
            }
            "2" {
                Write-Host -NoNewline "- [11 Mar '23] Pythia SFT-1 12B 7B (~24GB): " -ForegroundColor Red
                Write-Host "2" -ForegroundColor Green
            }
        }
    }
    
    do {
        $num = Read-Host "Enter a number"
    } while ($num -notin "1", "2")

    if ("1" -in $selectedNumbers) {
        Start-Process ".\start_oasst-sft-4-12b.bat"
    } elseif ("2" -in $selectedNumbers) {
        Start-Process ".\start_oasst-sft-1-12b.bat"
    }
}