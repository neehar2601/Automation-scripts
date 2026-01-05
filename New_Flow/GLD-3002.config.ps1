# ----------------------------------------------------------------------------------
# Test Config: GLD-3002
# Test Name: NPU-LLAMA3_8B_OV_FP16-INT4_SYM
# OpenVINO GenAI benchmark - Llama 3 8B on NPU with INT4 quantization
# ----------------------------------------------------------------------------------

@{
    # Required parameters
    TestType = "Perf"
    TestID = "GLD3002"
    TestName = "NPU-LLAMA3_8B_OV_FP16-INT4_SYM"
    TestDomain = "Golden"
    TestSubDomain = "NPU"
    
    # Override defaults
    Temperature = 60          # Default is 83
    RecordTime = 0
    WaitTime = 0
    
    # PreStep: Change directory to llm_bench
    TestPrestepCMD = {
        Write-Host "  [PreStep] Changing directory to llm_bench..." -ForegroundColor Gray
        Set-Location "C:\KSR_Package\tools\installers\openvino.genai\tools\llm_bench"
        Write-Host "  [PreStep] Current directory: $(Get-Location)" -ForegroundColor Green
    }
    
    # Test command: Run OpenVINO GenAI benchmark on NPU
    TestCMD = {
        $outputFile = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD3002\GLD3002_KingsScore_ClientAI_NPU_llama3-8b.csv"
        $modelPath = "C:\KSR_Package\tools\installers\openvino.genai\tools\llm_bench\Llama-3-8B_npu"
        $promptFile = "C:\KSR_Package\tools\installers\openvino.genai\tools\llm_bench\prompts\1k_pmpt.jsonl"
        
        Write-Host "  [Test] Running OpenVINO GenAI benchmark on NPU..." -ForegroundColor Yellow
        Write-Host "  Model: Llama-3-8B" -ForegroundColor Gray
        Write-Host "  Device: NPU" -ForegroundColor Gray
        Write-Host "  Input Context: 128 tokens" -ForegroundColor Gray
        Write-Host "  Iterations: 7" -ForegroundColor Gray
        Write-Host "  Output: $outputFile" -ForegroundColor Gray
        
        # Run benchmark
        Start-Process -FilePath "python" `
            -ArgumentList "benchmark.py", "-m", "`"$modelPath`"", "-d", "NPU", "-ic", "128", "-n", "7", "--genai", "-pf", "`"$promptFile`"", "-r", "`"$outputFile`"" `
            -NoNewWindow -Wait
        
        # Return to test directory
        Set-Location "C:\KSR_Package\KSR\Test_Run_KR"
        
        if (Test-Path $outputFile) {
            Write-Host "  [Test] Benchmark completed successfully" -ForegroundColor Green
            Write-Host "  Results saved to: $outputFile" -ForegroundColor Green
        } else {
            throw "Benchmark output file not created: $outputFile"
        }
    }
    
    # PostStep: Rename score files
    TestPoststepCMD = {
        Write-Host "  [PostStep] Renaming score files..." -ForegroundColor Gray
        Start-Process -FilePath "C:\KSR_Package\KSR\Test_Run_KR\Score_Rename.bat" `
            -ArgumentList "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD3002" `
            -NoNewWindow -Wait
        Write-Host "  [PostStep] Score files renamed" -ForegroundColor Green
    }
    
    # Result path (auto-generated based on TestID)
    ResultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD3002"
}
