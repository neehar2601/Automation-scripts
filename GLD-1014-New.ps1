# ----------------------------------------------------------------------------------
# GLD-1014 Wrapper Script
# Loads TestRunner and config, executes the test
# ----------------------------------------------------------------------------------

# Load the test runner (base class with all methods)
. "$PSScriptRoot\TestRunner.ps1"

# Load test configuration
$config = . "$PSScriptRoot\GLD-1014.config.ps1"

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
