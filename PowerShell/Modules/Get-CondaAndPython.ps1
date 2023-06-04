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

<#
.SYNOPSIS
Get Python command (eg. python, python3) & Check for compatible version

.OUTPUTS
Python command "python", "python3", etc.
#>
function Get-Python {
    param (
        [string]$PythonRegex = 'Python ([3].[1][0-1].[6-9]|3.10.1[0-1])',
        [string]$PythonRegexExplanation = "Python version is not between 3.10.6 and 3.10.11.",
        [string]$PythonInstallVersion = "3.10.11",
        [string]$ManualInstallGuide = "https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs",
        [bool]$condaFound = $false
    )
    $python = "python"

    if (-not (Get-Command Update-SessionEnvironment -ErrorAction SilentlyContinue)) {
        iex (irm refreshenv.tc.ht)
    }

    if ($condaFound) {
        return $python
    }
    
    Update-SessionEnvironment
    
    # Try Python instead
    # Check if Python returns anything (is installed - also is 3.10.6 - 3.10.11)
    $tryInstall = $false
    Try {
        Write-Host "Checking if Python is installed. This could take a while if it's not..." -ForegroundColor Yellow

        if (Get-Command python -ErrorAction SilentlyContinue) {
            $pythonVersion = python --version 2>&1
            
            if ($pythonVersion -match "Python was not found;") {
                # Issue: This only works with Windows...
                $tryInstall = $true
            }
        } else {
            $tryInstall = $true
        }

    }
    Catch {
        $tryInstall = $true
    }

    if ($tryInstall){
        Write-Host "Python is not installed (according to Windows)." -ForegroundColor Yellow
        Write-Host "`nInstalling Python $PythonInstallVersion." -ForegroundColor Cyan
        choco install python --version=$PythonInstallVersion -y | Write-Host
        if ($LASTEXITCODE -eq 1) {
            Write-Host "Installed!" -ForegroundColor Cyan
            return "python"
        } else {
            Write-Host "Choco failed to install Python" -ForegroundColor Red
        }
        Update-SessionEnvironment
    }


    # Verify Python install
    Try {
        $pythonVersion = &$python --version 2>&1
        if ($pythonVersion -match $PythonRegex) {
            Write-Host "Python version $($matches[1]) is installed." -ForegroundColor Green
        }
        else {
            Write-Host "$PythonRegexExplanation`nAssuming you've installed the correct version, please enter the comand you use to access Python 3.9/3.10." -ForegroundColor Yellow
        
            $pythonProgramName = Read-Host "Enter the Python program name (e.g. python3, python310)"
            $pythonVersion = &$pythonProgramName --version 2>&1
            if ($pythonVersion -match $PythonRegex) {
                Write-Host "Python version $($matches[1]) is installed."
                $python = $pythonProgramName
            } else {
                Write-Host "$PythonRegexExplanation`nAlternatively, follow this guide for manual installation: $ManualInstallGuide" -ForegroundColor Red
                Read-Host "Process can try to continue, but will likely fail. Press Enter to continue..."
            }
        }
    }
    Catch {
        Write-Host "$PythonRegexExplanation`nAlternatively, follow this guide for manual installation: $ManualInstallGuide..." -ForegroundColor Red
        Read-Host "Process can try to continue, but will likely fail. Press Enter to continue..."
    }

    return $python
}




# ----------------------------------------
# These functions are useful for using conda commands in a system that you don't know where Conda is installed.
# Without running the Conda hook, you won't be able to use Conda commands - As long as it's not globally activated/available always.
# Usually you'll see (Conda) before the path in the command line, assuming it's already active.
# ----------------------------------------

<#
.SYNOPSIS
Get the Conda PowerShell hook script path.

.DESCRIPTION
The Get-CondaPath function searches for the Conda PowerShell hook script in the specified paths, considering both Anaconda and Miniconda installations, and returns the path if found.

.EXAMPLE
$condaPath = Get-CondaPath

.NOTES
This function currently checks the following locations for the Conda PowerShell hook script:

1. C:\ProgramData\anaconda3\shell\condabin\conda-hook.ps1
2. C:\ProgramData\miniconda3\shell\condabin\conda-hook.ps1
3. C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Anaconda3 (64-bit)\Anaconda Powershell Prompt.lnk
4. C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Anaconda3\Anaconda Powershell Prompt.lnk
5. C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Miniconda3 (64-bit)\Anaconda Powershell Prompt (miniconda3).lnk
6. C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Miniconda3\Anaconda Powershell Prompt (miniconda3).lnk
-- 1-2 are also checked in %USERPROFILE%
-- 3-6 are also checked in %AppData%\Microsoft\Windows\Start Menu\Programs
#>
function Get-CondaPath {
    # Define the file paths to check
    $filePaths1 = @(
        "C:\ProgramData\anaconda3\shell\condabin\conda-hook.ps1",
        "C:\ProgramData\miniconda3\shell\condabin\conda-hook.ps1",
        "$env:USERPROFILE\anaconda3\shell\condabin\conda-hook.ps1"
        "$env:USERPROFILE\miniconda3\shell\condabin\conda-hook.ps1"
    )

    $filePaths2 = @(
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Anaconda3 (64-bit)\Anaconda Powershell Prompt.lnk",
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Anaconda3\Anaconda Powershell Prompt.lnk",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Anaconda3 (64-bit)\Anaconda Powershell Prompt.lnk",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Anaconda3\Anaconda Powershell Prompt.lnk",
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Miniconda3 (64-bit)\Anaconda Powershell Prompt (miniconda3).lnk",
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Miniconda3\Anaconda Powershell Prompt (miniconda3).lnk"
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Miniconda3 (64-bit)\Anaconda Powershell Prompt (miniconda3).lnk",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Miniconda3\Anaconda Powershell Prompt (miniconda3).lnk"
    )

    # Check if any of the first set of file paths exist
    foreach ($filePath1 in $filePaths1) {
        if (Test-Path $filePath1) {
            return $filePath1
        }
    }

    # Check if any of the shortcut files exist in the start menu
    foreach ($filePath2 in $filePaths2) {
        if (Test-Path $filePath2) {
            # Read the target of the .lnk file
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($filePath2)
            $targetPath = $shortcut.Arguments

            # Extract the ps1 script path
            $regex = "'.+\.ps1'"
            if ($targetPath -match $regex) {
                $ps1ScriptPath = $Matches[0].Trim("'")

                # Return script path
                return $ps1ScriptPath
            }
        }
    }

    # If none of the file paths were found, return an empty string
    return ""
}

<#
.SYNOPSIS
Opens the Conda environment if found. Then returns true or false whether it was successfully hooked or not.

.DESCRIPTION
The Open-Conda function calls the Get-CondaPath function to retrieve the Conda PowerShell hook script path and executes the script if found.

.EXAMPLE
$condaReady = Open-Conda

.NOTES
This function requires the Get-CondaPath function.
#>
function Open-Conda {
    $condaPath = Get-CondaPath
    Write-Host $condaPath
    if ($condaPath) {
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; &$condaPath | Write-Host
        Write-Host "Conda found! Hooked."
        return $true
    }
    Else {
        Write-Host "Conda is not installed."
        return $false
    }
}


<#
.SYNOPSIS
Gets whether Conda is installed, and if it is whether the user wants to use it. Creates environment too.

.OUTPUTS
Whether to use Conda or not, to be checked and used later.
#>
function Get-UseConda {
    param (
        [string]$Name = "AUTOMATIC1111 Stable Diffusion WebUI",
        [string]$EnvName = "a11",
        [string]$PythonVersion = "3.10.6"
    )

    # Allow Conda to run properly
    Set-ExecutionPolicy Bypass -Scope Process -Force

    if (-not (Get-Command Update-SessionEnvironment -ErrorAction SilentlyContinue)) {
        iex (irm refreshenv.tc.ht)
    }

    $condaFound = [bool](Get-Command conda -ErrorAction SilentlyContinue)

    if (-not $condaFound) {
        # Try checking if conda is installed a little deeper... (May not always be activated for user)
        $condaFound = Open-Conda # This checks for Conda, returns true if conda is hoooked
        Update-SessionEnvironment
    }
    
    # If conda found: create environment
    Clear-ConsoleScreen
    if ($condaFound) {
        Write-Host "Do you want to install $Name in a Conda environment called '$EnvName'?`nYou'll need to use 'conda activate $EnvName' before being able to use it?" -ForegroundColor Cyan
    
        do {
            Write-Host -ForegroundColor Cyan -NoNewline "`n`nUse Conda (y/n): "
            $useConda = Read-Host
        } while ($useConda -notin "Y", "y", "N", "n")
        
        if ($useConda -eq "y" -or $useConda -eq "Y") {
            # Initialize conda: it creates the powershell profile script
            conda init powershell
            # Load the profile for current session: it activates (base) environment
            invoke-expression -Command "$env:userprofile\Documents\WindowsPowerShell\profile.ps1"

            conda create -n $EnvName python=$PythonVersion pip -y | Write-Host
            conda activate $EnvName | Write-Host
        } else {
            Write-Host "Checking for Python instead..."
            return $false
        }
    }

    return $condaFound
}