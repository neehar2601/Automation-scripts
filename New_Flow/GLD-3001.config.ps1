# ----------------------------------------------------------------------------------
# Test Config: GLD-3001
# Test Name: GPU-LLAMA3_8B_OV_FP16-INT4_SYM
# OpenVINO GenAI benchmark - Llama 3 8B on GPU with INT4 quantization
# ----------------------------------------------------------------------------------

@{
    # Test identification
    TestType = "Perf"
    TestID = "GLD3001"
    TestName = "GPU-LLAMA3_8B_OV_FP16-INT4_SYM"
    TestDomain = "Golden"
    TestSubDomain = "GPU"
    
    # Test parameters
    Temperature = 50
    RecordTime = 0
    WaitTime = 0
    Repeats = 1
    
    # Result path
    ResultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD3001"
    
    # PreStep: Change directory to llm_bench
    TestPrestepCMD = {
        Write-Host "  [PreStep] Changing directory to llm_bench..." -ForegroundColor Gray
        Set-Location "C:\KSR_Package\tools\installers\openvino.genai\tools\llm_bench"
        Write-Host "  [PreStep] Current directory: $(Get-Location)" -ForegroundColor Green
    }
    
    # Test command: Run OpenVINO GenAI benchmark
    TestCMD = {
        $modelName = "llama3-8b-gpu"
        $outputFile = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD3001\GLD3001_KingsScore_ClientAI_GPU_llama3-8b.csv"
        $modelPath = "C:\KSR_Package\tools\installers\openvino.genai\tools\llm_bench\$modelName\pytorch\dldt\compressed_weights\OV_FP16-INT4_SYM"
        $promptFile = "C:\KSR_Package\tools\installers\openvino.genai\tools\llm_bench\prompts\llama-3-8b.jsonl"

        # Write-Host "  [Test] Running OpenVINO GenAI benchmark on GPU..." -ForegroundColor Yellow
        # Write-Host "  Model: $modelName" -ForegroundColor Gray
        # Write-Host "  Device: GPU" -ForegroundColor Gray
        # Write-Host "  Input Context: 128 tokens" -ForegroundColor Gray
        # Write-Host "  Iterations: 5" -ForegroundColor Gray
        # Write-Host "  Output: $outputFile" -ForegroundColor Gray

        # Run benchmark
        & python benchmark.py `
            -m $modelPath `
            -f ov `
            -d GPU `
            -r $outputFile `
            -n 5 `
            -pf $promptFile `
            -ic 128
        
        # Return to test directory
        Set-Location "C:\KSR_Package\KSR\Test_Run_KR"
        
        if (Test-Path $outputFile) {
            Write-Host "  [Test] Benchmark completed successfully" -ForegroundColor Green
            Write-Host "  Results saved to: $outputFile" -ForegroundColor Green
        } else {
            throw "Benchmark output file not created: $outputFile"
        }
    }
    
}