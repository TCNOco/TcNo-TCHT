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
# It runs the program, as requested, but also checks to see if Conda is set up properly.
# It also handles Python errors, assuming a module is not found (didn't install properly) it tries again.
# NOTE: This can't automatically re-run the one-line installer command as that usually requires admin.
# ----------------------------------------

Write-Host "-----------------------------------------" -ForegroundColor Cyan
Write-Host "TroubleChute %PROGRAMNAME% One-Line Launcher" -ForegroundColor Cyan
Write-Host "https://tc.ht/ & YouTube.com/TroubleChute" -ForegroundColor Cyan
Write-Host "-----------------------------------------" -ForegroundColor Cyan

Write-Host "Launching %PROGRAMNAME%..." -ForegroundColor Cyan

# Hardcoded path added by the one-line installer
$condaPath = %CONDAPATH%

# Check if Conda is still available
if (!(Test-Path -Path $condaPath -PathType Leaf)) {
    Write-Host "`nConda seems to have moved, or was uninstalled. Checking for a new location." -ForegroundColor Red
    Write-Host "Please note: If packages aren't installed, or the environment was deleted please run the one-line installer again." -ForegroundColor Yellow

    # Try and find updated Conda path
    iex (irm Get-CondaPath.tc.ht)
    $condaPath = Get-CondaPath

    if (!(Test-Path -Path $condaPath -PathType Leaf)) {
        Write-Host "`n`nThis likely means that the Conda environment was removed. Please run the one-line installer again."
        Write-Host "Conda does not seem to be installed. Please consider running the one-line installer again." -ForegroundColor Red
        Read-Host "`nPress any key to exit..."
        exit
    } else {
        Write-Host "`nNew conda found at ($condaPath). Activating and attempting to launch..." -ForegroundColor Yellow
    }
}

# Activate Conda
& $condaPath

# Try activating the conda environment, and throwing an error if failed.
try {
    conda activate %CONDAENVIRONMENTNAME%

    Set-Location %INSTALLLOCATION%
}
catch {
    if ($_.Exception -is [System.Management.Automation.RuntimeException] -and $_.CategoryInfo.Reason -eq "ParameterBindingValidationException") {
        Write-Host "Error: $($Error[0].Exception.Message)"
        Write-Host "This likely means that the Conda environment was removed. Please run the one-line installer again." -ForegroundColor Cyan
        Read-Host "`nPress any key to exit..."
        exit
    } else {
        Write-Host "Error: $($Error[0].Exception.Message)"
        Write-Host "An unknown error occured, please check the above error and should you not know a fix:" -ForegroundColor Cyan
        Write-Host "- Consider running the one-line installer again" -ForegroundColor Cyan
        Write-Host "- If it's an issue with the program, consider contating the program's developer through GitHub Issues, with a detailed error report" -ForegroundColor Cyan
        Write-Host "- If you are SURE this issue has to do with the install process, and not the program, consider opening an issue on the TCHT GitHub: https://github.com/TCNOco/TcNo-TCHT/issues" -ForegroundColor Cyan
        Read-Host "`nPress any key to exit..."
        exit
    }
}

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