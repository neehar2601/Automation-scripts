# Kings River Benchmark Test Framework

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![License](https://img.shields.io/badge/License-Intel-green.svg)]()

## 📋 Overview

The **Kings River Benchmark Test Framework** is a modular PowerShell-based testing framework designed for running performance benchmarks with integrated monitoring capabilities. The framework supports multiple monitoring tools including SoCWatch, EMON, PowerMeter, TypePerf, PresentMon, and WLC/IPF.

**Design Philosophy:** Ultra-simplified architecture with direct script calls - no wrappers, no abstraction layers.

---

## 🚀 Quick Start

### Basic Usage
```powershell
# Run a test without monitoring
.\RunTest.ps1 -TestID "GLD-1015"

# Run a test with SoCWatch monitoring
.\RunTest.ps1 -TestID "GLD-1015" -SoCWatch -WaitTime 30

# Run a test with EMON monitoring
.\RunTest.ps1 -TestID "GLD-1014" -EMON -WaitTime 60
```

### Command-Line Switches
| Switch | Description |
|--------|-------------|
| `-TestID` | Test case ID (e.g., GLD-1015, GLD-2001) |
| `-SoCWatch` | Enable SoCWatch monitoring |
| `-PowerMeter` | Enable PowerMeter monitoring |
| `-TypePerf_TP` | Enable TypePerf with full counter set |
| `-TypePerf_SC` | Enable TypePerf with subset counters |
| `-EMON` | Enable EMON EDP monitoring |
| `-EMON_P_Core` | Enable EMON P-Core monitoring |
| `-EMON_E_Core` | Enable EMON E-Core monitoring |
| `-EMON_P_Core_Cache` | Enable EMON P-Core cache monitoring |
| `-EMON_E_Core_Cache` | Enable EMON E-Core cache monitoring |
| `-PresentMon` | Enable PresentMon GPU monitoring |
| `-WLC` | Enable WLC/IPF profiling |
| `-WaitTime` | Stabilization wait time in seconds (default: 10) |

---

## 📁 Repository Structure

```
ksr-new/
├── RunTest.ps1                     # Entry point - Universal test wrapper
├── TestRunner.ps1                  # Main orchestrator - Test execution engine
├── GLD-*.config.ps1                # Test configuration files (26+ tests)
│
├── Monitors/                       # Monitoring tools directory
│   ├── start_socwatch.ps1          # SoCWatch start logic
│   ├── stop_socwatch.ps1           # SoCWatch stop logic
│   ├── start_power.ps1             # PowerMeter start logic
│   ├── stop_power.ps1              # PowerMeter stop logic
│   ├── start_typeperf.ps1          # TypePerf start logic
│   ├── stop_typeperf.ps1           # TypePerf stop logic
│   ├── start_emon.ps1              # EMON start logic
│   ├── stop_emon.ps1               # EMON stop logic
│   ├── start_presentmon.ps1        # PresentMon start logic
│   ├── stop_presentmon.ps1         # PresentMon stop logic
│   ├── start_wpr.ps1               # WPR start logic
│   ├── stop_wpr.ps1                # WPR stop logic
│   ├── SoCWatch.ps1                # SoCWatch monitoring module
│   ├── SoCWatchHelper.ps1          # SoCWatch helper functions
│   ├── EMON.ps1                    # EMON monitoring module
│   ├── EMONHelper.ps1              # EMON helper functions
│   ├── PowerMeter.ps1              # PowerMeter monitoring module
│   ├── PowerMeterHelper.ps1        # PowerMeter helper functions
│   ├── TypePerf.ps1                # TypePerf monitoring module
│   ├── PresentMon.ps1              # PresentMon monitoring module
│   ├── WLC.ps1                     # WLC/IPF monitoring module
│   ├── typeperf_metrics.txt        # TypePerf counter definitions
│   └── setup.ps1                   # Monitoring setup script
│
└── Documentation/
    ├── ARCHITECTURE.md             # Detailed architecture documentation
    ├── FRAMEWORK-SUMMARY.md        # Framework overview and features
    ├── NEW-EXECUTION-FLOW.md       # Execution flow details
    ├── MIGRATION-GUIDE.md          # Batch to PowerShell migration guide
    └── README-MONITORING.md        # Complete monitoring tools guide
```

---

## 🏗️ Architecture

### Core Components

#### 1. **RunTest.ps1** - Entry Point
- Parses command-line arguments
- Loads test configuration files (`GLD-*.config.ps1`)
- Creates BenchmarkTest instance
- Passes control to TestRunner

#### 2. **TestRunner.ps1** - Test Execution Engine
- Implements test lifecycle: PreStep → Test → PostStep
- Manages monitoring tool integration
- Direct script invocation using PowerShell `&` operator
- No intermediate layers or wrappers

#### 3. **Test Configuration Files** (`GLD-*.config.ps1`)
- Define test-specific parameters
- Include test commands, wait times, and settings
- Hashtable-based configuration format

#### 4. **Monitoring Scripts** (`Monitors/`)
- Direct start/stop scripts for each monitoring tool
- No abstraction layers
- Clean separation of concerns

### Execution Flow

```
┌──────────────────────────────────────────────────────────────┐
│ 1. RunTest.ps1                                               │
│    └─ Parses command-line arguments                          │
│    └─ Loads config file (GLD-*.config.ps1)                   │
│    └─ Creates BenchmarkTest instance                         │
├──────────────────────────────────────────────────────────────┤
│ 2. TestRunner.ps1 → PreStep()                                │
│    └─ Displays test info                                     │
│    └─ Executes TestPrestepCMD if defined                     │
├──────────────────────────────────────────────────────────────┤
│ 3. TestRunner.ps1 → Test()                                   │
│    └─ Determines which monitoring tool to use                │
│    └─ Calls RunWithMonitoring() OR RunNormal()               │
├──────────────────────────────────────────────────────────────┤
│ 4. TestRunner.ps1 → RunWithMonitoring()                      │
│    ├─ & Monitors\start_socwatch.ps1                          │
│    │   └─ Launches socwatch.exe in background                │
│    ├─ Wait for stabilization (WaitTime seconds)              │
│    ├─ Execute TestCMD (Invoke-Expression)                    │
│    ├─ Wait 2 seconds                                         │
│    └─ & Monitors\stop_socwatch.ps1                           │
│        └─ Stops socwatch.exe, saves results                  │
├──────────────────────────────────────────────────────────────┤
│ 5. TestRunner.ps1 → PostStep()                               │
│    └─ Executes TestPoststepCMD if defined                    │
│    └─ Displays completion message                            │
└──────────────────────────────────────────────────────────────┘
```

**Key Principle:** Direct script invocation - TestRunner.ps1 calls monitoring scripts directly using the `&` operator. No function calls, no module loading, no abstraction!

---

## 🎯 How It Works

### Direct Script Invocation

TestRunner.ps1 calls monitoring scripts directly:

```powershell
# Start monitoring
& "$PSScriptRoot\Monitors\start_socwatch.ps1" -LogDirectory $LogDirectory -FileName $FileName

# Wait for stabilization
Start-Sleep -Seconds $WaitTime

# Run test
Invoke-Expression $TestCMD

# Stop monitoring
& "$PSScriptRoot\Monitors\stop_socwatch.ps1" -LogDirectory $LogDirectory -FileName $FileName
```

### Wait Time Logic

**Single WaitTime property controls all timing:**

```powershell
# In config file:
@{
    WaitTime = 60  # Wait 60 seconds after monitoring starts
}

# In TestRunner.ps1:
if ($this.WaitTime -gt 0) {
    Write-Host "Waiting $($this.WaitTime) seconds for stabilization..."
    Start-Sleep -Seconds $this.WaitTime
}
```

**Flow with WaitTime:**
```
Start Script → Wait 60s → Run Test → Stop Script
```

---

## 📊 Supported Monitoring Tools

| # | Tool | Switch | Window Mode | Output Format |
|---|------|--------|-------------|---------------|
| 1 | SoCWatch | `-SoCWatch` | Visible | CSV + ETL |
| 2 | PowerMeter | `-PowerMeter` | Normal | CSV |
| 3 | TypePerf (Full) | `-TypePerf_TP` | Hidden | CSV |
| 4 | TypePerf (Subset) | `-TypePerf_SC` | Hidden | CSV |
| 5 | EMON EDP | `-EMON` | Minimized | DAT |
| 6 | EMON P-Core | `-EMON_P_Core` | Minimized | TXT |
| 7 | EMON E-Core | `-EMON_E_Core` | Minimized | TXT |
| 8 | EMON P-Core Cache | `-EMON_P_Core_Cache` | Minimized | TXT |
| 9 | EMON E-Core Cache | `-EMON_E_Core_Cache` | Minimized | TXT |
| 10 | PresentMon | `-PresentMon` | Hidden | CSV |
| 11 | WLC/IPF | `-WLC` | Command | CSV |
| 12 | WPR | (via scripts) | Normal | ETL |

---

## 💡 Usage Examples

### Example 1: 3DMark with SoCWatch
```powershell
.\RunTest.ps1 -TestID "GLD-1015" -SoCWatch -WaitTime 30

# Flow:
# 1. PreStep (setup)
# 2. Start SoCWatch monitoring
# 3. Wait 30 seconds for stabilization
# 4. Run 3DMark test
# 5. Stop SoCWatch monitoring
# 6. PostStep (cleanup)
```

### Example 2: Edge Browser with TypePerf
```powershell
.\RunTest.ps1 -TestID "GLD-1003" -TypePerf_TP

# Flow:
# 1. PreStep (navigate to test directory)
# 2. Start TypePerf with full counters
# 3. Wait for stabilization
# 4. Run Edge automation test
# 5. Stop TypePerf
# 6. PostStep (return to original directory)
```

### Example 3: Procyon with EMON
```powershell
.\RunTest.ps1 -TestID "GLD-2001" -EMON -WaitTime 60

# Flow:
# 1. PreStep
# 2. Start EMON EDP monitoring
# 3. Wait 60 seconds for system stabilization
# 4. Run Procyon benchmark
# 5. Stop EMON and collect data
# 6. PostStep
```

### Example 4: No Monitoring
```powershell
.\RunTest.ps1 -TestID "GLD-1001"

# Flow:
# 1. PreStep
# 2. Run test directly (no monitoring)
# 3. PostStep
```

---

## 📝 Test Configuration Format

Test configurations are defined in `GLD-*.config.ps1` files using PowerShell hashtables:

```powershell
@{
    TestID = "GLD-1015"
    TestName = "3DMark Time Spy"
    TestCMD = "Start-Process '3DMarkCmd.exe' -ArgumentList '--run=timespy' -Wait"
    TestPrestepCMD = "Write-Host 'Preparing 3DMark...'"
    TestPoststepCMD = "Write-Host 'Test completed'"
    WaitTime = 30
    LogDirectory = "C:\Logs\3DMark"
}
```

### Available Configuration Properties
- `TestID` - Unique test identifier
- `TestName` - Human-readable test name
- `TestCMD` - Command to execute the test
- `TestPrestepCMD` - Setup commands (optional)
- `TestPoststepCMD` - Cleanup commands (optional)
- `WaitTime` - Stabilization wait time in seconds
- `LogDirectory` - Output directory for test results

---

## 🔧 Available Test Suites

### Gaming & Graphics (GLD-1xxx)
- `GLD-1001` - WebXPRT 4
- `GLD-1003` - Edge Browser Power Test
- `GLD-1008` - Speedometer 3.0
- `GLD-1009` - JetStream 2
- `GLD-1010` - MotionMark 1.3
- `GLD-1014` - 3DMark Port Royal
- `GLD-1015` - 3DMark Time Spy
- `GLD-1016` - CineBench R24 Single Core

### Procyon Benchmarks (GLD-2xxx)
- `GLD-2001` - Procyon Office Productivity
- `GLD-2002` - Procyon Photo Editing
- `GLD-2003` - Procyon Video Editing
- `GLD-2004` - Procyon AI Inference
- `GLD-2005` - Procyon Battery Life
- `GLD-2006` - Procyon Storage
- `GLD-2007` - Procyon Full Suite

### Performance Tests (GLD-3xxx)
- `GLD-3001` - Performance Test Suite 1
- `GLD-3002` - Performance Test Suite 2

### Application Tests (GLD-4xxx)
- `GLD-4001` - Application Test 1
- `GLD-4002` - Application Test 2
- `GLD-4003` - Application Test 3

### Memory Benchmarks (GLD-8xxx)
- `GLD-8001` - Memory Latency Test
- `GLD-8002` - Memory Bandwidth Test
- `GLD-8003` - Memory Sequential Read
- `GLD-8004` - Memory Sequential Write
- `GLD-8005` - Memory Random Access
- `GLD-8006` - Memory Stress Test

---

## 🎨 Sequential Execution Flow

### Monitoring Tools in Separate Windows
```
┌────────────────────────────────────────────────────────┐
│ 1. START MONITORING (Separate Window)                 │
│    - SoCWatch: Visible window                          │
│    - EMON: Minimized window                            │
│    - TypePerf: Hidden window                           │
│    - PresentMon: Minimized window                      │
│    - PowerMeter: Background                            │
├────────────────────────────────────────────────────────┤
│ 2. WAIT FOR STABILIZATION (Main Window)                │
│    - Default: 3 seconds                                │
│    - Custom: -WaitTime parameter                       │
│    - Progress displayed in console                     │
├────────────────────────────────────────────────────────┤
│ 3. RUN TEST IN MAIN WINDOW                             │
│    - All test output visible in console                │
│    - Real-time progress monitoring                     │
│    - No background jobs                                │
│    - Direct execution (no job complexity)              │
├────────────────────────────────────────────────────────┤
│ 4. STOP MONITORING (Main Window)                       │
│    - Wait 2-3 seconds for final data capture           │
│    - Stop monitoring tool gracefully                   │
├────────────────────────────────────────────────────────┤
│ 5. RETRIEVE & PRINT RESULTS (Main Window)              │
│    - Get monitoring results summary                    │
│    - Display test completion status                    │
│    - Show duration and timestamps                      │
└────────────────────────────────────────────────────────┘
```

### Key Benefits
✅ **Test Output Visible** - All test output in main console  
✅ **Real-Time Monitoring** - See test progress as it happens  
✅ **Sequential Execution** - Clear start → test → stop flow  
✅ **Easy Debugging** - All output in one place  
✅ **ScriptBlock Support** - Better control over test execution  
✅ **Separate Monitoring Windows** - Clean window management  

---

## 📚 Documentation

Comprehensive documentation is available in the following files:

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed architecture and design decisions
- **[FRAMEWORK-SUMMARY.md](FRAMEWORK-SUMMARY.md)** - Quick reference and feature overview
- **[NEW-EXECUTION-FLOW.md](NEW-EXECUTION-FLOW.md)** - Execution flow details and patterns
- **[MIGRATION-GUIDE.md](MIGRATION-GUIDE.md)** - Guide for migrating from batch scripts
- **[README-MONITORING.md](README-MONITORING.md)** - Complete monitoring tools documentation

---

## 🛠️ Requirements

### Software Dependencies
- Windows 10/11
- PowerShell 5.1 or higher
- Intel monitoring tools (as needed):
  - SoCWatch
  - EMON
  - PowerMeter (SystemMeter)
  - PresentMon
  - WLC/IPF

### Hardware Requirements
- Intel-based system (for EMON, SoCWatch)
- Appropriate permissions for performance monitoring

---

## 🤝 Contributing

When adding new tests:

1. Create a new `GLD-XXXX.config.ps1` configuration file
2. Follow the existing hashtable format
3. Test with and without monitoring tools
4. Document any special requirements

When adding new monitoring tools:

1. Create `start_<tool>.ps1` and `stop_<tool>.ps1` scripts in `Monitors/`
2. Update TestRunner.ps1 to support the new tool
3. Add appropriate command-line switch to RunTest.ps1
4. Document the new tool in README-MONITORING.md

---

## 📄 License

Copyright © Intel Corporation. All rights reserved.

---

## 📞 Support

For issues, questions, or contributions, please contact the Intel Performance Engineering team.

---

## 🔄 Version History

- **v2.1** - Ultra-simplified architecture with direct script calls
- **v2.0** - Modular monitoring architecture with separate windows
- **v1.0** - Initial PowerShell framework implementation

---

## 🎯 Design Principles

1. **Simplicity First** - No wrappers, no abstraction layers
2. **Direct Invocation** - Use PowerShell `&` operator for script calls
3. **Single Responsibility** - Each script does one thing well
4. **Configuration Over Code** - Test behavior defined in config files
5. **Visibility** - All test output visible in main console
6. **Sequential Flow** - Clear start → test → stop pattern

---

**Built with ❤️ by Intel Performance Engineering**
