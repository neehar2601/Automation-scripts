# Migration Guide: start_test.bat → RunTest.ps1

## Overview
This guide helps you migrate from the batch script `start_test.bat` to the new PowerShell framework `RunTest.ps1`.

---

## Quick Reference

### Command Mapping

| Batch Script | PowerShell Equivalent |
|--------------|----------------------|
| `start_test.bat -TestId:GLD-1015` | `.\RunTest.ps1 -TestID GLD-1015` |
| `start_test.bat -TestId:GLD-1015 -SoCWatch` | `.\RunTest.ps1 -TestID GLD-1015 -SoCWatch` |
| `start_test.bat -TestId:GLD-1015 -PowerMeter` | `.\RunTest.ps1 -TestID GLD-1015 -PowerMeter` |
| `start_test.bat -TestId:GLD-1015 -Emon_edp` | `.\RunTest.ps1 -TestID GLD-1015 -EMON` |
| `start_test.bat -TestId:GLD-1015 -Emon_P_Core` | `.\RunTest.ps1 -TestID GLD-1015 -EMON_P_Core` |
| `start_test.bat -TestId:GLD-1015 -TypePerf_TP` | `.\RunTest.ps1 -TestID GLD-1015 -TypePerf_TP` |
| `start_test.bat -TestId:GLD-1015 -Presentmon` | `.\RunTest.ps1 -TestID GLD-1015 -PresentMon` |
| `start_test.bat -TestId:GLD-1015 -Wlc` | `.\RunTest.ps1 -TestID GLD-1015 -WLC` |
| `start_test.bat -TestId:GLD-1015 -PerfMon_ps` | `.\RunTest.ps1 -TestID GLD-1015 -PerfMon_PS` |
| `start_test.bat -TestId:GLD-1015 -JWorkload` | `.\RunTest.ps1 -TestID GLD-1015 -JWorkload` |

### Timing Syntax

| Batch Script | PowerShell Equivalent |
|--------------|----------------------|
| `start_test.bat -TestId:GLD-1015 -SoCWatch 5W:15R` | `.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 5 -RunTime 15` |
| `start_test.bat -TestId:GLD-1015 -SoCWatch 900W:0R` | `.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 900 -RunTime 0` |
| `start_test.bat -TestId:GLD-1015 -PowerMeter 30W` | `.\RunTest.ps1 -TestID GLD-1015 -PowerMeter -WaitTime 30` |

---

## All Monitoring Switches

### Batch → PowerShell Switch Names

| Batch Switch | PowerShell Switch | Notes |
|--------------|------------------|-------|
| `-SoCWatch` | `-SoCWatch` | Same name |
| `-PowerMeter` | `-PowerMeter` | Same name |
| `-Emon_edp` | `-EMON` or `-EMON_EDP` | Simplified to `-EMON` |
| `-Emon_P_Core` | `-EMON_P_Core` | Underscore preserved |
| `-Emon_E_Core` | `-EMON_E_Core` | Underscore preserved |
| `-Emon_P_Core_cache` | `-EMON_P_Core_Cache` | Case change |
| `-Emon_E_Core_cache` | `-EMON_E_Core_Cache` | Case change |
| `-Presentmon` | `-PresentMon` | Case change |
| `-Wlc` | `-WLC` | All caps |
| `-TypePerf_TP` | `-TypePerf_TP` | Same name |
| `-TypePerf_SC` | `-TypePerf_SC` | Same name |
| `-PerfMon_ps` | `-PerfMon_PS` | Case change |
| `-PerfMon_uarch` | `-PerfMon_UArch` | Case change |
| `-PerfMon_npu` | `-PerfMon_NPU` | All caps |
| `-PowerGadget` | `-PowerGadget` | Same name |
| `-Thermal` | `-Thermal` | Same name |
| `-OSPerf` | `-OSPerf` | Same name |
| `-JWorkload` | `-JWorkload` | Same name |

---

## Syntax Differences

### 1. Parameter Separator

**Batch**: Uses colon `:`
```batch
start_test.bat -TestId:GLD-1015
```

**PowerShell**: Uses space
```powershell
.\RunTest.ps1 -TestID GLD-1015
```

### 2. Timing Format

**Batch**: Combined string `{wait}W:{run}R`
```batch
start_test.bat -TestId:GLD-1015 -SoCWatch 5W:15R
```

**PowerShell**: Separate parameters
```powershell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 5 -RunTime 15
```

### 3. Test ID Parameter Name

**Batch**: `-TestId:` (with colon)
```batch
start_test.bat -TestId:GLD-1015
```

**PowerShell**: `-TestID` (no colon, capital ID)
```powershell
.\RunTest.ps1 -TestID GLD-1015
```

---

## Feature Comparison

| Feature | start_test.bat | RunTest.ps1 | Notes |
|---------|----------------|-------------|-------|
| **Monitoring Priority** | ✅ | ✅ | Same priority order |
| **SoCWatch** | ✅ | ✅ | Enhanced with helper |
| **PowerMeter** | ✅ | ✅ | Same functionality |
| **TypePerf** | ✅ | ✅ | TP and SC modes |
| **EMON** | ✅ | ✅ | All modes supported |
| **PresentMon** | ✅ | ✅ | GPU monitoring |
| **WLC** | ✅ | ✅ | IPF profiling |
| **VTune** | ✅ | ✅ | PS, UArch, NPU |
| **PowerGadget** | ✅ | ✅ | Intel Power Gadget |
| **Thermal** | ✅ | ✅ | PTAT monitoring |
| **OSPerf** | ✅ | ✅ | xperf + typeperf |
| **Help System** | ❌ | ✅ | `-Help` parameter |
| **Config Display** | ❌ | ✅ | `-DisplayConfig` |
| **Modular Design** | ❌ | ✅ | Separate monitor files |
| **Error Handling** | ⚠️ Basic | ✅ Advanced | Try/catch blocks |
| **Window Management** | ⚠️ Mixed | ✅ Optimized | Per-tool window modes |

---

## Migration Steps

### Step 1: Identify Your Batch Commands

List all your current batch script commands:
```batch
start_test.bat -TestId:GLD-1015 -SoCWatch 900W:0R
start_test.bat -TestId:GLD-1014 -PowerMeter
start_test.bat -TestId:GLD-1010 -Emon_edp
```

### Step 2: Convert to PowerShell

Apply the conversion rules:
```powershell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 900 -RunTime 0
.\RunTest.ps1 -TestID GLD-1014 -PowerMeter
.\RunTest.ps1 -TestID GLD-1010 -EMON
```

### Step 3: Create Test Config Files

For each test, create a `{TestID}.config.ps1` file:

```powershell
# GLD-1015.config.ps1
return @{
    TestID = "GLD-1015"
    TestName = "3DMark Wildlife Extreme"
    TestType = "Perf"
    TestDomain = "Golden"
    TestCMD = "C:\Path\To\Test.exe"
    WaitTime = 10
    Repeats = 1
}
```

### Step 4: Test Each Conversion

Run each converted command and verify:
- ✅ Test executes correctly
- ✅ Monitoring data is collected
- ✅ Output files are in correct location
- ✅ File naming matches expectations

### Step 5: Update Automation Scripts

Replace batch calls in automation scripts with PowerShell equivalents.

---

## Common Conversion Examples

### Example 1: SoCWatch with Wait Until Complete

**Batch**:
```batch
start_test.bat -TestId:GLD-1001 -SoCWatch 900W:0R
```

**PowerShell**:
```powershell
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch -WaitTime 900 -RunTime 0
```

### Example 2: PowerMeter with 30s Wait

**Batch**:
```batch
start_test.bat -TestId:GLD-1015 -PowerMeter 30W
```

**PowerShell**:
```powershell
.\RunTest.ps1 -TestID GLD-1015 -PowerMeter -WaitTime 30
```

### Example 3: EMON P-Core Monitoring

**Batch**:
```batch
start_test.bat -TestId:GLD-1014 -Emon_P_Core
```

**PowerShell**:
```powershell
.\RunTest.ps1 -TestID GLD-1014 -EMON_P_Core
```

### Example 4: Just Workload (No Monitoring)

**Batch**:
```batch
start_test.bat -TestId:GLD-1015 -JWorkload
```

**PowerShell**:
```powershell
.\RunTest.ps1 -TestID GLD-1015 -JWorkload
```

### Example 5: Multiple Monitors (Only Highest Priority Runs)

**Batch**:
```batch
start_test.bat -TestId:GLD-1015 -SoCWatch -PowerMeter -Emon_edp
```

**PowerShell**:
```powershell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -PowerMeter -EMON
# Only SoCWatch will run (highest priority)
```

### Example 6: VTune Performance Snapshot

**Batch**:
```batch
start_test.bat -TestId:GLD-1015 -PerfMon_ps
```

**PowerShell**:
```powershell
.\RunTest.ps1 -TestID GLD-1015 -PerfMon_PS
```

---

## Timing Parameter Conversion

### Format Explanation

**Batch Format**: `{waitTime}W:{runTime}R`
- `W` = Wait time in seconds
- `R` = Run time in seconds
- Combined in single string

**PowerShell Format**: Separate parameters
- `-WaitTime {seconds}`
- `-RunTime {seconds}`

### Conversion Table

| Batch | PowerShell |
|-------|------------|
| `5W:15R` | `-WaitTime 5 -RunTime 15` |
| `30W:60R` | `-WaitTime 30 -RunTime 60` |
| `900W:0R` | `-WaitTime 900 -RunTime 0` |
| `60W` | `-WaitTime 60` (RunTime optional) |
| `0W:120R` | `-RunTime 120` (WaitTime optional) |

### Special Cases

**Wait until test completes**:
```batch
# Batch
start_test.bat -TestId:GLD-1015 -SoCWatch 900W:0R

# PowerShell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 900 -RunTime 0
```

**No timing (default)**:
```batch
# Batch
start_test.bat -TestId:GLD-1015 -SoCWatch

# PowerShell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch
```

---

## Behavioral Differences

### 1. Window Management

**Batch**: 
- Mostly hidden or minimized windows
- Some commands open visible windows

**PowerShell**:
- **SoCWatch**: Visible window (see real-time progress)
- **EMON**: Minimized window (accessible via taskbar)
- **TypePerf**: Hidden (background collection)
- **WLC**: Command window (IPF interaction)

### 2. Error Handling

**Batch**: 
- Basic error checking
- Limited error messages

**PowerShell**:
- Try/catch blocks for robust error handling
- Detailed error messages with stack traces
- Graceful cleanup on errors

### 3. Output Messages

**Batch**: 
- Echo statements
- Mixed formatting

**PowerShell**:
- Color-coded output
- Structured logging
- Progress indicators
- Status messages

---

## Troubleshooting Migration

### Issue: Test ID not found

**Error**: `Config file not found: GLD-1015.config.ps1`

**Solution**: Create the config file for your test:
```powershell
# GLD-1015.config.ps1
return @{
    TestID = "GLD-1015"
    TestName = "Your Test Name"
    TestCMD = "Your test command"
}
```

### Issue: Monitoring tool not starting

**Solution**: Check tool paths in `TestRunner.ps1`:
```powershell
[string]$PowerSliderPath = "C:\KSR_Package\KSR\Test_Run_KR\PowerSlider.exe"
[string]$SoCWatchHelperPath = "C:\KSR_Package\KSR\Test_Run_KR\tools\socwatch\64\SoCWatchHelper.exe"
```

### Issue: Different output file names

**Batch**: May use different naming conventions

**PowerShell**: Standardized naming:
- `{TestID}_socwatch.csv`
- `{TestID}_power.csv`
- `{TestID}_emon.dat`

**Solution**: Update any post-processing scripts that rely on specific filenames.

### Issue: Script execution policy

**Error**: `cannot be loaded because running scripts is disabled`

**Solution**:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---

## Testing Your Migration

### 1. Test Without Monitoring
```powershell
.\RunTest.ps1 -TestID GLD-1015
```
Expected: Test runs successfully, no monitoring data collected.

### 2. Test With SoCWatch
```powershell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch
```
Expected: SoCWatch window opens, CSV files generated.

### 3. Test With Timing
```powershell
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 30 -RunTime 60
```
Expected: 30s wait, then 60s of data collection.

### 4. Test Config Display
```powershell
.\RunTest.ps1 -TestID GLD-1015 -DisplayConfig
```
Expected: Configuration details displayed before test runs.

### 5. Test Help
```powershell
.\RunTest.ps1 -Help
```
Expected: Full help documentation displayed.

---

## Rollback Plan

If you need to revert to batch scripts:

1. **Keep batch scripts** during migration period
2. **Run both in parallel** to compare results
3. **Validate outputs** before full switchover
4. **Document differences** for your specific use cases

---

## Benefits of PowerShell Framework

1. ✅ **Modular architecture** - Easier maintenance
2. ✅ **Better error handling** - Try/catch blocks
3. ✅ **Help system** - Built-in documentation
4. ✅ **Type safety** - PowerShell class properties
5. ✅ **Config display** - Verify settings before running
6. ✅ **Cleaner syntax** - Named parameters
7. ✅ **Window management** - Appropriate visibility per tool
8. ✅ **Extensibility** - Easy to add new monitors
9. ✅ **Reusability** - Helper scripts work independently
10. ✅ **Modern** - PowerShell vs legacy batch

---

## Next Steps

1. **Review this guide** - Understand conversion patterns
2. **Create test configs** - One .config.ps1 per test
3. **Convert commands** - Apply conversion rules
4. **Test each conversion** - Verify functionality
5. **Update automation** - Replace batch calls
6. **Document changes** - Note any custom modifications
7. **Train team** - Share PowerShell knowledge

---

**Version**: 1.0  
**Last Updated**: December 17, 2024  
**Status**: Migration Guide Complete ✅
