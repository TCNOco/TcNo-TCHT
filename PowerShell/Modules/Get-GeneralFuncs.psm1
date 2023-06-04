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
# This module has commonly used good little snippets for use in my code projects.
# ----------------------------------------

<#
.SYNOPSIS
Clears the console screen and moves the cursor to the top-left corner.

.DESCRIPTION
The Clear-ConsoleScreen function clears the screen and positions the cursor at the top-left corner of the console window. It utilizes an ANSI escape sequence to achieve this effect.
#>
function Clear-ConsoleScreen {
    [CmdletBinding()]
    param()

    Write-Host "" # Add an extra newline
    $e = [char]27; Write-Host "$e[2J$e[H" -NoNewline
}

function New-LauncherWithErrorHandling {
    param(
        [Parameter(Mandatory=$true)] [string]$ProgramName,
        [Parameter(Mandatory=$true)] [string]$InstallLocation,
        [Parameter(Mandatory=$true)] [string]$RunCommand,
        [Parameter(Mandatory=$true)] [string]$ReinstallCommand,
        [Parameter()] [string]$CondaPath,
        [Parameter()] [string]$CondaEnvironmentName,
        [Parameter()] [string]$LauncherName = "Launcher"
    )
    Set-Variable ProgressPreference SilentlyContinue # Remove annoying yellow progress bars when doing Invoke-WebRequest for this session

    if ($CondaPath) {
        Invoke-WebRequest -Uri "https://scriptlauncher-conda.tc.ht/" -OutFile "$LauncherName.ps1"
    } else {
        Invoke-WebRequest -Uri "https://scriptlauncher.tc.ht/" -OutFile "$LauncherName.ps1"
    }

    $content = Get-Content "$LauncherName.ps1"
    $content = $content -replace '%PROGRAMNAME%', $ProgramName -replace '%INSTALLLOCATION%', $InstallLocation -replace '%RUNCOMMAND%', $RunCommand -replace '%REINSTALLCOMMAND%', $ReinstallCommand
    if ($CondaPath) {
        $content = $content -replace '%CONDAPATH%', $CondaPath
    }
    if ($CondaEnvironmentName) {
        $content = $content -replace '%CONDAENVIRONMENTNAME%', $CondaEnvironmentName
    }
    
    $content | Set-Content "$LauncherName.ps1"

    # Create bat launcher for those who like batch files (or don't know what ps1 files are)
    Set-Content -Path "$LauncherName.bat" -Value "@echo off`npowershell -ExecutionPolicy ByPass -NoExit -File `"$LauncherName.ps1`""
}

<#
.SYNOPSIS
Calculates the size of a folder in MB or GB

.OUTPUTS
Returns the size of the folder in MB or GB as a string
#>
function Get-FolderSize {
    param(
        [Parameter(Mandatory=$true)] [string]$Path
    )

    $Foldersize = Get-ChildItem $Path -recurse | Measure-Object -property length -sum
    $outputSize = [math]::Round(($FolderSize.sum / 1MB),2)
    if ("$outputSize".Length -gt 6) {
        $outputSize = [math]::Round(($FolderSize.sum / 1GB),2)
    }

    return "$outputSize MB"
}

<#
.SYNOPSIS
Tries to sync a git repository. If the folder already exists, it will pull the latest updates. If the folder does not exist, it will clone the repository.
If the repo fails to pull, but the folder exists, it renames it and recreates the repo. This way even if there are files in the folder it will clone the repo anyway.
#>
function Sync-GitRepo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectFolder,
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,
        [Parameter(Mandatory = $true)]
        [bool]$IsSymlink,
        [Parameter(Mandatory = $true)]
        [string]$GitUrl
    )

    $renameTo = "$ProjectFolder.old"
    if ((Test-Path -Path $ProjectFolder) -and -not $IsSymlink) {
        Write-Host "The folder already exists. We'll pull the latest updates (git pull)" -ForegroundColor Green
        Set-Location $ProjectFolder
    
        git pull
        if ($LASTEXITCODE -eq 128) {
            Write-Host "Could not find existing git repository. Renaming folder to $renameTo and cloning $ProjectName...`n`n"
            Set-Location "$TCHT\"
    
            # Delete folder if exists
            if (Test-Path $renameTo) {
                Do {
                    if (!(Remove-Item -Path $renameTo -Recurse -Force)) {
                        Write-Host "Failed to delete folder $renameTo (there may be a process using the folder)." -ForegroundColor Yellow
                        Write-Host "Press any key to try again..."
                        Read-Host
                    }
                }
                Until (!(Test-Path $renameTo))
            }
    
            # Wait for folder rename
            Do {
                if (!(Rename-Item -Path "$ProjectFolder" -NewName $renameTo)) {
                    Write-Host "Failed to rename folder. Please try do it manually (there may be a process using the folder)." -ForegroundColor Yellow
                    Write-Host "Move '$ProjectFolder' to '$renameTo'." -ForegroundColor Yellow
                    Write-Host "Press any key to try again..."
                    Read-Host
                }
            }
            Until (Test-Path $renameTo)
    
            if (!(Test-Path -Path $ProjectFolder)) {
                New-Item -ItemType Directory -Path $ProjectFolder | Out-Null
            }
    
            Set-Location "$ProjectFolder"
    
            git clone $GitUrl .
        }
    } else {
        Write-Host "Cloning $ProjectName...`n`n"
        
        if (!(Test-Path -Path $ProjectFolder)) {
            New-Item -ItemType Directory -Path $ProjectFolder | Out-Null
        }
    
        Set-Location $ProjectFolder
    
        git clone $GitUrl .
    }
}