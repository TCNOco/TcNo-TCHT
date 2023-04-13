# While you could go out of your way to create a VCredist installer...
# There already exists one:
# https://vcredist.com/quick/#install-the-visual-c-redistributables
# 
# A huge thank you to aaronparker/vcredist for this!

iex (irm Import-RemoteFunction.tc.ht) # Get RemoteFunction importer
Import-RemoteFunction -ScriptUri "Invoke-Elevated.tc.ht" # Import function to raise code to Admin

# The following does need to be run as admin, so that is done with the above to elevate it.
Invoke-Elevated {
    Write-Host "Preparing to download and install missing VcRedists (if any)." -ForegroundColor Yellow
    Write-Host "Please close this window when the process completes to continue (if it does not close itself)!" -ForegroundColor Red
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://vcredist.com/install.ps1'))
}