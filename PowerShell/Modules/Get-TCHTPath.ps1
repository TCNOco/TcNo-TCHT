# This function gets and/or sets the TCHT install path.

function Get-TCHTPath() {
    $os = [System.Environment]::OSVersion.Platform.ToString()

    switch ($os) {
        "Win32NT" {
            $registryPath = "HKCU:\Software\TCHT\Path"
            if (Test-Path $registryPath) {
                return (Get-ItemProperty $registryPath).Path
            } else {
                return ""
            }
            break
        }
        "Unix" {
            # If gsettings installed:
            $gsettingsPath = "tc.ht"
            $gsettingsKey = "path"
            $gsettingsValue = $(gsettings get $gsettingsPath $gsettingsKey 2> $null)
            if ($LASTEXITCODE -eq 0) {
                return $gsettingsValue.Trim("`"'")
            } else {
                # If not dconf installed:
                if (! $(command -v dconf)) {
                    Install-Dconf
                }

                # If dconf installed:
                $dconfPath = "/tcht/path"
                $dconfValue = $(dconf read $dconfPath 2> $null)
                if ($LASTEXITCODE -eq 0) {
                    return $dconfValue
                }
            }

            return ""
            break
        }
        default {
            throw "Unsupported operating system."
        }
    }
}


function Get-TCHTPathFromUser() {
    $os = [System.Environment]::OSVersion.Platform.ToString()

    switch ($os) {
        "Win32NT" {
            $path = "C:\TCHT"
            break
        }
        "Unix" {
            $uname = $(uname)
            if ($uname -eq "Darwin") {
                $path = Join-Path (Resolve-Path "~/Documents") "TCHT"
            } else {
                $path = "/home/TCHT"
            }
            break
        }
        default {
            throw "Unsupported operating system."
        }
    }


    # Ask the user where to install
    $installLocation = Read-Host @"
Pick where to install:
1. (default) $path
2. Current folder: $((Get-Location).Path)
or Enter a custom path
"@

    $firstLoop = $True
    if ($installLocation -eq "1") {
        $installLocation = $path
        if (!(Test-Path $installLocation -PathType Container)) {
            Write-Host "Folder created: $installLocation"
            New-Item -ItemType Directory -Path $installLocation | Out-Null
        }        
    }
    elseif ($installLocation -eq "2") {
        $installLocation = (Get-Location).Path
        if (!(Test-Path $installLocation -PathType Container)) {
            Write-Host "Folder created: $installLocation"
            New-Item -ItemType Directory -Path $installLocation | Out-Null
        }
    }
    # Else, a custom path entered. Check the path exists and prompt about spaces.
    do {
        if (-not $firstLoop) {
            $installLocation = Read-Host "Please enter a custom path"
            $firstLoop = $False
        } else {
            if (!(Test-Path $installLocation -PathType Container)) {
                $createFolder = Read-Host "The folder $installLocation does not exist. Do you want to create it? (Y/N)"
                if ($createFolder -eq "Y" -or $createFolder -eq "y") {
                    Write-Host "Folder created: $installLocation"
                    New-Item -ItemType Directory -Path $installLocation | Out-Null
                }
            }            
        }
        if ($installLocation.Contains(" ")) {
            $proceedAnyway = Read-Host "Using a path with a space can result in things not working properly. Enter another path or type Y to use the current path: $installPath"
        }
    } while ($installLocation.Contains(" ") -and $proceedAnyway -notin 'Y', 'y')

    Write-Host "Saving path..."
    Set-TCHTPath -Path $installationLocation

    Write-Host "Installing this, and future TC.HT programs to: $installationLocation"
    return $installLocation
}

function Install-Dconf() {
    $os = [System.Environment]::OSVersion.Platform.ToString()

    switch ($os) {
        "Win32NT" {
            Write-Host "You only need DConf on Mac or Linux."
            return
        }
        "Unix" {
            if (which apt-get) {
                # Ubuntu, Debian, Raspbian, Kali, etc.
                sudo apt-get update
                sudo apt-get install -y dconf-cli
            } elseif (which dnf) {
                # Fedora, RedHat, CentOS, etc.
                sudo dnf install -y dconf
            } elseif (which yum) {
                # CentOS, RedHat, etc.
                sudo yum install -y dconf
            } elseif (which apk) {
                # Alpine, etc.
                sudo apk update
                sudo apk add dconf
            } elseif (which snap) {
                # Snap
                sudo snap install dconf
            } else {
                Write-Error "Could not find a package manager to install DConf."
            }
            break
        }
        default {
            throw "Unsupported operating system."
        }
    }
}





function Set-TCHTPath() {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    $os = [System.Environment]::OSVersion.Platform.ToString()

    switch ($os) {
        "Win32NT" {
            $registryPath = "HKCU:\Software\TCHT\Path"
            if (Test-Path $registryPath) {
                Set-ItemProperty $registryPath -Name Path -Value $path
            } else {
                New-Item -Path "HKCU:\Software\TCHT" -Force | Out-Null
                New-ItemProperty -Path $registryPath -Name Path -Value $path -PropertyType String | Out-Null
            }
            break
        }
        "Unix" {
            $gsettingsPath = "tc.ht"
            $gsettingsKey = "path"
            $gsettingsValue = $(gsettings get $gsettingsPath $gsettingsKey 2> $null)
            if ($LASTEXITCODE -eq 0) {
                # If gsettings is installed, use it to set the key value
                gsettings set $gsettingsPath $gsettingsKey "$path"
            } else {
                # If not dconf installed:
                if (! $(command -v dconf)) {
                    Install-Dconf
                }

                # If dconf installed:
                $dconfPath = "/tcht/path"
                dconf write $dconfPath "$path"
            }
            break
        }
        default {
            throw "Unsupported operating system."
        }
    }

}

Write-Host "Getting path from saved registry or gsettings: "
$path = Get-TCHTPath
Write-Host "RESULT: '$path'"

$path = Get-TCHTPathFromUser
Write-Host "$test is where I am!"