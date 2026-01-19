# ----------------------------------------------------------------------------------
# PresentMon Monitoring Module
# GPU frame rate and present metrics monitoring
# ----------------------------------------------------------------------------------

function Invoke-PresentMonMonitoring {
    param(
        [Parameter(Mandatory=$true)]
        [object]$TestInstance
    )

    Write-Host "  [PresentMon] Monitoring enabled" -ForegroundColor Cyan
    
    & $TestInstance.PowerSliderPath $TestInstance.ResultPath $TestInstance.TestID "PRESENTMON_Started"

    try {
        # Step 1: Start PresentMon monitoring
        Write-Host "  [PresentMon] Starting PresentMon monitoring in minimized window..." -ForegroundColor Cyan
        Start-Process -FilePath "C:\Users\Administrator\Downloads\presentmon\PresentMon-2.3.0-x64.exe" -WindowStyle Minimized
        
        # Step 2: Wait for monitoring to initialize
        Write-Host "  [PresentMon] Waiting 3 seconds for monitoring to initialize..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
        
        # Step 3: Run test in MAIN WINDOW
        Write-Host "  [PresentMon] Running test in main window..." -ForegroundColor Yellow
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
        
        # Step 4: Stop PresentMon
        Write-Host "  [PresentMon] Stopping PresentMon..." -ForegroundColor Yellow
        Stop-Process -Name "PresentMon-2.3.0-x64" -Force -ErrorAction SilentlyContinue
        
        Write-Host "  [OK] PresentMon monitoring completed" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] PresentMon monitoring failed: $($_.Exception.Message)" -ForegroundColor Red
        Stop-Process -Name "PresentMon-2.3.0-x64" -Force -ErrorAction SilentlyContinue
        throw
    }
    finally {
        & $TestInstance.PowerSliderPath $TestInstance.ResultPath $TestInstance.TestID "PRESENTMON_Ended"
    }
}
