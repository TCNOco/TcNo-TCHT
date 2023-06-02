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

Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's MPT installer!" -ForegroundColor Cyan
Write-Host "MPT as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-05-09]" -ForegroundColor Cyan
Write-Host "`nConsider supporting these install scripts: https://tc.ht/support" -ForegroundColor Cyan
Write-Host "----------------------------------------`n`n" -ForegroundColor Cyan

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
    Read-Host
}

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")
$TCHT = Get-TCHTPath

# 1. Check if has oobabooga_windows directory ($TCHT\oobabooga_windows) (Default C:\TCHT\oobabooga_windows)
$toDownload = $True
if (Test-Path -Path "$TCHT\oobabooga_windows") {
    Write-Host "The 'oobabooga_windows' folder already exists." -ForegroundColor Green
    do {
        Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want to download it again [NEW: Choose yes to move]? (y/n): "
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
    Clear-ConsoleScreen
    Write-Host "Updating Oobabooga...`n`n" -ForegroundColor Cyan
    ./update_windows.bat
    Clear-ConsoleScreen
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

$models = @{
    "1" = @{
        "Name" = "MPT-7B-StoryWriter-65k+"
        "Size" = "~13.30GB"
        "Repo" = "mosaicml/mpt-7b-storywriter"
        "BatName" = "start_mpt-7b-storywriter.bat"
        "ShortcutName" = "MPT 7b Storywriter - Oobabooga"
        "Args" = "--notebook --trust-remote-code"
    }
    "2" = @{
        "Name" = "MPT-7B-Instruct"
        "Size" = "~13.30GB"
        "Repo" = "mosaicml/mpt-7b-instruct"
        "BatName" = "start_mpt-7b-instruct.bat"
        "ShortcutName" = "MPT 7b Instruct - Oobabooga"
        "Args" = "--notebook --trust-remote-code"
    }
    "3" = @{
        "Name" = "MPT-7B-Chat"
        "Size" = "~13.30GB"
        "Repo" = "mosaicml/mpt-7b-chat"
        "BatName" = "start_mpt-7b-chat.bat"
        "ShortcutName" = "MPT 7b Chat - Oobabooga"
        "Args" = "--chat --trust-remote-code"
    }
}

$selectedModels = @()

# 3. Ask user what model they want
do {
    Clear-ConsoleScreen
    Write-Host "What model do you want to download?" -ForegroundColor Cyan
    foreach ($key in ($models.Keys | Sort-Object)) {
        if ($key -in $selectedModels) { Write-Host -NoNewline "[DONE] " -ForegroundColor Green }
        Write-Host -NoNewline "- $($models.$key.Name) $($models.$key.Size): " -ForegroundColor Red
        Write-Host $key -ForegroundColor Green
    }

    do {
        $num = Read-Host "Enter a number"
    } while ($num -notin $models.Keys)
    $selectedModels += $num
    Write-Host "Downloading $($models.$num.Name)" -ForegroundColor Yellow
    Get-HuggingFaceRepo -Model $models.$num.Repo -OutputPath "text-generation-webui\models\$($models.$num.Repo -replace '/','_')"

    if ($selectedModels.Count -lt $models.Count) {
        Clear-ConsoleScreen
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
            "call pip install einops`ncd text-generation-webui`npython server.py --model $model $otherArgs")
    } | Set-Content -Path $newBatchFile
}

# 4. Replace commands in the start-webui.bat file
$cpuOnly = Read-Host "The MPT models require a LOT of VRAM. As in a 3090+. Do you want to run in CPU-only mode? (Y/N)"
foreach ($num in ($selectedModels | Sort-Object)) {
    Write-Host "Creating launcher: $num"

    $modelArgs = $models.$num.Args

    if ($cpuOnly -in "Y", "y") {
        New-WebUIBat -model ($models.$num.Repo -replace '/','_') -newBatchFile $models.$num.BatName -otherArgs "--cpu $modelArgs"
    } else {
        New-WebUIBat -model ($models.$num.Repo -replace '/','_') -newBatchFile $models.$num.BatName -otherArgs "$modelArgs"
    }
}

# 5. Create desktop shortcuts
function Deploy-Shortcut {
    param(
        [string]$name,
        [string]$batFile
    )
    New-Shortcut -ShortcutName $name -TargetPath $batFile -IconLocation 'mpt.ico'
}

Clear-ConsoleScreen
do {
    Write-Host -ForegroundColor Cyan -NoNewline "Do you want desktop shortcuts? (y/n): "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n")


if ($shortcuts -eq "Y" -or $shortcuts -eq "y") {
    iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading MPT icon..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/mpt.ico' -OutFile 'mpt.ico'
    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan

    foreach ($num in ($selectedModels | Sort-Object)) {
        Write-Host "Creating shortcut: $num"
        Deploy-Shortcut -name $models.$num.ShortcutName -batFile $models.$num.BatName
    }
}

# 5. Run the webui
Clear-ConsoleScreen
if (@($selectedModels).Count -eq 1) {
    # Run the only model by running the ".BatName"
    $batFilePath = $models.($selectedModels[0]).BatName
    Start-Process -FilePath cmd.exe -ArgumentList "/C $batFilePath"
} else {
    Write-Host "Which model would you like to launch?" -ForegroundColor Cyan
    foreach ($num in ($selectedModels | Sort-Object)) {
        Write-Host -NoNewline "$num - " -ForegroundColor Green
        Write-Host "$($models.$num.Name)" -ForegroundColor Yellow
    }
    
    do {
        $num = Read-Host "Enter a number"
    } while ($num -notin $selectedModels)

    # Run the selected model by running the ".BatName"
    $batFilePath = $models.$num.BatName
    Start-Process -FilePath cmd.exe -ArgumentList "/C $batFilePath"
}
