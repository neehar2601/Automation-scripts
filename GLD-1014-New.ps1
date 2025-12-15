# ----------------------------------------------------------------------------------
# Kings River Benchmark Test Script
# Test Name: 3DMark Wildlife extreme unlimited
# Created by: Neehara Govinda N (Converted to PowerShell)
# Modified by: Neehara Govinda N
# Last Modified date: 11-12-2025
# ----------------------------------------------------------------------------------


# Load the test runner (base class with all methods)
. "$PSScriptRoot\TestRunner.ps1"

# Load test configuration
$config = @{
    # Required parameters
    TestID = "GLD1014"
    TestName = "3DMark TimeSpy"
    TestSubDomain = "GFX-DX12"
    TestCMD = "3DMarkCmd.exe --definition=timespy.3dmdef --export=C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1014\GLD1014_KingsScore_Benchmark_TimeSpyPerformanceGraphicsScore.xml"
    
    # Optional overrides
    # Temperature = 85
    # WaitTime = 15
    # Repeats = 2
}

# Create test instance with config
$test = [BenchmarkTest]::new($config)

# Display configuration (optional)
# $test.DisplayConfig()

# Run the test
$result = $test.Run()

# Exit with appropriate code
if ($result.Status -eq "Success") {
    exit 0
} else {
    exit 1
}
