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
# A nifty little script to install aria2c using Chocolatey
# Functions provided here also make it easy to download a file or list of files using aria2c
# Assuming Chocolatey doesn't have access to install aria2c, this script runs download-aria2.tc.ht, which downloads the aria2c zip and extracts the exe for use.
# ----------------------------------------

<#
.SYNOPSIS
Initialize the Aria2 download utility.

.DESCRIPTION
The Initialize-Aria2 function installs Chocolatey and Aria2c if not already installed and the script is running with administrator privileges. If Aria2c is not installed globally and not found in the current directory, it downloads and extracts it.

.EXAMPLE
Initialize-Aria2

.NOTES
This function will attempt to download and extract the Aria2 binary if it is not installed globally or found in the current directory.
#>
function Initialize-Aria2 {
    # If is currently admin: Install choco and aria2
    if (-not ($triedAria2Install) -and ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -and ($null -eq (Get-Command aria2c -ErrorAction SilentlyContinue))) {
        $triedAria2Install = $True

        # 1. Install Chocolatey
        Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        # 2. Install aria2
        Write-Host "`nInstalling aria2c (Faster model download)..." -ForegroundColor Cyan
        choco upgrade aria2 -y | Write-Host

        if (-not (Get-Command Update-SessionEnvironment -ErrorAction SilentlyContinue)) {
            # Import function to reload without needing to re-open Powershell
            iex (irm refreshenv.tc.ht)
        }
        Update-SessionEnvironment
    }

    # If aria2 not installed globally (from choco or other) and ./aria2c.exe does not exist: Download and extract to current directory
    if (-not ($triedAria2Extract) -and ($null -eq (Get-Command aria2c -ErrorAction SilentlyContinue)) -and ($null -eq (Get-Command ./aria2c -ErrorAction SilentlyContinue))) {
        $triedAria2Extract = $True

        # Download aria2 binary for faster downloads, if not already installed.
        iex (irm download-aria2.tc.ht)
    }

    # If file exists, save full path for use in other folders too
    if (Test-Path "$((Get-Location).Path)\aria2c.exe") {
        $global:aria2Path = (Get-Location).Path + '\aria2c.exe'
    }

    # If not either, then use another download function
    if (-not ($importedOtherDownloadFunc) -and ($null -eq (Get-Command aria2c -ErrorAction SilentlyContinue)) -and ($null -eq (Get-Command $global:aria2Path -ErrorAction SilentlyContinue))) {
        $importedOtherDownloadFunc = $true
        # Import download command if not already available
        Import-FunctionIfNotExists -Command Get-FileFromWeb -ScriptUri "https://tc.ht/PowerShell/Modules/Get-FileFromWeb.psm1"
    }
}

<#
.SYNOPSIS
Downloads a file using Aria2 or a fallback method.

.DESCRIPTION
The Get-Aria2File function uses Aria2c or a fallback method to download a file from the specified URL to the specified output path.

.PARAMETER

Url: The URL of the file to download.
OutputPath: The path where the downloaded file will be saved.

.EXAMPLE
Get-Aria2File -Url "https://example.com/file.txt" -OutputPath "C:\Downloads\file.txt"

.NOTES
This function requires the Initialize-Aria2 function.
#>
function Get-Aria2File {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )

    # Import or install aria2c if not already
    Initialize-Aria2

    # Check if aria2c is available
    if (-not ($null -eq (Get-Command aria2c -ErrorAction SilentlyContinue))) {
        # Use aria2c to download the files
        aria2c --disable-ipv6 -x 8 -s 8 --continue --out="$OutputPath" "$Url" --console-log-level=error --download-result=hide
    } elseif (-not ($null -eq (Get-Command $aria2Path -ErrorAction SilentlyContinue))) {
        # Use aria2c to download the files
        & $aria2Path --disable-ipv6 -x 8 -s 8 --continue --out="$OutputPath" "$Url" --console-log-level=error --download-result=hide
    } else {
        # Import download command if not already available
        Import-FunctionIfNotExists -Command Get-FileFromWeb -ScriptUri "https://tc.ht/PowerShell/Modules/Get-FileFromWeb.psm1"
       
        # Use Get-FileFromWeb to download the files
        Get-FileFromWeb -URL $url -File $outputPath
    }
}

<#
.SYNOPSIS
Downloads multiple files using Aria2 or a fallback method.

.DESCRIPTION
The Get-Aria2Files function uses Aria2c or a fallback method to download multiple files from the specified base URL to the specified output path.

.PARAMETER

Url: The base URL for the files to download.
OutputPath: The path where the downloaded files will be saved.
Files: An array of file names to download from the base URL.

.EXAMPLE
$files = @("file1.txt", "file2.txt")
Get-Aria2Files -Url "https://example.com/" -OutputPath "C:\Downloads" -Files $files

.NOTES
This function requires the Initialize-Aria2 function.
#>
function Get-Aria2Files {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Files
    )

    # Import or install aria2c if not already
    Initialize-Aria2
    
    # Check if aria2c is available
    if (-not ($null -eq (Get-Command aria2c -ErrorAction SilentlyContinue))) {
        # Use aria2c to download the files
        $files | ForEach-Object {
            aria2c --disable-ipv6 -x 8 -s 8 --continue --out="$outputPath\$_" "$Url/$_" --console-log-level=error --download-result=hide
        }
    } elseif (-not ($null -eq (Get-Command $aria2Path -ErrorAction SilentlyContinue))) {
        # Use aria2c to download the files
        $files | ForEach-Object {
            & $aria2Path --disable-ipv6 -x 8 -s 8 --continue --out="$outputPath\$_" "$Url/$_" --console-log-level=error --download-result=hide
        }
    } else {
        # Import download command if not already available
        Import-FunctionIfNotExists -Command Get-FileFromWeb -ScriptUri "https://tc.ht/PowerShell/Modules/Get-FileFromWeb.psm1"

        # Use Get-FileFromWeb to download the files
        $files | ForEach-Object {
            Get-FileFromWeb -URL "$Url\$_" -File "$outputPath\$_"
        }
    }
}