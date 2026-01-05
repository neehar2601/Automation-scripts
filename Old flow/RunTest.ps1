# ----------------------------------------------------------------------------------
# Universal Test Wrapper
# Accepts test case ID as parameter and runs the test
# Usage: .\RunTest.ps1 -TestID GLD1015
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
    Universal test wrapper for Kings River Benchmark Test Scripts

.DESCRIPTION
    This script loads and executes benchmark tests based on TestID parameter.
    It automatically loads the corresponding config file and uses TestRunner.ps1
    for execution.

.PARAMETER TestID
    The test case ID to execute (e.g., GLD1015, GLD1014, GLD1001)
    Required parameter.

.PARAMETER DisplayConfig
    Optional switch to display test configuration before execution.

.PARAMETER Help
    Display this help information.

.EXAMPLE
    .\RunTest.ps1 -TestID GLD1015
    Runs the GLD1015 test case

.EXAMPLE
    .\RunTest.ps1 -TestID GLD1014 -DisplayConfig
    Runs the GLD1014 test case and displays configuration first

.EXAMPLE
    .\RunTest.ps1 -Help
    Displays help information

.NOTES
    File Name      : RunTest.ps1
    Prerequisite   : TestRunner.ps1 and corresponding .config.ps1 files
    Created        : 2025-12-15
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$TestID,
    
    [Parameter(Mandatory=$false)]
    [switch]$DisplayConfig,
    
    [Parameter(Mandatory=$false)]
    [Alias("h")]
    [switch]$Help
)

# Function to display help
function Show-Help {
    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "  Kings River Benchmark Test Scripts - Universal Wrapper" -ForegroundColor Cyan
    Write-Host "================================================================`n" -ForegroundColor Cyan
    
    Write-Host "DESCRIPTION:" -ForegroundColor Yellow
    Write-Host "  Universal test wrapper that loads and executes benchmark tests"
    Write-Host "  based on TestID parameter.`n"
    
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\RunTest.ps1 -TestID <TestID> [-DisplayConfig]"
    Write-Host "  .\RunTest.ps1 -Help`n"
    
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -TestID <string>      Test case ID to execute (Required)"
    Write-Host "                        Examples: GLD1015, GLD1014, GLD1001"
    Write-Host ""
    Write-Host "  -DisplayConfig        Display test configuration before running (Optional)"
    Write-Host ""
    Write-Host "  -Help, -h             Display this help information`n"
    
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\RunTest.ps1 -TestID GLD-1015"
    Write-Host "      Runs the GL-1015 test case`n"

    Write-Host "  .\RunTest.ps1 -TestID GL-1014 -DisplayConfig"
    Write-Host "      Runs GL-1014 and displays configuration first`n"

    Write-Host "  .\RunTest.ps1 -Help"
    Write-Host "      Shows this help information`n"
    
    Write-Host "AVAILABLE TESTS:" -ForegroundColor Yellow
    $configFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.config.ps1" -ErrorAction SilentlyContinue
    if ($configFiles) {
        foreach ($file in $configFiles) {
            $testId = $file.Name -replace '\.config\.ps1$', ''
            Write-Host "  - $testId" -ForegroundColor Cyan
        }
    } else {
        Write-Host "  (No config files found)" -ForegroundColor Gray
    }
    
    Write-Host "`n================================================================`n" -ForegroundColor Cyan
}

# Show help if requested or if no TestID provided
if ($Help -or [string]::IsNullOrWhiteSpace($TestID)) {
    Show-Help
    exit 0
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
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "                     Test Summary                               " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
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

Write-Host "================================================================`n" -ForegroundColor Cyan

# Exit with appropriate code
if ($result.Status -eq "Success") {
    Write-Host " Test completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host " Test failed!" -ForegroundColor Red
    exit 1
}
