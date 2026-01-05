# ----------------------------------------------------------------------------------
# Universal Test Wrapper with Monitoring Support
# Accepts test case ID and monitoring tool parameters
# Usage: .\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 900 -RunTime 0
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
    Universal test wrapper for Kings River Benchmark Test Scripts with monitoring support

.DESCRIPTION
    This script loads and executes benchmark tests based on TestID parameter.
    Supports various monitoring tools: SoCWatch, PowerMeter, TypePerf, EMON, PresentMon, WLC, etc.

.PARAMETER TestID
    The test case ID to execute (e.g., GLD-1015, GLD-1014, GLD-1001)

.PARAMETER SoCWatch
    Enable SoCWatch monitoring

.PARAMETER PowerMeter
    Enable PowerMeter (SystemMeter) monitoring

.PARAMETER TypePerf_TP
    Enable TypePerf with full counter set

.PARAMETER TypePerf_SC
    Enable TypePerf with subset counters

.PARAMETER EMON
    Enable EMON EDP (Event Data Processing) monitoring

.PARAMETER EMON_P_Core
    Enable EMON P-Core monitoring

.PARAMETER EMON_E_Core
    Enable EMON E-Core monitoring

.PARAMETER EMON_P_Core_Cache
    Enable EMON P-Core cache monitoring

.PARAMETER EMON_E_Core_Cache
    Enable EMON E-Core cache monitoring

.PARAMETER PresentMon
    Enable PresentMon GPU monitoring

.PARAMETER WLC
    Enable WLC (IPF) profiling

.PARAMETER PerfMon_PS
    Enable VTune Performance Snapshot

.PARAMETER PerfMon_UArch
    Enable VTune Microarchitecture Exploration

.PARAMETER PerfMon_NPU
    Enable VTune NPU monitoring

.PARAMETER PowerGadget
    Enable Intel Power Gadget

.PARAMETER Thermal
    Enable PTAT thermal monitoring

.PARAMETER OSPerf
    Enable OS Performance (xperf + typeperf)

.PARAMETER JWorkload
    Run just the workload without monitoring

.PARAMETER WaitTime
    Wait time before starting monitoring (in seconds)

.PARAMETER RunTime
    Monitoring runtime (in seconds). 0 = wait for test completion

.PARAMETER DisplayConfig
    Display test configuration before execution

.PARAMETER Help
    Display this help information

.EXAMPLE
    .\RunTest.ps1 -TestID GLD-1015
    Runs GLD-1015 without monitoring

.EXAMPLE
    .\RunTest.ps1 -TestID GLD-1001 -SoCWatch -WaitTime 900 -RunTime 0
    Runs GLD-1001 with SoCWatch, 900s wait, monitor until completion

.EXAMPLE
    .\RunTest.ps1 -TestID GLD-1015 -PowerMeter -WaitTime 30
    Runs GLD-1015 with PowerMeter monitoring, 30s wait

.EXAMPLE
    .\RunTest.ps1 -TestID GLD-1014 -TypePerf_TP -DisplayConfig
    Runs GLD-1014 with TypePerf and shows config first

.EXAMPLE
    .\RunTest.ps1 -TestID GLD-1015 -EMON
    Runs GLD-1015 with EMON monitoring

.NOTES
    File Name      : RunTest.ps1
    Prerequisite   : TestRunner.ps1 and corresponding .config.ps1 files
    Created        : 2025-12-17
    Version        : 2.0
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$TestID,
    
    # Monitoring tool switches
    [Parameter(Mandatory=$false)]
    [switch]$SoCWatch,
    
    [Parameter(Mandatory=$false)]
    [switch]$PowerMeter,
    
    [Parameter(Mandatory=$false)]
    [switch]$TypePerf_TP,
    
    [Parameter(Mandatory=$false)]
    [switch]$TypePerf_SC,
    
    [Parameter(Mandatory=$false)]
    [switch]$EMON,
    
    [Parameter(Mandatory=$false)]
    [switch]$EMON_P_Core,
    
    [Parameter(Mandatory=$false)]
    [switch]$EMON_E_Core,
    
    [Parameter(Mandatory=$false)]
    [switch]$EMON_P_Core_Cache,
    
    [Parameter(Mandatory=$false)]
    [switch]$EMON_E_Core_Cache,
    
    [Parameter(Mandatory=$false)]
    [switch]$EMON_EDP,
    
    [Parameter(Mandatory=$false)]
    [switch]$PresentMon,
    
    [Parameter(Mandatory=$false)]
    [switch]$WLC,
    
    [Parameter(Mandatory=$false)]
    [switch]$PerfMon_PS,
    
    [Parameter(Mandatory=$false)]
    [switch]$PerfMon_UArch,
    
    [Parameter(Mandatory=$false)]
    [switch]$PerfMon_NPU,
    
    [Parameter(Mandatory=$false)]
    [switch]$PowerGadget,
    
    [Parameter(Mandatory=$false)]
    [switch]$Thermal,
    
    [Parameter(Mandatory=$false)]
    [switch]$OSPerf,
    
    [Parameter(Mandatory=$false)]
    [switch]$JWorkload,
    
    # Timing parameters
    [Parameter(Mandatory=$false)]
    [int]$WaitTime = -1,
    
    [Parameter(Mandatory=$false)]
    [int]$RunTime = -1,
    
    # Display options
    [Parameter(Mandatory=$false)]
    [switch]$DisplayConfig,
    
    [Parameter(Mandatory=$false)]
    [Alias("h")]
    [switch]$Help
)

# Function to display help
function Show-Help {
    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "  Kings River Benchmark Test Scripts - Universal Wrapper v2.0" -ForegroundColor Cyan
    Write-Host "================================================================`n" -ForegroundColor Cyan
    
    Write-Host "DESCRIPTION:" -ForegroundColor Yellow
    Write-Host "  Universal test wrapper with monitoring tool support"
    Write-Host "  Supports: SoCWatch, PowerMeter, TypePerf, EMON, PresentMon, WLC, and more`n"
    
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\RunTest.ps1 -TestID <TestID> [MonitoringOptions] [TimingOptions]"
    Write-Host "  .\RunTest.ps1 -Help`n"
    
    Write-Host "MONITORING OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -SoCWatch             Enable SoCWatch monitoring"
    Write-Host "  -PowerMeter           Enable SystemMeter power monitoring"
    Write-Host "  -TypePerf_TP          Enable TypePerf (full counters)"
    Write-Host "  -TypePerf_SC          Enable TypePerf (subset counters)"
    Write-Host "  -EMON                 Enable EMON EDP monitoring (recommended)"
    Write-Host "  -EMON_P_Core          Enable EMON P-Core monitoring"
    Write-Host "  -EMON_E_Core          Enable EMON E-Core monitoring"
    Write-Host "  -EMON_P_Core_Cache    Enable EMON P-Core cache monitoring"
    Write-Host "  -EMON_E_Core_Cache    Enable EMON E-Core cache monitoring"
    Write-Host "  -PresentMon           Enable PresentMon GPU monitoring"
    Write-Host "  -WLC                  Enable WLC (IPF) profiling"
    Write-Host "  -PerfMon_PS           Enable VTune Performance Snapshot"
    Write-Host "  -PerfMon_UArch        Enable VTune Microarchitecture Exploration"
    Write-Host "  -PerfMon_NPU          Enable VTune NPU monitoring"
    Write-Host "  -PowerGadget          Enable Intel Power Gadget"
    Write-Host "  -Thermal              Enable PTAT thermal monitoring"
    Write-Host "  -OSPerf               Enable OS Performance (xperf + typeperf)"
    Write-Host "  -JWorkload            Run workload only (no monitoring)`n"
    
    Write-Host "TIMING OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -WaitTime <seconds>   Wait before starting monitoring"
    Write-Host "  -RunTime <seconds>    Monitoring duration (0=until completion)`n"
    
    Write-Host "OTHER OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -DisplayConfig        Display test configuration before running"
    Write-Host "  -Help, -h             Display this help information`n"
    
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  # Run test without monitoring"
    Write-Host "  .\RunTest.ps1 -TestID GLD-1015`n"
    
    Write-Host "  # Run with SoCWatch, 900s wait, monitor until completion"
    Write-Host "  .\RunTest.ps1 -TestID GLD-1001 -SoCWatch -WaitTime 900 -RunTime 0`n"
    
    Write-Host "  # Run with PowerMeter, 30s wait"
    Write-Host "  .\RunTest.ps1 -TestID GLD-1015 -PowerMeter -WaitTime 30`n"
    
    Write-Host "  # Run with TypePerf and display config"
    Write-Host "  .\RunTest.ps1 -TestID GLD-1014 -TypePerf_TP -DisplayConfig`n"
    
    Write-Host "  # Run with EMON monitoring"
    Write-Host "  .\RunTest.ps1 -TestID GLD-1015 -EMON`n"
    
    Write-Host "  # Run with multiple monitors (priority applies)"
    Write-Host "  .\RunTest.ps1 -TestID GLD-1015 -SoCWatch -EMON -PowerMeter`n"
    
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

# Override config with monitoring parameters if specified
if ($SoCWatch) {
    $config['EnableSoCWatch'] = $true
    if ($WaitTime -ge 0) { $config['SoCWatchWaitTime'] = $WaitTime }
    if ($RunTime -ge 0) { $config['SoCWatchRunTime'] = $RunTime }
}

if ($PowerMeter) {
    $config['EnablePowerMeter'] = $true
    if ($WaitTime -ge 0) { $config['PowerMeterWaitTime'] = $WaitTime }
    if ($RunTime -ge 0) { $config['PowerMeterRunTime'] = $RunTime }
}

if ($TypePerf_TP) {
    $config['EnableTypePerfTP'] = $true
    if ($WaitTime -ge 0) { $config['TypePerfWaitTime'] = $WaitTime }
}

if ($TypePerf_SC) {
    $config['EnableTypePerfSC'] = $true
    if ($WaitTime -ge 0) { $config['TypePerfWaitTime'] = $WaitTime }
}

# EMON switches
if ($EMON) { $config['EnableEMON_EDP'] = $true }
if ($EMON_P_Core) { $config['EnableEMON_P_Core'] = $true }
if ($EMON_E_Core) { $config['EnableEMON_E_Core'] = $true }
if ($EMON_P_Core_Cache) { $config['EnableEMON_P_Core_Cache'] = $true }
if ($EMON_E_Core_Cache) { $config['EnableEMON_E_Core_Cache'] = $true }
if ($EMON_EDP) { $config['EnableEMON_EDP'] = $true }

# Other monitoring switches
if ($PresentMon) { $config['EnablePresentMon'] = $true }
if ($WLC) { $config['EnableWLC'] = $true }
if ($PerfMon_PS) { $config['EnablePerfMon_PS'] = $true }
if ($PerfMon_UArch) { $config['EnablePerfMon_UArch'] = $true }
if ($PerfMon_NPU) { $config['EnablePerfMon_NPU'] = $true }
if ($PowerGadget) { $config['EnablePowerGadget'] = $true }
if ($Thermal) { $config['EnableThermal'] = $true }
if ($OSPerf) { $config['EnableOSPerf'] = $true }
if ($JWorkload) { $config['JWorkloadOnly'] = $true }

# Display active monitoring tools
$activeMonitors = @()
if ($SoCWatch) { $activeMonitors += "SoCWatch" }
if ($PowerMeter) { $activeMonitors += "PowerMeter" }
if ($TypePerf_TP) { $activeMonitors += "TypePerf_TP" }
if ($TypePerf_SC) { $activeMonitors += "TypePerf_SC" }
if ($EMON -or $EMON_EDP) { $activeMonitors += "EMON" }
if ($EMON_P_Core) { $activeMonitors += "EMON_P_Core" }
if ($EMON_E_Core) { $activeMonitors += "EMON_E_Core" }
if ($PresentMon) { $activeMonitors += "PresentMon" }
if ($WLC) { $activeMonitors += "WLC" }
if ($PerfMon_PS) { $activeMonitors += "VTune_PS" }
if ($PerfMon_UArch) { $activeMonitors += "VTune_UArch" }
if ($PerfMon_NPU) { $activeMonitors += "VTune_NPU" }
if ($PowerGadget) { $activeMonitors += "PowerGadget" }
if ($Thermal) { $activeMonitors += "Thermal" }
if ($OSPerf) { $activeMonitors += "OSPerf" }

if ($activeMonitors.Count -gt 0) {
    Write-Host "`nActive Monitoring Tools: " -NoNewline -ForegroundColor Cyan
    Write-Host ($activeMonitors -join ", ") -ForegroundColor Yellow
}

if ($WaitTime -ge 0 -or $RunTime -ge 0) {
    Write-Host "Timing Parameters: " -NoNewline -ForegroundColor Cyan
    if ($WaitTime -ge 0) { Write-Host "WaitTime=$($WaitTime)s " -NoNewline -ForegroundColor Yellow }
    if ($RunTime -ge 0) { Write-Host "RunTime=$($RunTime)s" -NoNewline -ForegroundColor Yellow }
    Write-Host ""
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
