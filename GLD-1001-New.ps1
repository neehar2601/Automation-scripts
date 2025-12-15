# ----------------------------------------------------------------------------------
# GLD-1001 Wrapper Script
# Test Name: Busy Idle Consumer
# Loads TestRunner and config, executes the test
# ----------------------------------------------------------------------------------

# Load the test runner (base class with all methods)
. "$PSScriptRoot\TestRunner.ps1"

# Load test configuration
$config = . "$PSScriptRoot\GLD-1001.config.ps1"

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