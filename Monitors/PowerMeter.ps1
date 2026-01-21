# ----------------------------------------------------------------------------------
# PowerMeter (SystemMeter) Monitoring Module
# Power measurement using Intel SystemMeter with RAPL and PAC counters
# Uses PowerMeterHelper.ps1 for simplified control
# ----------------------------------------------------------------------------------

function Invoke-PowerMeterMonitoring {
    param(
        [Parameter(Mandatory=$true)]
        [object]$TestInstance
    )

    Write-Host "  [PowerMeter] Monitoring enabled" -ForegroundColor Cyan
    
    $helperScript = Join-Path $PSScriptRoot "PowerMeterHelper.ps1"
    
    if (!(Test-Path $helperScript)) {
        Write-Host "  [ERROR] PowerMeterHelper.ps1 not found at: $helperScript" -ForegroundColor Red
        throw "PowerMeterHelper.ps1 not found"
    }
    
    # Signal monitoring start
    # & $TestInstance.PowerSliderPath $TestInstance.ResultPath $TestInstance.TestID "POWERMETER_Started"

    try {
        # Determine monitoring duration
        $duration = if ($TestInstance.PowerMeterRunTime -gt 0) { $TestInstance.PowerMeterRunTime } else { 300 }

         # Step 1: Wait if WaitTime specified
        if ($TestInstance.PowerMeterWaitTime -gt 0) {
            Write-Host "  [PowerMeter] Waiting $($TestInstance.PowerMeterWaitTime) seconds for stabilization..." -ForegroundColor Gray
            Start-Sleep -Seconds $TestInstance.PowerMeterWaitTime
        }
        else {
            Write-Host "  [PowerMeter] Waiting 3 seconds for monitoring to initialize..." -ForegroundColor Gray
            Start-Sleep -Seconds 3
        }
        
        # Step 2: Start PowerMeter monitoring using helper
        Write-Host "  [PowerMeter] Starting SystemMeter monitoring..." -ForegroundColor Cyan
        & $helperScript -Action Start `
                       -LogDirectory $TestInstance.ResultPath `
                       -FileName $TestInstance.TestID `
                       -Duration $duration
        
        # Step 3: Run test in MAIN WINDOW
        Write-Host "  [PowerMeter] Running test in main window..." -ForegroundColor Yellow
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
        
        # Step 4: Wait a bit before stopping
        Write-Host "  [PowerMeter] Waiting 2 seconds before stopping monitoring..." -ForegroundColor Gray
        Start-Sleep -Seconds 2
        
        # Step 5: Stop PowerMeter using helper
        Write-Host "  [PowerMeter] Stopping SystemMeter..." -ForegroundColor Yellow
        & $helperScript -Action Stop `
                       -LogDirectory $TestInstance.ResultPath `
                       -FileName $TestInstance.TestID
        
        # Step 6: Get results using helper
        Write-Host "  [PowerMeter] Retrieving results..." -ForegroundColor Cyan
        & $helperScript -Action GetResults `
                       -LogDirectory $TestInstance.ResultPath `
                       -FileName $TestInstance.TestID
        
        Write-Host "  [OK] PowerMeter monitoring completed" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] PowerMeter monitoring failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Attempt cleanup
        try {
            & $helperScript -Action Stop -LogDirectory $TestInstance.ResultPath -FileName $TestInstance.TestID
        } catch {
            Write-Host "  [PowerMeter] Cleanup attempted" -ForegroundColor Gray
        }
        
        throw
    }
    finally {
        # Signal monitoring end
        # & $TestInstance.PowerSliderPath $TestInstance.ResultPath $TestInstance.TestID "POWERMETER_Ended"
    }
}
