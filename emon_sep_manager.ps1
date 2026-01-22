param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("install", "uninstall")]
    [string]$Action
)

$sepPath = "C:\Program Files (x86)\IntelSWTools\sep"
$zipPath = "C:\KSR_Package\KSR\Test_Run_KR\sep_private_5_56_win_10010457b11497234.zip"
$extractPath = "C:\KSR_Package\KSR\Test_Run_KR\sep"
$installerDir = "C:\KSR_Package\KSR\Test_Run_KR\sep\sep_private_5_56_win_10010457b11497234"
$installerCmd = "sep-installer.cmd"
$sepVarsCmd = "C:\Program Files (x86)\IntelSWTools\sep\sep_vars.cmd"
$workingDir = "C:\KSR_Package\KSR\Test_Run_KR"

if ($Action -eq "install") {
    if (-Not (Test-Path $sepPath)) {
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        Write-Host "Sep installation started"
        Push-Location $installerDir
        Start-Process -Wait -FilePath $installerCmd -ArgumentList "-i --accept-license -ni"
        Write-Host "Sep Installation done" -ForegroundColor Green
        Start-Sleep -Seconds 5
        Start-Process cmd.exe -ArgumentList "/k `"$sepVarsCmd`""
        Pop-Location
        Set-Location $workingDir
        Write-Host "Env set done" -ForegroundColor Green
    } else {
        Write-Host "EMON already present."
        Start-Process cmd.exe -ArgumentList "/k `"$sepVarsCmd`""
        Pop-Location
        Set-Location $workingDir
        Write-Host "Env set done" -ForegroundColor Green
    }
}
elseif ($Action -eq "uninstall") {
    if (Test-Path $sepPath) {
        Push-Location $installerDir
        Start-Process -Wait -FilePath $installerCmd -ArgumentList "-u -ni"
        Pop-Location
        Remove-Item -Path $sepPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "SEP uninstalled." -ForegroundColor Yellow
    } else {
        Write-Host "SEP is not installed."
    }
}

