# ----------------------------------------------------------------------------------
# Kings River Benchmark Test Script
# Test Name: Busy Idle Consumer
# Created by: Neehara Govinda N (Converted to PowerShell)
# Modified by: Neehara Govinda N
# Last Modified date: 15-12-2025
# ----------------------------------------------------------------------------------

# Load the test runner (base class with all methods)
. "$PSScriptRoot\TestRunner.ps1"

# Test Configuration (inline)
$config = @{
    # Required parameters
    TestType = "Power"
    TestID = "GLD1001"
    TestName = "Busy Idle Consumer"
    TestSubDomain = "CPU"
    
    # Override defaults
    Temperature = 25          # Default is 83
    RecordTime = 180          # Default is 0
    WaitTime = 900            # Default is 10 (15 minutes)
    
    # Commands
    TestPrestepCMD = "& 'C:\KSR_Package\KSR\Test_Run_KR\GLD\script\GLD1001_pre.exe'"
    TestCMD = "& 'C:\KSR_Package\KSR\Test_Run_KR\GLD\script\GLD1001_CMD.bat'"
    TestPoststepCMD = "& 'C:\KSR_Package\KSR\Test_Run_KR\postkill.bat'"
    
    # Result path (auto-generated if not specified)
    ResultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1001"
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