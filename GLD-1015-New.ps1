# ----------------------------------------------------------------------------------
# Kings River Benchmark Test Script
# Test Name: 3DMark Wildlife extreme unlimited
# Created by: Neehara Govinda N (Converted to PowerShell)
# Modified by: Neehara Govinda N
# Last Modified date: 11-12-2025
# ----------------------------------------------------------------------------------

# Load the test runner (base class with all methods)
. "$PSScriptRoot\TestRunner.ps1"

# Test Configuration (inline)
$config = @{
    # Required parameters
    TestID = "GLD1015"
    TestName = "3DMark Wildlife extreme unlimited"
    TestSubDomain = "GFX-DX12"
    TestCMD = "3DMarkCmd.exe --definition=wildlife_extreme.3dmdef --export=C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1015\GLD1015_KingsScore_Benchmark_WildLifeExtremeGraphicsScore.xml"
    
    # Optional overrides (uncomment to override defaults)
    # Temperature = 85        # Default is 83
    # WaitTime = 15          # Default is 10
    # Repeats = 3            # Default is 1
    # TestDomain = "Custom"  # Default is "Golden"
}

# Create test instance with config
$test = [BenchmarkTest]::new($config)

# Optional: Display configuration for verification
# $test.DisplayConfig()

# Run the test
$result = $test.Run()

# Display results summary
Write-Host "`n========== Test Summary ==========" -ForegroundColor Cyan
Write-Host "Test ID    : $($result.TestID)" -ForegroundColor White
Write-Host "Test Name  : $($result.TestName)" -ForegroundColor White
Write-Host "Status     : $($result.Status)" -ForegroundColor $(if ($result.Status -eq "Success") { "Green" } else { "Red" })
Write-Host "Duration   : $([math]::Round($result.Duration, 2)) seconds" -ForegroundColor White
Write-Host "Result Path: $($result.ResultPath)" -ForegroundColor White
if ($result.ErrorMessage) {
    Write-Host "Error      : $($result.ErrorMessage)" -ForegroundColor Red
}
Write-Host "==================================`n" -ForegroundColor Cyan

# Exit with appropriate code
if ($result.Status -eq "Success") {
    exit 0
} else {
    exit 1
}
