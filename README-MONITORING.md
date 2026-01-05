# Kings River Benchmark Framework - Monitoring Guide

## Overview
This PowerShell framework provides comprehensive monitoring capabilities for benchmark testing, with modular architecture supporting all monitoring tools from the original `start_test.bat` batch script.

---

## Quick Start

### Run Test Without Monitoring
```powershell
.\RunTest.ps1 -TestID GLD-1015
```

### Run Test with SoCWatch
```powershell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch
```

### Run Test with EMON
```powershell
.\RunTest.ps1 -TestID GLD-1015 -EMON
```

### Run with Multiple Monitors (Priority Applies)
```powershell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -PowerMeter -EMON
# Only SoCWatch will run (highest priority)
```

---

## Supported Monitoring Tools

### 1. SoCWatch - SoC Monitoring
**Window**: Visible (normal window)  
**Purpose**: System-on-Chip monitoring (power, temp, CPU, GPU, NPU)

```powershell
# Basic SoCWatch
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch

# With timing
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 60 -RunTime 120

# Wait until test completes
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 900 -RunTime 0
```

**Helper**: `Monitors\SoCWatchHelper.ps1`  
**Output**: CSV + ETL files in result directory

---

### 2. PowerMeter - Power Monitoring
**Window**: Normal  
**Purpose**: Power consumption measurement (RAPL, PAC)

```powershell
# Basic PowerMeter
.\RunTest.ps1 -TestID GLD-1015 -PowerMeter

# With timing
.\RunTest.ps1 -TestID GLD-1015 -PowerMeter -WaitTime 30
```

**Tool**: SystemMeter.exe  
**Output**: `{TestID}_power.csv`

---

### 3. TypePerf - Windows Performance Counters
**Window**: Hidden  
**Purpose**: Windows performance counter collection

```powershell
# Full counter set
.\RunTest.ps1 -TestID GLD-1015 -TypePerf_TP

# Subset counters
.\RunTest.ps1 -TestID GLD-1015 -TypePerf_SC
```

**Tool**: typeperf.exe  
**Output**: `{TestID}_typeperf_TP.csv` or `{TestID}_typeperf_SC.csv`

---

### 4. EMON - Intel Event Monitoring
**Window**: Minimized  
**Purpose**: CPU microarchitecture performance counters

```powershell
# EDP mode (recommended)
.\RunTest.ps1 -TestID GLD-1015 -EMON

# P-Core specific
.\RunTest.ps1 -TestID GLD-1015 -EMON_P_Core

# E-Core specific
.\RunTest.ps1 -TestID GLD-1015 -EMON_E_Core

# P-Core cache monitoring
.\RunTest.ps1 -TestID GLD-1015 -EMON_P_Core_Cache

# E-Core cache monitoring
.\RunTest.ps1 -TestID GLD-1015 -EMON_E_Core_Cache
```

**Helper**: `Monitors\EMONHelper.ps1`  
**Output**: `{TestID}_emon.dat` or mode-specific .txt files

---

### 5. PresentMon - GPU Monitoring
**Window**: Hidden  
**Purpose**: GPU frame monitoring and metrics

```powershell
.\RunTest.ps1 -TestID GLD-1015 -PresentMon
```

**Tool**: PresentMon-2.3.0-x64.exe  
**Output**: PresentMon CSV files

---

### 6. WLC - Wireless Profiling
**Window**: Command window  
**Purpose**: Intel IPF (Integrated Performance Framework) profiling

```powershell
# Basic WLC
.\RunTest.ps1 -TestID GLD-1015 -WLC

# With timing
.\RunTest.ps1 -TestID GLD-1015 -WLC -WaitTime 60 -RunTime 0
```

**Tool**: IPF (ipf_uf.exe)  
**Output**: `{TestID}_wlc_participant_log.csv`

---

### 7. VTune Performance Snapshot
**Tool**: Intel VTune Profiler  
**Purpose**: Quick performance overview

```powershell
.\RunTest.ps1 -TestID GLD-1015 -PerfMon_PS
```

**Output**: 
- `{TestID}_ps/` directory
- `{TestID}_ps_summary.html`

---

### 8. VTune Microarchitecture Exploration
**Tool**: Intel VTune Profiler  
**Purpose**: Detailed microarchitecture analysis

```powershell
.\RunTest.ps1 -TestID GLD-1015 -PerfMon_UArch
```

**Output**: 
- `{TestID}_uarch/` directory
- `{TestID}_uarch_summary.html`

---

### 9. VTune NPU Monitoring
**Tool**: Intel VTune Profiler  
**Purpose**: NPU (Neural Processing Unit) monitoring

```powershell
.\RunTest.ps1 -TestID GLD-1015 -PerfMon_NPU
```

**Output**: 
- `{TestID}_npu/` directory
- `{TestID}_npu_summary.html`

---

### 10. Intel Power Gadget
**Window**: GUI application  
**Purpose**: Real-time power monitoring UI

```powershell
.\RunTest.ps1 -TestID GLD-1015 -PowerGadget
```

**Tool**: IntelPowerGadget.exe  
**Note**: GUI will open; user must manually start/stop recording

---

### 11. PTAT Thermal Monitoring
**Tool**: ptat.exe  
**Purpose**: Thermal monitoring

```powershell
.\RunTest.ps1 -TestID GLD-1015 -Thermal
```

**Output**: `{TestID}_PTATLog.csv`

---

### 12. OS Performance (xperf + typeperf)
**Tool**: Windows Performance Toolkit  
**Purpose**: OS-level performance analysis

```powershell
.\RunTest.ps1 -TestID GLD-1015 -OSPerf
```

**Output**: 
- `OS_perf.etl`
- `{TestID}_process.csv`
- `{TestID}_cswitch_*.csv`
- `{TestID}_power_pstate.csv`
- `{TestID}_energydiag.csv`
- `{TestID}_perf_params.csv`

---

### 13. Just Workload (No Monitoring)
**Purpose**: Run test without any monitoring overhead

```powershell
.\RunTest.ps1 -TestID GLD-1015 -JWorkload
```

---

## Monitoring Priority Order

When multiple monitoring tools are specified, only **ONE** will run based on priority:

1. **SoCWatch** (highest priority)
2. **PowerMeter**
3. **TypePerf**
4. **EMON**
5. **PresentMon**
6. **WLC**
7. **Normal** (no monitoring)

**Example**:
```powershell
# Only SoCWatch will run
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -EMON -PowerMeter
```

**To run multiple monitors**, execute the test multiple times:
```powershell
# Run with SoCWatch
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch

# Run again with EMON
.\RunTest.ps1 -TestID GLD-1015 -EMON

# Run again with PowerMeter
.\RunTest.ps1 -TestID GLD-1015 -PowerMeter
```

---

## Timing Parameters

### WaitTime
**Purpose**: Wait before starting monitoring (in seconds)  
**Use Case**: Allow system to stabilize before data collection

```powershell
# Wait 60 seconds before starting SoCWatch
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 60
```

### RunTime
**Purpose**: Duration of monitoring (in seconds)  
**Special Value**: `0` = wait until test completes

```powershell
# Monitor for 120 seconds
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 30 -RunTime 120

# Monitor until test completes
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 900 -RunTime 0
```

---

## Framework Architecture

### File Structure
```
New_Flow_4/
├── RunTest.ps1                  # Universal wrapper with monitoring switches
├── TestRunner.ps1               # Base class with lifecycle methods
├── GLD-1014.config.ps1          # Test configuration files
├── GLD-1015.config.ps1
└── Monitors/                    # Modular monitoring implementations
    ├── SoCWatchHelper.ps1       # SoCWatch control (Start/Stop/GetResults)
    ├── SoCWatch.ps1             # SoCWatch monitoring module
    ├── EMONHelper.ps1           # EMON control (Start/Stop/GetResults)
    ├── EMON.ps1                 # EMON monitoring module
    ├── PowerMeter.ps1           # PowerMeter monitoring module
    ├── TypePerf.ps1             # TypePerf monitoring module
    ├── PresentMon.ps1           # PresentMon monitoring module
    └── WLC.ps1                  # WLC monitoring module
```

### Key Components

#### 1. RunTest.ps1
- Universal entry point
- Accepts monitoring switches
- Loads test configuration
- Injects monitoring parameters
- Displays help and examples

#### 2. TestRunner.ps1
- Base class `BenchmarkTest`
- Properties for all monitoring tools
- Lifecycle methods: PreStep() → Test() → PostStep()
- Loads monitoring modules
- Delegates to appropriate monitor based on priority

#### 3. Monitoring Modules (Monitors/*.ps1)
- Self-contained monitoring implementations
- Each exports `Invoke-{Monitor}Monitoring` function
- Accepts `$TestInstance` parameter
- Handles tool-specific logic
- Independent development and testing

#### 4. Helper Scripts (Monitors/*Helper.ps1)
- Tool control scripts (Start/Stop/GetResults)
- Used by monitoring modules
- Simplified interfaces
- Manages window behavior

---

## Window Behavior

| Tool | Window Mode | Reason |
|------|-------------|--------|
| SoCWatch | Normal (visible) | Real-time progress display useful |
| EMON | Minimized (taskbar) | Verbose output, long runtime |
| PowerMeter | Normal | Tool output may be informative |
| TypePerf | Hidden | Background data collection |
| PresentMon | Hidden | Background GPU monitoring |
| WLC | Command window | IPF interaction required |
| VTune | Hidden | Batch mode collection |
| PowerGadget | GUI | Interactive UI tool |
| Thermal | Hidden | Background logging |
| OSPerf | Hidden | System-level collection |

---

## Migration from start_test.bat

### Batch Script → PowerShell Equivalents

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
   - PowerShell: Parameter names case insensitive, values may be case sensitive

4. **Tool Names**
   - Batch: `-Emon_edp`
   - PowerShell: `-EMON` (simplified) or `-EMON_EDP`

---

## Configuration Files

Test configuration files (*.config.ps1) return a hashtable with test parameters:

```powershell
# GLD-1015.config.ps1 example
return @{
    TestID = "GLD-1015"
    TestName = "3DMark Wildlife Extreme Unlimited"
    TestType = "Perf"
    TestDomain = "Golden"
    TestCMD = "C:\Path\To\3DMark.exe --run-benchmark wildlife_extreme"
    WaitTime = 10
    Repeats = 1
    
    # Monitoring defaults (can be overridden by RunTest.ps1 parameters)
    EnableSoCWatch = $false
    EnablePowerMeter = $false
    SoCWatchWaitTime = 0
    SoCWatchRunTime = 0
}
```

**RunTest.ps1 overrides** config values when monitoring switches are used.

---

## Advanced Usage

### Display Configuration Before Running
```powershell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -DisplayConfig
```

### Check Available Tests
```powershell
.\RunTest.ps1 -Help
```

### Run with Custom Timing
```powershell
# Wait 900s, then monitor until test completes
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch -WaitTime 900 -RunTime 0
```

### Sequential Monitoring Collection
```bash
# Collect SoCWatch data
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch

# Collect EMON data
.\RunTest.ps1 -TestID GLD-1015 -EMON

# Collect PowerMeter data
.\RunTest.ps1 -TestID GLD-1015 -PowerMeter
```

---

## Troubleshooting

### Issue: Monitoring tool not starting
**Solution**: Check tool paths in `TestRunner.ps1`:
- `PowerSliderPath`
- `SoCWatchHelperPath`

### Issue: Multiple monitors specified but only one runs
**Explanation**: This is by design (priority order). Run test multiple times with different monitors.

### Issue: Window not visible
**Check**: Window mode for that specific tool (see Window Behavior table)

### Issue: Helper script not found
**Solution**: Ensure `Monitors\` directory exists with all helper scripts.

---

## Tool Paths

Update these paths in `TestRunner.ps1` if tools are installed elsewhere:

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

## Benefits Over Batch Script

1. **Modular Architecture** - Each monitor in separate file
2. **Better Error Handling** - PowerShell try/catch blocks
3. **Type Safety** - Strong typing in PowerShell classes
4. **Help System** - Built-in `-Help` parameter
5. **Configuration Display** - `-DisplayConfig` to verify settings
6. **Cleaner Syntax** - Named parameters vs positional args
7. **Extensibility** - Easy to add new monitors
8. **Maintainability** - ~200-300 lines per file vs monolithic batch
9. **Window Management** - Appropriate visibility per tool
10. **Reusability** - Helper scripts can be used independently

---

## Next Steps

1. **Create test configs** for your tests (*.config.ps1)
2. **Test monitoring tools** individually
3. **Verify tool paths** in TestRunner.ps1
4. **Run sample tests** with different monitors
5. **Check output files** in result directories

---

**Version**: 2.0  
**Last Updated**: December 17, 2024  
**Status**: Production Ready ✅
