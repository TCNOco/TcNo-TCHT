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
# This script has lots of useful commands for file/directory actions
# ----------------------------------------

function Show-Animation {
    param (
        [string]$Text = "Deleting files",
        [int]$Duration = 3000
    )
    $spinner = @("|", "/", "-", "\")
    $endTime = (Get-Date).AddMilliseconds($Duration)
    while ((Get-Date) -lt $endTime) {
        foreach ($frame in $spinner) {
            if ((Get-Date) -ge $endTime) { break }
            $host.ui.Write("$Text $frame`r")
            Start-Sleep -Milliseconds 200
        }
    }
    $host.ui.Write("Deleting files...`r")
}

<#
.SYNOPSIS
    Recursively deletes a folder and its contents.

.DESCRIPTION
    This function deletes a folder and all its contents, including subdirectories and files, recursively.
    It includes an option to ignore any errors encountered during the deletion process.

.PARAMETER Path
    The full path of the folder to delete.

.PARAMETER IgnoreErrors
    If set to $true, the function will ignore any errors encountered during deletion.
    Defaults to $true.

.EXAMPLE
    Remove-FolderRecursive -Path "C:\Temp\FolderToDelete"

    This will delete the folder "C:\Temp\FolderToDelete" and all its contents.

.EXAMPLE
    Remove-FolderRecursive -Path "C:\Temp\FolderToDelete" -IgnoreErrors $true

    This will delete the folder "C:\Temp\FolderToDelete", ignoring any errors encountered during deletion.
#>

function Remove-FolderRecursive {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [bool]$IgnoreErrors = $true,
        [bool]$DryRun =  $false
    )

    try {
        if (Test-Path $Path) {
            # Start the animation in the background
            $animationJob = Start-Job -ScriptBlock { Show-Animation }

            try {
                Get-ChildItem -Path $Path -Recurse -Force -ErrorAction Stop | ForEach-Object {
                    try {
                        if (-not $DryRun) {
                            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
                        }
                        Write-Host "Deleted: $($_.FullName)"
                    } catch {
                        if ($IgnoreErrors) {
                            # Commented out to reduce time overhead
                            # Write-Warning "An error occurred while deleting '$($_.FullName)', but it was ignored: $_"
                            continue
                        } else {
                            throw $_
                        }
                    }
                }
            } catch {
                if ($IgnoreErrors) {
                    # Commented out to reduce time overhead
                    # Write-Warning "An error occurred while accessing items in '$Path', but it was ignored: $_"
                    continue
                } else {
                    throw $_
                }
            } finally {
                # Stop the animation
                Stop-Job -Job $animationJob | Out-Null
                Remove-Job -Job $animationJob
                Write-Host "Deleting files... Done.`r"
            }

            try {
                if (-not $DryRun) {
                    Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
                }
                Write-Host "Folder '$Path' deleted successfully."
            } catch {
                if ($IgnoreErrors) {
                    # Commented out to reduce time overhead
                    # Write-Warning "An error occurred while deleting the root folder '$Path', but it was ignored: $_"
                    continue
                } else {
                    throw $_
                }
            }
        } else {
            Write-Host "Folder '$Path' does not exist."
        }
    } catch {
        if ($IgnoreErrors) {
            Write-Warning "An error occurred, but it was ignored: $_"
        } else {
            throw $_
        }
    }
}




<#
.SYNOPSIS
    Uses Remove-FolderRecursive on an array of folders.

.PARAMETER Folders
    Array of folder strings. Can include environment variables.

.PARAMETER IgnoreErrors
    If set to $true, the function will ignore any errors encountered during deletion.
    Defaults to $true.

#>
function Remove-Folders {
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$Folders = $null,
        [bool]$IgnoreErrors = $true,
        [bool]$DryRun =  $false
    )

    if (-not $Folders -or -not ($Folders -is [array])) {
        Write-Host "No valid folders provided. Exiting."
        return
    }

    foreach ($folder in $Folders) {
        $expandedFolder = [Environment]::ExpandEnvironmentVariables($folder)
        Write-Host "Processing folder: $expandedFolder"
        
        Remove-FolderRecursive -Path $expandedFolder -IgnoreErrors $IgnoreErrors -DryRun $DryRun
    }
}

<#
.SYNOPSIS
    Returns string of free space on the system drive (Default C:\) in GB.
#>
function Get-FreeSpace {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    $drive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($os.SystemDrive)'" | Select @{Name="FreeGB";Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}
    return "$($drive.FreeGB) GB"
}

<#
.SYNOPSIS
    Returns string of the size of the requested $Folders array in GB.
    
.PARAMETER Folders
    Array of folder strings. Can include environment variables.

#>

function Get-FolderSizeInGB {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Folders
    )
    
    $animationJob = Start-Job -ScriptBlock { Show-Animation -Text "Calculating size" }

    function Measure-Size {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Path
        )

        $totalSize = 0
        
        if (Test-Path $Path) {
            try {
                $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction Stop
                foreach ($file in $files) {
                    $totalSize += $file.Length
                }
            } catch {
                Write-Warning "Error calculating size for '$Path': $_"
            }
        } else {
            Write-Warning "Path does not exist: $Path"
        }

        Stop-Job -Job $animationJob | Out-Null
        Remove-Job -Job $animationJob
        
        return $totalSize
    }

    $totalBytes = 0
    
    foreach ($folder in $Folders) {
        $expandedFolder = [Environment]::ExpandEnvironmentVariables($folder)
        $folderSize = Measure-Size -Path $expandedFolder
        $totalBytes += $folderSize
    }

    $totalGB = [math]::Round($totalBytes / 1GB, 2) # Convert bytes to GB and round to 2 decimal places
    return "$totalGB GB"
}