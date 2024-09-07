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
# This script:
# 1. Sets generateResolvConf = false in wsl.conf
# 2. Restarts WSL
# 3. Sets the resolv.conf to known DNS servers
# ----------------------------------------

Write-Host "---------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's DNS Fixer tool for WSL!" -ForegroundColor Cyan
Write-Host "This script:" -ForegroundColor Cyan
Write-Host "- Sets generateResolvConf = false in wsl.conf" -ForegroundColor Cyan
Write-Host "- Sets the resolv.conf to known DNS servers" -ForegroundColor Cyan
Write-Host "[Version 2024-09-07]" -ForegroundColor Cyan
Write-Host "`nThis script is provided AS-IS without warranty of any kind. See https://tc.ht/privacy & https://tc.ht/terms."
Write-Host "Consider supporting these install scripts: https://tc.ht/support" -ForegroundColor Green
Write-Host "---------------------------------------------------------------------------`n`n" -ForegroundColor Cyan

# Ask the user if they want to continue
do {
    $continue = Read-Host "This script will modify your WSL configuration. Do you want to continue? (Y/N)"
} while ($continue -notin "Y", "y", "N", "n", "")

if ($continue -notin "Y", "y" ) {
    Write-Host "Exiting script..."
    Exit
}


iex (irm Import-RemoteFunction.tc.ht)
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")
Import-FunctionIfNotExists -Command Get-FileFromWeb -ScriptUri "WSL-Tools.tc.ht"

$selectedDistro = Select-OSDistribution

Write-Host "`n`nSetting WSL.conf to not generate resolv.conf..." -ForegroundColor Cyan
Write-Host "This will replace all text within /etc/wsl.conf. Last settings backup: /etc/wsl.conf.bak"
Invoke-WSLCommand -distroName $selectedDistro -command "sudo touch /etc/wsl.conf &&  sudo cp /etc/wsl.conf /etc/wsl.conf.bak && echo -e `"[network]\ngenerateResolvConf = false`" | sudo tee /etc/wsl.conf"

Write-Host "`n`nRestarting WSL..." -ForegroundColor Cyan
wsl --shutdown

Write-Host "`n`nSetting known DNS servers..." -ForegroundColor Cyan
Write-Host "This will replace all text within /etc/resolv.conf. Last settings backup: /etc/resolv.conf.bak"
Invoke-WSLCommand -distroName $selectedDistro -command "sudo touch /etc/resolv.conf && sudo cp /etc/resolv.conf /etc/resolv.conf.bak && echo -e `"nameserver 8.8.8.8\nnameserver 1.1.1.1`" | sudo tee /etc/resolv.conf"
