# New Test Execution Flow - Updated Architecture

## Overview
The test execution flow has been updated to provide better visibility and control:
- **Monitoring tools** run in **separate windows** (visible/minimized)
- **Test workload** runs in the **MAIN window** (same PowerShell console)
- **Sequential execution** with clear start/stop phases

---

## Execution Flow

### 1. **Start Monitoring** (Separate Window)
```
┌─────────────────────────────────────┐
│  Monitoring Window (Separate)      │
│  - SoCWatch: Visible                │
│  - EMON: Minimized                  │
│  - TypePerf: Hidden                 │
│  - PresentMon: Minimized            │
└─────────────────────────────────────┘
```

### 2. **Wait for Stabilization** (Main Window)
```
Main Window:
  [SoCWatch] Waiting 30 seconds for stabilization...
  [Progress displayed in main console]
```

### 3. **Run Test** (Main Window - VISIBLE)
```
Main Window:
  [SoCWatch] Running test in main window...
  Executing: <Test Command>
  
  ┌─────────────────────────────────┐
  │  TEST OUTPUT APPEARS HERE       │
  │  [All test output visible]      │
  │  [Real-time progress]           │
  └─────────────────────────────────┘
  
  [OK] Test execution completed
```

### 4. **Stop Monitoring** (Main Window)
```
Main Window:
  [SoCWatch] Waiting 3 seconds before stopping...
  [SoCWatch] Stopping data collection...
  [SoCWatch] Retrieving results...
  [OK] SoCWatch monitoring completed
```

---

## Updated Monitoring Modules

All monitoring modules now follow this pattern:

### **SoCWatch.ps1** (Visible Window)
```powershell
# Step 1: Start monitoring in SEPARATE WINDOW (visible)
Write-Host "[SoCWatch] Starting monitoring in separate window..."
& $helperScript -Action Start

# Step 2: Wait for stabilization (if specified)
Write-Host "[SoCWatch] Waiting 30 seconds..."
Start-Sleep -Seconds 30

# Step 3: Run test in MAIN WINDOW
Write-Host "[SoCWatch] Running test in main window..."
if ($TestCMD -is [scriptblock]) {
    & $TestCMD
} else {
    Invoke-Expression $TestCMD
}

# Step 4: Stop monitoring
Write-Host "[SoCWatch] Stopping data collection..."
& $helperScript -Action Stop

# Step 5: Get results
Write-Host "[SoCWatch] Retrieving results..."
& $helperScript -Action GetResults
```

### **EMON.ps1** (Minimized Window)
- Starts EMON in **minimized window** (clean desktop)
- Test runs in **main window**
- Sequential start → test → stop → results

### **PowerMeter.ps1**
- Starts SystemMeter monitoring
- Test runs in **main window**
- Stops monitoring after test completes

### **TypePerf.ps1** (Hidden Window)
- Starts TypePerf in **hidden background**
- Test runs in **main window**
- Stops TypePerf after completion

### **PresentMon.ps1** (Minimized Window)
- Starts PresentMon in **minimized window**
- Test runs in **main window**
- Stops PresentMon after completion

### **WLC.ps1**
- Cleans IPF logs
- Starts IPF profiling
- Test runs in **main window**
- Completes profiling

---

## Window Visibility Strategy

| Monitoring Tool | Window Mode | Reason |
|-----------------|-------------|--------|
| **SoCWatch** | Visible | Users need real-time SoC metrics feedback |
| **EMON** | Minimized | Verbose output, accessible via taskbar |
| **TypePerf** | Hidden | Background counter collection |
| **PowerMeter** | Hidden | Background power monitoring |
| **PresentMon** | Minimized | GPU metrics, accessible if needed |
| **WLC/IPF** | N/A | Driver-level profiling |
| **Test Workload** | **MAIN WINDOW** | **Always visible to user** |

---

## Benefits of New Flow

### ✅ **1. Test Output Visibility**
- All test output appears in **main console window**
- Real-time progress visible to user
- Easy to monitor test execution
- No need to check background jobs

### ✅ **2. Monitoring in Separate Windows**
- Monitoring tools don't clutter main window
- SoCWatch visible for real-time metrics
- EMON minimized (accessible via taskbar)
- TypePerf hidden (just collecting data)

### ✅ **3. Sequential Execution**
```
1. Start monitoring → 2. Run test → 3. Stop monitoring → 4. Print results
```
- Clear execution phases
- No background job complexity
- Easy to debug issues
- Deterministic flow

### ✅ **4. ScriptBlock Support**
Tests can use both formats:
```powershell
# String command
TestCMD = "benchmark.exe --run"

# ScriptBlock command (recommended)
TestCMD = {
    Start-Process -FilePath "benchmark.exe" `
        -ArgumentList '--run' `
        -RedirectStandardOutput "output.txt" `
        -Wait
}
```

### ✅ **5. Error Handling**
- Try/catch blocks ensure monitoring stops on error
- Main window shows all error messages
- Easy to identify where failures occur

---

## Example Execution Output

### **With SoCWatch Monitoring:**
```powershell
PS> .\RunTest.ps1 -TestID GLD-8001 -SoCWatch -WaitTime 30

Loading config: GLD-8001.config.ps1

Active Monitoring Tools: SoCWatch
Timing Parameters: WaitTime=30s

Starting test execution: GLD-8001
================================================================

================================================================
  PreStep: GLD8001
================================================================
  Test Name: Babel Stream Memory Benchmark
  Domain: Golden | SubDomain: Memory
  Temperature Limit: 60°C
  Wait Time: 30s
  [OK] PreStep completed

================================================================
  Test Execution: GLD8001
================================================================
  [SoCWatch] Monitoring enabled
  [SoCWatch] Starting monitoring in separate window...
  
  ┌─────────────────────────────────┐
  │  SoCWatch Window (Visible)      │  ← Separate window opens
  │  [Real-time SoC metrics]        │
  └─────────────────────────────────┘
  
  [SoCWatch] Waiting 30 seconds for stabilization...
  [Progress: 30s countdown]
  
  [SoCWatch] Running test in main window...
  Executing: <ScriptBlock>
  
  ┌─────────────────────────────────┐
  │  BABEL STREAM OUTPUT            │  ← Test runs in MAIN window
  │  Array size: 268435456          │
  │  Running kernels...             │
  │  Copy:  125.4 GB/s              │
  │  Scale: 123.8 GB/s              │
  │  Add:   129.2 GB/s              │
  │  Triad: 130.1 GB/s              │
  └─────────────────────────────────┘
  
  [OK] Test execution completed
  
  [SoCWatch] Waiting 3 seconds before stopping...
  [SoCWatch] Stopping data collection...
  [SoCWatch] Retrieving results...
  [OK] SoCWatch monitoring completed

================================================================
  PostStep: GLD8001
================================================================
  Result Path: C:\KSR_Package\...\GLD8001
  [OK] PostStep completed

================================================================
                     Test Summary
================================================================
  Test ID     : GLD8001
  Test Name   : Babel Stream Memory Benchmark
  Status      : Success
  Duration    : 45.32 seconds
  [OK] Test completed successfully!
```

### **Without Monitoring (Normal Mode):**
```powershell
PS> .\RunTest.ps1 -TestID GLD-8001

Loading config: GLD-8001.config.ps1

Starting test execution: GLD8001
================================================================

================================================================
  Test Execution: GLD8001
================================================================
  [INFO] Running test without monitoring
  Executing: <ScriptBlock>
  
  ┌─────────────────────────────────┐
  │  BABEL STREAM OUTPUT            │  ← Test runs in MAIN window
  │  [All output visible]           │
  └─────────────────────────────────┘
  
  [OK] Test execution completed
```

---

## Usage Examples

### **1. Run with SoCWatch (with wait time)**
```powershell
.\RunTest.ps1 -TestID GLD-8001 -SoCWatch -WaitTime 30
```
**Flow:**
1. SoCWatch starts in **visible window**
2. Waits **30 seconds** in main window
3. Test runs in **main window** (output visible)
4. SoCWatch stops
5. Results displayed

### **2. Run with EMON (minimized)**
```powershell
.\RunTest.ps1 -TestID GLD-1016 -EMON
```
**Flow:**
1. EMON starts in **minimized window**
2. Waits **3 seconds** (default)
3. Test runs in **main window**
4. EMON stops
5. Results displayed

### **3. Run with TypePerf (hidden)**
```powershell
.\RunTest.ps1 -TestID GLD-2001 -TypePerf_TP
```
**Flow:**
1. TypePerf starts in **hidden window**
2. Test runs in **main window**
3. TypePerf stops
4. Results displayed

### **4. Run without monitoring**
```powershell
.\RunTest.ps1 -TestID GLD-8001
```
**Flow:**
1. Test runs directly in **main window**
2. All output visible
3. Results displayed

---

## Key Changes from Previous Version

| Aspect | Old Flow | New Flow |
|--------|----------|----------|
| **Test Execution** | Background job | **Main window** |
| **Test Output** | Hidden in job | **Visible in console** |
| **Monitoring Window** | Background/Hidden | **Separate window** |
| **User Experience** | Need to check jobs | **Real-time visibility** |
| **Debugging** | Complex (job inspection) | **Simple (console output)** |
| **Flow** | Parallel (complex) | **Sequential (clear)** |

---

## Technical Details

### **ScriptBlock vs String TestCMD**

Both formats are supported:

#### **String Format:**
```powershell
TestCMD = "benchmark.exe --run"
```
- Executed via `Invoke-Expression`
- Works for simple commands

#### **ScriptBlock Format (Recommended):**
```powershell
TestCMD = {
    Start-Process -FilePath "benchmark.exe" `
        -ArgumentList '--run' `
        -RedirectStandardOutput "output.txt" `
        -RedirectStandardError "error.txt" `
        -NoNewWindow -Wait
}
```
- Executed via `& $TestCMD`
- Better control over execution
- Proper output redirection
- Error handling

### **Detection Logic:**
```powershell
if ($TestCMD -is [scriptblock]) {
    Write-Host "<ScriptBlock>" -ForegroundColor Gray
    & $TestCMD
} else {
    Write-Host "$TestCMD" -ForegroundColor Gray
    Invoke-Expression $TestCMD
}
```

---

## Monitoring Module Pattern

All monitoring modules follow this consistent pattern:

```powershell
function Invoke-<Tool>Monitoring {
    param([object]$TestInstance)
    
    try {
        # Step 1: Start monitoring (separate window)
        Write-Host "[Tool] Starting monitoring..."
        Start-Monitoring
        
        # Step 2: Wait for stabilization
        Write-Host "[Tool] Waiting for stabilization..."
        Start-Sleep -Seconds 3
        
        # Step 3: Run test in MAIN WINDOW
        Write-Host "[Tool] Running test in main window..."
        if ($TestCMD -is [scriptblock]) {
            & $TestCMD
        } else {
            Invoke-Expression $TestCMD
        }
        Write-Host "[OK] Test execution completed"
        
        # Step 4: Stop monitoring
        Write-Host "[Tool] Stopping monitoring..."
        Stop-Monitoring
        
        # Step 5: Get results
        Write-Host "[Tool] Retrieving results..."
        Get-Results
        
        Write-Host "[OK] Tool monitoring completed"
    }
    catch {
        Write-Host "[ERROR] Monitoring failed: $_"
        Stop-Monitoring  # Ensure cleanup
        throw
    }
}
```

---

## Migration Notes

### **For Existing Test Configs:**

1. **String TestCMD:** No changes needed, works as before
2. **ScriptBlock TestCMD:** Already supported, works better
3. **Monitoring switches:** Same as before
4. **Timing parameters:** Same as before

### **What Changed:**

1. **Test now runs in main window** (not background job)
2. **Test output visible in real-time**
3. **Monitoring windows separate** (not hidden jobs)
4. **Sequential flow** (easier to debug)

### **What Stayed the Same:**

1. All command-line switches
2. All monitoring tools
3. All timing parameters
4. All config file formats

---

## Troubleshooting

### **If test output is not visible:**
- Test should now ALWAYS appear in main window
- Check if TestCMD is properly defined
- Verify monitoring module updated to new flow

### **If monitoring doesn't start:**
- Check helper script paths
- Verify monitoring tool installed
- Look for error messages in main window

### **If monitoring doesn't stop:**
- Try/catch blocks should handle this
- Check PowerSlider calls
- Manual stop: `Stop-Process -Name "toolname"`

---

## Summary

✅ **Monitoring:** Runs in **separate windows**  
✅ **Test Workload:** Runs in **MAIN window** (visible)  
✅ **Flow:** Sequential **Start → Test → Stop → Results**  
✅ **Output:** **Real-time visibility** in console  
✅ **Debugging:** **Simple and straightforward**  

**Result:** Better user experience with clear visibility and control! 🚀

---

**Version:** 2.1  
**Date:** December 22, 2025  
**Status:** ✅ Implemented and Ready
