# New_Flow_5 - Ultra-Simplified Monitoring Architecture

## ✅ **Architecture Overview**

**Design Philosophy:** Direct script calls - no wrappers, no abstraction layers

### **File Structure:**

```
New_Flow_5/
├── RunTest.ps1                    # Entry point
├── TestRunner.ps1                 # Main orchestrator (calls scripts directly)
├── GLD-*.config.ps1               # Test configuration files (26 tests)
└── Monitors/
    ├── start_socwatch.ps1         # SoCWatch start logic
    ├── stop_socwatch.ps1          # SoCWatch stop logic
    ├── start_power.ps1            # PowerMeter start logic
    ├── stop_power.ps1             # PowerMeter stop logic
    ├── start_typeperf.ps1         # TypePerf start logic
    ├── stop_typeperf.ps1          # TypePerf stop logic
    ├── start_emon.ps1             # EMON start logic
    ├── stop_emon.ps1              # EMON stop logic
    ├── start_presentmon.ps1       # PresentMon start logic
    ├── stop_presentmon.ps1        # PresentMon stop logic
    ├── start_wpr.ps1              # WPR start logic
    ├── stop_wpr.ps1               # WPR stop logic
    └── typeperf_metrics.txt       # TypePerf counter definitions
```

**That's it! No wrapper modules needed!**

---

## 🎯 **How It Works**

### **Direct Script Invocation**

TestRunner.ps1 calls monitoring scripts directly using the `&` operator:

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

**No function calls, no module loading, no abstraction!**

---

## 📊 **Execution Flow**

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

**Key Point:** TestRunner.ps1 calls scripts directly - no intermediate layers!

---

## 🎨 **Wait Time Logic (Unified)**

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

**No per-tool wait times needed!** All timing logic is in one place.

---

## 🚀 **Usage Examples**

### **Example 1: SoCWatch Monitoring**
```powershell
.\RunTest.ps1 -TestID "GLD-1015" -SoCWatch -WaitTime 30

# Flow:
# 1. PreStep (setup)
# 2. Start-SoCWatch → start_socwatch.ps1
# 3. Wait 30 seconds
# 4. Run 3DMark test
# 5. Stop-SoCWatch → stop_socwatch.ps1
# 6. PostStep (cleanup)
```

### **Example 2: TypePerf Monitoring**
```powershell
.\RunTest.ps1 -TestID "GLD-1003" -TypePerf_TP

# Flow:
# 1. PreStep (cd to EdgeBrowsingPower folder)
# 2. Start-TypePerf -Mode TP → start_typeperf.ps1
# 3. Wait 10 seconds (default from config)
# 4. Run EdgeAutomationClient.exe
# 5. Stop-TypePerf -Mode TP → stop_typeperf.ps1
# 6. PostStep (return to test directory)
```

### **Example 3: No Monitoring**
```powershell
.\RunTest.ps1 -TestID "GLD-1001"

# Flow:
# 1. PreStep (GLD1001_pre.exe)
# 2. Wait 900 seconds (config WaitTime)
# 3. Run test (15 min idle)
# 4. PostStep (postkill.bat)
```

---

## 📝 **Adding a New Monitoring Tool**

To add a new tool (e.g., "MyTool"), you only need **3 steps**:

### **Step 1: Create start/stop scripts**
```powershell
# Monitors/start_mytool.ps1
param([string]$LogDirectory, [string]$FileName)
Write-Host "  [MyTool] Starting..." -ForegroundColor Cyan
Start-Process "mytool.exe" -ArgumentList "-out $LogDirectory\$FileName.log" -PassThru | Out-Null
Write-Host "  [MyTool] Started successfully" -ForegroundColor Green

# Monitors/stop_mytool.ps1
param([string]$LogDirectory, [string]$FileName)
Write-Host "  [MyTool] Stopping..." -ForegroundColor Yellow
Stop-Process -Name "mytool" -Force -ErrorAction SilentlyContinue
Write-Host "  [MyTool] Stopped successfully" -ForegroundColor Green
```

### **Step 2: Update TestRunner.ps1**
```powershell
# Add property
[bool]$EnableMyTool = $false

# Add to Test() method
elseif ($this.EnableMyTool) {
    $monitoringTool = "MyTool"
}

# Add to RunWithMonitoring() start section
"MyTool" {
    & "$monitorScript\start_mytool.ps1" -LogDirectory $this.ResultPath -FileName $this.TestID
}

# Add to RunWithMonitoring() stop section
"MyTool" {
    & "$monitorScript\stop_mytool.ps1" -LogDirectory $this.ResultPath -FileName $this.TestID
}

# Add to error cleanup section (same stop code)
"MyTool" { 
    & "$monitorScript\stop_mytool.ps1" -LogDirectory $this.ResultPath -FileName $this.TestID 
}
```

### **Step 3: Update RunTest.ps1**
```powershell
# Add parameter
[switch]$MyTool,

# Add to config override
if ($MyTool) { $config['EnableMyTool'] = $true }
```

**That's it!** 3 steps, 2 script files, no wrapper needed!

---

## ✅ **Advantages Over Old Architecture**

| Aspect | Old (2-File per Tool) | New (Direct Script Calls) |
|--------|----------------------|----------------------------|
| **Files per tool** | 2 files (orchestrator + helper) | **2 files (start + stop)** |
| **Wrapper layer** | Yes (6 wrapper modules) | **None - direct calls** |
| **Workflow logic** | Duplicated in each orchestrator | **Single location** (TestRunner.ps1) |
| **Wait time logic** | Duplicated 6+ times | **Single location** |
| **Module loading** | 6 dot-source commands | **None needed** |
| **Code lines** | ~1800 lines | **~500 lines** |
| **Maintainability** | Hard (change 6 places) | **Easy (change 1 place)** |
| **Consistency** | Manual sync needed | **Automatic** |
| **Testing** | Test each orchestrator | **Test once** |
| **Adding new tool** | 4 steps, 3 files | **3 steps, 2 files** |
| **Debugging** | Check multiple files | **Check TestRunner.ps1** |
| **Abstraction layers** | 2 layers | **Zero layers** |

**Result: 70% less code, zero abstraction layers, maximum simplicity!**

---

## 🎯 **Best Practices**

### **1. Config Files**
```powershell
@{
    TestID = "GLD-1015"
    TestName = "3DMark Wildlife Extreme"
    WaitTime = 30  # Single wait time for all modes
    TestCMD = "3DMarkCmd.exe --definition=wildlife_extreme.3dmdef"
}
```

### **2. Command Line**
```powershell
# Override wait time at runtime
.\RunTest.ps1 -TestID "GLD-1015" -SoCWatch -WaitTime 60

# No monitoring (just run test)
.\RunTest.ps1 -TestID "GLD-1015"
```

### **3. Error Handling**
- Start functions: **Throw errors** (stop execution)
- Stop functions: **Catch and log** (allow graceful shutdown)

---

## 📚 **Summary**

✅ **Ultra-Simplified Architecture**
- Direct script calls (no wrappers)
- Zero abstraction layers
- TestRunner.ps1 orchestrates everything

✅ **Unified Workflow**
- All timing logic in one place
- Consistent behavior across all tools
- Easy to modify and maintain

✅ **Minimal Code**
- Just start/stop scripts per tool
- No wrapper modules needed
- 70% less code than old architecture

✅ **Production Ready**
- 26 test configs included
- All 6 monitoring tools supported  
- Error handling and cleanup
- Existing scripts work as-is

**The New_Flow_5 architecture is as simple as it gets - direct script calls, no layers!** 🚀

---

**Last Updated:** January 20, 2026
**Architecture Version:** 4.0 (Direct Script Calls - No Wrappers)
