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
# This function gets and/or sets the TCHT install path.
# ----------------------------------------

function Get-TCHTPathSaved() {
    $os = [System.Environment]::OSVersion.Platform.ToString()

    switch ($os) {
        "Win32NT" {
            $registryPath = "HKCU:\Software\TCHT"
            if (Test-Path $registryPath) {
                return (Get-ItemProperty $registryPath).Path
            } else {
                return ""
            }
            break
        }
        "Unix" {
            # If gsettings installed:
            if (command -v gsettings) {
                Write-Host "gsettings is installed"
                
                $gsettingsValue = $(gsettings get tc.ht path 2> $null)
                if ($LASTEXITCODE -eq 0) {
                    return $gsettingsValue.Trim("`"'")
                }
            }

            return ""
            break
        }
        default {
            throw "Unsupported operating system."
        }
    }
}


function Get-TCHTPathFromUser() {
    $os = [System.Environment]::OSVersion.Platform.ToString()

    switch ($os) {
        "Win32NT" {
            if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
                Read-Host
            }

            $path = "C:\TCHT"
            break
        }
        "Unix" {
            $uname = $(uname)
            if ($uname -eq "Darwin") {
                $path = Join-Path (Resolve-Path "~/Documents") "TCHT"
            } else {
                $path = "/home/TCHT"
            }
            break
        }
        default {
            throw "Unsupported operating system."
        }
    }


    # Ask the user where to install
    $installLocation = Read-Host @"
Pick where to install:
1. (default) $path
2. Current folder: $((Get-Location).Path)
or Enter a custom path
"@

    $firstLoop = $True
    if ($installLocation -in "1", "", " ") {
        $installLocation = $path
        if (!(Test-Path $installLocation -PathType Container)) {
            Write-Host "Folder created: $installLocation"
            New-Item -ItemType Directory -Path $installLocation | Out-Null
        }        
    }
    elseif ($installLocation -eq "2") {
        $installLocation = (Get-Location).Path
        if (!(Test-Path $installLocation -PathType Container)) {
            Write-Host "Folder created: $installLocation"
            New-Item -ItemType Directory -Path $installLocation | Out-Null
        }
    }
    # Else, a custom path entered. Check the path exists and prompt about spaces.
    do {
        if (-not $firstLoop) {
            $installLocation = Read-Host "Please enter a custom path"
            $firstLoop = $False
        } else {
            if (!(Test-Path $installLocation -PathType Container)) {
                $createFolder = Read-Host "The folder $installLocation does not exist. Do you want to create it? (Y/N)"
                if ($createFolder -eq "Y" -or $createFolder -eq "y") {
                    Write-Host "Folder created: $installLocation"
                    New-Item -ItemType Directory -Path $installLocation | Out-Null
                }
            }            
        }
        if ($installLocation.Contains(" ")) {
            $proceedAnyway = Read-Host "Using a path with a space can result in things not working properly. Enter another path or type Y to use the current path: $installPath"
        }
    } while ($installLocation.Contains(" ") -and $proceedAnyway -notin 'Y', 'y')

    Write-Host "Saving path..."
    Set-TCHTPath -Path $installLocation

    Write-Host "Installing this, and future TC.HT programs to: $installLocation"
    return $installLocation
}


function Install-GSettings {
    $os = [System.Environment]::OSVersion.Platform.ToString()

    switch ($os) {
        "Win32NT" {
            Write-Host "You only need GSettings on Mac or Linux."
            return
        }
        "Unix" {
            if (which apt-get) {
                # Ubuntu, Debian, Raspbian, Kali, etc.
                apt-get update
                apt-get install -y gsettings-ubuntu-schemas
                if (command -v gsettings) { return }
            }
            if (which dnf) {
                # Fedora, RedHat, CentOS, etc.
                dnf install -y gsettings-desktop-schemas
                if (command -v gsettings) { return }
            }
            if (which yum) {
                # CentOS, RedHat, etc.
                yum install -y gsettings-desktop-schemas
                if (command -v gsettings) { return }
            }
            if (which apk) {
                # Alpine, etc.
                apk update
                apk add glib-dev
                apk add gsettings-desktop-schemas
                if (command -v gsettings) { return }
            }
            if (which pacman) {
                # Pacman
                pacman -S glib2
                if (command -v gsettings) { return }
            }
            
            Write-Error "Could not find a package manager to install gsettings."
            break
        }
        default {
            throw "Unsupported operating system."
        }
    }
}


function Set-TCHTPath() {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    $os = [System.Environment]::OSVersion.Platform.ToString()

    switch ($os) {
        "Win32NT" {
            $registryPath = "HKCU:\Software\TCHT"
            if (Test-Path $registryPath) {
                Set-ItemProperty $registryPath -Name Path -Value $path
            } else {
                New-Item -Path $registryPath -Force | Out-Null
                New-ItemProperty -Path $registryPath -Name Path -Value $path -PropertyType String | Out-Null
            }
            break
        }
        "Unix" {
            if (command -v gsettings) {
                Write-Host "gsettings installed."
                if (!(command -v glib-compile-schemas)) {
                    Write-Host "glib not installed. Installing..."
                    brew install glib
                }

                # Install schema
                @"
<?xml version="1.0" encoding="UTF-8"?>
<schemalist>
  <schema id="tc.ht" path="/org/gnome/tc/ht/">
    <key name="path" type="s">
      <default>'/Users/mish/Documents/TCHT'</default>
      <summary>Path for TCHT</summary>
      <description>Path where TCHT files are located.</description>
    </key>
  </schema>
</schemalist>
"@ | Set-Content -Path ./tc.ht.gschema.xml
                
                $SchemaDir = "$HOME/.local/share/glib-2.0/schemas"
                if (-not (Test-Path -Path $SchemaDir)) {
                    New-Item -ItemType Directory -Path $SchemaDir -Force | Out-Null
                }

                glib-compile-schemas . --strict --targetdir=$HOME/.local/share/glib-2.0/schemas
                $Env:GSETTINGS_SCHEMA_DIR="$HOME/.local/share/glib-2.0/schemas"
                
                Write-Host "Saving gsettings path as /tc.ht/path, $path"
                gsettings set tc.ht path "/Users/mish/Documents/TCHT"
            } else {
                # If not gsettings installed:
                if (! $(command -v gsettings)) {
                    Write-Host "gsettings not installed. Installing..."
                    Install-GSettings
                }

                Write-Host "Saving gsettings path as /tc.ht/path, $path"
                # If gsettings installed:
                gsettings write "/tcht/path" "$path"
            }
            break
        }
        default {
            throw "Unsupported operating system."
        }
    }

}

# From: https://stackoverflow.com/a/818054
# Tests to see if path is a symlink
function Test-ReparsePoint([string]$path) {
    $file = Get-Item $path -Force -ea SilentlyContinue
    return [bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)
  }
  
function Get-TCHTPath() {
    param (
        [Parameter()]
        [string]$Subfolder = ""
    )
    $path = Get-TCHTPathSaved
    $returnValue = "$path"

    if ($path -eq "") {
        $path = Get-TCHTPathFromUser
    } else {
        # Ask the user if they want to install this software here, or in another location
        $clearScreenFound = Get-Command Clear-ConsoleScreen -erroraction silentlycontinue
        if (!$clearScreenFound) {
            iex (irm Import-RemoteFunction.tc.ht)
            Import-RemoteFunction("Get-GeneralFuncs.tc.ht")
        }

        Clear-ConsoleScreen
        if ($Subfolder -ne "") {
            Write-Host "$Subfolder will install to $path." -ForegroundColor Cyan
        } else {
            Write-Host "The program will install to $path." -ForegroundColor Cyan
        }
        do {
            Write-Host -ForegroundColor Cyan -NoNewline "`n`nDo you want to install it somewhere else? (y/n): "
            $installElsewhere = Read-Host
        } while ($installElsewhere -notin "Y", "y", "N", "n")
        
        if ($installElsewhere -in "Y", "y") {
            Clear-ConsoleScreen
            Write-Host "The install script choses a folder, and installs programs inside of it. This is what you're setting." -ForegroundColor Cyan
            Write-Host "The default is C:\TCHT"
            $chosenPath = ""
            do {
                Write-Host -ForegroundColor Cyan -NoNewline "`n`nEnter a path to install this (and possibly other programs) to: "
                $chosenPath = Read-Host
            } while ($chosenPath -eq "")

            # For some reason POWERSHELL LOVES CHANGING THE TYPE OF THIS TO AN OBJECT
            $returnValue = "$chosenPath"

            # If doesn't exist, create the path
            if (!(Test-Path -Path $chosenPath)) {
                New-Item -ItemType Directory -Path $chosenPath | Out-Null
            }

            # If $Subfolder is set
            if ($Subfolder -ne "") {
                $originalPath = Join-Path -Path $path -ChildPath $Subfolder
                $chosenPathSubfolder = Join-Path -Path $chosenPath -ChildPath $Subfolder
                
                # If the $originalPath exists:
                if (Test-Path -Path $originalPath) {
                    $existsAsSymlink = Test-ReparsePoint -path $originalPath

                    # If $existsAsSymlink: Expand symlink path to real path
                    if ($existsAsSymlink) {
                        $symlinkPath = $originalPath
                        $originalPath = (Get-Item $originalPath).Target

                        # Remove existing, now wrong, symlink:
                        Remove-Item -Path $symlinkPath | Out-Null
                    }

                    Write-Host "Moving existing files from $originalPath to $chosenPathSubfolder..." -ForegroundColor Yellow
                    Move-Item -Path $originalPath -Destination $chosenPath -Force
                }
            }

            do {
                Clear-ConsoleScreen
                Write-Host -ForegroundColor Cyan -NoNewline "Would you like to install all future TCHT programs to this path? ($chosenPath) (y/n): "
                $changeDefault = Read-Host
            } while ($changeDefault -notin "Y", "y", "N", "n")

            # Set default if chosen
            if ($changeDefault -in "Y", "y") {
                Write-Host "`nCalculating existing folder size..."
                $getTotalFolderSize = Get-Command Get-FolderSize -erroraction silentlycontinue
                if (!$getTotalFolderSize) {
                    iex (irm Import-RemoteFunction.tc.ht)
                    Import-RemoteFunction("Get-GeneralFuncs.tc.ht")
                }
                $existingFolderSize = Get-FolderSize -Path $path
                
                do {
                    Clear-ConsoleScreen
                    Write-Host -ForegroundColor Cyan -NoNewline "Do you want to move existing programs installed to ($path) to ($chosenPath)? Total size: $existingFolderSize (y/n): "
                    $moveExisting = Read-Host
                } while ($moveExisting -notin "Y", "y", "N", "n")
                
                if ($moveExisting -in "Y", "y") {
                    # Foreach folder in $path
                    # Move to $chosenPath
                    # Create symlink in $path to $chosenPath
                    ForEach-Object -InputObject (Get-ChildItem -Path $path -Directory) -Process {
                        $folderName = $_.Name
                        $folderPath = Join-Path -Path $path -ChildPath $folderName
                        $folderPathChosen = Join-Path -Path $chosenPath -ChildPath $folderName

                        # If $folderPathChosen exists
                        if (Test-Path -Path $folderPathChosen) {
                            do {
                                try {
                                    Remove-Item $folderPathChosen -Recurse -Force -ErrorAction Stop
                                }
                                catch {
                                    if ($_.Exception.Message.Contains("being used by another process")) {
                                        Write-Verbose "File locked, trying again in 5 seconds"
                                        Start-Sleep -Seconds 5
                                    }
                                    else {
                                        Write-Error $_.Exception.Message
                                        break
                                    }
                                }
                            } until (!(Test-Path -Path $folderPathChosen))
                        }

                        Write-Host "`nMoving $folderPath to $folderPathChosen..." -ForegroundColor Yellow
                        Move-Item -Path $folderPath -Destination $chosenPath -Force

                        Write-Host "Creating symlink from $folderPath to $folderPathChosen..." -ForegroundColor Yellow
                        New-Item -ItemType SymbolicLink -Path $folderPath -Target $folderPathChosen -Force | Out-Null
                    }

                    Write-Host "Done moving!" -ForegroundColor Green
                    Write-Host "The files have physically moved, but will still 'appear' to exist in the original path - This is so shortcuts still work." -ForegroundColor Cyan
                    Write-Host "Continuing in 5 seconds... Scroll up to continue reading!" -ForegroundColor Yellow
                    Start-Sleep -s 5
                } else {
                    # Else, just symlink all the existing folders in the new folder
                    # And copy any symlinks that may exist in the old folder, so no symlinks are symlinked.
                    ForEach-Object -InputObject (Get-ChildItem -Path $path -Directory) -Process {
                        $folderName = $_.Name
                        $folderPath = Join-Path -Path $path -ChildPath $folderName

                        $existsAsSymlink = Test-ReparsePoint -path $originalPath
                        # If $existsAsSymlink: Expand symlink path to real path
                        if ($existsAsSymlink) {
                            $folderPath = (Get-Item $folderPath).Target
                        }

                        $folderPathChosen = Join-Path -Path $chosenPath -ChildPath $folderName

                        Write-Host "`nCreating symlink from $folderPath to $folderPathChosen..." -ForegroundColor Yellow
                        New-Item -ItemType SymbolicLink -Path $folderPath -Target $folderPathChosen -Force | Out-Null
                    }
                }

                Set-TCHTPath -Path $chosenPath
            }

            return $returnValue
        } else {
            if ($Subfolder -ne ""){
                # Wants to install to default location, but may be moving everything back on update/reinstall
                # So, if it exists in another location (and is symlinked currently), move it and create a symlink in the old install path.
                $returnValue = "$path"
        
                $folderPath = Join-Path -Path $path -ChildPath $Subfolder
                $existsAsSymlink = Test-ReparsePoint -path $folderPath
                # If $existsAsSymlink: Expand symlink path to real path
                if ($existsAsSymlink) {    
                    $symlinkPath = $folderPath
                    $folderPath = (Get-Item $folderPath).Target
                    Remove-Item $symlinkPath -Recurse -Force | Out-Null
    
                    Write-Host "Moving existing files from $folderPath to $path..." -ForegroundColor Yellow
                    Move-Item -Path $folderPath -Destination $path -Force
        
                    Write-Host "`nCreating symlink from $folderPath to $symlinkPath..." -ForegroundColor Yellow
                    New-Item -ItemType SymbolicLink -Path $folderPath -Target $symlinkPath -Force | Out-Null
                }
            }
        }
    }

    # We'll create $TCHT if it doesn't already exist:
    if (!(Test-Path -Path $returnValue)) {
        New-Item -ItemType Directory -Path $returnValue | Out-Null
    }
    return $returnValue
}

<#
.SYNOPSIS
When a TCHT program is NOT being installed to the default path, then a symlink in the default path is created.
Returns whether is symlink or not.

.PARAMETER Path
Path to the new chosen install path (not including the program name)

.PARAMETER Subfolder
The programs name to be appended to Path
#>
function Sync-ProgramFolder() {
    param(
        [parameter(Mandatory=$true)][string]$ChosenPath,
        [parameter(Mandatory=$true)][string]$Subfolder
    )

    $clearScreenFound = Get-Command Clear-ConsoleScreen -erroraction silentlycontinue
    if (!$clearScreenFound) {
        iex (irm Import-RemoteFunction.tc.ht)
        Import-RemoteFunction("Get-GeneralFuncs.tc.ht")
    }

    $savedPath = Get-TCHTPathSaved

    if (!($ChosenPath -eq $savedPath)) {
        # User has chosen to install this in another directory
        $actualInstallPath = Join-Path -Path $ChosenPath -ChildPath $Subfolder
        $symlinkPath = Join-Path -Path $savedPath -ChildPath $Subfolder

        # If actualInstallPath doesn't exist, create it
        if (!(Test-Path -Path $actualInstallPath)) {
            New-Item -ItemType Directory -Path $actualInstallPath | Out-Null
        }

        # If savedPath doesn't exist, create it
        if (!(Test-Path -Path $savedPath)) {
            New-Item -ItemType Directory -Path $savedPath | Out-Null
        }

        # Create a symlink to the subfolder in savedPath
        New-Item -ItemType SymbolicLink -Path $symlinkPath -Target $actualInstallPath | Out-Null

        Clear-ConsoleScreen
        Write-Host "The installer has created a link between your default ($savedPath) and where it is actually installed ($actualInstallPath)" -ForegroundColor Cyan
        Write-Host "`n`nEven though the files appear to be on $symlinkPath, they take up no space, and are actually on $actualInstallPath"
        Write-Host "This is performed so shortcuts still work, easy management, etc."
        Write-Host "Interactions between the symlink (`"shortcut`") will appear in the actual location they are installed to. New files, changes, etc.`n`n"

        Write-Host "Continuing in 5 seconds... Scroll up to continue reading!" -ForegroundColor Yellow
        Start-Sleep -s 5
        return $true
    }

    return $false
}