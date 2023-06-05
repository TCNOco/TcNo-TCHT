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

    if ($minVersion -ge 2022 -and (Test-Path -Path "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC#") -or (Test-Path -Path "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC#")) {
        return $true
    }

    if ($minVersion -ge 2019 -and (Test-Path -Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC#") -or (Test-Path -Path "C:\Program Files\Microsoft Visual Studio\2019\BuildTools\VC#")) {
        return $true
    }

    if ($minVersion -ge 2017 -and (Test-Path -Path "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC") -or (Test-Path -Path "C:\Program Files\Microsoft Visual Studio\2017\BuildTools\VC")) {
        return $true
    }

    if ($minVersion -ge 2015 -and (Test-Path -Path "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC") -or (Test-Path -Path "C:\Program Files\Microsoft Visual Studio\2017\BuildTools\VC")) {
        return $true
    }

    return $false
}

function Install-BuildTools {
    if (Test-Path -Path "C:\Program Files (x86)\Microsoft Visual Studio\Installer") {
        Write-Host "The Visual Studio Installer is already available on your system." -ForegroundColor Red
        Write-Host "The automated installer for BuildTools is unable to continue." -ForegroundColor Yellow
        Write-Host "`nPlease manually install BuildTools. Guide: https://hub.tcno.co/software/vs/buildtools/" -ForegroundColor Cyan
        Write-Host "Open the VS Installer > Select Modify > Choose Desktop development with C++ > Install" -ForegroundColor Cyan
        Write-Host "`nWhen you have installed Desktop development with C++`nPress enter to continue, or type 1 and enter to install anyway"
        $response = Read-Host
        if ($response -eq "1") {
            Write-Host "Continuing with installation..."
        } else {
            return
        }
    }
    
    if (Test-BuildToolsInstalled) {
        Write-Host "Microsoft BuildTools is already installed."
    } else {
        # Install Chocolatey if not already installed
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
            Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }

        Write-Host "`n`nThe process may get stuck on `"Installing visualstudio2022buildtools...`" while downloading and installing. Please do wait for it to complete..." -ForegroundColor Cyan
        choco install visualstudio2022buildtools --package-parameters "--add Microsoft.VisualStudio.Workload.MSBuildTools;includeRecommended --add Microsoft.VisualStudio.Workload.VCTools;includeRecommended" -y | Write-Host
        
        if (Test-BuildToolsInstalled) {
            Write-Host "Microsoft BuildTools was succesfully installed."
        } else {
            Write-Host "Microsoft BuildTools was not installed..." -ForegroundColor Red
            Write-Host "Please manually install BuildTools. Guide: https://hub.tcno.co/software/vs/buildtools/" -ForegroundColor Cyan
        }
    
    }
}

Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's BuildTools installer!" -ForegroundColor Cyan
Write-Host "Chocolatey [package manager] and BuildTools will now be installed..." -ForegroundColor Cyan
Write-Host "[Version 2023-06-03]" -ForegroundColor Cyan
Write-Host "`nConsider supporting these install scripts: https://tc.ht/support" -ForegroundColor Cyan
Write-Host "--------------------------------------------`n`n" -ForegroundColor Cyan

Install-BuildTools