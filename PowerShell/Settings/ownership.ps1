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
# This script enables or disabled the "Take Ownership" option in the right-click menu.
# ----------------------------------------


Write-Host "---------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's `"Take Ownership`" setup!" -ForegroundColor Cyan
Write-Host "This allows you to add/remove the option from your context menu easily." -ForegroundColor Cyan
Write-Host "[Version 2023-09-21]" -ForegroundColor Cyan
Write-Host "`nThis script is provided AS-IS without warranty of any kind. See https://tc.ht/privacy & https://tc.ht/terms."
Write-Host "Consider supporting these install scripts: https://tc.ht/support" -ForegroundColor Green
Write-Host "---------------------------------------------------------------------------`n`n" -ForegroundColor Cyan

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
    Read-Host
}

# Why a function for this? Well, Set-ItemProperty when -Path has a * in it... Breaks. Nothing happens. This is annoying.
function Set-RegistryValue {
    param(
        [string]$KeyPath,
        [string]$ValueName,
        [string]$ValueData
    )

    # Open the registry key
    $key = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($KeyPath, $true)

    # Set the value
    $key.SetValue($ValueName, $ValueData)

    # Close the key when you're done
    $key.Close()
}

function Install-TakeOwnership {
    try {
        # Create or modify the keys for files
        New-Item -Path "HKLM:\Software\Classes\*\shell\runas" -Force | Out-Null
        Set-RegistryValue -KeyPath "*\shell\runas" -ValueName "" -ValueData "Take Ownership"
        Set-RegistryValue -KeyPath "*\shell\runas" -ValueName "NoWorkingDirectory" -ValueData ""

        New-Item -Path "HKLM:\Software\Classes\*\shell\runas\command" -Force | Out-Null
        Set-RegistryValue -KeyPath "*\shell\runas\command" -ValueName "" -ValueData 'cmd.exe /c takeown /f "%1" && icacls "%1" /grant administrators:F'
        Set-RegistryValue -KeyPath "*\shell\runas\command" -ValueName "IsolatedCommand" -ValueData 'cmd.exe /c takeown /f "%1" && icacls "%1" /grant administrators:F'

        # Create or modify the keys for directories
        New-Item -Path "HKLM:\Software\Classes\Directory\shell\runas" -Force | Out-Null
        Set-RegistryValue -KeyPath "Directory\shell\runas" -ValueName "" -ValueData "Take Ownership"
        Set-RegistryValue -KeyPath "Directory\shell\runas" -ValueName "NoWorkingDirectory" -ValueData ""

        New-Item -Path "HKLM:\Software\Classes\Directory\shell\runas\command" -Force | Out-Null
        Set-RegistryValue -KeyPath "Directory\shell\runas\command" -ValueName "" -ValueData 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant administrators:F /t'
        Set-RegistryValue -KeyPath "Directory\shell\runas\command" -ValueName "IsolatedCommand" -ValueData 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant administrators:F /t'
    }
    catch {
        Write-Error "Failed to install Take Ownership: $_"
    }
}

# The same here
function Remove-RegistryKey {
    param(
        [string]$KeyPath
    )

    # Open the parent registry key
    $parentKeyPath = Split-Path -Path $KeyPath
    $keyName = Split-Path -Path $KeyPath -Leaf
    $parentKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($parentKeyPath, $true)

    # Remove the key
    if ($parentKey -ne $null) {
        $parentKey.DeleteSubKeyTree($keyName, $false)
    } else {
        Write-Error "Key not found: $KeyPath"
    }

    # Close the key when you're done
    $parentKey.Close()
}


function Uninstall-TakeOwnership {
    try {
        # Remove the keys for files
        Remove-RegistryKey -KeyPath "Software\Classes\*\shell\runas"

        # Remove the keys for directories
        Remove-RegistryKey -KeyPath "Software\Classes\Directory\shell\runas"
    }
    catch {
        Write-Error "Failed to remove Take Ownership: $_"
    }
}

# Prompt the user for action
Write-Host -ForegroundColor Cyan 'Choose an action for "Take Ownership", type a number and hit Enter'
Write-Host -NoNewline '- Install: ' -ForegroundColor Red
Write-Host "1" -ForegroundColor Green
Write-Host -NoNewline '- Remove: ' -ForegroundColor Red
Write-Host "2" -ForegroundColor Green

do {
    $num = Read-Host "Enter a number"
} while ($num -notin "1", "2")

if ($num -eq "1") {
    Install-TakeOwnership
    Write-Host -ForegroundColor Cyan "The 'Take Ownership' context menu option has been installed."
} elseif ($num -eq "2") {
    Uninstall-TakeOwnership
    Write-Host -ForegroundColor Cyan "The 'Take Ownership' context menu option has been removed."
} else {
    Write-Host -ForegroundColor Red "Invalid action. Please enter 'install' or 'remove'."
}

Write-Host -NoNewline "`nPress any key to exit..."
Read-Host
exit