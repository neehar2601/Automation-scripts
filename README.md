# Kings River Benchmark Test Framework v2.0

## 📋 Overview

A modular, PowerShell-based test automation framework for running performance and power KPI benchmarks with integrated monitoring support. This framework supports **cyclic monitoring** for accurate power measurements and provides a clean, configuration-driven approach to test execution.

---

## 🚀 Key Features

- ✅ **Modular Architecture** - Separate configuration files for each test case
- ✅ **Cyclic Monitoring** - Multiple monitoring cycles for consistent measurements
- ✅ **Multiple Monitor Support** - SoCWatch, PowerMeter, TypePerf, EMON, PresentMon, WLC, VTune, etc.
- ✅ **Configuration-Driven** - All test parameters in `.config.ps1` files
- ✅ **Command-Line Overrides** - Override any config parameter from command line
- ✅ **Visual Progress** - Countdown timers with progress bars
- ✅ **Error Handling** - Automatic cleanup on failures
- ✅ **Extensible** - Easy to add new tests and monitoring tools

---

## 📁 Directory Structure

```
New_Flow_5/
│
├── RunTest.ps1                 # Main entry point (universal test wrapper)
├── TestRunner.ps1              # Base class with test execution logic
├── TestConfig.ps1              # Test type classification (Power vs Perf)
├── README.md                   # This file
│
├── POWER_KPI/                  # Power KPI test configurations
│   ├── GLD-1001.config.ps1     # Busy Idle Consumer
│   ├── GLD-1002.config.ps1     # Netflix Playback
│   ├── GLD-1003.config.ps1     # YouTube Playback
│   ├── GLD-1004.config.ps1     # WebEx Meeting
│   ├── GLD-1005.config.ps1     # MS Teams Meeting
│   ├── GLD-1006.config.ps1     # Video Playback (Local)
│   └── GLD-1007.config.ps1     # Modern Standby
│
├── PERF_KPI/                   # Performance KPI test configurations
│   ├── GLD-1008.config.ps1     # Geekbench
│   ├── GLD-1009.config.ps1     # PCMark
│   ├── GLD-1010.config.ps1     # 3DMark
│   ├── GLD-1014.config.ps1     # SPECviewperf
│   ├── GLD-1015.config.ps1     # SPECworkstation
│   └── ...
│
└── Monitors/                   # Monitoring tool scripts
    ├── start_socwatch.ps1
    ├── stop_socwatch.ps1
    ├── start_power.ps1
    ├── stop_power.ps1
    ├── start_typeperf.ps1
    ├── stop_typeperf.ps1
    ├── start_emon.ps1
    ├── stop_emon.ps1
    └── ...
```

---

## 🎯 Quick Start

### Basic Usage (Single Run, No Monitoring)

```powershell
.\RunTest.ps1 -TestID GLD-1015
```

### With SoCWatch Monitoring

```powershell
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch
```

### With Custom Wait Time

```powershell
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch -WaitTime 30
```

### Multiple Monitoring Cycles (Recommended for Power Tests)

```powershell
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch -WaitTime 20 -Repeats 3 -InterCycleWait 10
```

### Display Configuration Before Running

```powershell
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch -DisplayConfig
```

### Get Help

```powershell
.\RunTest.ps1 -Help
```

---

## 🔧 Configuration Files

Each test has a `.config.ps1` file that returns a hashtable with test parameters.

### Example: `GLD-1001.config.ps1` (Power KPI)

```powershell
return @{
    TestID = 'GLD-1001'
    TestName = 'Busy Idle Consumer'
    TestDomain = 'Golden'
    TestSubDomain = 'Power_KPI'
    
    # Timing Configuration
    WaitTime = 20               # Initial wait AFTER PreStep (seconds)
    InterCycleWait = 10         # Wait BETWEEN monitoring cycles (seconds)
    Repeats = 3                 # Number of monitoring cycles
    
    # Test Command
    TestCMD = 'Start-Sleep -Seconds 60'
    
    # PreStep: Setup (runs ONCE at start)
    TestPrestepCMD = @'
& "C:\Path\To\GLD1001_Apps.ps1"
& "C:\Path\To\GLD1001_Chrome.ps1"
'@
    
    # PostStep: Cleanup (runs ONCE at end)
    TestPoststepCMD = @'
Get-Process -Name "chrome", "Teams", "Outlook", "Excel" -ErrorAction SilentlyContinue | Stop-Process -Force
'@
    
    # Monitoring Configuration
    EnableSoCWatch = $true
    
    # Result Path
    ResultPath = 'C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD-1001'
}
```

---

## 🔄 Test Execution Flow

### Single Run (Repeats = 1)

```
┌─────────────────────────────────────────────────────┐
│ 1. PreStep (setup apps, environment)               │
│    - Run prestep commands                           │
│    - Launch applications                            │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 2. Initial Wait (WaitTime)                          │
│    - System stabilization                           │
│    - Thermal equilibrium                            │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 3. Start Monitor (SoCWatch/PowerMeter/etc.)        │
│    - File: GLD-1001.csv                            │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 4. Run Test Workload (TestCMD)                     │
│    - Execute benchmark                              │
│    - Workload runs while monitoring                 │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 5. Stop Monitor                                     │
│    - Capture results                                │
│    - Save logs                                      │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 6. PostStep (cleanup)                               │
│    - Kill processes                                 │
│    - Process results                                │
└─────────────────────────────────────────────────────┘
```

### Multiple Runs (Repeats = 3)

```
┌─────────────────────────────────────────────────────┐
│ 1. PreStep (ONCE)                                   │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 2. Initial Wait (WaitTime = 20s)                    │
└─────────────────────────────────────────────────────┘
                      ↓
┌──────────────────── CYCLE 1 ────────────────────────┐
│ 3. Start Monitor → GLD-1001_cycle1.csv             │
│ 4. Run Test (60s idle)                             │
│ 5. Stop Monitor                                     │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 6. Inter-Cycle Wait (InterCycleWait = 10s)         │
└─────────────────────────────────────────────────────┘
                      ↓
┌──────────────────── CYCLE 2 ────────────────────────┐
│ 3. Start Monitor → GLD-1001_cycle2.csv             │
│ 4. Run Test (60s idle)                             │
│ 5. Stop Monitor                                     │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 6. Inter-Cycle Wait (InterCycleWait = 10s)         │
└─────────────────────────────────────────────────────┘
                      ↓
┌──────────────────── CYCLE 3 ────────────────────────┐
│ 3. Start Monitor → GLD-1001_cycle3.csv             │
│ 4. Run Test (60s idle)                             │
│ 5. Stop Monitor                                     │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│ 7. PostStep (ONCE)                                  │
└─────────────────────────────────────────────────────┘
```

**Result Files:**
- `GLD-1001_cycle1.csv` (First measurement)
- `GLD-1001_cycle2.csv` (Second measurement)
- `GLD-1001_cycle3.csv` (Third measurement)

---

## ⚙️ Configuration Parameters

### Core Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `TestID` | String | (required) | Unique test identifier (e.g., GLD-1001) |
| `TestName` | String | (required) | Human-readable test name |
| `TestDomain` | String | "Golden" | Test domain classification |
| `TestSubDomain` | String | "" | Test subdomain (e.g., Power_KPI, Perf_KPI) |
| `TestCMD` | String/ScriptBlock | (required) | Command to execute the test workload |
| `ResultPath` | String | Auto-generated | Directory to save results |

### Timing Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `WaitTime` | Int | 10 | **Initial wait** AFTER PreStep, BEFORE first monitor start (seconds) |
| `InterCycleWait` | Int | 5 | **Wait time BETWEEN** monitoring cycles (seconds) |
| `Repeats` | Int | 1 | **Number of monitoring cycles** (1 = single run) |
| `RecordTime` | Int | 0 | Recording duration (0 = until test completes) |

### PreStep/PostStep

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `TestPrestepCMD` | String | "" | Commands to run BEFORE test (setup) |
| `TestPoststepCMD` | String | "" | Commands to run AFTER test (cleanup) |

### Monitoring Tool Enables

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `EnableSoCWatch` | Bool | false | Enable SoCWatch system monitoring |
| `EnablePowerMeter` | Bool | false | Enable SystemMeter power monitoring |
| `EnableTypePerfTP` | Bool | false | Enable TypePerf (full counters) |
| `EnableTypePerfSC` | Bool | false | Enable TypePerf (subset counters) |
| `EnableEMON_P_Core` | Bool | false | Enable EMON P-Core monitoring |
| `EnableEMON_E_Core` | Bool | false | Enable EMON E-Core monitoring |
| `EnableEMON_P_Core_Cache` | Bool | false | Enable EMON P-Core cache monitoring |
| `EnableEMON_E_Core_Cache` | Bool | false | Enable EMON E-Core cache monitoring |
| `EnableEMON_EDP` | Bool | false | Enable EMON EDP (Event Data Processing) |
| `EnablePresentMon` | Bool | false | Enable PresentMon GPU monitoring |
| `EnableWLC` | Bool | false | Enable WLC (IPF) profiling |
| `EnablePerfMon_PS` | Bool | false | Enable VTune Performance Snapshot |
| `EnablePerfMon_UArch` | Bool | false | Enable VTune Microarchitecture Exploration |
| `EnablePerfMon_NPU` | Bool | false | Enable VTune NPU monitoring |
| `EnablePowerGadget` | Bool | false | Enable Intel Power Gadget |
| `EnableThermal` | Bool | false | Enable PTAT thermal monitoring |
| `EnableOSPerf` | Bool | false | Enable OS Performance (xperf + typeperf) |

### Monitoring Timing (Tool-Specific)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `SoCWatchWaitTime` | Int | 0 | SoCWatch-specific wait time (inherits WaitTime if 0) |
| `SoCWatchRunTime` | Int | 0 | SoCWatch recording duration |
| `PowerMeterWaitTime` | Int | 0 | PowerMeter-specific wait time (inherits WaitTime if 0) |
| `PowerMeterRunTime` | Int | 0 | PowerMeter recording duration |
| `TypePerfWaitTime` | Int | 0 | TypePerf-specific wait time (inherits WaitTime if 0) |
| `EMONWaitTime` | Int | 0 | EMON-specific wait time (inherits WaitTime if 0) |
| `EMONRunTime` | Int | 0 | EMON recording duration |

### SoCWatch Flags

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `SoCWatchFlags` | String | (see below) | SoCWatch command-line flags |

**Default SoCWatch Flags:**
```
-f sys -f memss-pstate -f cpu -f gfx -f npu -f power -f temp -f display -f io
```

---

## 📝 Command-Line Parameters

### Test Selection

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-TestID <string>` | Test case ID to execute | `-TestID GLD-1001` |

### Monitoring Tools (Switches)

| Parameter | Description |
|-----------|-------------|
| `-SoCWatch` | Enable SoCWatch monitoring |
| `-PowerMeter` | Enable PowerMeter monitoring |
| `-TypePerf_TP` | Enable TypePerf (full counters) |
| `-TypePerf_SC` | Enable TypePerf (subset counters) |
| `-EMON` | Enable EMON EDP monitoring |
| `-EMON_P_Core` | Enable EMON P-Core monitoring |
| `-EMON_E_Core` | Enable EMON E-Core monitoring |
| `-EMON_P_Core_Cache` | Enable EMON P-Core cache monitoring |
| `-EMON_E_Core_Cache` | Enable EMON E-Core cache monitoring |
| `-PresentMon` | Enable PresentMon GPU monitoring |
| `-WLC` | Enable WLC (IPF) profiling |
| `-PerfMon_PS` | Enable VTune Performance Snapshot |
| `-PerfMon_UArch` | Enable VTune Microarchitecture Exploration |
| `-PerfMon_NPU` | Enable VTune NPU monitoring |
| `-PowerGadget` | Enable Intel Power Gadget |
| `-Thermal` | Enable PTAT thermal monitoring |
| `-OSPerf` | Enable OS Performance monitoring |
| `-JWorkload` | Run workload only (no monitoring) |

### Timing Overrides

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-WaitTime <int>` | Override initial wait time (seconds) | `-WaitTime 30` |
| `-RunTime <int>` | Override monitoring duration (seconds) | `-RunTime 60` |
| `-Repeats <int>` | Override number of monitoring cycles | `-Repeats 3` |
| `-InterCycleWait <int>` | Override inter-cycle wait time (seconds) | `-InterCycleWait 15` |

### Display Options

| Parameter | Description |
|-----------|-------------|
| `-DisplayConfig` | Show configuration before execution |
| `-Help` or `-h` | Display help information |

---

## 💡 Usage Examples

### Example 1: Basic Test (No Monitoring)

```powershell
.\RunTest.ps1 -TestID GLD-1015
```

**What happens:**
- Runs GLD-1015 (SPECworkstation) without monitoring
- Uses default timing from config file

---

### Example 2: Power Test with SoCWatch (Single Run)

```powershell
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch
```

**What happens:**
- Runs GLD-1001 (Busy Idle Consumer)
- Single monitoring cycle (config default: Repeats=3 is overridden to 1 if not specified)
- Uses config defaults for WaitTime (20s)
- Output: `GLD-1001.csv`

---

### Example 3: Power Test with Multiple Cycles (Recommended)

```powershell
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch -WaitTime 20 -Repeats 3 -InterCycleWait 10
```

**What happens:**
1. PreStep: Launch apps (Teams, Outlook, Excel, Chrome)
2. Wait 20 seconds (system stabilization)
3. **Cycle 1:** Start SoCWatch → Run test (60s idle) → Stop SoCWatch → Save `GLD-1001_cycle1.csv`
4. Wait 10 seconds (inter-cycle wait)
5. **Cycle 2:** Start SoCWatch → Run test (60s idle) → Stop SoCWatch → Save `GLD-1001_cycle2.csv`
6. Wait 10 seconds (inter-cycle wait)
7. **Cycle 3:** Start SoCWatch → Run test (60s idle) → Stop SoCWatch → Save `GLD-1001_cycle3.csv`
8. PostStep: Kill apps (Teams, Outlook, Excel, Chrome)

**Benefits of Multiple Cycles:**
- ✅ Consistent measurements
- ✅ Statistical averaging
- ✅ Detect anomalies
- ✅ Better accuracy for power measurements

---

### Example 4: Performance Test with EMON

```powershell
.\RunTest.ps1 -TestID GLD-1015 -EMON -WaitTime 30
```

**What happens:**
- Runs SPECworkstation with EMON monitoring
- 30-second stabilization wait before monitoring starts

---

### Example 5: Override Config with Command Line

```powershell
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch -WaitTime 60 -Repeats 5 -InterCycleWait 20
```

**What happens:**
- Overrides config defaults:
  - WaitTime: 20s → 60s
  - Repeats: 3 → 5
  - InterCycleWait: 10s → 20s
- Runs 5 monitoring cycles with longer waits

---

### Example 6: Display Configuration Before Running

```powershell
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch -DisplayConfig
```

**Output:**
```
================================================================
  Test Configuration: GLD-1001
================================================================
  TestType            : Perf
  TestID              : GLD-1001
  TestName            : Busy Idle Consumer
  TestDomain          : Golden
  TestSubDomain       : Power_KPI
  Temperature         : 83
  RecordTime          : 0
  WaitTime            : 20
  InterCycleWait      : 10
  Repeats             : 3
  ResultPath          : C:\KSR_Package\...\GLD-1001
  EnableSoCWatch      : True
  ...
================================================================
```

---

### Example 7: Multiple Monitoring Tools (Priority-Based)

```powershell
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch -EMON -PowerMeter
```

**What happens:**
- Only **one** monitoring tool runs (highest priority)
- Priority order: SoCWatch → PowerMeter → TypePerf → EMON → ...
- In this case: **SoCWatch** runs (highest priority)

---

### Example 8: Run Workload Only (No Monitoring)

```powershell
.\RunTest.ps1 -TestID GLD-1001 -JWorkload
```

**What happens:**
- Runs PreStep → Test → PostStep
- Skips all monitoring
- Useful for testing workload without overhead

---

## 🎨 Visual Output Examples

### Single Run Output

```
================================================================
  PreStep: GLD-1001
================================================================
  Test Name: Busy Idle Consumer
  Domain: Golden | SubDomain: Power_KPI
  Temperature Limit: 83°C
  Initial Wait Time: 20s
  Monitoring Cycles: 1
  Executing Prestep Command...
  [OK] Prestep command completed
  [OK] PreStep completed

================================================================
  Test Execution: GLD-1001
================================================================

  [WAIT] Initial stabilization: 20 seconds...
  [########################################] Initial Wait: Complete!
  [OK] Initial wait completed

  [INFO] Running test with cyclic SoCWatch monitoring
  [INFO] Number of cycles: 1

  ============================================
  Monitoring Cycle 1 of 1
  ============================================

  [MONITOR] Starting SoCWatch...
  [OK] Monitoring started

  [TEST] Executing workload...
  [OK] Workload completed

  [MONITOR] Stopping SoCWatch...
  [OK] Monitoring stopped

  [SUCCESS] All 1 monitoring cycle(s) completed

================================================================
  PostStep: GLD-1001
================================================================
  Result Path: C:\KSR_Package\...\GLD-1001
  Executing Poststep Command...
  [OK] Poststep command completed
  [OK] Results saved to: C:\KSR_Package\...\GLD-1001
  [OK] PostStep completed

================================================================
  Test Completed: GLD-1001
  Status: Success | Duration: 95.3s
================================================================
```

### Multiple Runs Output

```
================================================================
  Test Execution: GLD-1001
================================================================

  [WAIT] Initial stabilization: 20 seconds...
  [####################--------------------] Initial Wait: 12s remaining
  ...
  [########################################] Initial Wait: Complete!

  [INFO] Running test with cyclic SoCWatch monitoring
  [INFO] Number of cycles: 3

  ============================================
  Monitoring Cycle 1 of 3
  ============================================

  [MONITOR] Starting SoCWatch...
  [OK] Monitoring started

  [TEST] Executing workload...
  [OK] Workload completed

  [MONITOR] Stopping SoCWatch...
  [OK] Monitoring stopped

  [WAIT] Inter-cycle wait: 10 seconds...
  [########################################] Inter-Cycle Wait: Complete!

  ============================================
  Monitoring Cycle 2 of 3
  ============================================
  ...

  [SUCCESS] All 3 monitoring cycle(s) completed
```

---

## 🛠️ Creating a New Test

### Step 1: Create Config File

Create a new file in `POWER_KPI/` or `PERF_KPI/` directory:

**Example: `POWER_KPI/GLD-1008.config.ps1`**

```powershell
return @{
    TestID = 'GLD-1008'
    TestName = 'My New Power Test'
    TestDomain = 'Golden'
    TestSubDomain = 'Power_KPI'
    
    # Timing
    WaitTime = 30
    InterCycleWait = 15
    Repeats = 3
    
    # Test Command
    TestCMD = 'C:\Path\To\MyBenchmark.exe'
    
    # PreStep (optional)
    TestPrestepCMD = @'
Write-Host "Setting up test environment..."
# Add your setup commands here
'@
    
    # PostStep (optional)
    TestPoststepCMD = @'
Write-Host "Cleaning up..."
# Add your cleanup commands here
'@
    
    # Monitoring
    EnableSoCWatch = $true
    
    # Results
    ResultPath = 'C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD-1008'
}
```

### Step 2: Add to TestConfig.ps1 (If Power KPI)

Edit `TestConfig.ps1` to classify your test:

```powershell
# Power KPI Tests
$powerKPIs = @(
    'GLD-1001',
    'GLD-1002',
    'GLD-1003',
    # ... existing tests ...
    'GLD-1008'  # Add your test ID here
)

return $powerKPIs
```

### Step 3: Run Your Test

```powershell
.\RunTest.ps1 -TestID GLD-1008 -SoCWatch
```

---

## 🐛 Troubleshooting

### Issue: "Unable to find type [BenchmarkTest]"

**Cause:** `TestRunner.ps1` not loaded or has syntax errors

**Solution:**
1. Check for syntax errors in `TestRunner.ps1`
2. Ensure file is in the same directory as `RunTest.ps1`
3. Try: `Get-Content .\TestRunner.ps1 | Out-Null` to check for errors

---

### Issue: "Config file not found"

**Cause:** Test ID not recognized or config file missing

**Solution:**
1. Check if file exists: `Test-Path .\POWER_KPI\GLD-1001.config.ps1`
2. Verify test ID spelling
3. Run `.\RunTest.ps1 -Help` to see available tests

---

### Issue: Monitors Don't Start

**Cause:** Monitoring scripts missing or incorrect paths

**Solution:**
1. Check `Monitors/` directory exists
2. Verify monitoring scripts are present:
   - `start_socwatch.ps1`
   - `stop_socwatch.ps1`
   - etc.
3. Check script paths in `TestRunner.ps1` line ~195

---

### Issue: PreStep/PostStep Commands Fail

**Cause:** Invalid PowerShell syntax or missing files

**Solution:**
1. Test commands separately in PowerShell console
2. Check file paths in `TestPrestepCMD` and `TestPoststepCMD`
3. Use absolute paths instead of relative paths
4. Escape special characters properly

---

### Issue: Results Not Saved

**Cause:** Invalid or inaccessible `ResultPath`

**Solution:**
1. Verify path exists: `Test-Path "C:\KSR_Package\..."`
2. Check write permissions
3. Use auto-generated path (omit `ResultPath` in config)

---

## 📊 Best Practices

### For Power KPI Tests

✅ **Use Multiple Cycles**
```powershell
-Repeats 3  # Minimum 3 cycles for statistical significance
```

✅ **Allow Adequate Stabilization**
```powershell
-WaitTime 30  # 30+ seconds for thermal equilibrium
```

✅ **Use Inter-Cycle Waits**
```powershell
-InterCycleWait 10  # 10+ seconds to reset system state
```

✅ **Close Background Apps**
```powershell
TestPoststepCMD = "Get-Process -Name 'chrome','teams' | Stop-Process -Force"
```

---

### For Performance KPI Tests

✅ **Single Run Sufficient**
```powershell
-Repeats 1  # Performance tests usually don't need multiple cycles
```

✅ **Shorter Wait Times**
```powershell
-WaitTime 10  # 10-15 seconds usually enough
```

✅ **Use Appropriate Monitors**
- CPU-intensive: EMON, TypePerf
- GPU-intensive: PresentMon
- Mixed workload: SoCWatch

---

### General Best Practices

✅ **Always Use `-DisplayConfig`** for first run
```powershell
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch -DisplayConfig
```

✅ **Consistent Result Paths**
```powershell
ResultPath = 'C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\{TestID}'
```

✅ **Use Descriptive Test Names**
```powershell
TestName = 'Netflix 1080p Playback - 30min'
```

✅ **Document PreStep Requirements**
```powershell
TestPrestepCMD = @'
# REQUIRES: Chrome installed, Netflix account configured
& "C:\Path\To\Setup.ps1"
'@
```

---

## 🔍 Advanced Features

### Custom Monitoring Tool Timing

Override tool-specific wait times:

```powershell
return @{
    TestID = 'GLD-1001'
    # ...
    WaitTime = 20               # Default wait time
    SoCWatchWaitTime = 30       # SoCWatch-specific override
    PowerMeterWaitTime = 25     # PowerMeter-specific override
}
```

### ScriptBlock Test Commands

Use scriptblocks for complex test logic:

```powershell
return @{
    TestID = 'GLD-1001'
    TestCMD = {
        Write-Host "Starting complex test..."
        for ($i = 1; $i -le 5; $i++) {
            Write-Host "Iteration $i"
            Start-Sleep -Seconds 10
        }
        Write-Host "Test complete!"
    }
}
```

### Multi-Line PreStep/PostStep

```powershell
TestPrestepCMD = @'
Write-Host "Step 1: Launching apps..."
& "C:\Apps\Launch.ps1"

Write-Host "Step 2: Configuring environment..."
Set-ItemProperty -Path "HKCU:\Software\MyApp" -Name "Setting" -Value "Value"

Write-Host "Step 3: Waiting for apps to stabilize..."
Start-Sleep -Seconds 15
'@
```

---

## 📈 Performance Considerations

### Memory Usage
- Each monitoring tool consumes ~50-200MB RAM
- Multiple cycles do not increase memory significantly (files written to disk)

### Disk Space
- SoCWatch: ~10-50MB per cycle
- PowerMeter: ~5-20MB per cycle
- EMON: ~100-500MB per cycle
- Plan for ~500MB per test execution

### Execution Time

| Test Type | Single Cycle | 3 Cycles | 5 Cycles |
|-----------|-------------|----------|----------|
| Short (1min) | ~2min | ~6min | ~10min |
| Medium (5min) | ~6min | ~18min | ~30min |
| Long (30min) | ~31min | ~93min | ~155min |

**Formula:** `TotalTime ≈ WaitTime + (TestDuration + InterCycleWait) × Repeats + PostStepTime`

---

## 🎓 Training & Support

### Additional Resources

- **TestRunner.ps1** - Main class implementation (read for API details)
- **RunTest.ps1** - Entry point with parameter handling
- **TestConfig.ps1** - Test classification logic
- **Existing .config.ps1 files** - Real-world examples

### Getting Help

```powershell
# Display help
.\RunTest.ps1 -Help

# List available tests
Get-ChildItem .\POWER_KPI\*.config.ps1 | ForEach-Object { $_.BaseName -replace '\.config$' }
Get-ChildItem .\PERF_KPI\*.config.ps1 | ForEach-Object { $_.BaseName -replace '\.config$' }

# Check test configuration
.\RunTest.ps1 -TestID GLD-1001 -DisplayConfig
```

---

## 📝 Version History

### v2.0 (February 2026)
- ✅ Implemented cyclic monitoring (multiple start/stop cycles)
- ✅ Added `InterCycleWait` parameter for wait time between cycles
- ✅ Added countdown timers with progress bars
- ✅ Improved error handling with automatic cleanup
- ✅ Command-line parameter overrides for all config settings
- ✅ Visual feedback improvements
- ✅ Modular architecture with class-based design

### v1.0 (December 2025)
- Initial release with basic test execution
- Single monitoring cycle support
- Configuration file support

---

## 🤝 Contributing

### Adding New Monitoring Tools

1. Create `Monitors/start_toolname.ps1` and `Monitors/stop_toolname.ps1`
2. Add `EnableToolName` parameter to `TestRunner.ps1` class
3. Add tool detection logic to `Test()` method
4. Add tool handling to `RunWithCyclicMonitoring()` method
5. Update `RunTest.ps1` with new switch parameter
6. Update this README with documentation

---

## 📄 License

Copyright © 2026 Intel Corporation. All rights reserved.

---

## 🎯 Summary

This framework provides a **flexible**, **modular**, and **powerful** way to execute benchmark tests with integrated monitoring. Key highlights:

- 🚀 **Easy to use** - Simple command-line interface
- 🔧 **Highly configurable** - Config files + CLI overrides
- 🔄 **Cyclic monitoring** - Multiple measurements for accuracy
- 📊 **Multiple monitors** - SoCWatch, PowerMeter, EMON, TypePerf, PresentMon, etc.
- ✅ **Production-ready** - Error handling, logging, automatic cleanup

**Get Started:**
```powershell
.\RunTest.ps1 -TestID GLD-1001 -SoCWatch -WaitTime 30 -Repeats 3
```

---

**Questions? Issues? Suggestions?**  
Contact the test automation team or refer to the inline documentation in the source files.
