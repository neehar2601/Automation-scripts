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
    
    # Test command: Run Stable Diffusion 1.5 benchmark
    TestCMD = {
        $scriptPath = "C:\KSR_Package\KSR\Test_Run_KR\GLD\Script\GLD_4001.bat"
        $resultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD4001"
        
        # Write-Host "  [Test] Running Stable Diffusion 1.5 (GPU) benchmark..." -ForegroundColor Yellow
        # Write-Host "  Script: $scriptPath" -ForegroundColor Gray
        # Write-Host "  Output: $resultPath" -ForegroundColor Gray
        
        # Run SD 1.5 benchmark script
        Start-Process -FilePath "cmd.exe" `
            -ArgumentList "/c", "`"$scriptPath`"", "$resultPath" `
            -NoNewWindow -Wait
        
        # # Verify results were created
        # if (Test-Path "$resultPath\*") {
        #     Write-Host "  [Test] Benchmark completed successfully" -ForegroundColor Green
        # } else {
        #     throw "No output files found in $resultPath"
        # }
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