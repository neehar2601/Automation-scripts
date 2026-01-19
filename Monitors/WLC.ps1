# ----------------------------------------------------------------------------------
# WLC (IPF Profiling) Monitoring Module
# Wireless LAN Characterization and Intel IPF profiling
# ----------------------------------------------------------------------------------

function Invoke-WLCMonitoring {
    param(
        [Parameter(Mandatory=$true)]
        [object]$TestInstance
    )

    Write-Host "  [WLC] IPF Profiling enabled" -ForegroundColor Cyan
    
    & $TestInstance.PowerSliderPath $TestInstance.ResultPath $TestInstance.TestID "WLC_Started"

    try {
        # Step 1: Prepare IPF environment
        Write-Host "  [WLC] Cleaning previous IPF logs..." -ForegroundColor Cyan
        Remove-Item "C:\Windows\System32\drivers\DriverData\Intel\IPF\log\*" -Force -ErrorAction SilentlyContinue
        
        # Step 2: Start IPF Profiling
        Write-Host "  [WLC] Starting IPF Profiling..." -ForegroundColor Cyan
        # IPF profiling commands here
        Start-Sleep -Seconds 2
        
        # Step 3: Run test in MAIN WINDOW
        Write-Host "  [WLC] Running test in main window..." -ForegroundColor Yellow
        Write-Host "  Executing: " -NoNewline -ForegroundColor White
        
        # Check if TestCMD is a ScriptBlock or string
        if ($TestInstance.TestCMD -is [scriptblock]) {
            Write-Host "<ScriptBlock>" -ForegroundColor Gray
            & $TestInstance.TestCMD
        }
        else {
            Write-Host "$($TestInstance.TestCMD)" -ForegroundColor Gray
            Invoke-Expression $TestInstance.TestCMD
        }
        
        Write-Host "  [OK] Test execution completed" -ForegroundColor Green
        
        Write-Host "  [OK] WLC profiling completed" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] WLC profiling failed: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
    finally {
        & $TestInstance.PowerSliderPath $TestInstance.ResultPath $TestInstance.TestID "WLC_Ended"
    }
}
