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
# 1. Install Chocolatey
# 2. Installs Process Monitor from SysInternals (Microsoft), WinMerge, RegistryChangesView, Sublime Text, HxD
# 3. Windows settings tweaks (Show hidden files & Extensions)
# 4. Associate .json files with Sublime Text
# ----------------------------------------

Write-Host "---------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's TcNo Account Switcher Sandbox installer!" -ForegroundColor Cyan
Write-Host "This installs all the tools I usually use for adding new platforms." -ForegroundColor Cyan
Write-Host "I usually run this in Windows Sandbox to set up a clean, quiet environment." -ForegroundColor Cyan
Write-Host "[Version 2024-05-26]" -ForegroundColor Cyan
Write-Host "`nThis script is provided AS-IS without warranty of any kind. See https://tc.ht/privacy & https://tc.ht/terms."
Write-Host "Consider supporting these install scripts: https://tc.ht/support" -ForegroundColor Green
Write-Host "---------------------------------------------------------------------------`n`n" -ForegroundColor Cyan

Set-Variable ProgressPreference SilentlyContinue # Remove annoying yellow progress bars when doing Invoke-WebRequest for this session

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
    Read-Host
}

# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")
Set-Variable ProgressPreference SilentlyContinue # Remove annoying yellow progress bars when doing Invoke-WebRequest for this session

# 1. Install Chocolatey
Clear-ConsoleScreen
Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install files.
Clear-ConsoleScreen
Write-Host "Installing:" -ForegroundColor Cyan
Write-Host "- Process Monitor from SysInternals (Microsoft)..." -ForegroundColor Cyan
Write-Host "- WinMerge..." -ForegroundColor Cyan
Write-Host "- RegistryChangesView..." -ForegroundColor Cyan
Write-Host "- Sublime Text..." -ForegroundColor Cyan
Write-Host "- HxD (Hex Editor)..." -ForegroundColor Cyan
choco install procmon winmerge registrychangesview sublimetext3 hxd -y

Write-Host "Creating shortcuts..."

function CreateShortcut {
    param (
        [string]$title,
        [string]$targetPath
    )
    $desktop = [System.Environment]::GetFolderPath('Desktop')
    $wshShell = New-Object -ComObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut("$desktop\$title.lnk")
    $shortcut.TargetPath = $targetPath
    $shortcut.Save()
}

"C:\ProgramData\chocolatey\lib\registrychangesview\tools"

CreateShortcut "Process Monitor" "C:\ProgramData\chocolatey\lib\procmon\tools\Procmon64.exe"
CreateShortcut "WinMerge" "C:\Program Files\WinMerge\WinMergeU.exe"
CreateShortcut "RegistryChangesView" "C:\ProgramData\chocolatey\lib\registrychangesview\tools\RegistryChangesView.exe"
CreateShortcut "Sublime Text" "C:\Program Files\Sublime Text 3\sublime_text.exe"
CreateShortcut "HxD" "C:\Program Files\HxD\HxD.exe"


# 3. Windows settings tweaks (Show hidden files & Extensions)
Write-Host "Showing Hidden Files & File Extensions"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
Stop-Process -Name explorer -Force
Start-Process explorer.exe


# 4. Associate .json files with Sublime Text
Write-Host "Linking .JSON with Sublime Text"
$sublimePath = "C:\Program Files\Sublime Text 3\sublime_text.exe"

$extension = ".json"
$command = "`"$sublimePath`" `"%1`""

New-Item -Path "HKCU:\Software\Classes\$extension" -Force
Set-ItemProperty -Path "HKCU:\Software\Classes\$extension" -Name "(Default)" -Value "SublimeText.json"

New-Item -Path "HKCU:\Software\Classes\SublimeText.json\shell\open\command" -Force
Set-ItemProperty -Path "HKCU:\Software\Classes\SublimeText.json\shell\open\command" -Name "(Default)" -Value $command

$iconPath = "$sublimePath,0"
New-Item -Path "HKCU:\Software\Classes\SublimeText.json\DefaultIcon" -Force
Set-ItemProperty -Path "HKCU:\Software\Classes\SublimeText.json\DefaultIcon" -Name "(Default)" -Value $iconPath

& "C:\Windows\System32\cmd.exe" /c "assoc $extension=SublimeText.json"
& "C:\Windows\System32\cmd.exe" /c "ftype SublimeText.json=$command"
