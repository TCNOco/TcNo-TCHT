# Copyright (C) 2024 TroubleChute (Wesley Pyburn)
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
# This script will clear a ton of known cache/temp folders on Windows
# A lot of these can be cleared without issue, but some require user
# input as they may contain things like logins and more.
# ----------------------------------------

Write-Host "---------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's Cache & Temp Cleanup Tool!" -ForegroundColor Cyan
Write-Host "This script:" -ForegroundColor Cyan
Write-Host "- Automatically clear known Cache sources" -ForegroundColor Cyan
Write-Host "- Prompt you when deleting more important Cache/Temp folders" -ForegroundColor Cyan
Write-Host "[Version 2024-09-08]" -ForegroundColor Cyan
Write-Host "`nThis script is provided AS-IS without warranty of any kind. See https://tc.ht/privacy & https://tc.ht/terms."
Write-Host "Consider supporting these install scripts: https://tc.ht/support" -ForegroundColor Green
Write-Host "---------------------------------------------------------------------------`n" -ForegroundColor Cyan

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but not all temp/cache folders can be cleared properly. Press Enter to continue..." -ForegroundColor Red
    Read-Host
}

Write-Host "NOTE: " -ForegroundColor Cyan -NoNewline
Write-Host "When options include one capital letter, eg: (Y/n), the capital letter is the default option." -ForegroundColor Yellow
Write-Host "Hitting Enter with nothing typed for (Y/n) will choose Yes. (y/N) will choose No.`n" -ForegroundColor Yellow

$startTime = Get-Date
Write-Host "Start Time: $startTime" -ForegroundColor Cyan
Write-Host "Getting free space..." -ForegroundColor Cyan

iex (irm Import-RemoteFunction.tc.ht)
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")
Import-FunctionIfNotExists -Command Get-FreeSpace -ScriptUri "File-Actions.tc.ht"

$startingFreeSpace = Get-FreeSpace  
Write-Host  "Free space before cleanup: $startingFreeSpace`n" -ForegroundColor Cyan

function Confirm-Cleanup {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Folders,
        [string]$Text,
        [bool]$DefaultYes = $true
    )

    Write-Host "Clear $Text? Locations include:"
    foreach ($folder in $Folders) {
        $expandedFolder = [Environment]::ExpandEnvironmentVariables($folder)
        Write-Host "- $expandedFolder"
    }
    
    if ($(Confirm-Text -DefaultYes $DefaultYes)) {
        Remove-Folders -Folders $Folders
    }
}

function Confirm-Text {
    param (
        [bool]$DefaultYes = $true
    )

    do {
        $continue = Read-Host "Continue? (Y/n)"
    } while ($continue -notin "Y", "y", "1", "0", "N", "n", "")
    
    if ($DefaultYes) {
        if ($continue -in "Y", "y", "" ) {
            return $true
        } else {
            Write-Host "Skippping."
            return $false
        }
    } else {
        if ($continue -in "Y", "y" ) {
            return $true
        } else {
            Write-Host "Skippping."
            return $false
        }
    }
}


$Folders = @("C:\Windows\Temp", "C:\Temp", "C:\tmp", "C:\Windows\Prefetch", "$env:LocalAppData\Temp");
Confirm-Cleanup -Text "known common temp/cache" -Folders $Folders


Write-Host "`nClear Windows Update cache?"
    
if ($(Confirm-Text -DefaultYes $true)) {
    $WUServ = Get-Service wuauserv
    
    if ($WUServ.Status -eq "Running") {
        Write-Host "Stopping Windows Update..." -ForegroundColor Cyan
        $WUServ | Stop-Service -Force
    }

    Write-Host "Cleaning Windows Update Cache..." -ForegroundColor Cyan
    $Folders = @("$env:windir\SoftwareDistribution\Download");
    Remove-Folders -Folders $Folders
}


$endTime = Get-Date
Write-Host "End Time: $endTime" -ForegroundColor Cyan
$duration = $endTime - $startTime
Write-Host "Duration: $($duration.TotalSeconds) seconds" -ForegroundColor Cyan
Write-Host  "Free space before cleanup: $startingFreeSpace" -ForegroundColor Cyan
Write-Host  "Free space after cleanup: $(Get-FreeSpace)`n" -ForegroundColor Cyan