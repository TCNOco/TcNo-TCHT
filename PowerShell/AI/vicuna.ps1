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
# 4. Run the model downloader (Unless CPU-Only mode was selected in install, in which case the CPU model is downloaded)
# 5. Replace commands in the start-webui.bat file
# 6. Create desktop shortcuts
# 7. Run the webui
# ----------------------------------------

Write-Host "Welcome to TroubleChute's Vicuna installer!" -ForegroundColor Cyan
Write-Host "Vicuna as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-11]`n`n" -ForegroundColor Cyan

# 1. Check if current directory is oobabooga-windows, or oobabooga-windows is in directory
# If it is, CD back a folder.
$currentDir = (Get-Item -Path ".\" -Verbose).FullName
if ($currentDir -like "*\oobabooga-windows") {
    Set-Location ../
}

$containsFolder = Get-ChildItem -Path ".\" -Directory -Name | Select-String -Pattern "oobabooga-windows"
if ($containsFolder) {
    Write-Host "The 'oobabooga-windows' folder already exists." -ForegroundColor Cyan
    do {
        $downloadAgain = Read-Host "Do you want to download it again? (Y/N)"
    } while ($downloadAgain -notin "Y", "y", "N", "n")

    if ($downloadAgain -eq "Y" -or $downloadAgain -eq "y") {
        # Perform the download again
        $containsFolder = $False
    }
}

if (-not $containsFolder) {
    Write-Host "I'll start by installing Oobabooga first, then we'll get to the model...`n`n"
    
    #2. Choose CPU or GPU installation
    Write-Host "Do you have an NVIDIA GPU?" -ForegroundColor Cyan
    Write-Host "Enter anything but y or n to skip." -ForegroundColor Yellow

    do {
        $choice = Read-Host "Answer (y/n)"
    } while ($choice -notin "Y", "y", "N", "n")

    $skip_model = 1
    $skip_start = 1

    if ($choice -eq "Y" -or $choice -eq "y") {
        Write-Host "Installing GPU & CPU compatible version" -ForegroundColor Cyan
        Write-Host "If this fails, please delete the folder and choose 'N'" -ForegroundColor Cyan
        $gpu = "Yes"
        # 2. Run my install script for obabooga/text-generation-webui
        iex (irm ooba.tc.ht)
    }
    elseif ($choice -eq "N" -or $choice -eq "n") {
        Write-Host "Installing CPU-Only version" -ForegroundColor Cyan
        $gpu = "No"
        # 2. Run my install script for obabooga/text-generation-webui
        iex (irm ooba.tc.ht)
    }

} else {
    # CD into folder anyway
    Set-Location "./oobabooga-windows"
}


function Get-VincunaCPU13B {
    # Download CPU model 13B
    Write-Host "Downloading CPU model 13B" -ForegroundColor Yellow
    $blob = "https://huggingface.co/eachadea/ggml-vicuna-13b-1.1/resolve/main"
    $outputPath = "text-generation-webui\models\eachadea_ggml-vicuna-13b-1-1"
    Write-Host "Downloading: eachadea/ggml-vicuna-13b-1.1 (CPU model)" -ForegroundColor Cyan
    $files = @(
        "ggml-vicuna-13b-1.1-q4_0.bin",
        "ggml-vicuna-13b-1.1-q4_1.bin"
    )

    Get-Aria2Files -Url $blob -OutputPath $outputPath -Files $files
    Write-Host "Done" -ForegroundColor Yellow
}

function Get-VicunaCPU7B {
    # Download CPU model 7B
    Write-Host "Downloading CPU model 7B" -ForegroundColor Yellow
    $blob = "https://huggingface.co/eachadea/ggml-vicuna-7b-1.1/resolve/main"
    $outputPath = "text-generation-webui\models\eachadea_ggml-vicuna-7b-1-1"
    Write-Host "Downloading: eachadea/ggml-vicuna-7b-1.1 (CPU model)" -ForegroundColor Cyan
    $files = @(
        "ggml-vicuna-7b-1.1-q4_0.bin",
        "ggml-vicuna-7b-1.1-q4_1.bin"
    )

    Get-Aria2Files -Url $blob -OutputPath $outputPath -Files $files
    Write-Host "Done" -ForegroundColor Yellow
}

$global:cpuModel = ""
function Get-VicunaCPU() {
    if ($global:cpuModel -eq "1") {
        Get-VincunaCPU13B
    } elseif ($global:cpuModel -eq "2") {
        Get-VicunaCPU7B
    } elseif ($global:cpuModel -eq "3"){
        Get-VincunaCPU13B
        Get-VicunaCPU7B
    }

    Write-Host "`nDone!`n" -ForegroundColor Cyan
}

function Get-VicunaGPU13B {
    # Download GPU model 13B
    Write-Host "Downloading GPU model 13B" -ForegroundColor Yellow
    $blob = "https://huggingface.co/anon8231489123/vicuna-13b-GPTQ-4bit-128g/resolve/main"
    $outputPath = "text-generation-webui\models\anon8231489123_vicuna-13b-GPTQ-4bit-128g"

    # Download the file from the URL
    Write-Host "Downloading: anon8231489123/vicuna-13b-GPTQ-4bit-128g (GPU/CUDA model)" -ForegroundColor Cyan
    $files = @(
        "vicuna-13b-4bit-128g.safetensors",
        "tokenizer_config.json",
        "tokenizer.model",
        "special_tokens_map.json",
        "pytorch_model.bin.index.json",
        "generation_config.json",
        "config.json"
    )

    Get-Aria2Files -Url $blob -OutputPath $outputPath -Files $files
    Write-Host "Done" -ForegroundColor Yellow
}
function Get-VicunaGPU7B {
    # Download GPU model 7B
    Write-Host "Downloading GPU model 7B" -ForegroundColor Yellow
    $blob = "https://huggingface.co/TheBloke/vicuna-AlekseyKorshuk-7B-GPTQ-4bit-128g/resolve/main"
    $outputPath = "text-generation-webui\models\TheBloke_vicuna-AlekseyKorshuk-7B-GPTQ-4bit-128g"

    # Download the file from the URL
    Write-Host "Downloading: TheBloke/vicuna-AlekseyKorshuk-7B-GPTQ-4bit-128g (GPU/CUDA model)" -ForegroundColor Cyan
    $files = @(
        "vicuna-AlekseyKorshuk-7B-GPTQ-4bit-128g.safetensors",
        "tokenizer_config.json",
        "tokenizer.model",
        "special_tokens_map.json",
        "pytorch_model.bin.index.json",
        "generation_config.json",
        "added_tokens.json",
        "config.json"
    )

    Get-Aria2Files -Url $blob -OutputPath $outputPath -Files $files
    Write-Host "Done" -ForegroundColor Yellow
}

$global:gpuModel = ""
function Get-VicunaGPU() {
    if ($global:gpuModel -eq "1") {
        Get-VicunaGPU13B
    } elseif ($global:gpuModel -eq "2") {
        Get-VicunaGPU7B
    } elseif ($global:gpuModel -eq "3"){
        Get-VicunaGPU13B
        Get-VicunaGPU7B
    }

    Write-Host "`nDone!`n" -ForegroundColor Cyan
}

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-FunctionIfNotExists -Command Get-Aria2File -ScriptUri "File-DownloadMethods.tc.ht"

# Create the output folder if it does not exist
New-Item -ItemType Directory -Force -Path (Split-Path -Parent "text-generation-webui\models\eachadea_ggml-vicuna-13b-4bit") | Out-Null
if (-not $?) {
    Write-Error "Failed to create directory."
}

Write-Host "`n`nNOTE: If you see ""AttributeError: 'Llama' object has no attribute 'ctx' "" then you don't have enough RAM/VRAM." -ForegroundColor Red
Write-Host "Should you need less memory usage, see: https://github.com/oobabooga/text-generation-webui/wiki/Low-VRAM-guide" -ForegroundColor Green
Write-Host "(These will be added to the .bat you're trying to run in the oobabooga-windows folder)" -ForegroundColor Green

if ($gpu -eq "No") {
    # Ask user what CPU model they want
    Write-Host "`nPick a CPU model and enter a number below?" -ForegroundColor Cyan
    Write-Host -NoNewline "- 13B (~9.8GB+ RAM): " -ForegroundColor Red
    Write-Host "1" -ForegroundColor Green
    Write-Host -NoNewline "-  7B (~5.8GB+ RAM): " -ForegroundColor Red
    Write-Host "2" -ForegroundColor Green
    Write-Host -NoNewline "- Both: " -ForegroundColor Red
    Write-Host "3" -ForegroundColor Green
    
    do {
        $global:cpuModel = Read-Host "Enter choice"
    } while ($global:cpuModel -notin "1", "2", "3")

    Get-VicunaCPU
} else {
    Write-Host "`n`nPick which models to download:" -ForegroundColor Cyan
    Write-Host -NoNewline "CPU: " -ForegroundColor Red
    Write-Host "1" -ForegroundColor Green
    Write-Host -NoNewline "GPU [Nvidia]: " -ForegroundColor Red
    Write-Host "2" -ForegroundColor Green
    Write-Host -NoNewline "CPU + GPU [Nvidia]: " -ForegroundColor Red
    Write-Host "3" -ForegroundColor Green
    
    do {
        $num = Read-Host "Enter a number"
    } while ($num -notin "1", "2", "3")

    # Get choices
    if ($num -in "1", "3") {
        # Ask user what CPU model they want
        Write-Host "`n`nPick a CPU model and enter a number below?" -ForegroundColor Cyan
        Write-Host -NoNewline "- 13B (~9.8GB+ RAM): " -ForegroundColor Red
        Write-Host "1" -ForegroundColor Green
        Write-Host -NoNewline "-  7B (~5.8GB+ RAM): " -ForegroundColor Red
        Write-Host "2" -ForegroundColor Green
        Write-Host -NoNewline "- Both: " -ForegroundColor Red
        Write-Host "3" -ForegroundColor Green
        
        do {
            $global:cpuModel = Read-Host "Enter choice"
        } while ($global:cpuModel -notin "1", "2", "3")
    }
    if ($num -in "2", "3") {
        # Ask user what GPU model they want
        Write-Host "`n`nPick a GPU model and enter a number below?" -ForegroundColor Cyan
        Write-Host -NoNewline "- 13B (~7GB+ VRAM): " -ForegroundColor Red
        Write-Host "1" -ForegroundColor Green
        Write-Host -NoNewline "-  7B (~4.3GB+ VRAM): " -ForegroundColor Red
        Write-Host "2" -ForegroundColor Green
        Write-Host -NoNewline "- Both: " -ForegroundColor Red
        Write-Host "3" -ForegroundColor Green
    
        do {
            $global:gpuModel = Read-Host "Enter choice"
        } while ($global:gpuModel -notin "1", "2", "3")
    }
    
    # Download all requested models
    if ($num -in "1", "3") {
        Get-VicunaCPU
    }
    if ($num -in "2", "3") {
        Get-VicunaGPU
    }
}


function New-WebUIBat {
    param(
        [string]$model,
        [string]$newBatchFile,
        [string]$otherArgs
    )

    (Get-Content -Path "start-webui-vicuna.bat") | ForEach-Object {
        ($_ -replace
            'call python server\.py --auto-devices',
            "call python server.py --auto-devices --model $model $otherArgs") -replace '--cai-chat', '--chat'
    } | Set-Content -Path $newBatchFile
}

# 5. Replace commands in the start-webui.bat file
# Create CPU and GPU versions
Copy-Item "start-webui.bat" "start-webui-vicuna.bat"

if (-not ($gpu -eq "No")) {    
    if ($global:gpuModel -eq "1") {
        New-WebUIBat -model "anon8231489123_vicuna-13b-GPTQ-4bit-128g" -newBatchFile "start-webui-vicuna-gpu-13B.bat" -otherArgs "--wbits 4 --groupsize 128"
    } elseif ($global:gpuModel -eq "2") {
        New-WebUIBat -model "TheBloke_vicuna-AlekseyKorshuk-7B-GPTQ-4bit-128g" -newBatchFile "start-webui-vicuna-gpu-7B.bat" -otherArgs "--wbits 4 --groupsize 128"
    } elseif ($global:gpuModel -eq "3") {
        New-WebUIBat -model "anon8231489123_vicuna-13b-GPTQ-4bit-128g" -newBatchFile "start-webui-vicuna-gpu-13B.bat" -otherArgs "--wbits 4 --groupsize 128"
        New-WebUIBat -model "TheBloke_vicuna-AlekseyKorshuk-7B-GPTQ-4bit-128g" -newBatchFile "start-webui-vicuna-gpu-7B.bat" -otherArgs "--wbits 4 --groupsize 128"
    }
}

if ($global:cpuModel -eq "1") {
    New-WebUIBat -model "eachadea_ggml-vicuna-13b-1-1" -newBatchFile "start-webui-vicuna-cpu-13B.bat" -otherArgs ""
} elseif ($global:cpuModel -eq "2") {
    New-WebUIBat -model "eachadea_ggml-vicuna-7b-1-1" -newBatchFile "start-webui-vicuna-cpu-7B.bat" -otherArgs ""
} elseif ($global:cpuModel -eq "3") {
    New-WebUIBat -model "eachadea_ggml-vicuna-13b-1-1" -newBatchFile "start-webui-vicuna-cpu-13B.bat" -otherArgs ""
    New-WebUIBat -model "eachadea_ggml-vicuna-7b-1-1" -newBatchFile "start-webui-vicuna-cpu-7B.bat" -otherArgs ""
}

# 6. Create desktop shortcuts
if ($gpu -eq "No") {
    Write-Host "`n`nCreate desktop shortcuts for 'Vicuna (CPU)'" -ForegroundColor Cyan
} else {
    Write-Host "`n`nCreate desktop shortcuts for 'Vicuna' and 'Vicuna (CPU)'" -ForegroundColor Cyan
}

function Deploy-Shortcut {
    param(
        [string]$name,
        [string]$batFile
    )
    New-Shortcut -ShortcutName $name -TargetPath $batFile -IconLocation 'vicuna.ico'
}

do {
    $shortcuts = Read-Host "Do you want desktop shortcuts? (Y/N)"
} while ($shortcuts -notin "Y", "y", "N", "n")


if ($shortcuts -eq "Y" -or $shortcuts -eq "y") {
    iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
    Import-RemoteFunction -ScriptUri "https://New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading Vicuna icon..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/vicuna.ico' -OutFile 'vicuna.ico'
    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
    if (-not ($gpu -eq "No")) {
        if ($global:gpuModel -eq "1") {
            Deploy-Shortcut -name "Vicuna GPU [13B] oobabooga" -batFile "start-webui-vicuna-gpu-13B.bat"
        } elseif ($global:gpuModel -eq "2") {
            Deploy-Shortcut -name "Vicuna GPU [7B] oobabooga" -batFile "start-webui-vicuna-gpu-7B.bat"
        } elseif ($global:gpuModel -eq "3") {
            Deploy-Shortcut -name "Vicuna GPU [13B] oobabooga" -batFile "start-webui-vicuna-gpu-13B.bat"
            Deploy-Shortcut -name "Vicuna GPU [7B] oobabooga" -batFile "start-webui-vicuna-gpu-7B.bat"
        }
    }

    if ($global:cpuModel -eq "1") {
        Deploy-Shortcut -name "Vicuna CPU [13B] oobabooga" -batFile "start-webui-vicuna-cpu-13B.bat"
    } elseif ($global:cpuModel -eq "2") {
        Deploy-Shortcut -name "Vicuna CPU [7B] oobabooga" -batFile "start-webui-vicuna-cpu-7B.bat"
    } elseif ($global:cpuModel -eq "3") {
        Deploy-Shortcut -name "Vicuna CPU [13B] oobabooga" -batFile "start-webui-vicuna-cpu-13B.bat"
        Deploy-Shortcut -name "Vicuna CPU [7B] oobabooga" -batFile "start-webui-vicuna-cpu-7B.bat"
    }
}

# 7. Run the webui
if ($gpu -eq "No") {
    Start-Process ".\start-webui-vicuna.bat"
} else {
    # Ask user if they want to launch the CPU or GPU version
    Write-Host "`n`nAll set up. Which model should I launch?" -ForegroundColor Cyan
    Write-Host -NoNewline "- CPU version: " -ForegroundColor Red
    Write-Host "1" -ForegroundColor Green
    Write-Host -NoNewline "- GPU version: " -ForegroundColor Red
    Write-Host "2" -ForegroundColor Green
    Write-Host -NoNewline "- Exit: " -ForegroundColor Red
    Write-Host "3" -ForegroundColor Green
    
    do {
        $choice = Read-Host "Enter a number"
    } while ($choice -notin "1", "2", "3")
    
    if ($choice -eq "1") {
        if ($global:gpuModel -eq "1") {
            Start-Process ".\start-webui-vicuna-cpu-13B.bat"
        } elseif ($global:gpuModel -eq "2") {
            Start-Process ".\start-webui-vicuna-cpu-7B.bat"
        } elseif ($global:gpuModel -eq "3") {
            Write-Host "`n`nWhich model version?" -ForegroundColor Cyan
                
            do {
                $choice2 = Read-Host "1 (13B-CPU) or 2 (7B-CPU)"
            } while ($choice2 -notin "1", "2")

            if ($choice2 -eq "1") {
                Start-Process ".\start-webui-vicuna-cpu-13B.bat"
            } else {
                Start-Process ".\start-webui-vicuna-cpu-7B.bat"
            }
        }
    }
    elseif ($choice -eq "2") {
        if ($global:gpuModel -eq "1") {
            Start-Process ".\start-webui-vicuna-gpu-13B.bat"
        } elseif ($global:gpuModel -eq "2") {
            Start-Process ".\start-webui-vicuna-gpu-7B.bat"
        } elseif ($global:gpuModel -eq "3") {
            Write-Host "`n`nWhich model version?" -ForegroundColor Cyan

            do {
                $choice2 = Read-Host "1 (13B-GPU) or 2 (7B-GPU)"
            } while ($choice2 -notin "1", "2")
            
            if ($choice2 -eq "1") {
                Start-Process ".\start-webui-vicuna-gpu-13B.bat"
            } else {
                Start-Process ".\start-webui-vicuna-gpu-7B.bat"
            }
        }
    }
    else {
        Write-Host "Invalid choice. Please enter 1 or 2."
    }
}
