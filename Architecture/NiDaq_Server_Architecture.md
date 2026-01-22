# NiDaq Server Architecture Documentation

## Overview

The **NiDaq Server** (NiDaq_Server.py) is a socket-based server application designed to control and coordinate power measurement testing using PACS (Power Analysis and Characterization Software) hardware. It acts as a central orchestrator for automated test execution, data collection, and system control in a distributed testing environment.

**Current Version:** 1.13  
**Last Updated:** January 22, 2026  
**Primary Language:** Python 3.x

## Architecture

### Component Structure

```
┌─────────────────────────────────────────────────────────┐
│                    NiDaq Server                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │         Socket Server (TCP)                       │  │
│  │         Host: Configurable                        │  │
│  │         Port: Configurable (default: 55555)       │  │
│  └───────────────────────────────────────────────────┘  │
│                         │                               │
│  ┌──────────────────────┴────────────────────────────┐  │
│  │        Command Processing Layer                   │  │
│  │  (Codes: 101-113)                                 │  │
│  └──────────────────────┬────────────────────────────┘  │
│                         │                               │
│  ┌──────────┬───────────┴──────┬──────────┬──────────┐  │
│  │   PACS   │   Test Control   │  File    │  Remote  │  │
│  │  Control │   & Workload     │ Transfer │  Exec    │  │
│  │          │   Management     │          │ (psexec) │  │
│  └──────────┴──────────────────┴──────────┴──────────┘  │
└─────────────────────────────────────────────────────────┘
              │                    │                │
    ┌─────────┘                    │                └─────────┐
    │                              │                          │
┌───▼────┐                    ┌────▼─────┐              ┌─────▼────┐
│  PACS  │                    │  Client  │              │  Remote  │
│Hardware│                    │  System  │              │ Scripts  │
│(pyPACS)│                    │   (SUT)  │              │  & Tools │
└────────┘                    └──────────┘              └──────────┘
```

## Core Components

### Configuration Management

The server reads from a `config.ini` file containing:

- **Server Settings**: Host IP and port
- **Path Configuration**: 
  - `result_path`: Where measurement results are stored (e.g., `C:\Test\results`)
  - `PACS_exe_path`: Location of PACS executable (e.g., `C:\Intel\PACS\pacs.exe`)
  - `PACS_path`: PACS installation directory (e.g., `C:\Intel\PACS` or `C:\Program Files\PACS`)
  - `config_file_path`: Test configuration file (e.g., `C:\Test\testconfig.csv`)
  - `delay_before_start_recording`: Pre-recording delay (default: 10 seconds)

**Additional Path Constants:**
- `KSR_path`: `C:\KSR_Package\KSR\Test_Run_KR` (Client-side test framework path)
- `SUT_result_path`: `C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results` (Client result storage)

**Example Configuration:**
```ini
[Server]
host = 192.168.0.3
port = 55555

[Paths]
result_path = C:\Test\results
PACS_exe_path = C:\Intel\PACS\pacs.exe
PACS_path = C:\Intel\PACS
config_file_path = C:\Test\testconfig.csv
delay_before_start_recording = 10
```

**Important Notes:**
- The server supports both `C:\Intel\PACS` and `C:\Program Files\PACS` installation paths
- PACS path is automatically added to Python `sys.path` for `__pyPACS` import
- Configuration validation ensures all required paths exist before server starts

### 2. PACS Integration

Uses the `__pyPACS` library (Intel proprietary) to control power measurement hardware:

- **Status Codes**:
  - `-1`: Not running / None
  - `0`: Unconfigured
  - `1`: Configured Idle
  - `2`: Running (Ready to record)
  - `3`: Collecting Data (Recording)
  - `4`: Paused
  - `5`: Processing Data

- **Key Operations**:
  - `p.version()`: Get PACS version string
  - `p.runPACS(exe_path)`: Start PACS application (accepts path with spaces using quotes)
  - `p.loadConfig(config_path)`: Load measurement configuration from CSV
  - `p.startDAQ(mode)`: Initialize data acquisition (mode: 0)
  - `p.record(path, filename)`: Start recording measurements to specified directory
  - `p.stop()`: Stop current recording
  - `p.exit()`: Close PACS application
  - `p.status()`: Get current PACS state (returns string: "-1", "0", "1", "2", "3", "4", "5")

**PACS State Machine:**
```
┌─────────┐
│ Stopped │
│  (-1)   │
└────┬────┘
     │ runPACS()
     ▼
┌─────────┐
│Unconfigured
│   (0)   │
└────┬────┘
     │ loadConfig()
     ▼
┌─────────┐
│Configured
│Idle (1) │
└────┬────┘
     │ startDAQ()
     ▼
┌─────────┐
│ Running │ ←─────┐
│   (2)   │       │
└────┬────┘       │
     │ record()   │ stop()
     ▼            │
┌──────────┐      │
│Recording │──────┘
│   (3)    │
└────┬─────┘
     │ exit()
     ▼
┌─────────┐
│ Stopped │
│  (-1)   │
└─────────┘
```

**Special Handling for Program Files Path:**
```python
if "Program Files\PACS" in PACS_exe_path:
    p.runPACS('"C:\Program Files\PACS\pacs.exe"')  # Quoted path
else:
    p.runPACS(PACS_exe_path)
```

### 3. Command Protocol (Codes 101-113)

The server accepts numeric commands from clients:

| Code | Function | Description | Status |
|------|----------|-------------|--------|
| **101** | Online Check | Returns PACS version | ✅ Implemented |
| **102** | Create Test Case | Client-side only (not server) | ⚠️ Client |
| **103** | Start PACS | Initializes PACS with configuration | ✅ Implemented |
| **104** | PACS Status | Returns current PACS state | ✅ Implemented |
| **105** | Start Recording | Recording with timing control (W:R: format) | ✅ Implemented |
| **106** | Stop PACS | Stops recording and exits PACS | ✅ Implemented |
| **107** | File Transfer | Sends CSV results to client | ✅ Implemented |
| **108** | Mark Complete | Client-side only (updates KPI list) | ⚠️ Client |
| **109** | Set Temperature | Controls test chamber temperature | ✅ Implemented |
| **110** | Get Temperature | Fetches current temperature | ✅ Implemented |
| **111** | Copy Results | Client-side result organization | ⚠️ Client |
| **112** | Advanced Test | Complex multi-workload orchestration | ✅ Implemented |
| **113** | Network Copy | Copies results via network share (server-side) | ✅ Implemented |

**Command Validation:**
```python
# Server validates incoming commands
if isinstance(message, str) and "105" in message:
    # Special handling for 105 with parameters
elif isinstance(message, str) and "112" in message:
    # Special handling for 112 (most complex)
elif not isinstance(message, numbers.Number):
    try:
        value = int(message)
        if not 101 <= value <= 113:
            print_error("Invalid code")
    except ValueError:
        print_error("Invalid code")
```

### Code 101: Online Check
```
Client → Server: "101"
Server → Client: "PACS Online - Version X.X.X"
```

### Code 103: Start PACS
```
Client → Server: "103"
Server Actions:
  1. Check if PACS already running
  2. If not, execute p.runPACS()
  3. Load configuration file
  4. Start DAQ
Server → Client: "PACS Started Successfully" or "PACS Already Running"
```

### Code 105: Recording with W:R: Format

**Input Format:**
```
"105 W:30:R:60:W:10"
```

**Parameter Format:**
- `W:<seconds>`: Wait for specified seconds
- `R:<seconds>`: Record for specified seconds

**Execution Logic:**
```python
parts = message.split(" ")
if len(parts) > 1:
    values = parts[1].split(":")  # ["W", "30", "R", "60", "W", "10"]
    
    # Check if all values contain 'R' or 'W'
    if all(any(c in v.lower() for c in ["r", "w"]) for v in values):
        record_count = 0
        for value in values:
            time_part = "".join(filter(str.isdigit, value))    # Extract numbers
            action_part = "".join(filter(str.isalpha, value))  # Extract letters
            
            if action_part.lower() == "w":  # Wait
                time.sleep(int(time_part))
            elif action_part.lower() == "r":  # Record
                record_count += 1
                p.record(result_path, f"NiDaqResult{record_count}")
                if int(time_part) > 0:
                    time.sleep(int(time_part) - 2)
                    if not p.status() == "-1":
                        p.stop()
```

**Example:**
```
Client → "105 W:30:R:60:W:10:R:120"

Server Actions:
  1. Wait 30 seconds
  2. Start recording (NiDaqResult1)
  3. Record for 60 seconds
  4. Stop recording
  5. Wait 10 seconds
  6. Start recording (NiDaqResult2)
  7. Record for 120 seconds
  8. Stop recording
```

**Simple Mode (No Parameters):**
```
Client → "105"

Server Actions:
  1. Wait <delay_before_start_recording> seconds (from config, default: 10)
  2. Start recording (NiDaqResult)
  3. [Recording continues until manual stop]
```

### Code 112: Advanced Test Execution (Most Complex)

**Input Format:**
```
"112 -TestId:GLD1015 -InitialWait:60 -WorkloadInitialWait:30 
     -JWORKLOAD(InitialWait:10,Repeat:3,Record:120,Wait:30) 
     -SOCWATCH(Repeat:2,Record:60,Wait:15)
     -RESTART"
```

**Supported Workload Types:**
- `JWORKLOAD`: Primary test workload (Just Workload)
- `SoCWatch`: Intel SoC monitoring tool
- `WLC`: Windows Lifecycle
- `TypePerf`: Windows Performance counters
- `Emon_edp`: Intel EMON Energy Data Processor
- `ETL`: Event Trace for Windows

**Parameter Extraction (Regex):**
```python
# Patterns for workload parameters
patterns = {
    "JWORKLOAD": r"-JWORKLOAD\(([^)]+)\)",
    "SoCWatch":  r"-SOCWATCH\(([^)]+)\)",
    "WLC":       r"-WLC\(([^)]+)\)",
    "TypePerf":  r"-TYPEPERF\(([^)]+)\)",
    "Emon_edp":  r"-EMON_EDP\(([^)]+)\)",
    "ETL":       r"-ETL\(([^)]+)\)"
}

# Extract key:value pairs
pattern = re.compile(r"-(\w+):([\w\-]+)", re.IGNORECASE)
params = dict(pattern.findall(message))

# Result:
# params = {
#     "TestId": "GLD1015",
#     "InitialWait": "60",
#     "WorkloadInitialWait": "30",
#     "WorkloadRestart": "Yes"  # if present
# }

# Find debug tools (workloads to monitor)
debug_pattern = r'-(\w+)(?=\()'
debug_params = [match for match in re.findall(debug_pattern, message) 
                if match.upper() != 'JWORKLOAD']
# Result: ["SOCWATCH", "WLC"] (excluding JWORKLOAD)

# Check for restart flag
Restart = bool(re.search('-RESTART', message))
```

**Per-Workload Parameters:**
```python
for name, pattern in patterns.items():
    match = re.search(pattern, part, re.IGNORECASE)
    if match:
        params = {}
        for kv in match.group(1).split(","):
            k, v = kv.split(":")
            params[k.strip()] = v.strip()
        
        # Result for JWORKLOAD(InitialWait:10,Repeat:3,Record:120,Wait:30):
        # params = {
        #     "InitialWait": "10",
        #     "Repeat": "3",
        #     "Record": "120",
        #     "Wait": "30"
        # }
```

## Workflow for Code 112 (Advanced Test Execution)

This is the most complex operation, designed for comprehensive test scenarios with multiple monitoring tools and workloads.

### Execution Flow

```
1. Command Reception & Parsing
   ├─ Receive "112" command with parameters
   ├─ Extract TestId (e.g., GLD1015)
   ├─ Extract timing parameters (InitialWait, WorkloadInitialWait)
   ├─ Identify workloads (JWORKLOAD, SoCWatch, WLC, TypePerf, EMON_EDP, ETL)
   ├─ Extract debug tools (all workloads except JWORKLOAD)
   └─ Detect restart flag (-RESTART)

2. Pre-Test System Cleanup & Preparation
   ├─ Stop any running PACS instance (p.stop(), p.exit())
   ├─ Wait 60 seconds for system stabilization
   ├─ Collect background service reports (collect_report(test_id))
   ├─ psexec → Report.bat on client system
   └─ Apply InitialWait timing (sleep_timer)

3. PACS Initialization
   ├─ Check if PACS is stopped (p.status() == "-1")
   ├─ If stopped:
   │   ├─ Start PACS: p.runPACS(PACS_exe_path)
   │   ├─ Load configuration: p.loadConfig(config_file_path)
   │   └─ Start DAQ: p.startDAQ(0)
   └─ If not ready: Log error

4. Test-Specific Pre-Execution Scripts
   ├─ GLD1006: Initiate Modern Standby via TTK
   │   ├─ Calculate total runtime for CS (Connected Standby)
   │   ├─ Check for TTK library (FrontPanel.py)
   │   └─ Execute mcs_ttk() to put system to sleep
   │
   ├─ GLD6001: Execute pre-test script
   │   └─ psexec → GLD6001_pre.exe
   │
   ├─ GLD6002: Execute pre-test script
   │   └─ psexec → GLD6002_pre.exe
   │
   ├─ GLD1001: Execute pre-test script
   │   └─ psexec → GLD1001_pre.exe
   │
   ├─ GLD5001: Execute pre-test script
   │   └─ psexec → GLD5001_pre.exe
   │
   └─ GLD5002: Execute pre-test script
       └─ psexec → GLD5002_pre.exe

5. WorkloadInitialWait
   └─ sleep_timer(WorkloadInitialWait) - Wait before starting workloads

6. For Each Workload Type (JWORKLOAD, SOCWATCH, WLC, etc.):
   │
   ├─ Mark workload start in logs (power_mode if not GLD1006/GLD1013)
   │   └─ power_mode("{workload}_Started")
   │
   ├─ For Each Repeat Iteration:
   │   │
   │   ├─ Execute test-specific repeat scripts (if applicable)
   │   │   ├─ GLD6001: psexec → Seek.exe --KPIID GLD6001
   │   │   ├─ GLD6002: psexec → Seek.exe --KPIID GLD6002
   │   │   └─ GLD1003: psexec → GLD1003.bat
   │   │
   │   ├─ Pre-check validation
   │   │   ├─ For non-GLD1013 tests: Execute NiDaq_precheck.exe
   │   │   └─ Wait for client response: "pass" or "fail"
   │   │   └─ If "fail": Log error and skip to next iteration
   │   │
   │   ├─ InitialWait (first iteration only)
   │   │   └─ If workload has InitialWait parameter and iteration == 1
   │   │       └─ sleep_timer(InitialWait)
   │   │
   │   ├─ Start debug log collection (if workload in debug_params)
   │   │   └─ collect_debug_logs(workload, "START")
   │   │
   │   ├─ Begin PACS Recording
   │   │   ├─ If Repeat == 1:
   │   │   │   └─ Filename: {TestId}_Nidaq_Result_{WorkloadName}
   │   │   └─ If Repeat > 1:
   │   │       └─ Filename: {TestId}_Nidaq_Result_{WorkloadName}_{Iteration}
   │   │   └─ p.record(result_path, filename)
   │   │
   │   ├─ Wait for recording duration
   │   │   └─ time.sleep(record_time - 2)
   │   │
   │   ├─ Stop PACS Recording
   │   │   └─ if not p.status() == "-1": p.stop()
   │   │
   │   ├─ Stop debug log collection (if workload in debug_params)
   │   │   └─ collect_debug_logs(workload, "STOP")
   │   │
   │   └─ Apply post-recording wait time
   │       └─ sleep_timer(wait_time)
   │
   ├─ Mark workload end in logs (power_mode if not GLD1006/GLD1013)
   │   └─ power_mode("{workload}_Ended")
   │
   └─ Wake from Modern Standby (if GLD1006 and TTK was used)
       └─ mcs_ttk() to wake system

7. Post-Test PACS Cleanup
   ├─ Wait 10 seconds
   ├─ Stop PACS: p.stop()
   └─ Exit PACS: p.exit()

8. Test-Specific Post-Execution Scripts
   ├─ GLD5001/GLD5002: Execute cleanup
   │   └─ psexec → teams_del.exe
   └─ All tests: Execute post-test script
       ├─ If -RESTART flag: psexec → Client_Post.cmd Restart
       └─ If no -RESTART: psexec → Client_Post.cmd NoRestart

9. Test Complete
   └─ Server ready for next command
```

### Visual Workflow Diagram

```
START
  │
  ▼
┌────────────────────┐
│ Parse Command 112  │
│ Extract Parameters │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Stop Running PACS  │
│ Collect Reports    │
│ Wait (InitialWait) │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Start PACS         │
│ Load Config        │
│ Start DAQ          │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Pre-Test Setup     │
│ (GLD-specific)     │
└─────────┬──────────┘
          │
          ▼
    ┌─────────────┐
    │  WORKLOAD 1 │ (e.g., JWORKLOAD)
    └─────┬───────┘
          │
          ├─ Iteration 1
          │   ├─ Pre-check
          │   ├─ DEBUG START (optional)
          │   ├─ RECORD (120s)
          │   ├─ STOP
          │   ├─ DEBUG STOP (optional)
          │   └─ WAIT (10s)
          │
          ├─ Iteration 2
          │   └─ [same steps]
          │
          └─ Iteration 3
              └─ [same steps]
          │
          ▼
    ┌─────────────┐
    │  WORKLOAD 2 │ (e.g., SOCWATCH)
    └─────┬───────┘
          │
          ├─ Iteration 1
          │   └─ [same pattern]
          │
          └─ Iteration 2
              └─ [same pattern]
          │
          ▼
┌────────────────────┐
│ Post-Test Cleanup  │
│ Stop PACS          │
│ Exit PACS          │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Restart/No-Restart │
│ (based on flag)    │
└─────────┬──────────┘
          │
          ▼
        END
```

## Key Features

### 1. Remote Execution via PsExec

Uses `psexec` for remote command execution on client systems:

**Function Signature:**
```python
def psexec(cmd):
    """
    Execute command on remote system
    
    Args:
        cmd: Full psexec command string including target IP, credentials, and command
    
    Returns:
        Prints stdout, stderr, and return code
    
    Process:
        - Uses subprocess.run() with shell=True
        - Captures both stdout and stderr as text
        - Has 300-second (5-minute) timeout
        - Logs command execution and results
    """
    try:
        print_Info(cmd)
        result = subprocess.run(
            cmd, 
            shell=True, 
            capture_output=True, 
            text=True, 
            timeout=300
        )
        print("Return code:", result.returncode)
        print(result.stdout)
        print(result.stderr)
    except Exception as e:
        print("Error:", e)
```

**Command Format:**
```python
# Template
psexec_cmd = rf'psexec \\{client_ip} -i 1 -d -u "Administrator" -p "" ' \
             rf'-w "{working_dir}" cmd /c "{command}"'

# Flags explained:
# -i 1         : Run interactively in session 1
# -d           : Don't wait for process to terminate (detached mode)
# -u "Admin"   : Username for authentication
# -p ""        : Password (empty in this implementation)
# -w "path"    : Working directory for command execution
# cmd /c "..."  : Execute command via cmd.exe
```

**Use Cases:**
1. **Start Test Workloads:**
```python
psexec(rf'psexec \\{client_ip} -i 1 -d -u "Administrator" -p "" ' \
       rf'-w "C:\KSR_Package\KSR\Test_Run_KR\GLD\Script" cmd /c "GLD1015_pre.exe"')
```

2. **Collect Debug Logs:**
```python
psexec(rf'psexec \\{client_ip} -u "Administrator" -p "" ' \
       rf'-w {KSR_path} cmd /c "Tool.bat SOCWATCH START {test_id}"')
```

3. **Execute Post-Test Scripts:**
```python
psexec(rf'psexec \\{client_ip} -i 1 -d -u "Administrator" -p "" ' \
       rf'-w {KSR_path} cmd /c "Client_Post.cmd Restart"')
```

4. **Collect Background Reports:**
```python
psexec(rf'psexec \\{client_ip} -d -u "Administrator" -p "" ' \
       rf'-w {KSR_path} cmd /c "Report.bat {test_id}"')
```

### 2. Multi-Workload Support

Handles multiple workload types simultaneously or sequentially:

| Workload | Purpose | Typical Use | Detection Pattern |
|----------|---------|-------------|-------------------|
| **JWORKLOAD** | Primary test workload | Main performance/power test | `-JWORKLOAD(...)` |
| **SoCWatch**  | Intel SoC monitoring | Platform power analysis | `-SOCWATCH(...)` |
| **WLC**       | Windows Lifecycle | System state transitions | `-WLC(...)` |
| **TypePerf**  | Performance counters | CPU/Memory/Disk metrics | `-TYPEPERF(...)` |
| **Emon_edp**  | Energy monitoring | Core-level power analysis | `-EMON_EDP(...)` |
| **ETL**       | Event tracing | System event logging | `-ETL(...)` |

**Regex Pattern Matching:**
```python
patterns = {
    "JWORKLOAD": r"-JWORKLOAD\(([^)]+)\)",
    "SoCWatch":  r"-SOCWATCH\(([^)]+)\)",
    "WLC":       r"-WLC\(([^)]+)\)",
    "TypePerf":  r"-TYPEPERF\(([^)]+)\)",
    "Emon_edp":  r"-EMON_EDP\(([^)]+)\)",
    "ETL":       r"-ETL\(([^)]+)\)"
}
```

**Debug Tool Identification:**
```python
# Find all debug tools (excluding JWORKLOAD which is the main workload)
debug_pattern = r'-(\w+)(?=\()'
result = re.findall(debug_pattern, message)
debug_params = [match for match in result if match.upper() != 'JWORKLOAD']
# Example result: ["SOCWATCH", "WLC", "TYPEPERF"]
```

**Example Multi-Workload Test:**
```
112 -TestId:GLD1015 -InitialWait:60
-JWORKLOAD(Repeat:3,Record:120,Wait:10)
-SOCWATCH(Repeat:3,Record:120,Wait:10)
-TYPEPERF(Repeat:3,Record:120,Wait:10)
```

**Execution Sequence:**
1. JWORKLOAD runs 3 times (3 x 120s recording = 360s total)
2. SOCWATCH runs 3 times (3 x 120s recording = 360s total)
3. TYPEPERF runs 3 times (3 x 120s recording = 360s total)
4. All synchronized with PACS power measurements
5. Each workload produces separate result files

### 3. Debug Log Collection

The `collect_debug_logs()` function triggers collection of monitoring tool data on the client system.

**Function Signature:**
```python
def collect_debug_logs(tool, action):
    """
    Collect debug logs for specific workload/tool
    
    Args:
        tool: Name of tool (JWORKLOAD, SOCWATCH, WLC, etc.)
        action: "START" or "STOP"
    
    Actions:
        - Executes Tool.bat on remote client via psexec
        - Passes test_id as parameter
        - Logs are collected on client system (SUT)
        - Synchronized with PACS recording
    
    Special Handling:
        - GLD1006: Uses -d flag (detached mode)
        - Other tests: Runs without -d flag (waits for completion)
    """
    print_Info(f"{tool} {action}")
    
    if test_id == "GLD1006":
        debug_str = rf'psexec \\{client_ip} -d -u "Administrator" -p "" ' \
                    rf'-w {KSR_path} cmd /c "Tool.bat {tool.upper()} {action.upper()} {test_id}"'
    else: 
        debug_str = rf'psexec \\{client_ip} -u "Administrator" -p "" ' \
                    rf'-w {KSR_path} cmd /c "Tool.bat {tool.upper()} {action.upper()} {test_id}"'
    
    psexec(debug_str)
```

**Tool.bat Command Format:**
```batch
Tool.bat SOCWATCH START GLD1015
Tool.bat SOCWATCH STOP GLD1015
Tool.bat WLC START GLD1015
Tool.bat WLC STOP GLD1015
```

**Debug Log Types Collected:**
- **SoCWatch**: Platform power/performance metrics (CPU, GPU, NPU, memory, display)
- **WLC**: Windows Lifecycle events (sleep/wake, power transitions)
- **TypePerf**: Windows performance counters (CPU%, memory, disk I/O)
- **EMON**: Low-level CPU performance counters (cache, TLB, branch prediction)
- **ETL**: Windows Event Tracing (kernel events, context switches)

**Workflow Integration:**
```
START Recording
  ↓
collect_debug_logs("SOCWATCH", "START") → Start SoCWatch on client
  ↓
p.record() → Start PACS power recording
  ↓
[Test runs for 120s]
  ↓
p.stop() → Stop PACS recording
  ↓
collect_debug_logs("SOCWATCH", "STOP") → Stop SoCWatch on client
  ↓
STOP Recording
```

**Result Files (on Client):**
```
C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1015\
├── GLD1015_SOCWATCH_START.log
├── GLD1015_SOCWATCH_STOP.log
├── socwatch_output.csv
├── WLC_events.etl
└── typeperf_counters.csv
```

### 4. Temperature Control

Integration with temperature control system (thermal chamber via KSRTemp.py):

**Function: Code 109 (Set Temperature)**
```python
# Client sends temperature value
Client → "109"
Server → "Waiting for Temperature...."

# Client sends temperature (e.g., "25")
Client → "25"
Server → "Temperature Values received by Server successfully."

# Server executes temperature control script
cmd = ["python", "KSRTemp.py", "--set", "25"]
result = subprocess.run(cmd, capture_output=True, text=True)

if result.stderr:
    Server → "Failed to set temperature"
else:
    Server → "Temperature has been successfully set"
```

**Function: Code 110 (Get Temperature)**
```python
# Client requests current temperature
Client → "110"

# Server queries temperature
result = subprocess.run(["python", "KSRTemp.py"], capture_output=True, text=True)

# Parse output using regex
output = result.stdout.strip()
match = re.search(r"Current Temperature:\s*(\d+(\.\d+)?)", output)
if match:
    temperature = round(float(match.group(1)), 1)
    Server → f"Current Temperature:{temperature}"
else:
    Server → "Temperature not found"
```

**Use Case Example:**
Test device under controlled thermal conditions:
```
1. Set temperature to 20°C → Code 109
2. Wait for stabilization (30 minutes)
3. Verify temperature → Code 110 (returns "Current Temperature:20.1")
4. Run power test → Code 112
5. Set temperature to 30°C → Code 109
6. Wait for stabilization (30 minutes)
7. Run power test again → Code 112
8. Compare power at different temperatures
```

**KSRTemp.py Interface:**
- `python KSRTemp.py`: Get current temperature
- `python KSRTemp.py --set <temp>`: Set target temperature
- Returns formatted output: "Current Temperature: XX.X"

### 5. File Transfer Mechanism (Code 107)

Sophisticated file transfer protocol for sending PACS CSV results to client:

**Transfer Protocol:**
```
Client → Server: "107"

Server Actions:
1. Send acknowledgment: "START FILE TRANSFER"
2. Wait for client ACK
3. Send folder count (number of result folders)
4. For each folder:
   a. Wait for client: "Send the Size"
   b. Send file size in bytes
   c. Wait for client: "Send the filename"
   d. Send filename (e.g., "NiDaqResult1_JWORKLOAD_1_summary.csv")
   e. Wait for client: "Received file Content"
   f. Send file data in 1024-byte chunks
   g. Log completion

Client Actions:
1. Send "107" command
2. Receive "START FILE TRANSFER"
3. Send "Send the folder count"
4. Receive folder count
5. For each folder:
   a. Send "Send the Size"
   b. Receive file size
   c. Send "Send the filename"
   d. Receive filename
   e. Send "Received file Content"
   f. Receive chunks until complete
   g. Save file locally
```

**Server Implementation:**
```python
if message.lower().strip() == '107':
    try:
        print_Info("COPY THE RESULT CSV FILE FROM PACS TO CLIENT SYSTEM!")
        client_socket.send("START FILE TRANSFER".encode('utf-8'))
        
        ack = client_socket.recv(1024).decode('utf-8')
        print_Info(f"Client ACK: {ack}")
        
        # Get list of result folders starting with "NiDaqResult"
        result_folders = [
            folder for folder in os.listdir(result_path)
            if os.path.isdir(os.path.join(result_path, folder)) 
            and folder.startswith("NiDaqResult")
        ]
        
        folder_count = len(result_folders)
        print_Info(f"Total result folders: {folder_count}")
        client_socket.send(str(folder_count).encode('utf-8'))
        
        for folder in result_folders:
            folder_path = os.path.join(result_path, folder)
            expected_filename = f"{folder}_summary.csv"
            full_file_path = os.path.join(folder_path, expected_filename)
            
            if os.path.exists(full_file_path):
                file_size = os.path.getsize(full_file_path)
                print_Info(f"Preparing to send: {full_file_path} ({file_size} bytes)")
                
                # Send file size
                print_Info(client_socket.recv(1024).decode('utf-8'))
                client_socket.send(str(file_size).encode('utf-8'))
                
                # Send filename
                print_Info(client_socket.recv(1024).decode('utf-8'))
                client_socket.send(expected_filename.encode('utf-8'))
                
                # Send file content
                print_Info(client_socket.recv(1024).decode('utf-8'))
                with open(full_file_path, 'rb') as file:
                    while chunk := file.read(1024):
                        client_socket.send(chunk)
                
                print_Info("CSV file sent successfully.")
            else:
                print_Info(f"File not found: {full_file_path}")
    
    except Exception as e:
        print_Info(f"Unexpected error: {e}")
```

**Error Handling:**
- Validates folder existence before transfer
- Checks for `_summary.csv` file in each folder
- Handles FileNotFoundError, OSError, socket.error
- Logs all transfer attempts and results
- Continues to next folder if one fails

**Result File Naming:**
```
NiDaqResult1/
└── NiDaqResult1_summary.csv

GLD1015_Nidaq_Result_JWORKLOAD_1/
└── GLD1015_Nidaq_Result_JWORKLOAD_1_summary.csv

GLD1015_Nidaq_Result_SOCWATCH_2/
└── GLD1015_Nidaq_Result_SOCWATCH_2_summary.csv
```

### 6. Modern Standby Support (GLD1006)

Special handling for Connected Standby (CS) / Modern Standby testing:

**Function: `mcs_ttk()`**
```python
def mcs_ttk():
    """
    Control Modern Connected Standby via TTK (Test Toolkit)
    
    Actions:
        1. Execute KSR_CS_PowerButton.py script
        2. Wait 5 seconds for system to respond
        3. Check for errors
    
    Purpose:
        - Press virtual power button to put system to sleep (CS entry)
        - Or wake system from CS (CS exit)
    
    Hardware Requirement:
        - TTK hardware connected to system
        - FrontPanel.py library must be present at:
          C:\SVshare\user_apps\ttk3\api\python\FrontPanel.py
    """
    cmd = ["python", "KSR_CS_PowerButton.py"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    time.sleep(5)
    
    if result.stderr:
        print_error("Error output on using TTK")
        print_error(result.stderr)
```

**GLD1006 Special Workflow:**
```python
if test_id == "GLD1006":
    # Calculate total CS runtime
    cs_total_runtime = 0
    cs_socwatch_runtime = 0
    
    # Extract JWORKLOAD parameters
    jworkload_match = re.search(r"-JWORKLOAD\(([^)]+)\)", message, re.IGNORECASE)
    if jworkload_match:
        params = parse_parameters(jworkload_match.group(1))
        repeat = int(params.get("Repeat", 1))
        record = int(params.get("Record"))
        wait = int(params.get("Wait"))
        cs_total_runtime = ((record + wait) * repeat) + workload_initial_wait
    
    # Extract SOCWATCH parameters (if present)
    socwatch_match = re.search(r"-SOCWATCH\(([^)]+)\)", message, re.IGNORECASE)
    if socwatch_match:
        params = parse_parameters(socwatch_match.group(1))
        repeat = int(params.get("Repeat", 1))
        record = int(params.get("Record"))
        wait = int(params.get("Wait"))
        cs_socwatch_runtime = ((record + wait) * repeat) + workload_initial_wait
    
    # Check for TTK availability
    if os.path.exists(r"C:\SVshare\user_apps\ttk3\api\python\FrontPanel.py"):
        print_Info("TTK found")
        print_Info("Connected Modern Standby using TTK")
        print_Info("Putting System into Sleep....")
        mcs_ttk()  # Put system to sleep
        ttk = True
    else:
        logging.error("TTK not found")
        pre_check = "fail"
        continue
```

**Workflow for GLD1006:**
```
1. Calculate expected CS duration
2. Verify TTK hardware present
3. Start PACS recording
4. Put system into Modern Standby (mcs_ttk)
   └─ System enters low-power state (S0ix)
5. System sleeps for calculated duration
6. PACS records power during entire sleep period
7. Wake system from Modern Standby (mcs_ttk)
8. Stop PACS recording
```

**Network Validation:**
```python
# Before test, verify system is reachable
result = subprocess.run(
    ["ping", "-n", "1", client_ip],
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL
)
if result.returncode == 0:
    pre_check = "pass"  # System reachable
else:
    logging.error("System not put to sleep, Retriggering CS")
    pre_check = "fail"  # System still awake
```

**Wake Verification:**
```python
# After CS period, wake system
if ttk:
    print_Info("Waking System from sleep..")
    mcs_ttk()  # Wake via TTK
    ttk = False
```

## Result Management

### Result Storage Structure
```
C:\Test\results\
├── NiDaqResult1\
│   └── NiDaqResult1_summary.csv
├── GLD1001_Nidaq_Result_JWORKLOAD_1\
│   ├── GLD1001_Nidaq_Result_JWORKLOAD_1_summary.csv
│   ├── GLD1001_Nidaq_Result_JWORKLOAD_1_raw.csv
│   └── GLD1001_Nidaq_Result_JWORKLOAD_1.cfg
├── GLD1001_Nidaq_Result_SOCWATCH_1\
│   └── GLD1001_Nidaq_Result_SOCWATCH_1_summary.csv
└── GLD1001_Nidaq_Result_SOCWATCH_2\
    └── GLD1001_Nidaq_Result_SOCWATCH_2_summary.csv
```

### CSV File Contents

**_summary.csv Format:**
```csv
Timestamp,Channel,Voltage(V),Current(A),Power(W),Temperature(C)
2025-01-22 10:00:00,CH1,12.05,2.34,28.20,25.3
2025-01-22 10:00:01,CH1,12.04,2.35,28.29,25.3
2025-01-22 10:00:02,CH1,12.06,2.33,28.10,25.4
...
```

### Result Processing (Code 113)

Automated result organization and network copy:

**Function: Code 113**
```python
def process_results(network_path):
    """
    Organize and copy results to network share
    
    Args:
        network_path: Target network location (e.g., \\server\share\results)
    
    Process:
        1. Scan result_path for all folders
        2. Extract Test ID from folder name
        3. Create organized directory structure
        4. Copy _summary.csv files
        5. Handle duplicates (add numbering)
        6. Clean up source directories (optional)
    """
```

**Organization Logic:**
```
Source: C:\Test\results\GLD1001_Nidaq_Result_JWORKLOAD_1\

Extract TestId: GLD1001

Target: \\server\share\results\
├── GLD1001\
│   ├── GLD1001_JWORKLOAD_1_summary.csv
│   ├── GLD1001_JWORKLOAD_2_summary.csv
│   ├── GLD1001_SOCWATCH_1_summary.csv
│   └── GLD1001_SOCWATCH_2_summary.csv
└── GLD1002\
    └── GLD1002_JWORKLOAD_1_summary.csv
```

**Duplicate Handling:**
```
If file exists: GLD1001_JWORKLOAD_1_summary.csv
Create: GLD1001_JWORKLOAD_1_summary_1.csv
If that exists: GLD1001_JWORKLOAD_1_summary_2.csv
...and so on
```

## Logging

Comprehensive logging via Python's logging module:

**Configuration:**
```python
import logging

# Log file format
log_filename = f"NiDaq_Server_Log_{datetime.now().strftime('%Y%m%d')}.log"

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_filename),
        logging.StreamHandler()  # Also print to console
    ]
)
```

**Logging Functions:**

```python
def print_Info(message):
    """Log informational messages"""
    logging.info(message)
    print(f"[INFO] {message}")

def print_error(message):
    """Log error messages"""
    logging.error(message)
    print(f"[ERROR] {message}")
```

**What Gets Logged:**
- ✅ Server startup and configuration
- ✅ Client connections (IP, timestamp)
- ✅ Command received and parsed
- ✅ PACS state changes (started, recording, stopped)
- ✅ File operations (transfer, copy, delete)
- ✅ Remote execution results (psexec)
- ✅ Error conditions and exceptions
- ✅ Test completion status

**Example Log Output:**
```
2025-01-22 10:30:00 - INFO - NiDaq Server Started on 192.168.1.10:55555
2025-01-22 10:30:15 - INFO - Client connected from 192.168.1.100
2025-01-22 10:30:16 - INFO - Command received: 112 -TestId:GLD1001...
2025-01-22 10:30:16 - INFO - Parsed TestId: GLD1001
2025-01-22 10:30:17 - INFO - PACS stopped (if running)
2025-01-22 10:30:18 - INFO - PACS started successfully
2025-01-22 10:30:45 - INFO - Recording started: GLD1001_Nidaq_Result_JWORKLOAD_1
2025-01-22 10:32:45 - INFO - Recording stopped
2025-01-22 10:32:46 - INFO - Test completed successfully
```

## Error Handling

Robust error handling throughout the application:

### 1. Configuration Validation
```python
try:
    config = configparser.ConfigParser()
    config.read('config.ini')
    
    # Validate required sections
    if 'Server' not in config:
        raise ValueError("Missing [Server] section in config.ini")
    
    # Validate paths exist
    if not os.path.exists(config['Paths']['result_path']):
        raise ValueError(f"Result path does not exist: {result_path}")
        
except Exception as e:
    print_error(f"Configuration error: {e}")
    sys.exit(1)
```

### 2. Socket Error Recovery
```python
try:
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((host, port))
    server_socket.listen(5)
except socket.error as e:
    print_error(f"Socket error: {e}")
    print_error("Port may already be in use")
    sys.exit(1)
```

### 3. File Operation Error Handling
```python
try:
    with open(csv_file, 'rb') as f:
        data = f.read()
except FileNotFoundError:
    print_error(f"File not found: {csv_file}")
    client_socket.send(b"ERROR:FILE_NOT_FOUND")
except PermissionError:
    print_error(f"Permission denied: {csv_file}")
    client_socket.send(b"ERROR:PERMISSION_DENIED")
```

### 4. PACS State Verification
```python
# Before recording
if p.getStatus() != 2:  # Should be "Running"
    print_error("PACS not in ready state")
    p.runPACS()
    time.sleep(5)
    p.loadConfig(config_file)
    p.startDAQ()

# After operation
if p.getStatus() == -1:  # Unexpectedly stopped
    print_error("PACS crashed during operation")
    # Restart PACS
    p.runPACS()
```

### 5. Subprocess Timeout Protection
```python
try:
    result = subprocess.call(
        command,
        timeout=300  # 5 minutes max
    )
except subprocess.TimeoutExpired:
    print_error("Command timed out after 300 seconds")
    # Kill process
    process.kill()
```

### 6. Network Transfer Error Detection
```python
try:
    bytes_sent = client_socket.send(data)
    if bytes_sent < len(data):
        print_error("Partial data sent - network issue")
        # Retry logic here
except socket.error as e:
    print_error(f"Network error during transfer: {e}")
    # Close connection and cleanup
```

## Test-Specific Logic

### GLD1001 (Busy Idle Consumer)
```python
if "GLD1001" in test_id or "GLD5001" in test_id:
    # Pre-execution script
    psexec("C:\\Tests\\GLD1001_PreCheck.bat", DUT_IP, username, password)
    
    # Standard workload execution
    # ...
    
    # Post-execution cleanup
    psexec("C:\\Tests\\GLD1001_Cleanup.bat", DUT_IP, username, password)
```

### GLD1006 (Connected Standby)
```python
if "GLD1006" in test_id:
    # Calculate runtime (default 20 hours)
    runtime_minutes = 20 * 60
    
    # Start PACS recording
    p.record(filename)
    
    # Trigger Modern Standby via TTK
    mcs_ttk(runtime_minutes)
    
    # Stop PACS recording
    p.stop()
```

### GLD5002 (Power Slider Test)
```python
if "GLD5002" in test_id:
    # Test all power modes
    for mode in ["Best Performance", "Balanced", "Best Power Efficiency"]:
        # Set power mode
        power_mode(mode)
        
        # Wait for system to adapt
        time.sleep(30)
        
        # Record power
        p.record(f"{test_id}_{mode}")
        time.sleep(120)
        p.stop()
```

### GLD6001/GLD6002 (Custom Pre/Post Scripts)
```python
if "GLD6001" in test_id or "GLD6002" in test_id:
    # Execute custom pre-script
    pre_script = f"C:\\Tests\\{test_id}_Pre.ps1"
    psexec(f"powershell.exe -File {pre_script}", DUT_IP, username, password)
    
    # Standard test execution
    # ...
    
    # Execute custom post-script
    post_script = f"C:\\Tests\\{test_id}_Post.ps1"
    psexec(f"powershell.exe -File {post_script}", DUT_IP, username, password)
```

## Utility Functions

### 1. `sleep_timer(seconds)`
Visual countdown timer for wait periods:

```python
def sleep_timer(seconds):
    """
    Sleep with visual countdown timer
    
    Args:
        seconds: Duration to sleep
    
    Displays:
        "Waiting for {N} seconds..." (updates in place every second)
    
    Implementation:
        - Uses range(seconds, 0, -1) for countdown
        - print() with end="\r" to overwrite line
        - time.sleep(1) for 1-second intervals
    """
    print_Info(f"Wait for {seconds}s")
    for timer in range(seconds, 0, -1):
        print(f"Waiting for {timer} seconds...", end="\r")  # '\r' overwrites line
        time.sleep(1)
```

**Example Output:**
```
[INFO] Wait for 120s
Waiting for 120 seconds...
Waiting for 119 seconds...
...
Waiting for 1 seconds...
[INFO] Wait complete
```

---

### 2. `collect_report(KPIID)`
Collect background services and system state reports:

```python
def collect_report(KPIID):
    """
    Collect system state reports from client
    
    Args:
        KPIID: Test ID (e.g., "GLD1015")
    
    Actions:
        - Executes Report.bat on client via psexec
        - Runs in detached mode (-d flag)
        - Logs are saved on client system
    
    Purpose:
        - Document running services before test
        - Capture system configuration
        - Baseline for debugging anomalies
    """
    cmd = rf'psexec \\{client_ip} -d -u "Administrator" -p "" ' \
          rf'-w {KSR_path} cmd /c "Report.bat {KPIID}"'
    print_Info("Collecting Background Services Reports.....")
    psexec(cmd)
```

**Report.bat Output (on Client):**
```
C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1015\
├── GLD1015_services.csv       # Running Windows services
├── GLD1015_processes.csv      # Active processes
├── GLD1015_drivers.txt        # Loaded drivers
└── GLD1015_system_info.txt    # System configuration
```

---

### 3. `power_mode(msg)`
Log power mode events for correlation:

```python
def power_mode(msg):
    """
    Log power mode events on client system
    
    Args:
        msg: Event message (e.g., "JWORKLOAD_Started", "SoCWatch_Ended")
    
    Actions:
        - Executes KSRPowerSlider.exe on client via psexec
        - Logs event with timestamp
        - Runs in detached mode (-d flag)
    
    Purpose:
        - Mark specific events in result logs
        - Correlate workload phases with power data
        - Debugging and analysis
    
    Note:
        - NOT executed for GLD1006 (Modern Standby)
        - NOT executed for GLD1013
    """
    cmd = rf'psexec \\{client_ip} -d -u "Administrator" -p "" ' \
          rf'-w {KSR_path} cmd /c "KSRPowerSlider.exe {SUT_result_path}\{test_id} {test_id} {msg}"'
    psexec(cmd)
```

**Usage Example:**
```python
# Before JWORKLOAD
power_mode("JWORKLOAD_Started")

# Run JWORKLOAD iterations

# After JWORKLOAD
power_mode("JWORKLOAD_Ended")
```

**Result File (on Client):**
```
C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1015\GLD1015_events.log

2025-01-22 10:30:00 - JWORKLOAD_Started
2025-01-22 10:35:00 - JWORKLOAD_Ended
2025-01-22 10:35:05 - SOCWATCH_Started
2025-01-22 10:40:05 - SOCWATCH_Ended
```

---

### 4. `print_Info(message)`
Logging wrapper for informational messages:

```python
def print_Info(message):
    """
    Log informational message
    
    Args:
        message: Message to log
    
    Actions:
        - Logs via logging.info()
        - Message includes timestamp, level, and content
    
    Format:
        YYYY-MM-DD HH:MM:SS - INFO - <message>
    """
    logging.info(message)
```

---

### 5. `print_error(message)`
Logging wrapper for error messages:

```python
def print_error(message):
    """
    Log error message
    
    Args:
        message: Error message to log
    
    Actions:
        - Logs via logging.error()
        - Message includes timestamp, level, and content
    
    Format:
        YYYY-MM-DD HH:MM:SS - ERROR - <message>
    """
    logging.error(message)
```

---

### 6. Result Processing Functions

**Not Implemented in Server** - The following functions are mentioned in original docs but not present in actual server code:

- ~~`collect_debug_logs(workload, mode, iteration)`~~ → Simplified to `collect_debug_logs(tool, action)`
- ~~`power_mode(mode)`~~ → Changed to `power_mode(msg)` for event logging only

## Connection Model

### Single-Threaded Architecture

The server operates in a **single-threaded, blocking** model:

```python
while True:
    # Accept connection (blocking)
    client_socket, client_address = server_socket.accept()
    print_Info(f"Client connected from {client_address[0]}")
    
    # Receive command (blocking)
    data = client_socket.recv(4096)
    command = data.decode('utf-8').strip()
    
    # Process command (synchronous)
    process_command(command)
    
    # Send response
    client_socket.send(response.encode('utf-8'))
    
    # Close connection
    client_socket.close()
    
    # Ready for next client
```

### Connection Lifecycle

```
1. Server Startup
   └─ Bind to host:port
   └─ Listen for connections

2. Client Connection
   └─ Accept connection
   └─ Log client IP

3. Command Reception
   └─ Receive data (up to 4096 bytes)
   └─ Decode as UTF-8
   └─ Parse command code

4. Command Execution
   └─ Execute appropriate function
   └─ May take seconds to hours (for Code 112)

5. Response Transmission
   └─ Send result/status
   └─ For file transfer, send binary data

6. Connection Closure
   └─ Close client socket
   └─ Release resources

7. Wait for Next Client
   └─ Loop back to step 2
```

### Limitations

**Single Client at a Time:**
- ❌ Cannot handle concurrent clients
- ❌ New connections blocked during command execution
- ❌ Long-running tests block server

**Workaround:**
- Each test typically runs for minutes/hours
- Only one DUT per server instance
- For multiple DUTs, run multiple server instances on different ports

**Example Multi-DUT Setup:**
```
Server 1: Port 55555 → DUT 1
Server 2: Port 55556 → DUT 2
Server 3: Port 55557 → DUT 3
```

## Dependencies

### External Libraries

#### 1. **pyPACS**
```python
import pyPACS

# PACS hardware control library
p = pyPACS.PACS()
```

**Functions Used:**
- `runPACS()`: Start PACS application
- `loadConfig(file)`: Load configuration
- `startDAQ()`: Initialize data acquisition
- `record(filename)`: Start recording
- `stop()`: Stop recording
- `exit()`: Close PACS
- `getStatus()`: Get current state

#### 2. **PsExec**
```
psexec.exe \\192.168.1.100 -u admin -p password command.exe
```

**Purpose:** Remote command execution on Windows systems

**Installation:** SysInternals Suite

#### 3. **KSRTemp.py**
```python
subprocess.call(["python", "KSRTemp.py", "25"])
```

**Purpose:** Temperature chamber control

#### 4. **KSR_CS_PowerButton.py**
```python
subprocess.call(["python", "KSR_CS_PowerButton.py", DUT_IP, "press"])
```

**Purpose:** TTK interface for power button control

### Python Standard Library

```python
import socket          # Network communication
import configparser    # Configuration file parsing
import subprocess      # Process execution
import shutil          # File operations
import logging         # Event logging
import os              # OS interface
import sys             # System functions
import time            # Time operations
from datetime import datetime  # Timestamp handling
```

## Complete Command Reference

### Command Summary Table

| Code | Name | Syntax | Response | Duration |
|------|------|--------|----------|----------|
| 101 | Online Check | `101` | `PACS Online - Version X.X` | < 1s |
| 103 | Start PACS | `103` | `PACS Started` | 5-10s |
| 104 | PACS Status | `104` | `-1` / `2` / `3` | < 1s |
| 105 | Simple Record | `105 <time> <wait> <name>` | `Recording Complete` | Variable |
| 106 | Stop PACS | `106` | `PACS Stopped` | 2-5s |
| 107 | File Transfer | `107 <folder>` | Binary data | Variable |
| 109 | Set Temperature | `109 <temp>` | `Temperature Set: <temp>` | < 5s |
| 110 | Get Temperature | `110` | `Current Temp: <temp>` | < 2s |
| 111 | Copy Results | `111 <src> <dst>` | `Copy Complete` | Variable |
| 112 | Advanced Record | `112 <parameters>` | `Test Complete` | Hours |
| 113 | Network Copy | `113 <network_path>` | `Network Copy Complete` | Variable |

### Code 112 Parameter Reference

**Full Syntax:**
```
112 -TestId:<ID> -InitialWait:<sec> -WorkloadInitialWait:<sec>
-JWORKLOAD(Repeat:<n>,Record:<sec>,Wait:<sec>,InitialWait:<sec>)
-SOCWATCH(Repeat:<n>,Record:<sec>,Wait:<sec>)
-WLC(Repeat:<n>,Record:<sec>,Wait:<sec>)
-TYPEPERF(Repeat:<n>,Record:<sec>,Wait:<sec>)
-EMON_EDP(Repeat:<n>,Record:<sec>,Wait:<sec>)
-ETL(Repeat:<n>,Record:<sec>,Wait:<sec>)
-DEBUG
-RESTART
-NORESTART
```

**Parameter Breakdown:**

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `TestId` | String | Test identification | Required |
| `InitialWait` | Integer | Pre-test wait (seconds) | 0 |
| `WorkloadInitialWait` | Integer | Wait before workloads (seconds) | 0 |
| `Repeat` | Integer | Number of iterations | 1 |
| `Record` | Integer | Recording duration (seconds) | Required |
| `Wait` | Integer | Wait between iterations (seconds) | 0 |
| `InitialWait` | Integer | Wait before workload (seconds) | 0 |
| `DEBUG` | Flag | Enable debug logging | Off |
| `RESTART` | Flag | Reboot after test | Off |
| `NORESTART` | Flag | No reboot after test | On |

## Use Case Examples

### Use Case 1: Simple Power Measurement
```
Goal: Measure idle power for 2 minutes

Commands:
1. Client → "103" (Start PACS)
2. Client → "105 120 30 IdleTest" (Record 120s after 30s wait)
3. Client → "107 IdleTest_Nidaq_Result" (Download CSV)
4. Client → "106" (Stop PACS)

Result: IdleTest_Nidaq_Result_summary.csv with 120 seconds of power data
```

### Use Case 2: Workload Power Analysis
```
Goal: Measure power during 3DMark benchmark (3 runs)

Command:
112 -TestId:GLD1015 -InitialWait:60
-JWORKLOAD(Repeat:3,Record:300,Wait:60,InitialWait:30)
-SOCWATCH(Repeat:3,Record:300,Wait:60)

Process:
1. Wait 60s (system stabilization)
2. Start PACS
3. Wait 30s (workload initial wait)
4. For 3 iterations:
   - Start PACS recording (GLD1015_Nidaq_Result_JWORKLOAD_<i>)
   - Start SoCWatch monitoring
   - Record for 300s (5 minutes)
   - Stop recording
   - Stop SoCWatch
   - Wait 60s between iterations
5. Stop PACS

Result: 
- 3 PACS CSV files (JWORKLOAD_1, JWORKLOAD_2, JWORKLOAD_3)
- 3 SoCWatch log files (SOCWATCH_1, SOCWATCH_2, SOCWATCH_3)
```

### Use Case 3: Temperature-Controlled Testing
```
Goal: Test power at 3 different temperatures

Commands:
1. Client → "109 20" (Set to 20°C)
2. Wait 30 minutes (temperature stabilization)
3. Client → "110" (Verify: "Current Temp: 20.1°C")
4. Client → "112 -TestId:GLD1001_20C -JWORKLOAD(Repeat:1,Record:600)"
5. Client → "109 25" (Set to 25°C)
6. Wait 30 minutes
7. Client → "112 -TestId:GLD1001_25C -JWORKLOAD(Repeat:1,Record:600)"
8. Client → "109 30" (Set to 30°C)
9. Wait 30 minutes
10. Client → "112 -TestId:GLD1001_30C -JWORKLOAD(Repeat:1,Record:600)"

Result: Power profiles at 20°C, 25°C, and 30°C for comparison
```

### Use Case 4: Debug-Enabled Power Test
```
Goal: Measure power with detailed system state logs

Command:
112 -TestId:GLD1001 -InitialWait:60
-JWORKLOAD(Repeat:1,Record:120,Wait:0)
-DEBUG

Process:
1. Wait 60s
2. Start PACS
3. Collect debug logs (START) → services.csv, processes.csv
4. Start recording
5. Record for 120s
6. Stop recording
7. Collect debug logs (STOP) → services.csv, processes.csv
8. Stop PACS

Result:
- PACS power data (GLD1001_Nidaq_Result_JWORKLOAD_1_summary.csv)
- Pre-test system state (GLD1001_DEBUG_START.zip)
- Post-test system state (GLD1001_DEBUG_STOP.zip)
```

### Use Case 5: Modern Standby Power (GLD1006)
```
Goal: Measure Connected Standby power for 8 hours

Command:
112 -TestId:GLD1006 -InitialWait:30
-JWORKLOAD(Repeat:1,Record:28800,Wait:0)

Process:
1. Wait 30s (system stable)
2. Start PACS recording
3. Trigger Modern Standby via TTK (sleep)
4. System enters low-power state
5. Record for 28800s (8 hours)
6. Wake system via TTK
7. Stop PACS recording

Result: 8-hour power profile showing Connected Standby power consumption
```

## Architecture Patterns

### 1. Command-Response Pattern
```
Client                          Server
   │                               │
   ├────── Command (101) ─────────>│
   │                               │ [Process]
   │                               │
   │<────── Response ──────────────┤
   │      "PACS Online"            │
   │                               │
```

### 2. State Machine Pattern (PACS)
```
┌─────────────┐
│   Stopped   │ ◄──────────────┐
│   (Code -1) │                │
└──────┬──────┘                │
       │ runPACS()             │
       ▼                       │
┌─────────────┐                │
│   Running   │                │ exit()
│   (Code 2)  │                │
└──────┬──────┘                │
       │ record()              │
       ▼                       │
┌─────────────┐                │
│  Recording  │                │
│   (Code 3)  │                │
└──────┬──────┘                │
       │ stop()                │
       └───────────────────────┘
```

### 3. Orchestration Pattern (Code 112)
```
┌──────────────────────────────────────┐
│       Server (Orchestrator)          │
│                                      │
│  ┌────────────────────────────────┐ │
│  │   Workload Sequencer           │ │
│  └────────┬───────────────────────┘ │
│           │                          │
│  ┌────────▼────────┐  ┌───────────┐ │
│  │ PACS Controller │  │  Remote   │ │
│  │                 │  │  Executor │ │
│  │ - Start         │  │ (psexec)  │ │
│  │ - Record        │  │           │ │
│  │ - Stop          │  │ - Scripts │ │
│  └─────────────────┘  │ - Tools   │ │
│                       └───────────┘ │
└──────────────────────────────────────┘
           │                    │
           │                    │
    ┌──────▼─────┐      ┌──────▼──────┐
    │    PACS    │      │     DUT     │
    │  Hardware  │      │   (Client)  │
    └────────────┘      └─────────────┘
```

## Performance Considerations

### Bottlenecks

1. **Single-threaded**: Only one client at a time
2. **Blocking I/O**: Server waits for long operations
3. **Network Transfer**: 1024-byte chunks may be slow for large files
4. **PsExec Overhead**: Remote execution adds latency

### Optimization Opportunities

1. **Multi-threading**: Handle multiple DUTs
2. **Async I/O**: Non-blocking network operations
3. **Larger Buffers**: Increase chunk size for file transfer
4. **Connection Pooling**: Reuse connections
5. **Result Caching**: Cache frequent queries

## Security Considerations

### Current Security Posture

⚠️ **Weaknesses:**
- No authentication required
- Commands executed without validation
- Credentials in plaintext (psexec)
- No encryption (plaintext TCP)
- No input sanitization

### Recommended Improvements

1. **Authentication**
   ```python
   # Token-based auth
   AUTH_TOKEN = "secret_token_12345"
   
   if data.startswith(AUTH_TOKEN):
       command = data[len(AUTH_TOKEN):].strip()
   else:
       client_socket.send(b"ERROR:UNAUTHORIZED")
   ```

2. **TLS Encryption**
   ```python
   import ssl
   
   context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
   context.load_cert_chain(certfile="server.crt", keyfile="server.key")
   
   server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
   server_socket = context.wrap_socket(server_socket, server_side=True)
   ```

3. **Input Validation**
   ```python
   # Whitelist allowed commands
   ALLOWED_COMMANDS = ['101', '103', '104', '105', '106', '107', '109', '110', '111', '112', '113']
   
   command_code = data.split()[0]
   if command_code not in ALLOWED_COMMANDS:
       print_error(f"Invalid command: {command_code}")
       return
   ```

4. **Command Injection Prevention**
   ```python
   # Sanitize TestId
   import re
   
   test_id = re.sub(r'[^A-Za-z0-9_-]', '', test_id)
   ```

## Summary

The **NiDaq Server** is a sophisticated test orchestration system designed for:

✅ **Centralized Power Measurement Control**
- Single server manages PACS hardware
- Coordinates remote test execution
- Synchronizes measurements across tools

✅ **Flexible Test Automation**
- Simple commands (101-106) for basic operations
- Complex orchestration (112) for multi-workload tests
- Supports diverse test scenarios (idle, workload, thermal, standby)

✅ **Remote Test Execution**
- Controls client systems via PsExec
- Triggers workloads remotely
- Collects results centrally

✅ **Result Management**
- Automatic CSV generation
- Organized file storage
- Network copy capabilities

✅ **Extensibility**
- Test-specific logic (GLD1001, GLD1006, etc.)
- Debug log collection
- Temperature control integration
- Modern Standby support

**The architecture enables fully automated, repeatable power measurement testing with minimal manual intervention, supporting comprehensive validation and benchmarking workflows.**

---

**Document Version:** 1.0  
**Date:** January 22, 2026  
**Author:** Architecture Documentation Team
