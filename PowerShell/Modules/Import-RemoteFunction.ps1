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

<#
.SYNOPSIS
Imports a remote PowerShell function from a script URI.

.DESCRIPTION
The Import-RemoteFunction function downloads a PowerShell script from a specified URI and imports a function defined in the script into the current PowerShell session.

.PARAMETERS
-ScriptUri
Specifies the URI of the script that defines the function to import.

.EXAMPLE
PS C:\> Import-RemoteFunction -ScriptUri https://example.com/MyFunction.ps1

This command imports the function defined in the MyFunction.ps1 script from the example.com website.

.NOTES
This function requires an active internet connection and sufficient permissions to download and execute scripts from remote sources.
#>
function Import-RemoteFunction ($ScriptUri) {
    $functionName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptUri)
    if (-not (Get-Command $functionName -ErrorAction SilentlyContinue)) {
        $tempModulePath = Join-Path ([System.IO.Path]::GetTempPath()) ($functionName + ".psm1")
        Invoke-WebRequest -Uri $ScriptUri -OutFile $tempModulePath
        $originalExecutionPolicy = Get-ExecutionPolicy -Scope Process
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
        Import-Module $tempModulePath
        Set-ExecutionPolicy -ExecutionPolicy $originalExecutionPolicy -Scope Process -Force
    }
}

<#
.SYNOPSIS
Checks if a PowerShell command exists, and imports a remote function if the command does not exist.

.DESCRIPTION
The Import-FunctionIfNotExists function checks if a PowerShell command exists, and runs the Import-RemoteFunction function if the command does not exist. This function is useful for importing remote functions only if they are not already defined in the current PowerShell session.

.PARAMETERS
-Command <string>
The name of the PowerShell command to check.

-ScriptUri <string>
The URI of the script that defines the function to import.

.EXAMPLE
Import-FunctionIfNotExists -Command "Get-FileFromWeb" -ScriptUri "https://gist.githubusercontent.com/ChrisStro/37444dd012f79592080bd46223e27adc/raw/5ba566bd030b89358ba5295c04b8ef1062ddd0ce/Get-FileFromWeb.ps1"

This example checks if the Get-FileFromWeb function exists, and runs the Import-RemoteFunction function to import the function if it does not exist.
#>
function Import-FunctionIfNotExists {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Command,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptUri
    )

    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        Import-RemoteFunction -ScriptUri $ScriptUri
    }
}
