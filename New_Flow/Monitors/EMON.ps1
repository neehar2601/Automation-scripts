# ----------------------------------------------------------------------------------
# EMON Monitoring Module
# Intel Event Monitoring for microarchitecture performance counters
# Uses EMONHelper.ps1 for simplified control with minimized window
# ----------------------------------------------------------------------------------

function Invoke-EMONMonitoring {
    param(
        [Parameter(Mandatory=$true)]
        [object]$TestInstance
    )

    Write-Host "  [EMON] Monitoring enabled" -ForegroundColor Cyan
    
    $helperScript = Join-Path $PSScriptRoot "EMONHelper.ps1"
    
    if (!(Test-Path $helperScript)) {
        Write-Host "  [ERROR] EMONHelper.ps1 not found at: $helperScript" -ForegroundColor Red
        throw "EMONHelper.ps1 not found"
    }
    
    # Determine which EMON mode(s) are enabled
    $emonModes = @()
    if ($TestInstance.EnableEMON_P_Core) { $emonModes += "P-Core" }
    if ($TestInstance.EnableEMON_E_Core) { $emonModes += "E-Core" }
    if ($TestInstance.EnableEMON_P_Core_Cache) { $emonModes += "P-Core-Cache" }
    if ($TestInstance.EnableEMON_E_Core_Cache) { $emonModes += "E-Core-Cache" }
    if ($TestInstance.EnableEMON_EDP) { $emonModes += "EDP" }
    
    Write-Host "  [EMON] Modes: $($emonModes -join ', ')" -ForegroundColor Cyan
    
    & $TestInstance.PowerSliderPath $TestInstance.ResultPath $TestInstance.TestID "EMON_Started"

    try {
        # Step 1: Start EMON monitoring in minimized window
        Write-Host "  [EMON] Starting monitoring in minimized window..." -ForegroundColor Cyan
        & $helperScript -Action Start -LogDirectory $TestInstance.ResultPath -FileName "$($TestInstance.TestID)_emon"
        
        # Step 2: Wait for monitoring to initialize
        Write-Host "  [EMON] Waiting 3 seconds for monitoring to initialize..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
        
        # Step 3: Run test in MAIN WINDOW (not background job)
        Write-Host "  [EMON] Running test in main window..." -ForegroundColor Yellow
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
        Write-Host "  [EMON] Waiting 3 seconds before stopping monitoring..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
        
        # Step 5: Stop EMON monitoring
        Write-Host "  [EMON] Stopping data collection..." -ForegroundColor Yellow
        & $helperScript -Action Stop -LogDirectory $TestInstance.ResultPath -FileName "$($TestInstance.TestID)_emon"
        
        # Step 6: Get results summary
        Write-Host "  [EMON] Retrieving results..." -ForegroundColor Cyan
        $results = & $helperScript -Action GetResults -LogDirectory $TestInstance.ResultPath -FileName "$($TestInstance.TestID)_emon"
        
        Write-Host "  [OK] EMON monitoring completed" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] EMON monitoring failed: $($_.Exception.Message)" -ForegroundColor Red
        # Try to stop EMON on error
        try {
            & $helperScript -Action Stop -LogDirectory $TestInstance.ResultPath -FileName "$($TestInstance.TestID)_emon"
        } catch {}
        throw
    }
    finally {
        & $TestInstance.PowerSliderPath $TestInstance.ResultPath $TestInstance.TestID "EMON_Ended"
    }
}
