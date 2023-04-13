# Allow importing remote functions
iex (irm Import-RemoteFunction.tc.ht)

function Initialize-Aria2 {
    # If is currently admin: Install choco and aria2
    if (-not ($triedAria2Install) -and ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -and ($null -eq (Get-Command aria2c -ErrorAction SilentlyContinue))) {
        $triedAria2Install = $True

        # 1. Install Chocolatey
        Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        # 2. Install aria2
        Write-Host "`nInstalling aria2c (Faster model download)..." -ForegroundColor Cyan
        choco install aria2 -y

        if (-not (Get-Command Update-SessionEnvironment -ErrorAction SilentlyContinue)) {
            # Import function to reload without needing to re-open Powershell
            iex (irm refreshenv.tc.ht)
        }
        Update-SessionEnvironment
    }

    # If aria2 not installed globally (from choco or other) and ./aria2c.exe does not exist: Download and extract to current directory
    if (-not ($triedAria2Extract) -and ($null -eq (Get-Command aria2c -ErrorAction SilentlyContinue)) -and ($null -eq (Get-Command ./aria2c -ErrorAction SilentlyContinue))) {
        $triedAria2Extract = $True

        # Download aria2 binary for faster downloads, if not already installed.
        iex (irm download-aria2.tc.ht)
    }

    # If file exists, save full path for use in other folders too
    if (Test-Path "$((Get-Location).Path)\aria2c.exe") {
        $global:aria2Path = (Get-Location).Path + '\aria2c.exe'
    }

    # If not either, then use another download function
    if (-not ($importedOtherDownloadFunc) -and ($null -eq (Get-Command aria2c -ErrorAction SilentlyContinue)) -and ($null -eq (Get-Command $global:aria2Path -ErrorAction SilentlyContinue))) {
        $importedOtherDownloadFunc = $true
        # Import download command if not already available
        Import-FunctionIfNotExists -Command Get-FileFromWeb -ScriptUri "https://gist.githubusercontent.com/ChrisStro/37444dd012f79592080bd46223e27adc/raw/5ba566bd030b89358ba5295c04b8ef1062ddd0ce/Get-FileFromWeb.ps1"
    }
}

function Get-Aria2File {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )

    # Import or install aria2c if not already
    Initialize-Aria2

    # Check if aria2c is available
    if (-not ($null -eq (Get-Command aria2c -ErrorAction SilentlyContinue))) {
        # Use aria2c to download the files
        aria2c -x 8 -s 8 --continue --out="$OutputPath" "$Url" --console-log-level=error --download-result=hide
    } elseif (-not ($null -eq (Get-Command $aria2Path -ErrorAction SilentlyContinue))) {
        # Use aria2c to download the files
        & $aria2Path -x 8 -s 8 --continue --out="$OutputPath" "$Url" --console-log-level=error --download-result=hide
    } else {
        # Import download command if not already available
        Import-FunctionIfNotExists -Command Get-FileFromWeb -ScriptUri "https://gist.githubusercontent.com/ChrisStro/37444dd012f79592080bd46223e27adc/raw/5ba566bd030b89358ba5295c04b8ef1062ddd0ce/Get-FileFromWeb.ps1"
       
        # Use Get-FileFromWeb to download the files
        Get-FileFromWeb -URL $url -File $outputPath
    }
}
function Get-Aria2Files {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Files
    )

    # Import or install aria2c if not already
    Initialize-Aria2
    
    # Check if aria2c is available
    if (-not ($null -eq (Get-Command aria2c -ErrorAction SilentlyContinue))) {
        # Use aria2c to download the files
        $files | ForEach-Object {
            aria2c -x 8 -s 8 --continue --out="$outputPath\$_" "$Url/$_" --console-log-level=error --download-result=hide
        }
    } elseif (-not ($null -eq (Get-Command $aria2Path -ErrorAction SilentlyContinue))) {
        # Use aria2c to download the files
        $files | ForEach-Object {
            & $aria2Path -x 8 -s 8 --continue --out="$outputPath\$_" "$Url/$_" --console-log-level=error --download-result=hide
        }
    } else {
        # Import download command if not already available
        Import-FunctionIfNotExists -Command Get-FileFromWeb -ScriptUri "https://gist.githubusercontent.com/ChrisStro/37444dd012f79592080bd46223e27adc/raw/5ba566bd030b89358ba5295c04b8ef1062ddd0ce/Get-FileFromWeb.ps1"

        # Use Get-FileFromWeb to download the files
        $files | ForEach-Object {
            Get-FileFromWeb -URL "$Url\$_" -File "$outputPath\$_"
        }
    }
}