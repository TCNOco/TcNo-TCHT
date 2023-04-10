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
# Use this function to open an elevated Powershell window (if not already elevated) and run a script.
# Call as `Invoke-Elevated {echo "test"}`, for example.
# ----------------------------------------

<#
.Synopsis
   Executes a script block with elevated privileges.

.Description
   The Invoke-Elevated function runs the provided script block with administrative privileges. If the current session does not have administrative privileges, it starts a new elevated PowerShell session, executes the script block, and waits for the elevated session to close before continuing with the original script.

.Parameter Script
   The script block to be executed with elevated privileges.

.Parameter Arguments
   An optional array of arguments to pass to the script block.

.Example
   Invoke-Elevated { param($dir) Remove-Item -Path $dir -Recurse -Force } -Arguments "C:\ProtectedFolder"

   This example removes a protected folder by invoking the Remove-Item cmdlet with elevated privileges.
#>
function Invoke-Elevated([ScriptBlock]$Script, $Arguments) {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        $tempFile = [System.IO.Path]::GetTempFileName()
        $encodedScript = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Script.ToString()))
        $psPath = (Get-Command powershell.exe).Source
        $argumentsList = @("-NoExit", "-Command &{cd '$(Get-Location)'; [ScriptBlock]::Create([Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('$encodedScript'))).Invoke($Arguments); Remove-Item -Path '$tempFile'; Exit}")
        Start-Process -FilePath $psPath -Verb RunAs -ArgumentList $argumentsList

        Write-Host "New PowerShell window opened with Admin privileges. After completing tasks in the Admin window, close it to continue with the original script." -ForegroundColor Yellow
        Write-Host "Waiting for elevated session to close..." -ForegroundColor Yellow

        while (Test-Path -Path $tempFile) {
            Start-Sleep -Seconds 1
        }

        Write-Host "Elevated session closed. Continuing script execution..." -ForegroundColor Yellow
    } else {
        $Script.Invoke($Arguments)
    }
}