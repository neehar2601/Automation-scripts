@{
    TestID = "GLD-4003"
    TestName = "GPU Stable Diffusion 1.5 FP8 Best Performance"
    Description = "GPU-based Stable Diffusion 1.5 image generation benchmark with FP8 quantization in best performance mode"
    Category = "AI"
    SubCategory = "Image Generation"
    Device = "GPU"
    Model = "sd_1.5_square_fp8"
    PerformanceMode = "best performance"
    Iterations = 5
    Temperature = 60
    ResultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD4003"
    
    TestCMD = {
        try {
            # Set proxy environment variables
            $env:http_proxy = "http://proxy-us.intel.com:912"
            $env:https_proxy = "http://proxy-us.intel.com:912"
            $env:HTTP_PROXY = "http://proxy-us.intel.com:912"
            $env:HTTPS_PROXY = "http://proxy-us.intel.com:912"
            Write-Host "Proxy set to $($env:http_proxy)" -ForegroundColor Cyan
            
            # Navigate to working directory
            Push-Location "C:\Users\Public\gimp"
            
            # Ensure result directory exists
            $resultDir = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD4003"
            if (-not (Test-Path $resultDir)) {
                New-Item -ItemType Directory -Path $resultDir -Force | Out-Null
            }
            
            # Get timestamp for output file
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $outputFile = "$resultDir\GLD4003_CMD_KingsScore_ClientAI_GPU_SD_$timestamp.txt"
            
            # Write-Host "Starting GPU Stable Diffusion 1.5 FP8 (best performance)..." -ForegroundColor Green
            # Write-Host "Working Directory: $(Get-Location)" -ForegroundColor Yellow
            # Write-Host "Output File: $outputFile" -ForegroundColor Yellow
            
            # Execute the Python benchmark with output capture
            $process = Start-Process -FilePath "gimpenv3\Scripts\python.exe" `
                -ArgumentList "GIMP-ML-OV\testscases\StableDiffusion\stable_diffusion_engine_tc.py -m sd_1.5_square_fp8 -pm `"best performance`" -n 5" `
                -NoNewWindow `
                -Wait `
                -PassThru `
                -RedirectStandardOutput $outputFile `
                -RedirectStandardError "$resultDir\GLD4003_error_$timestamp.txt"
            
            # # Display the output
            # if (Test-Path $outputFile) {
            #     Write-Host "`n=== Test Output ===" -ForegroundColor Cyan
            #     Get-Content $outputFile | Tee-Object -FilePath $outputFile
            #     Write-Host "===================`n" -ForegroundColor Cyan
            # }
            
            # # Check for errors
            # $errorFile = "$resultDir\GLD4003_error_$timestamp.txt"
            # if (Test-Path $errorFile) {
            #     $errorContent = Get-Content $errorFile -Raw
            #     if ($errorContent.Trim().Length -gt 0) {
            #         Write-Host "Errors detected:" -ForegroundColor Red
            #         Write-Host $errorContent -ForegroundColor Red
            #     }
            # }
            
            # if ($process.ExitCode -ne 0) {
            #     Write-Host "Test completed with exit code: $($process.ExitCode)" -ForegroundColor Yellow
            # } else {
            #     Write-Host "Test completed successfully!" -ForegroundColor Green
            # }
            
            return $process.ExitCode
        }
        catch {
            Write-Host "Error during test execution: $_" -ForegroundColor Red
            throw
        }
        finally {
            # Return to original directory
            Pop-Location
        }
    }
}
