# KSR-on-PowerShell - Modular Testing Framework

## Table of Contents
- [Overview](#overview)
- [Quick Start](#quick-start)
- [Framework Architecture](#framework-architecture)
- [Execution Flow](#execution-flow)
- [Supported Monitoring Tools](#supported-monitoring-tools)
- [Test Configurations](#test-configurations)
- [Command Examples](#command-examples)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)
- [Development Guide](#development-guide)

---

## Overview

Complete PowerShell testing framework with modular monitoring architecture supporting all tools from `start_test.bat`.

### Key Features
-  **Visible Test Output** - All test output displayed in main console window
-  **Sequential Execution** - Clear start → test → stop flow
-  **Modular Architecture** - Each monitoring tool in separate file (~60-80 lines)
-  **18 Monitoring Tools** - Complete parity with batch script
-  **Separate Windows** - Monitoring tools run in their own windows
-  **Real-Time Monitoring** - See test progress as it happens
-  **Easy Debugging** - All output in one place
-  **ScriptBlock Support** - Better control over test execution

### Version Information
- **Version**: 2.1
- **Last Updated**: January 19, 2026

---

## Quick Start

### Basic Usage

```powershell
# Run test without monitoring
.\RunTest.ps1 -TestID GLD-1015

# Run test with SoCWatch
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch

# Run test with EMON
.\RunTest.ps1 -TestID GLD-1015 -EMON

# Run with custom timing
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 60 -RunTime 120

# Display help
.\RunTest.ps1 -Help

# Display configuration
.\RunTest.ps1 -TestID GLD-1015 -DisplayConfig
```

### What's Included

**Core Framework Files:**
- `RunTest.ps1` - Universal test wrapper with all monitoring switches (~450 lines)
- `TestRunner.ps1` - Base class with monitoring support (~270 lines)
- `*.config.ps1` - Test configuration files (16+ configs)

**Monitoring Modules (Debug_Collectors/):**
- `SoCWatchHelper.ps1` - SoCWatch control (~280 lines)
- `SoCWatch.ps1` - SoCWatch monitoring (~80 lines)
- `EMONHelper.ps1` - EMON control (~330 lines)
- `EMON.ps1` - EMON monitoring (~80 lines)
- `PowerMeter.ps1` - Power monitoring (~70 lines)
- `PowerMeterHelper.ps1` - Power monitoring helper
- Additional monitoring modules for TypePerf, PresentMon, WLC, etc.

**Test Configurations:**
- **Performance Tests**: GLD-1008 to GLD-1016
- **Power Tests**: GLD-1001, GLD-1003
- **Procyon AI Tests**: GLD-2001 to GLD-2007
- **GPU Tests**: GLD-3001, GLD-3002
- **Stress Tests**: GLD-4001 to GLD-4003
- **Memory Tests**: GLD-8001 to GLD-8006

---

## Framework Architecture

### Directory Structure
```
KSR-on-powershell/
├── README.md                    # This file
├── Infra/
│   ├── RunTest.ps1              # Entry point with monitoring switches
│   └── TestRunner.ps1           # Base class with lifecycle methods
├── Perf_KPI/
│   ├── GLD-1008.config.ps1      # 3DMark Solar Bay
│   ├── GLD-1009.config.ps1      # 3DMark Steel Nomad
│   ├── GLD-1010.config.ps1      # 3DMark Time Spy
│   ├── GLD-1014.config.ps1      # 3DMark Wildlife Extreme
│   ├── GLD-1015.config.ps1      # 3DMark Wildlife Extreme Unlimited
│   ├── GLD-1016.config.ps1      # CineBench R24 Single Core
│   ├── GLD-2001.config.ps1      # Procyon AI CPU FP32
│   ├── GLD-2002.config.ps1      # Procyon AI CPU INT8
│   ├── GLD-2003.config.ps1      # Procyon AI GPU FP16
│   ├── GLD-2004.config.ps1      # Procyon AI GPU INT8
│   ├── GLD-2005.config.ps1      # Procyon AI NPU FP16
│   ├── GLD-2006.config.ps1      # Procyon AI NPU INT8
│   ├── GLD-2007.config.ps1      # Procyon AI NPU FP16 (alt)
│   ├── GLD-3001.config.ps1      # GPU workload
│   ├── GLD-3002.config.ps1      # GPU workload
│   ├── GLD-4001.config.ps1      # Stress test
│   ├── GLD-4002.config.ps1      # Stress test
│   ├── GLD-4003.config.ps1      # Stress test
│   ├── GLD-8001.config.ps1      # Babel Stream Memory
│   ├── GLD-8002.config.ps1      # AIDA64 Memory Copy
│   ├── GLD-8003.config.ps1      # AIDA64 Memory Read
│   ├── GLD-8004.config.ps1      # AIDA64 Memory Write
│   ├── GLD-8005.config.ps1      # AIDA64 Memory Latency
│   └── GLD-8006.config.ps1      # Stream Memory Triad
├── Power_KPI/
│   ├── GLD-1001.config.ps1      # Busy Idle Consumer
│   └── GLD-1003.config.ps1      # ADK Browsing
└── Debug_Collectors/
    ├── SoCWatchHelper.ps1       # SoCWatch control
    ├── SoCWatch.ps1             # SoCWatch monitoring
    ├── EMONHelper.ps1           # EMON control
    ├── EMON.ps1                 # EMON monitoring
    ├── PowerMeterHelper.ps1     # Power monitoring helper
    └── PowerMeter.ps1           # Power monitoring
```

### Modular Design Benefits

1. **Single Entry Point** - `RunTest.ps1` for all tests
2. **Separation of Concerns** - Each tool in its own module
3. **Easy Maintenance** - Update one tool without affecting others
4. **Testability** - Test each module independently
5. **Extensibility** - Add new tools easily
6. **Reusability** - Helper scripts work standalone

---

## Execution Flow

### Sequential Test Execution (v2.1)

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
│ 3. RUN TEST IN MAIN WINDOW ✨                          │
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

 **Test Output Visible** - All test output in main console  
 **Real-Time Monitoring** - See test progress as it happens  
 **Sequential Execution** - Clear start → test → stop flow  
 **Easy Debugging** - All output in one place  
 **ScriptBlock Support** - Better control over test execution  
 **Separate Monitoring Windows** - Clean window management  

---

## Supported Monitoring Tools

### Tool Summary Table

| # | Tool | Switch | Helper | Window | Output |
|---|------|--------|--------|--------|--------|
| 1 | SoCWatch | `-SoCWatch` | ✅ | Visible | CSV + ETL |
| 2 | PowerMeter | `-PowerMeter` | ✅ | Normal | CSV |
| 3 | TypePerf (Full) | `-TypePerf_TP` | ❌ | Hidden | CSV |
| 4 | TypePerf (Subset) | `-TypePerf_SC` | ❌ | Hidden | CSV |
| 5 | EMON EDP | `-EMON` | ✅ | Minimized | DAT |
| 6 | EMON P-Core | `-EMON_P_Core` | ✅ | Minimized | TXT |
| 7 | EMON E-Core | `-EMON_E_Core` | ✅ | Minimized | TXT |
| 8 | EMON P-Core Cache | `-EMON_P_Core_Cache` | ✅ | Minimized | TXT |
| 9 | EMON E-Core Cache | `-EMON_E_Core_Cache` | ✅ | Minimized | TXT |
| 10 | PresentMon | `-PresentMon` | ❌ | Hidden | CSV |
| 11 | WLC/IPF | `-WLC` | ❌ | Command | CSV |
| 12 | VTune PS | `-PerfMon_PS` | ❌ | Hidden | HTML |
| 13 | VTune UArch | `-PerfMon_UArch` | ❌ | Hidden | HTML |
| 14 | VTune NPU | `-PerfMon_NPU` | ❌ | Hidden | HTML |
| 15 | Power Gadget | `-PowerGadget` | ❌ | GUI | Manual |
| 16 | PTAT Thermal | `-Thermal` | ❌ | Hidden | CSV |
| 17 | OS Perf (xperf) | `-OSPerf` | ❌ | Hidden | ETL+CSV |
| 18 | Just Workload | `-JWorkload` | ❌ | N/A | None |

**Total: 18 monitoring options** (complete parity with start_test.bat)

### 1. SoCWatch - System-on-Chip Monitoring

**Purpose**: Real-time SoC monitoring (power, temperature, CPU, GPU, NPU)  
**Window**: Visible (separate window)  
**Output**: CSV + ETL files

```powershell
# Basic SoCWatch
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch

# With timing
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 60 -RunTime 120

# Wait until test completes
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch -WaitTime 900 -RunTime 0
```

### 2. EMON - Intel Event Monitoring

**Purpose**: CPU microarchitecture performance counters  
**Window**: Minimized (accessible via taskbar)  
**Output**: DAT or TXT files

```powershell
# EDP mode (recommended)
.\RunTest.ps1 -TestID GLD-1015 -EMON

# P-Core specific
.\RunTest.ps1 -TestID GLD-1015 -EMON_P_Core

# E-Core specific
.\RunTest.ps1 -TestID GLD-1015 -EMON_E_Core

# Cache monitoring
.\RunTest.ps1 -TestID GLD-1015 -EMON_P_Core_Cache
.\RunTest.ps1 -TestID GLD-1015 -EMON_E_Core_Cache
```

### 3. PowerMeter - Power Monitoring

**Purpose**: Power consumption measurement (RAPL, PAC)  
**Window**: Normal  
**Output**: CSV files

```powershell
# Basic PowerMeter
.\RunTest.ps1 -TestID GLD-1015 -PowerMeter

# With timing
.\RunTest.ps1 -TestID GLD-1015 -PowerMeter -WaitTime 30
```

<!-- ### 4. TypePerf - Windows Performance Counters

**Purpose**: Windows performance counter collection  
**Window**: Hidden  
**Output**: CSV files

```powershell
# Full counter set
.\RunTest.ps1 -TestID GLD-1015 -TypePerf_TP

# Subset counters
.\RunTest.ps1 -TestID GLD-1015 -TypePerf_SC
```

### 5. PresentMon - GPU Monitoring

**Purpose**: GPU frame monitoring and metrics  
**Window**: Hidden  
**Output**: CSV files

```powershell
.\RunTest.ps1 -TestID GLD-1015 -PresentMon
```

### 6. WLC - Wireless Profiling

**Purpose**: Intel IPF (Integrated Performance Framework) profiling  
**Window**: Command window  
**Output**: CSV files

```powershell
# Basic WLC
.\RunTest.ps1 -TestID GLD-1015 -WLC

# With timing
.\RunTest.ps1 -TestID GLD-1015 -WLC -WaitTime 60 -RunTime 0
```

### 7-9. VTune Profiling

**Purpose**: Intel VTune profiling (Performance Snapshot, Microarchitecture, NPU)  
**Window**: Hidden  
**Output**: HTML reports

```powershell
# Performance Snapshot
.\RunTest.ps1 -TestID GLD-1015 -PerfMon_PS

# Microarchitecture Exploration
.\RunTest.ps1 -TestID GLD-1015 -PerfMon_UArch

# NPU Monitoring
.\RunTest.ps1 -TestID GLD-1015 -PerfMon_NPU
```

### 10. Power Gadget

**Purpose**: Real-time power monitoring GUI  
**Window**: GUI application  
**Output**: Manual recording

```powershell
.\RunTest.ps1 -TestID GLD-1015 -PowerGadget
```

### 11. PTAT Thermal Monitoring

**Purpose**: Thermal monitoring  
**Window**: Hidden  
**Output**: CSV files

```powershell
.\RunTest.ps1 -TestID GLD-1015 -Thermal
```

### 12. OS Performance (xperf)

**Purpose**: OS-level performance analysis  
**Window**: Hidden  
**Output**: ETL + CSV files

```powershell
.\RunTest.ps1 -TestID GLD-1015 -OSPerf
``` -->

### 13. Just Workload

**Purpose**: Run test without monitoring overhead  
**Window**: Main console  
**Output**: None

```powershell
.\RunTest.ps1 -TestID GLD-1015 -JWorkload
```

### Monitoring Priority Order

When multiple monitoring tools are specified, only **ONE** will run based on priority:

1. SoCWatch (highest priority)
2. PowerMeter
3. TypePerf
4. EMON
5. PresentMon
6. WLC
7. Normal (no monitoring)

**Example**:
```powershell
# Only SoCWatch will run
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -EMON -PowerMeter
```

To collect data from multiple tools, run the test multiple times:
```powershell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch
.\RunTest.ps1 -TestID GLD-1015 -EMON
.\RunTest.ps1 -TestID GLD-1015 -PowerMeter
```

---

## Test Configurations

### Configuration File Format

Test configs return hashtables with parameters. **TestCMD** supports both string and scriptblock formats:

#### String Format (Simple)
```powershell
# GLD-1015.config.ps1
@{
    TestID = "GLD-1015"
    TestName = "3DMark Wildlife Extreme Unlimited"
    TestCMD = "benchmark.exe --run"
    WaitTime = 10
}
```

#### ScriptBlock Format (Recommended) 
```powershell
# GLD-8001.config.ps1
@{
    TestID = "GLD8001"
    TestName = "Babel Stream Memory Benchmark"
    TestCMD = {
        Start-Process -FilePath "C:\Path\To\BabelStream.exe" `
            -ArgumentList '--benchmark' `
            -RedirectStandardOutput "output.txt" `
            -RedirectStandardError "error.txt" `
            -NoNewWindow -Wait
    }
    WaitTime = 30
}
```

**ScriptBlock Benefits:**
- Better output control (redirect stdout/stderr)
- Proper error handling
- No shell escaping issues
- Cleaner syntax for complex commands

### Available Test Configurations

#### Performance Tests (Perf_KPI/)
- **GLD-1008**: 3DMark Solar Bay
- **GLD-1009**: 3DMark Steel Nomad
- **GLD-1010**: 3DMark Time Spy
- **GLD-1014**: 3DMark Wildlife Extreme
- **GLD-1015**: 3DMark Wildlife Extreme Unlimited
- **GLD-1016**: CineBench R24 Single Core

#### Procyon AI Tests (Perf_KPI/)
- **GLD-2001**: Procyon AI CPU FP32
- **GLD-2002**: Procyon AI CPU INT8
- **GLD-2003**: Procyon AI GPU FP16
- **GLD-2004**: Procyon AI GPU INT8
- **GLD-2005**: Procyon AI NPU FP16
- **GLD-2006**: Procyon AI NPU INT8
- **GLD-2007**: Procyon AI NPU FP16 (alternate)

#### GPU Tests (Perf_KPI/)
- **GLD-3001**: GPU workload
- **GLD-3002**: GPU workload

#### Stress Tests (Perf_KPI/)
- **GLD-4001**: Stress test
- **GLD-4002**: Stress test
- **GLD-4003**: Stress test

#### Memory Benchmarks (Perf_KPI/)
- **GLD-8001**: Babel Stream Memory Benchmark
- **GLD-8002**: AIDA64 Memory Copy
- **GLD-8003**: AIDA64 Memory Read
- **GLD-8004**: AIDA64 Memory Write
- **GLD-8005**: AIDA64 Memory Latency
- **GLD-8006**: Stream Memory Triad

#### Power Tests (Power_KPI/)
- **GLD-1001**: Busy Idle Consumer
- **GLD-1003**: ADK Browsing

---

## Command Examples

### Basic Tests

```powershell
# Run without monitoring
.\RunTest.ps1 -TestID GLD-1015

# Display help
.\RunTest.ps1 -Help

# Display configuration
.\RunTest.ps1 -TestID GLD-1015 -DisplayConfig
```

### With SoCWatch (Recommended for System Monitoring)

```powershell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch

# What happens:
# 1. SoCWatch window opens (VISIBLE, separate window)
# 2. Wait 3 seconds for monitoring to initialize
# 3. Test runs in MAIN window (all output visible)
# 4. SoCWatch stops after test completes
# 5. Results displayed in main window
```

### With EMON (Recommended for CPU Events)

```powershell
.\RunTest.ps1 -TestID GLD-1015 -EMON

# What happens:
# 1. EMON window opens (MINIMIZED, accessible via taskbar)
# 2. Wait 3 seconds for monitoring to initialize
# 3. Test runs in MAIN window (all output visible)
# 4. EMON stops after test completes
# 5. Results displayed in main window
```

### With Timing Parameters

```powershell
# Wait 60s, monitor for 120s
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 60 -RunTime 120

# Wait 900s, monitor until test completes
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch -WaitTime 900 -RunTime 0
```

### Memory Benchmarks with Monitoring

```powershell
# Babel Stream with SoCWatch
.\RunTest.ps1 -TestID GLD-8001 -SoCWatch -WaitTime 30

# AIDA64 Memory Read with EMON
.\RunTest.ps1 -TestID GLD-8003 -EMON
```

### Procyon AI Benchmarks

```powershell
# Procyon AI CPU INT8
.\RunTest.ps1 -TestID GLD-2002 -SoCWatch

# Procyon AI NPU FP16
.\RunTest.ps1 -TestID GLD-2007 -EMON
```

### Sequential Monitoring Collection

```powershell
# Collect SoCWatch data
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch

# Collect EMON data
.\RunTest.ps1 -TestID GLD-1015 -EMON

# Collect PowerMeter data
.\RunTest.ps1 -TestID GLD-1015 -PowerMeter
```

---

<!-- ## Migration from Batch Script

### Command Conversion Table

| Batch Command | PowerShell Equivalent |
|---------------|----------------------|
| `start_test.bat -TestId:GLD-1015 -SoCWatch` | `.\RunTest.ps1 -TestID GLD-1015 -SoCWatch` |
| `start_test.bat -TestId:GLD-1015 -PowerMeter` | `.\RunTest.ps1 -TestID GLD-1015 -PowerMeter` |
| `start_test.bat -TestId:GLD-1015 -Emon_edp` | `.\RunTest.ps1 -TestID GLD-1015 -EMON` |
| `start_test.bat -TestId:GLD-1015 -SoCWatch 5W:15R` | `.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 5 -RunTime 15` |
| `start_test.bat -TestId:GLD-1015 -JWorkload` | `.\RunTest.ps1 -TestID GLD-1015 -JWorkload` |

### Key Differences

1. **Parameter Syntax**
   - Batch: `-TestId:` (colon separator)
   - PowerShell: `-TestID` (space separator)

2. **Timing Syntax**
   - Batch: `5W:15R` (wait:run format)
   - PowerShell: `-WaitTime 5 -RunTime 15` (explicit parameters)

3. **Case Sensitivity**
   - Batch: Case insensitive
   - PowerShell: Parameter names case insensitive

4. **Tool Names**
   - Batch: `-Emon_edp`
   - PowerShell: `-EMON` (simplified)

### Benefits Over Batch Script

1. **Modular Architecture** - Each monitor in separate file (~60-80 lines)
2. **Better Error Handling** - PowerShell try/catch blocks
3. **Type Safety** - Strong typing in PowerShell classes
4. **Help System** - Built-in `-Help` parameter
5. **Configuration Display** - `-DisplayConfig` to verify settings
6. **Cleaner Syntax** - Named parameters vs positional args
7. **Extensibility** - Easy to add new monitors
8. **Maintainability** - Small, focused files vs monolithic batch
9. **Window Management** - Appropriate visibility per tool
10. **Reusability** - Helper scripts can be used independently
11. **Visible Output** - Test runs in main window (v2.1)
12. **Sequential Flow** - Clear start → test → stop (v2.1)

--- -->

## Advanced Usage

### Timing Parameters

#### WaitTime
**Purpose**: Wait before starting monitoring (in seconds)  
**Use Case**: Allow system to stabilize before data collection

```powershell
# Wait 60 seconds before starting SoCWatch
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 60
```

#### RunTime
**Purpose**: Duration of monitoring (in seconds)  
**Special Value**: `0` = wait until test completes

```powershell
# Monitor for 120 seconds
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 30 -RunTime 120

# Monitor until test completes
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 900 -RunTime 0
```

### Tool Path Configuration

Update tool paths in `TestRunner.ps1` if needed:

```powershell
[string]$PowerSliderPath = "C:\KSR_Package\KSR\Test_Run_KR\PowerSlider.exe"
[string]$SoCWatchHelperPath = "C:\KSR_Package\KSR\Test_Run_KR\tools\socwatch\64\SoCWatchHelper.exe"
```

Common tool locations:
- **SoCWatch**: `C:\KSR_Package\KSR\Test_Run_KR\tools\socwatch\64\`
- **EMON**: In system PATH or VTune installation
- **SystemMeter**: `C:\KSR_Package\KSR\Test_Run_KR\`
- **VTune**: `C:\Program Files\Intel\VTune Profiler\bin64\`
- **PresentMon**: Custom installation path

---

## Troubleshooting

### Issue: Test output not visible
**Solution**: Test should ALWAYS appear in main window (v2.1). If not:
- Check if TestCMD is properly defined in config file
- Verify monitoring module updated to new flow
- Check for errors in main console

### Issue: Monitoring tool not starting
**Solution**: 
- Check tool paths in `TestRunner.ps1`
- Verify monitoring tool is installed
- Look for error messages in main window
- Check helper script paths

### Issue: Multiple monitors specified but only one runs
**Explanation**: This is by design (priority order)
**Solution**: Run test multiple times with different monitors

### Issue: Window not visible
**Check**: Window mode for that specific tool (see Window Behavior table)
- SoCWatch: Visible (normal window)
- EMON: Minimized (taskbar)
- TypePerf: Hidden (background)
- PresentMon: Hidden (background)

### Issue: Helper script not found
**Solution**: Ensure `Debug_Collectors\` directory exists with all helper scripts

### Issue: Monitoring doesn't stop
**Solution**: 
- Try/catch blocks should handle this automatically
- Check PowerSlider calls in helper scripts
- Manual stop: `Stop-Process -Name "toolname"`

---

## Development Guide

### Adding a New Test Configuration

1. Create a new config file in `Perf_KPI/` or `Power_KPI/`:

```powershell
# GLD-XXXX.config.ps1
@{
    TestID = "GLD-XXXX"
    TestName = "Your Test Name"
    TestType = "Perf"  # or "Power"
    TestDomain = "Golden"
    TestCMD = {
        Start-Process -FilePath "C:\Path\To\Benchmark.exe" `
            -ArgumentList '--args' `
            -RedirectStandardOutput "output.txt" `
            -NoNewWindow -Wait
    }
    WaitTime = 30
    Repeats = 1
}
```

2. Test the configuration:

```powershell
.\RunTest.ps1 -TestID GLD-XXXX -DisplayConfig
.\RunTest.ps1 -TestID GLD-XXXX
```

### Adding a New Monitoring Tool

1. Create monitoring module in `Debug_Collectors/`:

```powershell
# NewTool.ps1
function Invoke-NewToolMonitoring {
    param([object]$TestInstance)
    
    try {
        # Step 1: Start monitoring (separate window)
        Write-Host "[NewTool] Starting monitoring..."
        Start-NewTool
        
        # Step 2: Wait for stabilization
        Write-Host "[NewTool] Waiting for stabilization..."
        Start-Sleep -Seconds 3
        
        # Step 3: Run test in MAIN WINDOW
        Write-Host "[NewTool] Running test in main window..."
        if ($TestInstance.TestCMD -is [scriptblock]) {
            & $TestInstance.TestCMD
        } else {
            Invoke-Expression $TestInstance.TestCMD
        }
        Write-Host "[OK] Test execution completed"
        
        # Step 4: Stop monitoring
        Write-Host "[NewTool] Stopping monitoring..."
        Stop-NewTool
        
        # Step 5: Get results
        Write-Host "[NewTool] Retrieving results..."
        Get-Results
        
        Write-Host "[OK] NewTool monitoring completed"
    }
    catch {
        Write-Host "[ERROR] Monitoring failed: $_"
        Stop-NewTool  # Ensure cleanup
        throw
    }
}

Export-ModuleMember -Function Invoke-NewToolMonitoring
```

2. Add switch to `RunTest.ps1`:

```powershell
[switch]$NewTool
```

3. Add property to `TestRunner.ps1`:

```powershell
[bool]$EnableNewTool = $false
```

4. Update monitoring logic in `TestRunner.ps1`:

```powershell
if ($this.EnableNewTool) {
    Import-Module "$PSScriptRoot\..\Debug_Collectors\NewTool.ps1" -Force
    Invoke-NewToolMonitoring -TestInstance $this
    return
}
```

5. Test the new tool:

```powershell
.\RunTest.ps1 -TestID GLD-1015 -NewTool
```

### Testing Checklist

#### Basic Tests
- [ ] Run test without monitoring
- [ ] Run test with SoCWatch
- [ ] Run test with EMON
- [ ] Run test with PowerMeter
- [ ] Run test with TypePerf

#### Timing Tests
- [ ] Test WaitTime parameter
- [ ] Test RunTime parameter
- [ ] Test RunTime=0 (wait until complete)

#### Framework Tests
- [ ] Display help
- [ ] Display configuration
- [ ] Test with invalid TestID
- [ ] Test with multiple monitors (priority)

#### Window Behavior
- [ ] Verify SoCWatch visible window (separate)
- [ ] Verify EMON minimized window (separate)
- [ ] Verify TypePerf hidden (background)
- [ ] Verify test output visible in MAIN window
- [ ] Verify monitoring and test run sequentially

---

<!--## Statistics

### Framework Size
- **Core Framework**: ~4,500 lines (well-documented, modular, maintainable)
- **vs start_test.bat**: ~1,200 lines (monolithic, complex, hard to maintain)

### File Sizes

| File | Lines | Purpose |
|------|-------|---------|
| RunTest.ps1 | ~450 | Universal wrapper with all switches |
| TestRunner.ps1 | ~270 | Base class with monitoring support |
| SoCWatchHelper.ps1 | ~280 | SoCWatch control |
| EMONHelper.ps1 | ~330 | EMON control |
| SoCWatch.ps1 | ~80 | SoCWatch monitoring logic |
| EMON.ps1 | ~80 | EMON monitoring logic |
| PowerMeter.ps1 | ~70 | PowerMeter monitoring |
| TypePerf.ps1 | ~70 | TypePerf monitoring |
| PresentMon.ps1 | ~60 | PresentMon monitoring |
| WLC.ps1 | ~60 | WLC monitoring |

### Code Quality Improvements
- **Modular**: Each monitor ~60-80 lines vs embedded in batch
- **Sequential**: Clear flow vs complex background job handling
- **Visible**: Test output in main window vs hidden in jobs
- **Maintainable**: Easy to update individual components
- **Testable**: Each module can be tested independently

---

## Contributing

### Guidelines
1. Follow PowerShell best practices
2. Use try/catch for error handling
3. Add comments for complex logic
4. Test changes thoroughly
5. Update documentation
6. Keep modules small and focused (~60-80 lines)
7. Use ScriptBlock format for TestCMD in configs

### Code Style
- Use PascalCase for function names
- Use camelCase for variable names
- Use meaningful variable names
- Add help comments for functions
- Use proper indentation (4 spaces)
 -->
---

## License

Copyright © Intel Corporation

---

## Support

For issues, questions, or contributions, please contact the KSR team or create an issue in the repository.

---

## Version History

### v2.1 (January 19, 2026)
-  Test execution in main window (visible output)
-  Sequential execution flow (start → test → stop)
-  ScriptBlock TestCMD support
-  16+ production test configurations
-  Comprehensive documentation

### v2.0 (December 17, 2024)
-  Modular monitoring architecture
-  18 monitoring tools
-  Helper scripts for complex tools
-  Complete parity with start_test.bat

### v1.0 (Initial Release)
- Basic test execution framework
- Limited monitoring support

---

**Framework Version**: 2.1  
**Last Updated**: January 19, 2026
