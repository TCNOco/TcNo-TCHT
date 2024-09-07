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
# This function allows users to select a WSL distribution (if >1 installed) and run commands on it through PowerShell easily.
# ----------------------------------------


<#
.Synopsis
   Gets all installed WSL distributions and provides a number select for the user. Returns the distribution name string.
#>
function Select-OSDistribution {
    $distributions = wsl --list --quiet

    $distrosArray = $distributions -split "\r?\n"
    $distrosArray = $distrosArray | Where-Object { $_.Trim().Length -ge 3 }

    $selectedDistro = $null

    if ($distrosArray -is [string]) {
        $selectedDistro = $distrosArray.Trim()
    } elseif ($distrosArray -is [array]) {
        if ($distrosArray.Length -gt 1) {
            for ($i = 0; $i -lt $distrosArray.Length; $i++) {
                Write-Host "$($i + 1): '$($distrosArray[$i].Trim())'"
            }
        } elseif ($distrosArray.Length -eq 1) {
            Write-Host "1: '$($distrosArray[0].Trim())'"
        }
    }
    
    while (-not $selectedDistro) {
        $selection = Read-Host "Select the WSL distribution number"

        if ([int]::TryParse($selection, [ref]$selectionNumber) -and $selectionNumber -gt 0 -and $selectionNumber -le $distrosArray.Length) {
            $selectedDistro = $distrosArray[$selectionNumber - 1].Trim()
            $selectedDistro = $selectedDistro -replace "[`0]", ""
            Write-Host "Selected distribution: $selectedDistro"
        }
        else {
            Write-Host "Invalid selection. Please enter a number between 1 and $($distrosArray.Length)."
        }
    }

    $selectedDistro = $selectedDistro -replace "[`0]", ""  # Replace null characters that seem to appear between chars in the string.

    return $selectedDistro
}

<#
.Synopsis
   Runs commands in selected WSL distribution.

.Parameter distroName
   This is a required argument - The distribution where the WSL command will be run.

.Parameter command
   The command to be run undder WSL

.Example
   Invoke-WSLCommand -DistroName "Ubuntu-Preview" -Command "echo 'Hello!'"

   This should return "Hello!" from the WSL installation.
#>
function Invoke-WSLCommand {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DistroName,
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    if ($DistroName) {
        Write-Host "Running command in distribution: $DistroName`n"
        wsl -d $DistroName -- bash -c "$Command"
    }
    else {
        Write-Host -ForegroundColor Red "No WSL distribution selected. Please run the script again to select a distribution."
        throw "No WSL distribution selected. Please run the script again to select a distribution."
    }
}

<#
.Synopsis
   Shuts down a specific WSL distribution.

.Parameter distroName
   This is a required argument - The distribution where the WSL command will be run.

.Example
   Invoke-WSLCommand -DistroName "Ubuntu-Preview"
#>
function Stop-WSLDistribution {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DistroName
    )

    if ($DistroName) {
        Write-Host "Stopping: $DistroName`n"
        wsl -t $DistroName
    }
    else {
        Write-Host -ForegroundColor Red "No WSL distribution selected. Please run the script again to select a distribution."
        throw "No WSL distribution selected. Please run the script again to select a distribution."
    }
}