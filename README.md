# Kings River Benchmark Testing Framework

## Overview

The Kings River Benchmark Testing Framework is a modular PowerShell-based automation system designed for comprehensive performance testing and monitoring of hardware platforms. This framework replaces legacy batch scripts with a modern, maintainable architecture that supports multiple monitoring tools and provides real-time test execution visibility.

## Architecture

### Core Components

```
ksr-new/
├── RunTest.ps1              # Universal test wrapper and entry point
├── TestRunner.ps1           # Base class with test lifecycle management
├── GLD-*.config.ps1         # Test configuration files (20+ tests)
├── Monitors/                # Monitoring modules directory
│   ├── SoCWatch.ps1         # SoC monitoring (power, temp, CPU, GPU, NPU)
│   ├── SoCWatchHelper.ps1   # SoCWatch control helper
│   ├── EMON.ps1             # Intel EMON performance monitoring
│   ├── EMONHelper.ps1       # EMON control helper
│   ├── PowerMeter.ps1       # SystemMeter power monitoring
│   ├── PowerMeterHelper.ps1 # PowerMeter control helper
│   ├── TypePerf.ps1         # Windows performance counters
│   ├── TypePerfHelper.ps1   # TypePerf control helper
│   ├── PresentMon.ps1       # GPU frame monitoring
│   └── WLC.ps1              # WLC/IPF profiling
└── Documentation/
    ├── FRAMEWORK-SUMMARY.md  # Framework overview
    ├── README-MONITORING.md  # Monitoring guide
    ├── NEW-EXECUTION-FLOW.md # Execution flow details
    └── MIGRATION-GUIDE.md    # Batch to PowerShell guide
```

### Test Categories

Tests are organized by domain and ID:

- **GLD-1xxx**: General Performance Tests (Gaming, Graphics, CPU)
- **GLD-2xxx**: Procyon Office Productivity Tests
- **GLD-3xxx**: Specialized Performance Tests
- **GLD-4xxx**: Application-specific Tests
- **GLD-8xxx**: Memory and System Benchmarks

## Execution Flow

The framework implements a sequential execution model for clarity and control:

```
┌────────────────────────────────────────────────────────┐
│ 1. WAIT FOR STABILIZATION                              │
│    - Default: 3 seconds                                │
│    - Configurable via -WaitTime parameter              │
├────────────────────────────────────────────────────────┤
│ 2. START MONITORING (Separate Window)                  │
│    - SoCWatch: Visible window                          │
│    - EMON: Minimized window                            │
│    - TypePerf: Hidden window                           │
│    - PresentMon: Minimized window                      │
│    - PowerMeter: Background process                    │
├────────────────────────────────────────────────────────┤
│ 3. RUN TEST IN MAIN WINDOW                             │
│    - All output visible in console                     │
│    - Real-time progress monitoring                     │
│    - Direct execution (no background jobs)             │
├────────────────────────────────────────────────────────┤
│ 4. STOP MONITORING                                     │
│    - Wait 2-3 seconds for final data capture           │
│    - Graceful shutdown of monitoring tools             │
├────────────────────────────────────────────────────────┤
│ 5. RETRIEVE & PRINT RESULTS                            │
│    - Summary of monitoring data                        │
│    - Test completion status                            │
│    - Duration and timestamps                           │
└────────────────────────────────────────────────────────┘
```

## Key Features

### ✅ Modular Architecture
- Separation of concerns: test logic, configuration, and monitoring
- Easy to extend with new tests and monitoring tools
- Reusable monitoring modules

### ✅ Real-Time Visibility
- All test output displayed in main console
- Sequential execution with clear phases
- Progress monitoring and status updates

### ✅ Comprehensive Monitoring
- 18+ monitoring tools supported
- Flexible tool selection via command-line switches
- Priority-based tool selection (mutual exclusion)

### ✅ Configuration Management
- Test configs as separate files
- Override-only pattern (inherit defaults)
- Easy to maintain and version control

### ✅ Window Management
- Separate windows for monitoring tools
- Main window for test execution
- Customizable window visibility (visible/minimized/hidden)

## Quick Start

### Basic Usage

Run a test without monitoring:
```powershell
.\RunTest.ps1 -TestID GLD-1015
```

Run a test with SoCWatch monitoring:
```powershell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch
```

Run a test with custom timing:
```powershell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 60 -RunTime 120
```

### Monitoring Tools

| Tool | Switch | Purpose | Window | Output |
|------|--------|---------|--------|--------|
| SoCWatch | `-SoCWatch` | SoC monitoring | Visible | CSV + ETL |
| PowerMeter | `-PowerMeter` | Power monitoring | Normal | CSV |
| TypePerf (Full) | `-TypePerf_TP` | Windows counters | Hidden | CSV |
| TypePerf (Subset) | `-TypePerf_SC` | Windows counters | Hidden | CSV |
| EMON EDP | `-EMON` | Event data | Minimized | DAT |
| EMON P-Core | `-EMON_P_Core` | P-Core metrics | Minimized | TXT |
| EMON E-Core | `-EMON_E_Core` | E-Core metrics | Minimized | TXT |
| EMON P-Core Cache | `-EMON_P_Core_Cache` | Cache metrics | Minimized | TXT |
| EMON E-Core Cache | `-EMON_E_Core_Cache` | Cache metrics | Minimized | TXT |
| PresentMon | `-PresentMon` | GPU monitoring | Hidden | CSV |
| WLC/IPF | `-WLC` | Profiling | Command | CSV |

### Examples

**3DMark TimeSpy with SoCWatch:**
```powershell
.\RunTest.ps1 -TestID GLD-1014 -SoCWatch -WaitTime 900 -RunTime 0
```

**CineBench with EMON P-Core monitoring:**
```powershell
.\RunTest.ps1 -TestID GLD-1016 -EMON_P_Core
```

**Procyon Office with PowerMeter:**
```powershell
.\RunTest.ps1 -TestID GLD-2001 -PowerMeter
```

## Test Configuration

### Configuration File Structure

Each test has a dedicated `.config.ps1` file (e.g., `GLD-1014.config.ps1`):

```powershell
@{
    # Required parameters
    TestID = "GLD1014"
    TestName = "3DMark TimeSpy"
    TestSubDomain = "GFX-DX12"
    TestCMD = "3DMarkCmd.exe --definition=timespy.3dmdef ..."
    
    # Optional overrides (inherit from TestRunner.ps1 defaults)
    # Temperature = 85
    # WaitTime = 15
    # Repeats = 2
}
```

### Available Test Configurations

- **GLD-1001**: General Performance Test
- **GLD-1008**: CPU Performance Test
- **GLD-1009**: Graphics Benchmark
- **GLD-1010**: System Test
- **GLD-1014**: 3DMark TimeSpy
- **GLD-1015**: Performance Benchmark
- **GLD-1016**: CineBench R24 Single Core
- **GLD-2001 - GLD-2007**: Procyon Office Suite
- **GLD-3001 - GLD-3002**: Specialized Tests
- **GLD-4001 - GLD-4003**: Application Tests
- **GLD-8001 - GLD-8006**: Memory Benchmarks

## TestRunner Class

The `TestRunner.ps1` base class provides:

### Properties
- Test identification (TestID, TestName, TestType)
- Test parameters (Temperature, RecordTime, WaitTime, Repeats)
- Monitoring tool flags (Enable*)
- Commands (TestCMD, TestPrestepCMD, TestPoststepCMD)

### Lifecycle Methods
1. **PreTestSetup()** - Initialize test environment
2. **StartMonitoring()** - Launch monitoring tools
3. **RunTest()** - Execute test workload
4. **StopMonitoring()** - Terminate monitoring
5. **PostTestCleanup()** - Clean up and generate reports

## Monitoring Modules

Each monitoring module (`Monitors/*.ps1`) follows a standard pattern:

1. **Start** - Launch monitoring in separate window
2. **Wait** - Stabilization period (optional)
3. **Execute** - Run test in main window
4. **Stop** - Gracefully terminate monitoring
5. **Results** - Retrieve and display results

### Helper Scripts

Some complex monitoring tools have dedicated helper scripts:
- `SoCWatchHelper.ps1` - Window management for SoCWatch
- `EMONHelper.ps1` - EMON control and data collection
- `PowerMeterHelper.ps1` - SystemMeter integration
- `TypePerfHelper.ps1` - TypePerf counter management

## Best Practices

### Running Tests
1. Always specify `-TestID` parameter
2. Use appropriate monitoring tool for test type
3. Set `-WaitTime 900 -RunTime 0` to wait for test completion
4. Use `-WaitTime` for stabilization period before test

### Creating New Tests
1. Create new `GLD-XXXX.config.ps1` file
2. Define only required parameters and overrides
3. Test without monitoring first
4. Add monitoring as needed

### Monitoring Guidelines
- Only one monitoring tool runs at a time (priority-based)
- SoCWatch has highest priority (most comprehensive)
- Choose tool based on metrics needed
- Use hidden windows for background monitors

## Troubleshooting

### Common Issues

**Test not found:**
```powershell
# Ensure config file exists: GLD-XXXX.config.ps1
ls *.config.ps1 | Select-String "GLD-XXXX"
```

**Monitoring tool not starting:**
```powershell
# Check tool paths in monitoring module
# Verify tool is installed and accessible
# Review helper script output
```

**Test output not visible:**
```powershell
# Ensure using latest framework version
# Test runs in main window by design
# Check for errors in console output
```

## Development

### Adding New Tests

1. Create configuration file:
```powershell
# GLD-XXXX.config.ps1
@{
    TestID = "GLDXXXX"
    TestName = "Your Test Name"
    TestSubDomain = "Category"
    TestCMD = "command.exe --args"
}
```

2. Test execution:
```powershell
.\RunTest.ps1 -TestID GLD-XXXX
```

### Adding New Monitoring Tools

1. Create module in `Monitors/` directory
2. Follow standard pattern (Start → Wait → Execute → Stop → Results)
3. Add switch parameter to `RunTest.ps1`
4. Update monitoring priority if needed

## Version History

- **v2.1** - Sequential execution with main window test output
- **v2.0** - Modular monitoring architecture
- **v1.0** - Initial PowerShell framework (migrated from batch)

## Documentation

For detailed information, see:

- **[FRAMEWORK-SUMMARY.md](FRAMEWORK-SUMMARY.md)** - Complete framework overview
- **[README-MONITORING.md](README-MONITORING.md)** - Monitoring tool guide
- **[NEW-EXECUTION-FLOW.md](NEW-EXECUTION-FLOW.md)** - Execution flow details
- **[MIGRATION-GUIDE.md](MIGRATION-GUIDE.md)** - Batch to PowerShell migration
- **[UPDATE-SUMMARY-v2.1.md](UPDATE-SUMMARY-v2.1.md)** - v2.1 update notes

## Requirements

- Windows PowerShell 5.1 or later
- Benchmark tools installed in appropriate locations
- Monitoring tools (SoCWatch, EMON, etc.) as needed
- Administrator privileges for some monitoring tools

## License

Intel Corporation Internal Use

## Contributing

Contact the Kings River benchmark team for contribution guidelines.

---

**Repository**: ksr-new  
**Branch**: flow3  
**Last Updated**: January 2026
