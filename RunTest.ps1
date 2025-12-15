# ----------------------------------------------------------------------------------
# Universal Test Wrapper
# Accepts test case ID as parameter and runs the test
# Usage: .\RunTest.ps1 -TestID GLD1015
# ----------------------------------------------------------------------------------

param(
    [Parameter(Mandatory=$true)]
    [string]$TestID,
    
    [Parameter(Mandatory=$false)]
    [switch]$DisplayConfig
)

# Validate TestID parameter
if ([string]::IsNullOrWhiteSpace($TestID)) {
    Write-Host "Error: TestID parameter is required" -ForegroundColor Red
    Write-Host "Usage: .\RunTest.ps1 -TestID <TestID>" -ForegroundColor Yellow
    Write-Host "Example: .\RunTest.ps1 -TestID GLD1015" -ForegroundColor Yellow
    exit 1
}

# Load the test runner (base class with all methods)
$testRunnerPath = Join-Path $PSScriptRoot "TestRunner.ps1"
if (-not (Test-Path $testRunnerPath)) {
    Write-Host "Error: TestRunner.ps1 not found at: $testRunnerPath" -ForegroundColor Red
    exit 1
}
. $testRunnerPath

# Build config file path
$configFileName = "$TestID.config.ps1"
$configFilePath = Join-Path $PSScriptRoot $configFileName

# Check if config file exists
if (-not (Test-Path $configFilePath)) {
    Write-Host "Error: Config file not found: $configFilePath" -ForegroundColor Red
    Write-Host "Available config files:" -ForegroundColor Yellow
    Get-ChildItem -Path $PSScriptRoot -Filter "*.config.ps1" | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Cyan
    }
    exit 1
}

# Load test configuration
Write-Host "Loading config: $configFileName" -ForegroundColor Cyan
try {
    $config = . $configFilePath
}
catch {
    Write-Host "Error loading config file: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Validate config
if ($null -eq $config -or $config.GetType().Name -ne 'Hashtable') {
    Write-Host "Error: Config file must return a hashtable" -ForegroundColor Red
    exit 1
}

# Create test instance with config
try {
    $test = [BenchmarkTest]::new($config)
}
catch {
    Write-Host "Error creating test instance: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Display configuration if requested
if ($DisplayConfig) {
    $test.DisplayConfig()
}

# Run the test
Write-Host "`nStarting test execution: $TestID" -ForegroundColor Magenta
Write-Host "================================================================`n" -ForegroundColor Magenta

$result = $test.Run()

# Display results summary
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                     Test Summary                               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "  Test ID     : $($result.TestID)" -ForegroundColor White
Write-Host "  Test Name   : $($result.TestName)" -ForegroundColor White
Write-Host "  Status      : " -NoNewline -ForegroundColor White
if ($result.Status -eq "Success") {
    Write-Host "$($result.Status)" -ForegroundColor Green
} else {
    Write-Host "$($result.Status)" -ForegroundColor Red
}
Write-Host "  Duration    : $([math]::Round($result.Duration, 2)) seconds" -ForegroundColor White
Write-Host "  Start Time  : $($result.StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "  End Time    : $($result.EndTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "  Result Path : $($result.ResultPath)" -ForegroundColor White

if ($result.ErrorMessage) {
    Write-Host "  Error       : $($result.ErrorMessage)" -ForegroundColor Red
}

Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Exit with appropriate code
if ($result.Status -eq "Success") {
    Write-Host "✓ Test completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ Test failed!" -ForegroundColor Red
    exit 1
}
