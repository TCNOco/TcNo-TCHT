# Copyright (C) 2026 TroubleChute (Wesley Pyburn)
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
# 1. Downloads PSExec to update
# 2. Runs the fixer script as System (higher than Admin) using PSExec
# 3. Undo changes possibly made by https://github.com/tsgrgo/windows-update-disabler
# 4. Undo changes possibly made by Privacy.sexy
# 5. Run the Chris Titus Tech Windows Update - Reset script from: https://github.com/ChrisTitusTech/winutil/blob/main/docs/content/dev/features/Fixes/Update.md
# ----------------------------------------

Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host "Welcome to TroubleChute's Windows Update fixer!" -ForegroundColor Cyan
Write-Host "[Version 2026-05-11]" -ForegroundColor Cyan
Write-Host "`nThis script is provided AS-IS without warranty of any kind. See https://tc.ht/privacy & https://tc.ht/terms."
Write-Host "Consider supporting these install scripts: https://tc.ht/support" -ForegroundColor Green
Write-Host "--------------------------------------------`n`n" -ForegroundColor Cyan

Set-Variable ProgressPreference SilentlyContinue # Remove annoying yellow progress bars when doing Invoke-WebRequest for this session

function Write-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ConsoleColor]$Color = [ConsoleColor]::Cyan
    )

    Write-Host "==> $Message" -ForegroundColor $Color
}

function Write-StepDetail {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host " -> $Message" -ForegroundColor DarkCyan
}

function Write-StepSuccess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[OK] $Message" -ForegroundColor Green
}

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as an administrator.`nProcess can try to continue, but will likely fail. Press Enter to continue..." -ForegroundColor Red
    Read-Host
}

iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
Import-RemoteFunction("Get-GeneralFuncs.tc.ht")

$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$isSystem = $currentIdentity.User.Value -eq 'S-1-5-18'
if (-not $isSystem) {
    Write-Host "This script will elevate to System to have more permissions."
    Write-Host "First it must download a copy of PsExec from Microsoft Sysinternals, then it will relaunch."
    # Set up install directory
    Import-FunctionIfNotExists -Command Get-TCHTPath -ScriptUri "Get-TCHTPath.tc.ht"
    $TCHT = Get-TCHTPath

    if (!(Test-Path -Path "$TCHT\PsExec")) {
        New-Item -ItemType Directory -Path "$TCHT\PsExec" | Out-Null
    }

    # Then CD into $TCHT\
    Set-Location "$TCHT\PsExec"

    Write-Step "Downloading the latest PsExec"
    Invoke-WebRequest -Uri "https://download.sysinternals.com/files/PSTools.zip" -OutFile "PSTools.zip"

    Write-Step "Extracting PsExec"
    Expand-Archive -Path "PSTools.zip" -DestinationPath ./ -Force
    Remove-Item -Path "PSTools.zip"

    $psExec = Join-Path "$TCHT\PsExec" "PsExec64.exe"
    if (-not (Test-Path $psExec)) {
        $psExec = Join-Path "$TCHT\PsExec" "PsExec.exe"
    }
    if (-not (Test-Path $psExec)) {
        throw "PsExec was not found after extraction."
    }
    Write-Step "Relaunching this script as NT AUTHORITY\SYSTEM" -Color Yellow
    Start-Process -FilePath $psExec -ArgumentList @(
        '-accepteula'
        '-i'
        '-s'
        'powershell.exe'
        '-NoProfile'
        '-ExecutionPolicy', 'Bypass'
        '-Command', "iex (irm 'https://fixupdates.tc.ht')"
    ) -Verb RunAs
    return
}
# This script should now be running as system.


# Configure services
Write-Step 'Restoring Windows Update service startup types'
Set-Service -Name 'wuauserv' -StartupType Automatic
Set-Service -Name 'UsoSvc' -StartupType Automatic
Write-StepDetail 'Configuring uhssvc for delayed automatic startup'
$uhsSvcConfig = Start-Process -FilePath 'sc.exe' -ArgumentList @('config', 'uhssvc', 'start=', 'delayed-auto') -NoNewWindow -Wait -PassThru
if ($uhsSvcConfig.ExitCode -ne 0) {
    Write-Warning "Unable to configure 'uhssvc' for delayed automatic startup."
}

# Restore renamed services (Happens with https://github.com/tsgrgo/windows-update-disabler)
Write-Step 'Restoring renamed Windows Update DLLs if needed'
$system32 = Join-Path $env:WINDIR 'System32'

foreach ($name in @('WaaSMedicSvc', 'wuaueng')) {
    $bakPath = Join-Path $system32 "${name}_BAK.dll"
    $dllPath = Join-Path $system32 "${name}.dll"

    if (Test-Path $bakPath) {
        Write-StepDetail "Restoring ${name}.dll"
        & takeown.exe /f $bakPath | Out-Null
        & icacls.exe $bakPath /grant '*S-1-1-0:F' | Out-Null

        Rename-Item -Path $bakPath -NewName "${name}.dll" -Force

        & icacls.exe $dllPath /setowner 'NT SERVICE\TrustedInstaller' | Out-Null
        & icacls.exe $dllPath /remove '*S-1-1-0' | Out-Null
    }
}

# Update registry
Write-Step 'Restoring Windows Update registry settings'
$waasMedicPsPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc'
$waasMedicNativePath = 'HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc'
$failureActionsHex = '840300000000000000000000030000001400000001000000c0d4010001000000e09304000000000000000000'
[byte[]]$failureActionsBytes = for ($i = 0; $i -lt $failureActionsHex.Length; $i += 2) {
    [Convert]::ToByte($failureActionsHex.Substring($i, 2), 16)
}

try {
    Set-ItemProperty -Path $waasMedicPsPath -Name Start -Type DWord -Value 3 -ErrorAction Stop
    New-ItemProperty `
        -Path $waasMedicPsPath `
        -Name 'FailureActions' `
        -PropertyType Binary `
        -Value $failureActionsBytes `
        -Force `
        -ErrorAction Stop | Out-Null
}
catch [System.Security.SecurityException] {
    Write-Warning "Direct access to 'WaaSMedicSvc' registry settings was blocked. Trying reg.exe fallback."

    $waasMedicStartResult = Start-Process -FilePath 'reg.exe' -ArgumentList @('add', $waasMedicNativePath, '/v', 'Start', '/t', 'REG_DWORD', '/d', '3', '/f') -NoNewWindow -Wait -PassThru
    $waasMedicFailureResult = Start-Process -FilePath 'reg.exe' -ArgumentList @('add', $waasMedicNativePath, '/v', 'FailureActions', '/t', 'REG_BINARY', '/d', $failureActionsHex, '/f') -NoNewWindow -Wait -PassThru

    if ($waasMedicStartResult.ExitCode -eq 0 -and $waasMedicFailureResult.ExitCode -eq 0) {
        Write-StepSuccess "Restored 'WaaSMedicSvc' registry settings via reg.exe"
    }
    else {
        Write-Warning "'WaaSMedicSvc' is protected on this system. Some registry settings could not be restored without TrustedInstaller-level access."
    }
}
catch {
    Write-Warning "Failed to restore 'WaaSMedicSvc' registry settings: $($_.Exception.Message)"
}

Remove-ItemProperty `
    -Path 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU' `
    -Name 'NoAutoUpdate' `
    -Force `
    -ErrorAction SilentlyContinue

# Enable all update-related scheduled tasks
Write-Step 'Re-enabling update-related scheduled tasks'
$taskPatterns = @(
    '\Microsoft\Windows\InstallService*'
    '\Microsoft\Windows\UpdateOrchestrator*'
    '\Microsoft\Windows\UpdateAssistant*'
    '\Microsoft\Windows\WaaSMedic*'
    '\Microsoft\Windows\WindowsUpdate*'
    '\Microsoft\WindowsUpdate*'
)

Get-ScheduledTask | Where-Object {
    $taskId = "$($_.TaskPath)$($_.TaskName)"
    foreach ($pattern in $taskPatterns) {
        if ($taskId -like $pattern) {
            return $true
        }
    }
    return $false
} | Enable-ScheduledTask -ErrorAction SilentlyContinue

# From Privacy.sexy:
# Undo: Disable peering download method for Windows Updates
Remove-ItemProperty `
    -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' `
    -Name 'DODownloadMode' `
    -Force `
    -ErrorAction SilentlyContinue
# ----------------------------------------------------------
# Undo: Disable "Delivery Optimization" service (breaks Microsoft Store downloads)
Write-Step 'Re-enabling the Delivery Optimization service'
$serviceQuery = 'DoSvc'
$defaultStartupMode = 'Automatic'
# 1. Skip if service does not exist
$service = Get-Service -Name $serviceQuery -ErrorAction SilentlyContinue
if (-not $service) {
    Write-Warning "Service query '$serviceQuery' did not yield any results. Skipping Delivery Optimization restore."
}
else {
    $serviceName = $service.Name
    Write-StepDetail "Restoring '$serviceName' to startup mode '$defaultStartupMode'"
    # 2. Skip if service info is not found in registry
    $registryKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$serviceName"
    if (-not (Test-Path $registryKey)) {
        Write-Warning "'$registryKey' was not found in registry. Skipping Delivery Optimization restore."
    }
    else {
        # 3. Restore startup mode if needed
        $defaultStartupRegValue = switch ($defaultStartupMode) {
            'Boot'      { 0 }
            'System'    { 1 }
            'Automatic' { 2 }
            'Manual'    { 3 }
            'Disabled'  { 4 }
            default {
                Write-Error "Unknown startup mode specified: '$defaultStartupMode'. Skipping Delivery Optimization restore."
                $null
            }
        }

        if ($null -ne $defaultStartupRegValue) {
            $currentStartValue = (Get-ItemProperty -Path $registryKey -ErrorAction Stop).Start
            if ($currentStartValue -eq $defaultStartupRegValue) {
                Write-StepDetail "'$serviceName' already has startup mode '$defaultStartupMode'"
            }
            else {
                try {
                    Set-ItemProperty -Path $registryKey -Name Start -Value $defaultStartupRegValue -Force
                    Write-StepSuccess "Restored '$serviceName' with '$defaultStartupMode' startup"
                }
                catch {
                    Write-Error "Could not restore '$serviceName': $($_.Exception.Message)"
                }
            }

            # 4. Start it if it should be running
            if ($defaultStartupMode -in @('Automatic', 'Boot', 'System')) {
                $service.Refresh()
                if ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
                    Write-StepDetail "Starting '$serviceName'"
                    try {
                        Start-Service -Name $serviceName -ErrorAction Stop
                        Write-StepSuccess "'$serviceName' started successfully"
                    }
                    catch {
                        Write-Warning "Failed to restart service. It may start after reboot. Error: $($_.Exception.Message)"
                    }
                }
                else {
                    Write-StepDetail "'$serviceName' is already running"
                }
            }
        }
    }
}
Write-Host ''
Write-Step 'Choose the Windows Update reset mode'
Write-Host '[Enter] Normal mode: Continue with the standard repair steps' -ForegroundColor Gray
Write-Host '[1] Aggressive mode: Takes longer, but is more thorough. Use if normal mode fails.' -ForegroundColor Gray
$modeSelection = Read-Host 'Selection'
$aggressiveMode = $modeSelection -eq '1'

if ($aggressiveMode) {
    Write-Step 'Aggressive mode selected' -Color Yellow
    Write-StepDetail 'Running CHKDSK scan'
    Start-Process -FilePath 'cmd.exe' -ArgumentList '/c chkdsk /scan /perf' -NoNewWindow -Wait
    Write-StepDetail 'Running SFC scan'
    Start-Process -FilePath 'cmd.exe' -ArgumentList '/c sfc /scannow' -NoNewWindow -Wait
    Write-StepDetail 'Running DISM health restore'
    Start-Process -FilePath 'cmd.exe' -ArgumentList '/c dism /online /cleanup-image /restorehealth' -NoNewWindow -Wait
}
else {
    Write-Step 'Normal mode selected' -Color Cyan
}

Write-Step 'Stopping core Windows Update services'
foreach ($serviceName in @('BITS', 'wuauserv', 'appidsvc', 'cryptsvc')) {
    try {
        Write-StepDetail "Stopping $serviceName"
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
    }
    catch {
    }
}

Write-Step 'Removing QMGR data files'
Remove-Item "$env:ALLUSERSPROFILE\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -Force -ErrorAction SilentlyContinue

if ($aggressiveMode) {
    Write-Step 'Renaming Windows Update datastore and signature folders'
    Rename-Item "$env:SystemRoot\SoftwareDistribution\DataStore" 'DataStore.bak' -ErrorAction SilentlyContinue
    Rename-Item "$env:SystemRoot\System32\Catroot2" 'catroot2.bak' -ErrorAction SilentlyContinue
}

Write-Step 'Renaming Windows Update download cache'
Rename-Item "$env:SystemRoot\SoftwareDistribution\Download" 'Download.bak' -ErrorAction SilentlyContinue

Write-Step 'Removing legacy Windows Update log'
Remove-Item "$env:SystemRoot\WindowsUpdate.log" -Force -ErrorAction SilentlyContinue

if ($aggressiveMode) {
    Write-Step 'Resetting Windows Update service security descriptors'
    Start-Process -NoNewWindow -FilePath 'sc.exe' -ArgumentList @('sdset', 'bits', 'D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)') -Wait
    Start-Process -NoNewWindow -FilePath 'sc.exe' -ArgumentList @('sdset', 'wuauserv', 'D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)') -Wait
}

Write-Step 'Reregistering Windows Update components'
$oldLocation = Get-Location
try {
    Set-Location "$env:SystemRoot\System32"
    $dlls = @(
        'atl.dll', 'urlmon.dll', 'mshtml.dll', 'shdocvw.dll', 'browseui.dll',
        'jscript.dll', 'vbscript.dll', 'scrrun.dll', 'msxml.dll', 'msxml3.dll',
        'msxml6.dll', 'actxprxy.dll', 'softpub.dll', 'wintrust.dll', 'dssenh.dll',
        'rsaenh.dll', 'gpkcsp.dll', 'sccbase.dll', 'slbcsp.dll', 'cryptdlg.dll',
        'oleaut32.dll', 'ole32.dll', 'shell32.dll', 'initpki.dll', 'wuapi.dll',
        'wuaueng.dll', 'wuaueng1.dll', 'wucltui.dll', 'wups.dll', 'wups2.dll',
        'wuweb.dll', 'qmgr.dll', 'qmgrprxy.dll', 'wucltux.dll', 'muweb.dll', 'wuwebv.dll'
    )

    foreach ($dll in $dlls) {
        if (Test-Path $dll) {
            Start-Process -NoNewWindow -FilePath 'regsvr32.exe' -ArgumentList @('/s', $dll) -Wait
        }
    }
}
finally {
    Set-Location $oldLocation
}

Write-Step 'Removing WSUS client settings'
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate') {
    foreach ($propertyName in @('AccountDomainSid', 'PingID', 'SusClientId')) {
        Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate' -Name $propertyName -Force -ErrorAction SilentlyContinue
    }
}

Write-Step 'Removing Windows Update policy settings'
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'ExcludeWUDriversInQualityUpdate' -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata' -Name 'PreventDeviceMetadataFromNetwork' -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching' -Name 'DontPromptForWindowsUpdate' -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching' -Name 'DontSearchWindowsUpdate' -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching' -Name 'DriverUpdateWizardWuSearchEnabled' -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoRebootWithLoggedOnUsers' -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'AUPowerManagement' -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'BranchReadinessLevel' -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'DeferFeatureUpdatesPeriodInDays' -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'DeferQualityUpdatesPeriodInDays' -Force -ErrorAction SilentlyContinue

foreach ($path in @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies',
    'HKCU:\Software\Microsoft\WindowsSelfHost',
    'HKCU:\Software\Policies',
    'HKLM:\Software\Microsoft\Policies',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate',
    'HKLM:\Software\Microsoft\WindowsSelfHost',
    'HKLM:\Software\Policies',
    'HKLM:\Software\WOW6432Node\Microsoft\Policies',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate'
)) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}

Start-Process -NoNewWindow -FilePath 'secedit.exe' -ArgumentList @('/configure', '/cfg', "$env:windir\inf\defltbase.inf", '/db', 'defltbase.sdb', '/verbose') -Wait
Remove-Item "$env:WinDir\System32\GroupPolicyUsers" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:WinDir\System32\GroupPolicy" -Recurse -Force -ErrorAction SilentlyContinue
Start-Process -NoNewWindow -FilePath 'gpupdate.exe' -ArgumentList @('/force') -Wait

Write-Step 'Resetting WinSock, WinHTTP, and IP stack'
Start-Process -NoNewWindow -FilePath 'netsh.exe' -ArgumentList @('winsock', 'reset') -Wait
Start-Process -NoNewWindow -FilePath 'netsh.exe' -ArgumentList @('winhttp', 'reset', 'proxy') -Wait
Start-Process -NoNewWindow -FilePath 'netsh.exe' -ArgumentList @('int', 'ip', 'reset') -Wait

Write-Step 'Removing BITS jobs'
Get-BitsTransfer -AllUsers -ErrorAction SilentlyContinue | Remove-BitsTransfer -ErrorAction SilentlyContinue

Write-Step 'Restoring service startup types and restarting services'
$bitsService = Get-Service -Name 'BITS' -ErrorAction SilentlyContinue
if ($bitsService) {
    Write-StepDetail 'Restoring and starting BITS'
    Set-Service -Name 'BITS' -StartupType Manual -ErrorAction SilentlyContinue
    Start-Service -Name 'BITS' -ErrorAction SilentlyContinue
}

$wuService = Get-Service -Name 'wuauserv' -ErrorAction SilentlyContinue
if ($wuService) {
    Write-StepDetail 'Restoring and starting wuauserv'
    Set-Service -Name 'wuauserv' -StartupType Manual -ErrorAction SilentlyContinue
    Start-Service -Name 'wuauserv' -ErrorAction SilentlyContinue
}

if (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\AppIDSvc') {
    Write-StepDetail 'Restoring and starting AppIDSvc'
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\AppIDSvc' -Name 'Start' -Type DWord -Value 3
    Start-Service -Name 'AppIDSvc' -ErrorAction SilentlyContinue
}

$cryptService = Get-Service -Name 'CryptSvc' -ErrorAction SilentlyContinue
if ($cryptService) {
    Write-StepDetail 'Restoring and starting CryptSvc'
    Set-Service -Name 'CryptSvc' -StartupType Manual -ErrorAction SilentlyContinue
    Start-Service -Name 'CryptSvc' -ErrorAction SilentlyContinue
}

Write-Step 'Forcing Windows Update discovery'
try {
    (New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()
}
catch {
    Write-Warning "Failed to create the Windows Update COM object: $($_.Exception.Message)"
}
Start-Process -NoNewWindow -FilePath 'wuauclt.exe' -ArgumentList @('/resetauthorization', '/detectnow') -Wait

Write-Host ''
Write-Host '==============================================='
Write-Host '-- Reset All Windows Update Settings to Stock -'
Write-Host '==============================================='
Write-StepSuccess 'Finished. Please reboot your computer.'
