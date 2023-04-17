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
# Lets user pick an install path for software
# Creates folder, and adds to PATH if not already.
# ----------------------------------------

<#
.Synopsis
Creates folders to later install a program to a specified path and adds the installation path to the user or system PATH environment variable.

.Description
The Install-ProgramPath function allows users to choose between installing a program for their user only or for all users, and creates a directory for the program at the specified location. The function then checks if the installation path is already present in the user or system PATH environment variable, and adds it to the appropriate PATH variable if necessary. The function returns the path to the directory where the program will be installed.

.Parameter ProgramName
Specifies the name of the program to be installed.

.Example
Install-ProgramPath -ProgramName "Whisper"
Prompts the user to choose between installing the Whisper program for their user only or for all users, creates a directory for Whisper at the specified location, and adds the installation path to the appropriate PATH environment variable.
This does not actually install anything, just lets you use the returned path/Whisper, as well as add Whisper to returned path/programs where it can be used from PATH.
#> 
function Install-ProgramPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProgramName
    )

    # Ask user where to install
    do {
        Write-Host -ForegroundColor Cyan "`nWhere do you want $ProgramName installed?`n1. Install for me only ($($env:USERPROFILE)\TCHT\$ProgramName)`n2. Install for all users (C:\TCHT\$ProgramName)"
        $choice = Read-Host "Answer (1/2)"
        switch ($choice) {
            "1" {
                $envPath = Join-Path $env:USERPROFILE "TCHT"
                $savePath = Join-Path $env:USERPROFILE "TCHT\$ProgramName"
                $pathType = "User"
                break
            }
            "2" {
                $envPath = "C:\TCHT\"
                $savePath = Join-Path $envPath "$ProgramName"
                $pathType = "System"
                break
            }
            default {
                Write-Host "Invalid choice. Please choose 1 or 2."
            }
        }
    } while ($choice -notin "1", "2")

    $envPathPrograms = Join-Path $envPath "_Programs"

    # Create folder
    if (-not (Test-Path $savePath)) {
        New-Item -ItemType Directory -Path $savePath | Out-Null
        Write-Host "Created directory $savePath."
    } else {
        Write-Host "Directory $savePath already exists."
    }
    if (-not (Test-Path $envPathPrograms)) {
        New-Item -ItemType Directory -Path $envPathPrograms | Out-Null
    }

    # Check if the installation path is already in the PATH
    if ($pathType -eq "User") {
        $path = [Environment]::GetEnvironmentVariable("PATH", "User")
    } else {
        $path = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    }

    if ($path -notlike "*$envPathPrograms*") {
        # Add the installation path to the PATH
        if ($pathType -eq "User") {
            $newPath = $path + ";$envPathPrograms"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        } else {
            $newPath = $path + ";$envPathPrograms"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        }
        Write-Host "The installation path has been added to the $pathType PATH."
    } else {
        Write-Host "The installation path is already in the $pathType PATH."
    }

    $filePath = Join-Path $env:USERPROFILE "TCHT/_Programs/_README.txt"
    $content = "This folder contains .exes from Python venvs (virtual environments) in the parent folder.`r`n`r`nPlease do not delete anything here, or in the parent folder. Instead use the following to uninstall properly:`r`niex (irm uninstall.tc.ht)"

    New-Item -ItemType File -Path $filePath -Force | Out-Null
    Set-Content -Path $filePath -Value $content


    $filePath = Join-Path $env:USERPROFILE "TCHT/_README.txt"
    $content = "This folder containsPython venvs (virtual environments) and programs 'installed' with TroubleChute's scripts in the _Programs folder.`r`n`r`nPlease do not delete anything here. Instead use the following to uninstall properly:`r`niex (irm uninstall.tc.ht)`n`n`nThe script will let you choose a program, then delete the linked exe, the actual venv files as well as unregister the venv from Python."

    New-Item -ItemType File -Path $filePath -Force | Out-Null
    Set-Content -Path $filePath -Value $content

    return $envPath
}