# SystemMeter Installation and Management Script
# Usage: 
#   .\install_SystemMeter.ps1              - Install/Check SystemMeter
#   .\install_SystemMeter.ps1 -Uninstall   - Uninstall SystemMeter

param(
    [switch]$Uninstall
)

function Uninstall-SystemMeter {
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "Starting SystemMeter Uninstallation Process" -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $systemMeterPath = "C:\Program Files\Intel Corporation\Intel(R) SystemMeter"
    $uninstallExe = Join-Path $systemMeterPath "\Uninstall\setup.exe"
    
    # Check if SystemMeter is installed
    if (Test-Path $systemMeterPath) {
        Write-Host "[INFO] SystemMeter installation found at: $systemMeterPath" -ForegroundColor White
        
        # Try to run the uninstaller if it exists
        if (Test-Path $uninstallExe) {
            Write-Host "[INFO] Running SystemMeter uninstaller..." -ForegroundColor White
            try {
                Start-Process -FilePath $uninstallExe -ArgumentList "/S" -Wait -ErrorAction Stop
                Write-Host "[SUCCESS] SystemMeter uninstaller executed" -ForegroundColor Green
            } catch {
                Write-Host "[WARNING] Uninstaller execution failed: $_" -ForegroundColor Yellow
            }
            Start-Sleep -Seconds 3
        } else {
            Write-Host "[WARNING] Uninstall.exe not found at: $uninstallExe" -ForegroundColor Yellow
        }
        
        # Force remove the directory if it still exists
        if (Test-Path $systemMeterPath) {
            Write-Host "[INFO] Removing SystemMeter directory..." -ForegroundColor White
            try {
                Remove-Item -Path $systemMeterPath -Recurse -Force -ErrorAction Stop
                Write-Host "[SUCCESS] SystemMeter directory removed" -ForegroundColor Green
            } catch {
                Write-Host "[ERROR] Failed to remove directory: $_" -ForegroundColor Red
                Write-Host "[INFO] You may need to manually delete: $systemMeterPath" -ForegroundColor Yellow
            }
        }
        
        # Remove extracted installation files
        $extractPath = "C:\KSR_Package\KSR\Test_Run_KR\SystemMeter\"
        if (Test-Path $extractPath) {
            Write-Host "[INFO] Removing extracted installation files..." -ForegroundColor White
            try {
                Remove-Item -Path $extractPath -Recurse -Force -ErrorAction Stop
                Write-Host "[SUCCESS] Extracted files removed" -ForegroundColor Green
            } catch {
                Write-Host "[WARNING] Failed to remove extracted files: $_" -ForegroundColor Yellow
            }
        }
        
        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host "SystemMeter Uninstallation Complete" -ForegroundColor Green
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "1. Restart your computer to complete the uninstallation" -ForegroundColor White
        Write-Host "2. To reinstall, run: .\install_SystemMeter.ps1" -ForegroundColor White
        Write-Host ""
        
    } else {
        Write-Host "[INFO] SystemMeter is not installed" -ForegroundColor Yellow
        Write-Host ""
    }
}

# Handle Uninstall parameter
if ($Uninstall) {
    Uninstall-SystemMeter
    exit 0
}

# Installation process
$systemMeterPath = "C:\Program Files\Intel Corporation\Intel(R) SystemMeter"
if (-Not (Test-Path $systemMeterPath)) {
    Write-Output "SystemMeter installation started"
    $zipPath = "C:\KSR_Package\KSR\Test_Run_KR\SystemMeter.zip"
    $destPath = "C:\KSR_Package\KSR\Test_Run_KR\SystemMeter\"
    Expand-Archive -Path $zipPath -DestinationPath $destPath -Force
    $installer = "C:\KSR_Package\KSR\Test_Run_KR\SystemMeter\SystemMeter\Intel(R)SystemMeterSetup.exe"
    Start-Process -FilePath $installer -ArgumentList "-s" -Wait
    Write-Output "SystemMeter installation end"
} else {
    Write-Output "SystemMeter already present."
}
$microchipDevice = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like '*Microchip*' -or
    ($_.HardwareID -ne $null -and $_.HardwareID -like '*VID_04D8*') -or
    ($_.Manufacturer -ne $null -and $_.Manufacturer -like '*Microchip*')
} | Select-Object FriendlyName, Status

if ($microchipDevice) {
    Write-Output "Microchip Energy Metering Device(s) found:"
    $deviceNotEnabled = $false
    $microchipDevice | ForEach-Object {
        Write-Output "Device: $($_.FriendlyName), Status: $($_.Status)"
        if ($_.Status -eq 'OK') {
            Write-Host "Device driver is enabled." -ForegroundColor Green
        } else {
            Write-Host "Device driver is NOT enabled." -ForegroundColor Red
            $deviceNotEnabled = $true
        }
    }
    
    if ($deviceNotEnabled) {
        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Red
        Write-Host "WARNING: One or more Microchip Energy Metering Device drivers are NOT enabled!" -ForegroundColor Yellow
        Write-Host "========================================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Reinstall the drivers" -ForegroundColor Cyan
        Write-Host ""
        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Red
        Start-Sleep -Seconds 15
        Stop-Process -Id $PID
    }
} else {
    Write-Output "No Microchip Energy Metering Device found."
    Write-Output "Please ensure that the Microchip Energy Metering Device driver is installed and the device is connected properly."
    Start-Sleep -Seconds 15
    Stop-Process -Id $PID
}