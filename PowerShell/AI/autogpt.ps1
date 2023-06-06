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
# This script lets you install AutoGPT in an even faster, easier way.
# The installation is already super simple, but this is next-level.
# This script:
# 1. Install Chocolatey
# 2. Installs Git (for downloading and future updates)
# 3. Installs Python should Python not be installed and > 3.8, or Conda
# 4. Downloads and installs Auto-GPT
# 5. Get API keys from user
# 6. Create desktop shortcuts
# 7. Run Auto-GPT
# ----------------------------------------

Write-Host "---------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's Auto-GPT installer!" -ForegroundColor Cyan
Write-Host "Auto-GPT as well as all of its other dependencies and a model should now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-04-16]" -ForegroundColor Cyan
Write-Host "`nConsider supporting these install scripts: https://tc.ht/support" -ForegroundColor Cyan
Write-Host "---------------------------------------------`n`n" -ForegroundColor Cyan

Set-Variable ProgressPreference SilentlyContinue # Remove annoying yellow progress bars when doing Invoke-WebRequest for this session

Write-Host -NoNewline "Important: " -ForegroundColor Red
Write-Host "Using OpenAI's API costs money, as well as a lot of others. Remember to set usage limits!" -ForegroundColor Yellow

Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")

# 1. Install Chocolatey
Clear-ConsoleScreen
Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install or update Git if not already installed
Clear-ConsoleScreen
Write-Host "Installing Git..." -ForegroundColor Cyan
iex (irm install-git.tc.ht)

# Import function to reload without needing to re-open Powershell
iex (irm refreshenv.tc.ht)


# 3. Installs Python should Python not be installed and > 3.8, or Conda
Import-FunctionIfNotExists -Command Get-UseConda -ScriptUri "Get-Python.tc.ht"

# Check if Conda is installed
$condaFound = Get-UseConda -Name "Auto-GPT" -EnvName "autogpt" -PythonVersion "3.10.11"

# Get Python command (eg. python, python3) & Check for compatible version
if ($condaFound) {
    conda activate "autogpt"
    $python = "python"
} else {
    $python = Get-Python -PythonRegex 'Python (3.(8|9|10).\d*)' -PythonRegexExplanation "Python version is not between 3.8 and 3.10.11." -PythonInstallVersion "3.10.11" -ManualInstallGuide "https://github.com/Significant-Gravitas/Auto-GPT#-installation"
    if ($python -eq "miniconda") {
        $python = "python"
        $condaFound = $true
    }
}


# 4. Downloads and installs Auto-GPT
Clear-ConsoleScreen
Write-Host "Installing or updating Auto-GPT..." -ForegroundColor Cyan
git clone https://github.com/Torantulino/Auto-GPT.git -b stable
Set-Location Auto-GPT

if ($condaFound) {
    # For some reason conda NEEDS to be deactivated and reactivated to use pip reliably... Otherwise python and pip are not found.
    conda deactivate
    #Open-Conda
    conda activate autogpt
    pip install -r requirements.txt # Environment is already active
} else {
    &$python -m pip install -r requirements.txt
    Update-SessionEnvironment
}

# 5. Get API keys from user
Clear-ConsoleScreen
Write-Host "Let's get some information from you for this to work..." -ForegroundColor Cyan
Write-Host "Should you not fill this in here, copy .env.template to .env, and fill in the info there." -ForegroundColor Cyan
Write-Host "But, let's do this automatically:" -ForegroundColor Cyan

Write-Host "`nFor information on how to get your OpenAI Key, see this: https://github.com/Significant-Gravitas/Auto-GPT#openai-api-keys-configuration`n" -ForegroundColor Cyan

$openAIKey = Read-Host "Enter your OpenAI key"

(Get-Content -Path ".env.template") | ForEach-Object {
    $_ -replace
        'OPENAI_API_KEY=your-openai-api-key',
        "OPENAI_API_KEY=$openAIKey"
} | Set-Content -Path ".env"

# Enter ElevenLabs API key
Clear-ConsoleScreen
Write-Host "If you want TTS, grab yourself an ElevenLabs key, or enter nothing to skip this: https://elevenlabs.io/`n" -ForegroundColor Cyan

$elevenLabsKey = ""
$elevenLabsKey = Read-Host "Enter your ElevenLabs key"
$elabs1 = ""
$elabs2 = ""
if (-not [String]::IsNullOrEmpty($elevenLabsKey)) {
    Write-Host "As you're using ElevenLabs you can enter up to 2 ElevenLabs voice id's:" -ForegroundColor Cyan
    $elabs1 = Read-Host "Enter your ElevenLabs voice ID 1"
    $elabs2 = Read-Host "Enter your ElevenLabs voice ID 2"

    (Get-Content -Path ".env") | ForEach-Object {
        (($_ -replace
            'ELEVENLABS_API_KEY=your-elevenlabs-api-key',
            "ELEVENLABS_API_KEY=$elevenLabsKey") -replace
            'ELEVENLABS_VOICE_1_ID=your-voice-id-1',
            "ELEVENLABS_VOICE_1_ID=$elabs1") -replace
            'ELEVENLABS_VOICE_2_ID=your-voice-id-2',
            "ELEVENLABS_VOICE_2_ID=$elabs2"
    } | Set-Content -Path ".env"
} else {
    Write-Host "`nWould you like to use the Brian TTS instead? No key required." -ForegroundColor Cyan
    do {
        $brianTTS = Read-Host "Use Brian TTS? (y/n)"
    } while ($brianTTS -notin "Y", "y", "N", "n" -and (-not [String]::IsNullOrEmpty($createShortcut)))
    if ($brianTTS -in "Y", "y") {
        (Get-Content -Path ".env") | ForEach-Object {
            $_ -replace
                'USE_BRIAN_TTS=False',
                "USE_BRIAN_TTS=True"
        } | Set-Content -Path ".env"
    }
}

# Enter Pinecone API key
Clear-ConsoleScreen
Write-Host "Do you want to use Pinecone API for memory?" -ForegroundColor Cyan
Write-Host "Find information here: https://github.com/Significant-Gravitas/Auto-GPT#-pinecone-api-key-setup`n" -ForegroundColor Cyan

$pineconeApi = Read-Host "Enter Pinecone API key (You can leave this blank)"
if (-not [String]::IsNullOrEmpty($pineconeApi)) {
    $pineconeRegion = Read-Host "Enter Pinecone region (Example: us-west-2)"

    (Get-Content -Path ".env") | ForEach-Object {
        (($_ -replace
        'MEMORY_BACKEND=local',
        "MEMORY_BACKEND=pinecone") -replace
        'PINECONE_API_KEY=your-pinecone-api-key',
        "PINECONE_API_KEY=$pineconeApi") -replace
        'PINECONE_ENV=your-pinecone-region',
        "PINECONE_ENV=$pineconeRegion"
    } | Set-Content -Path ".env"
}

# Create empty auto-gpt.json file for memory should pinecone be removed later, or not entered in the first place.
# Otherwise users will see error.
$FilePath = "auto-gpt.json"
New-Item -Path $FilePath -ItemType File -Value "{}" | Out-Null

# Enter Google Search key
Clear-ConsoleScreen
Write-Host "Too many Google Searches could end up with error 429. You can get and enter a Google API key to get around this." -ForegroundColor Cyan
Write-Host "Remember to set API limits to prevent unexpected charges, as well." -ForegroundColor Cyan
Write-Host "Find information here: https://github.com/Significant-Gravitas/Auto-GPT#-google-api-keys-configuration`n" -ForegroundColor Cyan

$googleApi = Read-Host "Enter Google API key (You can leave this blank)"
if (-not [String]::IsNullOrEmpty($googleApi)) {
    (Get-Content -Path ".env") | ForEach-Object {
        $_ -replace
            'GOOGLE_API_KEY=your-google-api-key',
            "GOOGLE_API_KEY=$googleApi"
    } | Set-Content -Path ".env"
}

# Enter Hugging Face API key for Stable Diffusion
Clear-ConsoleScreen
Write-Host "By default Auto-GPT uses DALL-e from OpenAI for image generation." -ForegroundColor Cyan
Write-Host "`nDo you want to use Hugging Face for Stable Diffusion instead?" -ForegroundColor Cyan
Write-Host "Find information here: https://github.com/Significant-Gravitas/Auto-GPT#-image-generation`n" -ForegroundColor Cyan

$hfApi = Read-Host "Enter Hugging Face API key (You can leave this blank)"
if (-not [String]::IsNullOrEmpty($hfApi)) {
    (Get-Content -Path ".env") | ForEach-Object {
        ($_ -replace
        'IMAGE_PROVIDER=dalle',
        "IMAGE_PROVIDER=sd") -replace
        'HUGGINGFACE_API_TOKEN=your-huggingface-api-token',
        "HUGGINGFACE_API_TOKEN=$hfApi"
    } | Set-Content -Path ".env"
}

# 6. Create desktop shortcuts
$condaPath = Get-CondaPath
# %windir%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy ByPass -NoExit -Command "& 'C:\ProgramData\miniconda3\shell\condabin\conda-hook.ps1' ; conda activate 'C:\ProgramData\miniconda3' "

iex (irm Import-RemoteFunction.tc.ht)
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")

# 7. Create a desktop shortcut
# Create start bat and ps1 files
if ($condaFound) {
    # As the Windows Target path can only have 260 chars, we easily hit that limit...
    $condaPath = "`"$(Get-CondaPath)`""
    $CondaEnvironmentName = "autogpt"
    $InstallLocation = "`"$(Get-Location)`""
    $ReinstallCommand = "python -m pip install -r requirements.txt"

    $ProgramName = "Auto-GPT"
    $RunCommand = "python -m autogpt"
    $LauncherName = "start"
    
    New-LauncherWithErrorHandling -ProgramName $ProgramName -InstallLocation $InstallLocation -RunCommand $RunCommand -ReinstallCommand $ReinstallCommand -CondaPath $condaPath -CondaEnvironmentName $CondaEnvironmentName -LauncherName $LauncherName


} else {
    $InstallLocation = "`"$(Get-Location)`""
    $ReinstallCommand = "python -m pip install -r requirements.txt"

    $ProgramName = "Auto-GPT"
    $RunCommand = "python -m autogpt"
    $LauncherName = "start"

    New-LauncherWithErrorHandling -ProgramName $ProgramName -InstallLocation $InstallLocation -RunCommand $RunCommand -ReinstallCommand $ReinstallCommand -LauncherName $LauncherName
}

# Create shortcut
do {
    Write-Host "`n`n"
    $createShortcut = Read-Host "Do you want a desktop shortcut? (Y/N)"
} while ($createShortcut -notin "Y", "y", "N", "n")

if ($createShortcut -in "Y", "y") {
    # Create desktop shortcut
    Import-RemoteFunction -ScriptUri "New-Shortcut.tc.ht" # Import function to create a shortcut
    
    Write-Host "Downloading Auto-GPT icon (not official)..."
    Invoke-WebRequest -Uri 'https://tc.ht/PowerShell/AI/autogpt.ico' -OutFile 'autogpt.ico'

    Write-Host "`nCreating shortcuts on desktop..." -ForegroundColor Cyan
    $shortcutName = "Auto-GPT"
    $targetPath = "$(Get-Location)\start.bat"
    $IconLocation = 'autogpt.ico'
    New-Shortcut -ShortcutName $shortcutName -TargetPath $targetPath -IconLocation $IconLocation
}

Clear-ConsoleScreen
Write-Host "Starting Auto-GPT...`n" -ForegroundColor Cyan

# 7. Run Auto-GPT
$Host.UI.RawUI.WindowTitle = 'Auto-GPT'
python -m autogpt