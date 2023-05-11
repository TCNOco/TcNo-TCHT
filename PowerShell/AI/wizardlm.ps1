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

Write-Host "Welcome to TroubleChute's WizardLM installer!" -ForegroundColor Cyan
Write-Host "WizardLM as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-05-11]`n`n" -ForegroundColor Cyan

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
    Clear-ConsoleScreen
    Write-Host "Updating Oobabooga...`n`n" -ForegroundColor Cyan
    ./update_windows.bat
    Clear-ConsoleScreen
    Write-Host "Finished updating Oobabooga...`n`n" -ForegroundColor Cyan
}

Import-FunctionIfNotExists -Command Get-Aria2File -ScriptUri "File-DownloadMethods.tc.ht"
Import-FunctionIfNotExists -Command Get-HuggingFaceRepo -ScriptUri "Get-HuggingFace.tc.ht"

$models = @{
    "1" = @{
        "Name" = "WizardLM-7B-GPTQ"
        "Size" = "~7.78 GB"
        "Repo" = "TheBloke/wizardLM-7B-GPTQ"
        "BatName" = "start_wizardLM-7B-GPTQ.bat"
        "ShortcutName" = "WizardLM 7B - Oobabooga"
        "Args" = "--chat --model_type llama --wbits 4 --groupsize 128"
        "SkipFiles" = @("wizardLM-7B-GPTQ-4bit.compat.latest.act-order.safetensors")
    }
    "2" = @{
        "Name" = "WizardLM-7B-uncensored-GPTQ 4bit"
        "Size" = "~3.89 GB"
        "Repo" = "TheBloke/WizardLM-7B-uncensored-GPTQ"
        "BatName" = "start_WizardLM-7B-uncensored-GPTQ-4bit.bat"
        "ShortcutName" = "WizardLM 7B Uncensored 4bit - Oobabooga"
        "Args" = "--chat --model_type llama --wbits 4 --groupsize 128"
    }
    "3" = @{
        "Name" = "WizardLM 13B Uncensored 4bit 128g"
        "Size" = "~7.45 GB"
        "Repo" = "ausboss/WizardLM-13B-Uncensored-4bit-128g"
        "BatName" = "start_WizardLM-13B-Uncensored-4bit-128g.bat"
        "ShortcutName" = "WizardLM 13B Uncensored - Oobabooga"
        "Args" = "--chat --model_type llama --wbits 4 --groupsize 128"
    }
}

$selectedModels = @()

# 2. Ask user what model they want
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
    Get-HuggingFaceRepo -Model $models.$num.Repo -OutputPath "text-generation-webui\models\$($models.$num.Repo -replace '/','_')" -SkipFiles $($models.$num.SkipFiles) -IncludeFiles $($models.$num.IncludeFiles)    

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
            "cd text-generation-webui`npython server.py --model $model $otherArgs")
    } | Set-Content -Path $newBatchFile
}

# 3. Replace commands in the start-webui.bat file
foreach ($num in ($selectedModels | Sort-Object)) {
    Write-Host "Creating launcher: $num"

    $modelArgs = $models.$num.Args
    New-WebUIBat -model ($models.$num.Repo -replace '/','_') -newBatchFile $models.$num.BatName -otherArgs "$modelArgs"
}

# 4. Create desktop shortcuts
function Deploy-Shortcut {
    param(
        [string]$name,
        [string]$batFile
    )
    New-Shortcut -ShortcutName $name -TargetPath $batFile -IconLocation 'wizardlm.ico'
}

Clear-ConsoleScreen
do {
    Write-Host -ForegroundColor Cyan -NoNewline "Do you want desktop shortcuts? (y/n): "
    $shortcuts = Read-Host
} while ($shortcuts -notin "Y", "y", "N", "n")


if ($shortcuts -eq "Y" -or $shortcuts -eq "y") {
    iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading WizardLM icon..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/wizardlm.ico' -OutFile 'wizardlm.ico'
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
