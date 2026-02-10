# ----------------------------------------------------------------------------------
# TypePerf Monitoring Module
# Windows Performance Counters monitoring (CPU, memory, disk, network)
# ----------------------------------------------------------------------------------

function Invoke-TypePerfMonitoring {
    param(
        [Parameter(Mandatory=$true)]
        [object]$TestInstance
    )

    $counterFile = if ($TestInstance.EnableTypePerfSC) { "subsetcounters.txt" } else { "typeperfinputKSR.txt" }
    $suffix = if ($TestInstance.EnableTypePerfSC) { "SC" } else { "TP" }
    
    Write-Host "  [TypePerf] Monitoring enabled (Mode: $suffix)" -ForegroundColor Cyan
    
    & $TestInstance.PowerSliderPath $TestInstance.ResultPath $TestInstance.TestID "TYPEPERF_$($suffix)_Started"

    try {
        $typeperfOutput = Join-Path $TestInstance.ResultPath "$($TestInstance.TestID)_typeperf_$suffix.csv"

        # Step 1: Wait if WaitTime specified
        if ($TestInstance.TypePerfWaitTime -gt 0) {
            Write-Host "  [TypePerf] Waiting $($TestInstance.TypePerfWaitTime) seconds for stabilization..." -ForegroundColor Gray
            Start-Sleep -Seconds $TestInstance.TypePerfWaitTime
        }
        else {
            Write-Host "  [TypePerf] Waiting 3 seconds for monitoring to initialize..." -ForegroundColor Gray
            Start-Sleep -Seconds 3
        }
        
        # Step 2: Start TypePerf monitoring in hidden window
        Write-Host "  [TypePerf] Starting TypePerf monitoring in hidden window..." -ForegroundColor Cyan
        Start-Process -FilePath "typeperf" -ArgumentList "-cf $counterFile -o `"$typeperfOutput`"" -WindowStyle Hidden
        
        
        
        # Step 3: Run test in MAIN WINDOW
        Write-Host "  [TypePerf] Running test in main window..." -ForegroundColor Yellow
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
        Write-Host "  [TypePerf] Waiting 2 seconds before stopping monitoring..." -ForegroundColor Gray
        Start-Sleep -Seconds 2
        
        # Step 5: Stop TypePerf
        Write-Host "  [TypePerf] Stopping TypePerf..." -ForegroundColor Yellow
        Stop-Process -Name "typeperf" -Force -ErrorAction SilentlyContinue
        
        Write-Host "  [OK] TypePerf monitoring completed" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] TypePerf monitoring failed: $($_.Exception.Message)" -ForegroundColor Red
        Stop-Process -Name "typeperf" -Force -ErrorAction SilentlyContinue
        throw
    }
    finally {
        & $TestInstance.PowerSliderPath $TestInstance.ResultPath $TestInstance.TestID "TYPEPERF_$($suffix)_Ended"
    }
}
