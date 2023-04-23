# This function gets and/or sets the TCHT install path.

function Get-TCHT-Path() {
    # Ask the user where to install
    $installLocation = Read-Host @"
Pick where to install:
1. (default) C:/TCHT
2. Current folder: $((Get-Location).Path)
or Enter a custom path
"@

    $firstLoop = $True
    if ($installLocation -eq "1") {
        $installLocation = "C:/TCHT"
    }
    elseif ($installLocation -eq "2") {
        $installLocation = (Get-Location).Path
    }
    # Else, a custom path entered. Check the path exists and prompt about spaces.
    do {
        if (-not $firstLoop) {
            $installLocation = Read-Host "Please enter a custom path"
            $firstLoop = $False
        }
        if ($installLocation.Contains(" ")) {
            $proceedAnyway = Read-Host "Using a path with a space can result in things not working properly. Enter another path or type Y to use the current path: $installPath"
        }
    } while ($installLocation.Contains(" ") -and $proceedAnyway -notin 'Y', 'y')

    Write-Host "Installing this, and future TC.HT programs to: $installationLocation"
}

$test = Get-TCHT-Path()
Write-Host "$test is where I am!"