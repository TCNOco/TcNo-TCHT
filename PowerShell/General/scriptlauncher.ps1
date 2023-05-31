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
# This is a rather advanced little launcher.
# It runs the program, as requested, but it also handles Python errors, assuming a module is not found (didn't install properly) it tries again.
# NOTE: This can't automatically re-run the one-line installer command as that usually requires admin.
# ----------------------------------------

Write-Host "-----------------------------------------" -ForegroundColor Cyan
Write-Host "TroubleChute %PROGRAMNAME% One-Line Launcher" -ForegroundColor Cyan
Write-Host "https://tc.ht/ & YouTube.com/TroubleChute" -ForegroundColor Cyan
Write-Host "-----------------------------------------" -ForegroundColor Cyan

Write-Host "Launching %PROGRAMNAME%..." -ForegroundColor Cyan

Set-Location %INSTALLLOCATION%

# Try run the program
%RUNCOMMAND%

Write-Host "`n--------------------------------" -ForegroundColor Cyan
Write-Host "TroubleChute One-Line installer:" -ForegroundColor Cyan
Write-Host "--------------------------------" -ForegroundColor Cyan
if ($LASTEXITCODE -eq 1){
    Write-Host "Python exited with an error code." -ForegroundColor Red
    do {
        Write-Host -ForegroundColor Cyan -NoNewline "Did you see something about 'ModuleNotFound above'? (y/n): "
        $reinstall = Read-Host
    } while ($reinstall -notin "Y", "y", "N", "n")

    if ($reinstall -in "Y", "y") {
        Write-Host "Reinstalling required packages..." -ForegroundColor Cyan
        
        %REINSTALLCOMMAND%

        Write-Host "`nTrying to launch again!`nAssuming you get another ModuleNotFound error consider running the one-line installer again or contacting the software's developer.`n--------------------------------`n" -ForegroundColor Cyan

        %RUNCOMMAND%
    } else {
        Write-Host "Exiting..." -ForegroundColor Cyan
    }
}