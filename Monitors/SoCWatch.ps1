# ----------------------------------------------------------------------------------
# SoCWatch Monitoring Module
# Intel SoC monitoring with CPU, GPU, NPU, power, and temperature tracking
# Uses SoCWatchHelper.ps1 for simplified control
# ----------------------------------------------------------------------------------

function Invoke-SoCWatchMonitoring {
    param(
        [Parameter(Mandatory=$true)]
        [object]$TestInstance
    )

    Write-Host "  [SoCWatch] Monitoring enabled" -ForegroundColor Cyan
    
    $helperScript = Join-Path $PSScriptRoot "SoCWatchHelper.ps1"
    
    if (!(Test-Path $helperScript)) {
        Write-Host "  [ERROR] SoCWatchHelper.ps1 not found at: $helperScript" -ForegroundColor Red
        throw "SoCWatchHelper.ps1 not found"
    }
    
    # Determine execution mode (default: background)
    $executionMode = if ($TestInstance.SoCWatchForeground -eq $true) { @{Foreground = $true} } else { @{} }
    
    $markerFile = "C:\KSR_Package\KSR\Test_Run_KR\process.done"
    if (Test-Path $markerFile) { Remove-Item $markerFile -Force }

    # & $TestInstance.PowerSliderPath $TestInstance.ResultPath $TestInstance.TestID "SOCWATCH_Started"

    try {
        # Step 1: Start SoCWatch monitoring in separate window
        Write-Host "  [SoCWatch] Starting monitoring in separate window..." -ForegroundColor Cyan
        & $helperScript -Action Start -LogDirectory $TestInstance.ResultPath -FileName $TestInstance.TestID -Flags $TestInstance.SoCWatchFlags @executionMode
        
        # Step 2: Wait if WaitTime specified
        if ($TestInstance.SoCWatchWaitTime -gt 0) {
            Write-Host "  [SoCWatch] Waiting $($TestInstance.SoCWatchWaitTime) seconds for stabilization..." -ForegroundColor Gray
            Start-Sleep -Seconds $TestInstance.SoCWatchWaitTime
        }
        else {
            # Default wait for monitoring to initialize
            Write-Host "  [SoCWatch] Waiting 3 seconds for monitoring to initialize..." -ForegroundColor Gray
            Start-Sleep -Seconds 3
        }
        
        # Step 3: Run test in MAIN WINDOW (not background job)
        Write-Host "  [SoCWatch] Running test in main window..." -ForegroundColor Yellow
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
        
        # Step 4: Wait a bit before stopping (let monitoring capture final data)
        Write-Host "  [SoCWatch] Waiting 3 seconds before stopping monitoring..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
        
        # Step 5: Stop SoCWatch monitoring
        Write-Host "  [SoCWatch] Stopping data collection..." -ForegroundColor Yellow
        & $helperScript -Action Stop -LogDirectory $TestInstance.ResultPath -FileName $TestInstance.TestID
        
        Write-Host "  [OK] SoCWatch monitoring completed" -ForegroundColor Green
        
        # Get results summary
        $results = & $helperScript -Action GetResults -LogDirectory $TestInstance.ResultPath -FileName $TestInstance.TestID
        
    }
    catch {
        Write-Host "  [ERROR] SoCWatch monitoring failed: $($_.Exception.Message)" -ForegroundColor Red
        # Try to stop SoCWatch on error
        try {
            & $helperScript -Action Stop -LogDirectory $TestInstance.ResultPath -FileName $TestInstance.TestID
        } catch {}
        throw
    }
    finally {
        # & $TestInstance.PowerSliderPath $TestInstance.ResultPath $TestInstance.TestID "SOCWATCH_Ended"
    }
}
