function Import-RemoteFunction ($ScriptUri) {
    $functionName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptUri)
    if (-not (Get-Command $functionName -ErrorAction SilentlyContinue)) {
        $tempModulePath = Join-Path ([System.IO.Path]::GetTempPath()) ($functionName + ".psm1")
        Invoke-WebRequest -Uri $ScriptUri -OutFile $tempModulePath
        $originalExecutionPolicy = Get-ExecutionPolicy -Scope Process
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
        Import-Module $tempModulePath
        Set-ExecutionPolicy -ExecutionPolicy $originalExecutionPolicy -Scope Process -Force
    }
}