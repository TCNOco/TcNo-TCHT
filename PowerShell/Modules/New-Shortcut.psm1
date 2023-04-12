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
# This function helps create a shortcut for the provided target, with a workingpath and shortcutname.
# ----------------------------------------

<#
.Synopsis
   Creates a desktop shortcut for a given target with optional customizations.

.Description
   The New-Shortcut function creates a desktop shortcut for the specified target with options for customizing the working directory, arguments, and icon. It takes two mandatory parameters - ShortcutName and TargetPath - and three optional parameters - WorkingDirectory, Arguments, and IconLocation.

.Parameter ShortcutName
   The name of the shortcut file to be created on the desktop, without the ".lnk" extension.

.Parameter TargetPath
   The path to the target file or application.

.Parameter WorkingDirectory
   The working directory for the target application when the shortcut is launched. If not specified, the function will set it to the same directory as the target file or application.

.Parameter Arguments
   Optional command-line arguments to pass to the target application when the shortcut is launched.

.Parameter IconLocation
   The optional path to the icon file to be used for the shortcut. The format should be "path, iconIndex", where "path" is the path to the file containing the icon, and "iconIndex" is the zero-based index of the icon in the file.

.Example
   New-Shortcut -ShortcutName "MyApp" -TargetPath "C:\Program Files\MyApp\MyApp.exe" -Arguments "/config C:\configs\myconfig.conf" -IconLocation "C:\Program Files\MyApp\MyApp.ico, 0"

   This example creates a desktop shortcut named "MyApp" that targets the "MyApp.exe" application, passes a command-line argument for a config file, and uses a custom icon.
#>
function New-Shortcut {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ShortcutName,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $false)]
        [string]$Arguments,

        [Parameter(Mandatory = $false)]
        [string]$IconLocation
    )

    # Set the working directory to the target path location if not provided
    if (-not $WorkingDirectory) {
        $WorkingDirectory = (Get-Item -Path (Resolve-Path $TargetPath)).Directory.FullName
    }

    # Create the desktop shortcut
    $shortcutPath = Join-Path -Path ([Environment]::GetFolderPath("Desktop")) -ChildPath "$ShortcutName.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    if ($Arguments) { $shortcut.Arguments = $Arguments }
    if ($IconLocation) {
      $fullIcoPath = (Resolve-Path -Path $IconLocation).Path
      $shortcut.IconLocation = $fullIcoPath
   }
    $shortcut.TargetPath = (Resolve-Path $TargetPath).Path
    $shortcut.WorkingDirectory = (Resolve-Path $WorkingDirectory).Path
    $shortcut.Save()
}
