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
# This script checks if BuildTools is installed or not, and installs it if nessecary.
# ----------------------------------------


function Test-BuildToolsInstalled {
    param (
        [string]$FolderPath,
        [int]$minVersion = 2015
    )

    if ($minVersion -ge 2022 -and (Test-Path -Path "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC#" -or Test-Path -Path "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC#")) {
        return $true
    }

    if ($minVersion -ge 2019 -and (Test-Path -Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC#" -or Test-Path -Path "C:\Program Files\Microsoft Visual Studio\2019\BuildTools\VC#")) {
        return $true
    }

    if ($minVersion -ge 2017 -and (Test-Path -Path "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC" -or Test-Path -Path "C:\Program Files\Microsoft Visual Studio\2017\BuildTools\VC")) {
        return $true
    }

    if ($minVersion -ge 2015 -and (Test-Path -Path "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC" -or Test-Path -Path "C:\Program Files\Microsoft Visual Studio\2017\BuildTools\VC")) {
        return $true
    }

    return $false
}

function Install-BuildTools {
    if (Test-BuildToolsInstalled) {
        Write-Host "Microsoft BuildTools is already installed."
    } else {
        # Install Chocolatey if not already installed
        if (!Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
            Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        
        choco install visualstudio2022buildtools --package-parameters "--add Microsoft.VisualStudio.Workload.MSBuildTools;includeRecommended --add Microsoft.VisualStudio.Workload.VCTools;includeRecommended --quiet" -y
        
        if (Test-BuildToolsInstalled) {
            Write-Host "Microsoft BuildTools was succesfully installed."
        } else {
            Write-Host "Microsoft BuildTools was not installed..." -ForegroundColor Red
            Write-Host "Please manually install BuildTools. Guide: https://hub.tcno.co/software/vs/buildtools/"
        }
    
    }
}

Install-BuildTools