# ----------------------------------------------------------------------------------
# Test Config: GLD-4001
# Test Name: SD 1.5 (GPU)
# Stable Diffusion 1.5 image generation benchmark on GPU
# ----------------------------------------------------------------------------------

@{
    # Required parameters
    TestType = "Perf"
    TestID = "GLD4001"
    TestName = "SD 1.5 (GPU)"
    TestDomain = "Golden"
    TestSubDomain = "GPU"
    
    # Override defaults
    Temperature = 50          # 50°C target
    RecordTime = 0
    WaitTime = 0
    Repeats = 1
    
    # Result path
    ResultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD4001"
    
    # Test command: Run Stable Diffusion 1.5 benchmark (migrated from GLD_4001.bat)
    TestCMD = {
        # Write-Host "  [Test] Running Stable Diffusion 1.5 (GPU) benchmark..." -ForegroundColor Yellow
        
        # Set proxy environment variables (migrated from batch)
        $env:http_proxy = "http://proxy-us.intel.com:912"
        $env:https_proxy = "http://proxy-us.intel.com:912"
        $env:HTTP_PROXY = "http://proxy-us.intel.com:912"
        $env:HTTPS_PROXY = "http://proxy-us.intel.com:912"
        Write-Host "  [Test] Proxy set to $env:http_proxy" -ForegroundColor Gray
        
        # Define paths
        $gimpPath = "C:\Users\Public\gimp\GIMP-ML-OV"
        $pythonExe = "C:\Users\Public\gimp\gimpenv3\Scripts\python.exe"
        $testScript = "GIMP-ML-OV\testscases\StableDiffusion\stable_diffusion_engine_tc.py"
        $outputFile = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD4001\GLD4001_CMD_KingsScore_ClientAI_GPU_SD.txt"
        
        # Write-Host "  [Test] Working directory: C:\Users\Public\gimp" -ForegroundColor Gray
        # Write-Host "  [Test] Model: SD 1.5 Square" -ForegroundColor Gray
        # Write-Host "  [Test] Performance mode: Best performance" -ForegroundColor Gray
        # Write-Host "  [Test] Iterations: 5" -ForegroundColor Gray
        # Write-Host "  [Test] Output: $outputFile" -ForegroundColor Gray
        
        # Change to working directory
        Push-Location "C:\Users\Public\gimp"
        
        try {
            # Run Stable Diffusion benchmark
            & $pythonExe $testScript `
                -m "sd_1.5_square" `
                -pm "best performance" `
                -n 5 `
                *>&1 | Tee-Object -FilePath $outputFile
            
            # # Check if output was created
            # if (Test-Path $outputFile) {
            #     $fileSize = (Get-Item $outputFile).Length
            #     Write-Host "  [Test] Benchmark completed successfully" -ForegroundColor Green
            #     Write-Host "  [Test] Output file size: $([math]::Round($fileSize / 1KB, 2)) KB" -ForegroundColor Green
            # } else {
            #     throw "Output file not created: $outputFile"
            # }
        }
        catch {
            Write-Host "  [Test] Error running benchmark: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
        finally {
            # Return to original directory
            Pop-Location
        }
    }
    
    # PostStep: Rename score files
    TestPoststepCMD = {
        # Write-Host "  [PostStep] Renaming score files..." -ForegroundColor Gray
        Start-Process -FilePath "C:\KSR_Package\KSR\Test_Run_KR\Score_Rename.bat" `
            -ArgumentList "`"C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD4001`"" `
            -NoNewWindow -Wait
        # Write-Host "  [PostStep] Score files renamed" -ForegroundColor Green
    }
}