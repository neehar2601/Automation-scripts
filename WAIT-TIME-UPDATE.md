# Wait Time Update - Framework v2.1

## Overview

The framework now uses a **unified wait time** approach to eliminate confusion and potential conflicts between test-level and monitor-level wait times.

---

## Key Changes

### Before (v2.0) - Confusing

```powershell
# Different wait times could conflict:
WaitTime = 60               # For normal execution
SoCWatchWaitTime = 900      # For SoCWatch
PowerMeterWaitTime = 30     # For PowerMeter

# Problem: Which one gets used?
```

### After (v2.1) - Unified ✅

```powershell
# Single wait time for all:
WaitTime = 60

# Automatically propagates to:
# - SoCWatchWaitTime = 60
# - PowerMeterWaitTime = 60
# - TypePerfWaitTime = 60
# - EMONWaitTime = 60
```

---

## How It Works

### Automatic Inheritance (Constructor)

```powershell
BenchmarkTest([hashtable]$config) {
    # ... load config ...
    
    # Inherit WaitTime for monitoring tools if not explicitly set
    if ($this.SoCWatchWaitTime -eq 0 -and $this.WaitTime -gt 0) {
        $this.SoCWatchWaitTime = $this.WaitTime
    }
    if ($this.PowerMeterWaitTime -eq 0 -and $this.WaitTime -gt 0) {
        $this.PowerMeterWaitTime = $this.WaitTime
    }
    if ($this.TypePerfWaitTime -eq 0 -and $this.WaitTime -gt 0) {
        $this.TypePerfWaitTime = $this.WaitTime
    }
    if ($this.EMONWaitTime -eq 0 -and $this.WaitTime -gt 0) {
        $this.EMONWaitTime = $this.WaitTime
    }
}
```

---

## Execution Flow Comparison

### Without Monitoring

```
┌─────────────────────────────────────┐
│ PreStep                             │
│   ↓                                 │
│ Wait (WaitTime) ← Applied here      │
│   ↓                                 │
│ Run Test                            │
│   ↓                                 │
│ PostStep                            │
└─────────────────────────────────────┘
```

### With SoCWatch Monitoring

```
┌─────────────────────────────────────┐
│ PreStep                             │
│   ↓                                 │
│ Start SoCWatch (separate window)    │
│   ↓                                 │
│ Wait (SoCWatchWaitTime)             │
│     ← Inherited from WaitTime       │
│   ↓                                 │
│ Run Test (main window)              │
│   ↓                                 │
│ Stop SoCWatch                       │
│   ↓                                 │
│ Get Results                         │
│   ↓                                 │
│ PostStep                            │
└─────────────────────────────────────┘
```

**Key Point:** Wait is applied **ONCE** at the appropriate location. No duplication!

---

## Usage Examples

### Example 1: Simple Wait Time

```powershell
@{
    TestID = "GLD-1015"
    WaitTime = 30  # 30 seconds stabilization
    TestCMD = "3DMarkCmd.exe --run"
}
```

**Behavior:**
- Without monitoring: Waits 30s, runs test
- With SoCWatch: Starts SoCWatch, waits 30s, runs test
- With PowerMeter: Starts PowerMeter, waits 30s, runs test

### Example 2: Power Test with Long Wait

```powershell
@{
    TestID = "GLD-1001"
    TestName = "Busy Idle Consumer"
    TestType = "Power"
    WaitTime = 900  # 15 minutes stabilization
    TestCMD = "Start-Sleep -Seconds 900"
}
```

**Behavior:**
- Without monitoring: Waits 900s, then runs test (900s idle)
- With SoCWatch: Starts SoCWatch, waits 900s, runs test, captures power data
- With PowerMeter: Starts PowerMeter, waits 900s, runs test, measures power

### Example 3: Override for Specific Tool

```powershell
@{
    TestID = "GLD-1015"
    WaitTime = 30              # Default: 30s
    SoCWatchWaitTime = 120     # Override: SoCWatch needs 2 min
    TestCMD = "3DMarkCmd.exe --run"
}
```

**Behavior:**
- Without monitoring: Waits 30s
- With SoCWatch: Waits 120s (overridden)
- With PowerMeter: Waits 30s (inherited)
- With TypePerf: Waits 30s (inherited)

### Example 4: Command-Line Override

```powershell
# Config has WaitTime = 30

# Override at runtime:
.\RunTest.ps1 -TestID GLD-1015 -SoCWatch -WaitTime 60

# SoCWatch will use 60s instead of 30s
```

---

## Migration Guide

### Old Configs (Still Work!)

```powershell
# Old way (still supported):
@{
    TestID = "GLD-1001"
    WaitTime = 60
    SoCWatchWaitTime = 900  # Explicit override
}
```

### New Configs (Recommended)

```powershell
# New way (simpler):
@{
    TestID = "GLD-1001"
    WaitTime = 900  # Single setting
}
```

**No breaking changes!** Both approaches work.

---

## Benefits

### ✅ Consistency
- Same wait time across all execution modes
- Predictable behavior

### ✅ Simplicity
- One parameter to set: `WaitTime`
- No need to remember monitor-specific names

### ✅ Flexibility
- Can still override per-tool if needed
- Can override at runtime via command-line

### ✅ No Conflicts
- Wait applied once at correct location
- No overlap or duplication

---

## Troubleshooting

### Q: My test waits too long with SoCWatch
**A:** Check if `SoCWatchWaitTime` is explicitly set in config. If so, it overrides `WaitTime`.

```powershell
# Remove explicit override:
# SoCWatchWaitTime = 900  ← Remove this line

# Use unified wait:
WaitTime = 60  # Will be used for all modes
```

### Q: Different monitors need different wait times
**A:** Set base `WaitTime` for most tools, override specific ones:

```powershell
WaitTime = 30                  # Default for most
SoCWatchWaitTime = 900         # Override for SoCWatch
PowerMeterWaitTime = 60        # Override for PowerMeter
```

### Q: How to skip wait entirely?
**A:** Set `WaitTime = 0` or omit it:

```powershell
@{
    TestID = "GLD-1008"
    # WaitTime not set or = 0
    TestCMD = "cinebench.exe"
}
```

---

## Technical Details

### Wait Time Priority

1. **Command-line parameter** (highest priority)
   ```powershell
   .\RunTest.ps1 -TestID GLD-1015 -WaitTime 120
   ```

2. **Tool-specific config** (medium priority)
   ```powershell
   SoCWatchWaitTime = 900
   ```

3. **Base WaitTime** (default)
   ```powershell
   WaitTime = 60
   ```

### Where Wait Happens

| Execution Mode | Where Wait Occurs | Code Location |
|----------------|-------------------|---------------|
| No monitoring | `RunNormal()` | TestRunner.ps1:147 |
| With SoCWatch | `Invoke-SoCWatchMonitoring` | Monitors/SoCWatch.ps1 |
| With PowerMeter | `Invoke-PowerMeterMonitoring` | Monitors/PowerMeter.ps1 |
| With TypePerf | `Invoke-TypePerfMonitoring` | Monitors/TypePerf.ps1 |
| With EMON | `Invoke-EMONMonitoring` | Monitors/EMON.ps1 |

---

## Summary

✅ **Use `WaitTime` for all tests** - It will work everywhere  
✅ **Override if needed** - Set tool-specific wait times only when necessary  
✅ **No conflicts** - Framework ensures wait is applied once at the right time  
✅ **Backward compatible** - Old configs still work  

**Updated:** December 22, 2024 - Framework v2.1
