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
# 2. Edit (or create and edit) settings.json
# 3. Ask the user what models they want to download
# 4. Replace commands in the start-webui.bat file
# 5. Create desktop shortcuts
# 6. Run the webui
# ----------------------------------------

Write-Host "Welcome to TroubleChute's MPT installer!" -ForegroundColor Cyan
Write-Host "MPT as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-05-09]`n`n" -ForegroundColor Cyan

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
    Read-Host
}

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
$TCHT = Get-TCHTPath

# 1. Check if has oobabooga_windows directory ($TCHT\oobabooga_windows) (Default C:\TCHT\oobabooga_windows)
$toDownload = $True
if (Test-Path -Path "$TCHT\oobabooga_windows") {
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
    
    Import-FunctionIfNotExists -Command Install-Ooba -ScriptUri "Install-Ooba.tc.ht"

    Install-Ooba -skip_model 1 -skip_start 1
    Set-Location "$TCHT\oobabooga_windows"

} else {
    # CD into folder anyway
    Set-Location "$TCHT\oobabooga_windows"
}

# Run the oobabooga updater
if (Test-Path -Path ./update_windows.bat) {
    Write-Host "Updating Oobabooga...`n`n" -ForegroundColor Cyan
    ./update_windows.bat
    Write-Host "Finished updating Oobabooga...`n`n" -ForegroundColor Cyan
}

# 2. Edit (or create and edit) settings.json
$source = "./text-generation-webui/settings-template.json"
$destination = "./text-generation-webui/settings.json"

if (!(Test-Path -Path $destination)) {
    Copy-Item -Path $source -Destination $destination
}

# Set:
# "truncation_length": 65000,
# "truncation_length_max": 65000,
(Get-Content -Path $destination) |
ForEach-Object { 
    if ($_ -match '^\s*"truncation_length":\s*\d+,*\s*$') { 
        $_ -replace '\d+', '65000'
    }
    elseif ($_ -match '^\s*"truncation_length_max":\s*\d+,*\s*$') { 
        $_ -replace '\d+', '65000'
    }
    else { 
        $_ 
    }
} | Set-Content -Path $destination




Import-FunctionIfNotExists -Command Get-Aria2File -ScriptUri "File-DownloadMethods.tc.ht"
Import-FunctionIfNotExists -Command Get-HuggingFaceRepo -ScriptUri "Get-HuggingFace.tc.ht"

$selectedNumbers = @()
$num = ""
do {
    #3. Ask user what model they want
    Write-Host "`n`nWhat model do you wan to download?" -ForegroundColor Cyan
    if ("1" -in $selectedNumbers){ Write-Host -NoNewline "[DONE] " -ForegroundColor Green }
    Write-Host -NoNewline "- MPT-7B-StoryWriter-65k+ (~13.30GB): " -ForegroundColor Red
    Write-Host "1" -ForegroundColor Green

    if ("2" -in $selectedNumbers){ Write-Host -NoNewline "[DONE] " -ForegroundColor Green }
    Write-Host -NoNewline "- MPT-7B-StoryWriter-65k+ 4bit 128g (~3.9GB): " -ForegroundColor Red
    Write-Host "2" -ForegroundColor Green

    if ("3" -in $selectedNumbers){ Write-Host -NoNewline "[DONE] " -ForegroundColor Green }
    Write-Host -NoNewline "- MPT-7B-Instruct (~13.30GB): " -ForegroundColor Red
    Write-Host "3" -ForegroundColor Green

    if ("4" -in $selectedNumbers){ Write-Host -NoNewline "[DONE] " -ForegroundColor Green }
    Write-Host -NoNewline "- MPT-7B-Chat (~13.30GB): " -ForegroundColor Red
    Write-Host "4" -ForegroundColor Green
    
    do {
        $num = Read-Host "Enter a number"
    } while ($num -notin "1", "2", "3", "4")
    
    switch ($num) {
        "1" {
            Write-Host "Downloading MPT-7B-StoryWriter-65k+" -ForegroundColor Yellow
            Get-HuggingFaceRepo -Model "mosaicml/mpt-7b-storywriter" -OutputPath "text-generation-webui\models\mosaicml_mpt-7b-storywriter"
        }
        "2" {
            Write-Host "Downloading MPT-7B-StoryWriter-65k+ 4bit 128g" -ForegroundColor Yellow
            Get-HuggingFaceRepo -Model "OccamRazor/mpt-7b-storywriter-4bit-128g" -OutputPath "text-generation-webui\models\OccamRazor_mpt-7b-storywriter-4bit-128g"
        }
        "3" {
            Write-Host "Downloading MPT-7B-Instruct" -ForegroundColor Yellow
            Get-HuggingFaceRepo -Model "mosaicml/mpt-7b-instruct" -OutputPath "text-generation-webui\models\mosaicml_mpt-7b-instruct"
        }
        "4" {
            Write-Host "Downloading MPT-7B-Chat" -ForegroundColor Yellow
            Get-HuggingFaceRepo -Model "mosaicml/mpt-7b-chat" -OutputPath "text-generation-webui\models\mosaicml_mpt-7b-chat"
        }
    }

    $selectedNumbers += $num
    if ($selectedNumbers.Count -lt 2) {
        Write-Host "Done downloading model`n`n" -ForegroundColor Yellow
        $again = Read-Host "Do you want to download another model? (y/n)"
    } else {
        $again = "N"
    }
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
            "call pip install einops`ncd text-generation-webui`npython server.py --auto-devices --chat --model $model $otherArgs")
    } | Set-Content -Path $newBatchFile
}

# 4. Replace commands in the start-webui.bat file
foreach ($number in $selectedNumbers) {
    Write-Host "Creating launcher: $number"
    switch ($number) {
        "1" {
            New-WebUIBat -model "mosaicml_mpt-7b-storywriter" -newBatchFile "start_mpt-7b-storywriter.bat" -otherArgs "--notebook --trust-remote-code"
        }
        "2" {
            New-WebUIBat -model "OccamRazor_mpt-7b-storywriter-4bit-128g" -newBatchFile "start_mpt-7b-storywriter-4bit.bat" -otherArgs "--notebook --trust-remote-code"
        }
        "3" {
            New-WebUIBat -model "mosaicml_mpt-7b-instruct" -newBatchFile "start_mpt-7b-instruct.bat" -otherArgs "--notebook --trust-remote-code"
        }
        "4" {
            New-WebUIBat -model "mosaicml_mpt-7b-chat" -newBatchFile "start_mpt-7b-chat.bat" -otherArgs "--notebook --trust-remote-code"
        }
    }
}

# 5. Create desktop shortcuts
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
                Deploy-Shortcut -name "MPT 7b Storywriter - Oobabooga" -batFile "start_mpt-7b-storywriter.bat"
            }
            "2" {
                Deploy-Shortcut -name "MPT 7b Storywriter 4bit - Oobabooga" -batFile "start_mpt-7b-storywriter-4bit.bat"
            }
            "3" {
                Deploy-Shortcut -name "MPT 7b Instruct - Oobabooga" -batFile "start_mpt-7b-instruct.bat"
            }
            "4" {
                Deploy-Shortcut -name "MPT 7b Chat - Oobabooga" -batFile "start_mpt-7b-chat.bat"
            }
        }
    }
}

# 6. Run the webui
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
                Write-Host "Downloading MPT-7B-StoryWriter-65k+" -ForegroundColor Yellow
                Write-Host "1" -ForegroundColor Green
            }
            "2" {
                Write-Host "Downloading MPT-7B-StoryWriter-65k+ 4bit 128g" -ForegroundColor Yellow
                Write-Host "2" -ForegroundColor Green
            }
            "3" {
                Write-Host "Downloading MPT-7B-Instruct" -ForegroundColor Yellow
                Write-Host "3" -ForegroundColor Green
            }
            "4" {
                Write-Host "Downloading MPT-7B-Chat" -ForegroundColor Yellow
                Write-Host "4" -ForegroundColor Green
            }
        }
    }
    
    do {
        $num = Read-Host "Enter a number"
    } while ($num -notin "1", "2", "3", "4")

    if ("1" -in $selectedNumbers) {
        Start-Process ".\start_mpt-7b-storywriter.bat"
    } elseif ("2" -in $selectedNumbers) {
        Start-Process ".\start_mpt-7b-storywriter-4bit.bat"
    } elseif ("3" -in $selectedNumbers) {
        Start-Process ".\start_mpt-7b-instruct.bat"
    } elseif ("4" -in $selectedNumbers) {
        Start-Process ".\start_mpt-7b-chat.bat"
    }
}