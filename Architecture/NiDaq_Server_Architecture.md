# NiDaq Server Architecture Documentation

## Overview

The **NiDaq Server** (NiDaq_Server.py) is a socket-based server application designed to control and coordinate power measurement testing using PACS (Power Analysis and Control System) hardware. It acts as a central orchestrator for automated test execution, data collection, and system control in a distributed testing environment.

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

### 1. Configuration Management

The server reads from a `config.ini` file containing:

- **Server Settings**: Host IP and port
- **Path Configuration**: 
  - `result_path`: Where measurement results are stored
  - `PACS_exe_path`: Location of PACS executable
  - `PACS_path`: PACS installation directory
  - `config_file_path`: Test configuration file
  - `delay_before_start_recording`: Pre-recording delay

**Example Configuration:**
```ini
[Server]
host = 192.168.1.10
port = 55555

[Paths]
result_path = C:\Test\results\
PACS_exe_path = C:\Program Files\PACS\pacs.exe
PACS_path = C:\Program Files\PACS\
config_file_path = C:\Test\configs\default.cfg
delay_before_start_recording = 5
```

### 2. PACS Integration

Uses the `pyPACS` library to control power measurement hardware:

- **Status Codes**:
  - `-1`: Not running
  - `2`: Running/Ready
  - `3`: Recording

- **Key Operations**:
  - `p.runPACS()`: Start PACS application
  - `p.loadConfig()`: Load measurement configuration
  - `p.startDAQ()`: Initialize data acquisition
  - `p.record()`: Start recording measurements
  - `p.stop()`: Stop recording
  - `p.exit()`: Close PACS

**PACS State Machine:**
```
┌─────────┐
│ Stopped │
│  (-1)   │
└────┬────┘
     │ runPACS()
     ▼
┌─────────┐
│ Running │
│   (2)   │
└────┬────┘
     │ record()
     ▼
┌──────────┐
│Recording │
│   (3)    │
└────┬─────┘
     │ stop()
     ▼
┌─────────┐
│ Stopped │
└─────────┘
```

### 3. Command Protocol (Codes 101-113)

The server accepts numeric commands from clients:

| Code | Function | Description | Parameters |
|------|----------|-------------|------------|
| **101** | Online Check | Returns PACS version | None |
| **103** | Start PACS | Initializes PACS with configuration | None |
| **104** | PACS Status | Returns current PACS state | None |
| **105** | Simple Record | Basic recording with timing control | `<record_time> <initial_wait> <filename>` |
| **106** | Stop PACS | Stops recording and exits PACS | None |
| **107** | File Transfer | Sends CSV results to client | `<folder_name>` |
| **109** | Set Temperature | Controls test chamber temperature | `<target_temp>` |
| **110** | Get Temperature | Fetches current temperature | None |
| **111** | Copy Results | Transfers results to local storage | `<source_path> <dest_path>` |
| **112** | Advanced Record | Complex multi-workload orchestration | See below |
| **113** | Network Copy | Copies results via network share | `<network_path>` |

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

### Code 105: Simple Recording
```
Client → Server: "105 120 30 Test1"
Parameters:
  - Record Time: 120 seconds
  - Initial Wait: 30 seconds
  - Filename: Test1

Server Actions:
  1. Wait 30 seconds
  2. Start recording (filename: Test1_Nidaq_Result)
  3. Wait 120 seconds
  4. Stop recording
Server → Client: "Recording Complete"
```

### Code 112: Advanced Test Execution (Most Complex)

**Input Format:**
```
112 -TestId:GLD1001 -InitialWait:60 -WorkloadInitialWait:30 
-JWORKLOAD(Repeat:3,Record:120,Wait:10,InitialWait:5) 
-SOCWATCH(Repeat:2,Record:60,Wait:15)
-RESTART
-DEBUG
```

**Parameters:**
- `-TestId`: Test identification
- `-InitialWait`: Pre-test wait time (seconds)
- `-WorkloadInitialWait`: Wait before first workload
- `-JWORKLOAD(...)`: Primary workload definition
  - `Repeat`: Number of iterations
  - `Record`: Recording duration per iteration
  - `Wait`: Wait time between iterations
  - `InitialWait`: Wait before starting workload
- `-SOCWATCH(...)`: Monitoring workload (similar params)
- `-RESTART`: Reboot system after test
- `-DEBUG`: Enable debug log collection

## Workflow for Code 112 (Advanced Test Execution)

This is the most complex operation, designed for comprehensive test scenarios:

### Execution Flow

```
1. Parse Test Parameters
   ├─ Extract TestId (e.g., GLD1001)
   ├─ Extract timing parameters (InitialWait, WorkloadInitialWait)
   ├─ Identify workloads (JWORKLOAD, SoCWatch, WLC, TypePerf, EMON_EDP, ETL)
   └─ Detect flags (DEBUG, RESTART, NORESTART)

2. Pre-Test Setup
   ├─ Stop any running PACS instance
   ├─ Collect background service reports (collect_report())
   ├─ Apply initial wait time (InitialWait)
   └─ Start PACS with configuration (runPACS() → loadConfig() → startDAQ())

3. Workload-Specific Pre-execution
   ├─ GLD1006: Initiate Modern Standby via TTK (mcs_ttk())
   ├─ GLD6001/6002: Run pre-test scripts via psexec
   └─ Apply workload initial wait (WorkloadInitialWait)

4. For Each Workload Type (JWORKLOAD, SOCWATCH, WLC, etc.):
   │
   ├─ Set Power Mode (if applicable)
   │   └─ power_mode(mode="Best Performance/Balanced/Best Power Efficiency")
   │
   ├─ For Each Repeat Iteration:
   │   │
   │   ├─ Execute pre-check scripts (if TestId requires)
   │   │   └─ psexec() to run validation scripts
   │   │
   │   ├─ Start debug log collection (if -DEBUG flag present)
   │   │   └─ collect_debug_logs(workload, "START", iteration)
   │   │
   │   ├─ Begin PACS Recording
   │   │   ├─ Filename: {TestId}_Nidaq_Result_{WorkloadName}_{Iteration}
   │   │   ├─ Example: GLD1001_Nidaq_Result_JWORKLOAD_1
   │   │   └─ p.record(filename)
   │   │
   │   ├─ Wait for recording duration
   │   │   └─ sleep_timer(record_time) with countdown display
   │   │
   │   ├─ Stop PACS Recording
   │   │   └─ p.stop()
   │   │
   │   ├─ Stop debug log collection (if -DEBUG flag present)
   │   │   └─ collect_debug_logs(workload, "STOP", iteration)
   │   │
   │   └─ Apply post-recording wait time
   │       └─ sleep_timer(wait_time)
   │
   └─ Reset Power Mode (if changed)

5. Post-Test Cleanup
   ├─ Stop and exit PACS
   │   └─ p.stop() → p.exit()
   ├─ Run workload-specific cleanup scripts
   │   └─ psexec() for cleanup commands
   └─ Execute restart/no-restart post script
       ├─ If -RESTART: Reboot system
       └─ If -NORESTART: No action
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
def psexec(cmd, DUT_IP, DUT_username, DUT_pwd):
    """
    Execute command on remote system
    
    Args:
        cmd: Command to execute
        DUT_IP: Target system IP
        DUT_username: Username for authentication
        DUT_pwd: Password for authentication
    
    Returns:
        Subprocess return code
    """
```

**Use Cases:**
- Trigger test workloads on SUT (System Under Test)
- Execute pre/post test scripts
- Collect debug logs
- Control system state (reboot, sleep, wake)

**Example:**
```python
# Start a workload on remote system
psexec("C:\\Tests\\workload.exe", "192.168.1.100", "admin", "password")

# Collect debug logs
psexec("C:\\Tools\\collect_logs.bat START", "192.168.1.100", "admin", "password")
```

### 2. Multi-Workload Support

Handles multiple workload types simultaneously or sequentially:

| Workload | Purpose | Typical Use |
|----------|---------|-------------|
| **JWORKLOAD** | Primary test workload | Main performance/power test |
| **SoCWatch**  | Intel SoC monitoring | Platform power analysis |
| **WLC**       | Windows Lifecycle | System state transitions |
| **TypePerf**  | Performance counters | CPU/Memory/Disk metrics |
| **EMON_EDP**  | Energy monitoring | Core-level power analysis |
| **ETL**       | Event tracing | System event logging |

**Example Multi-Workload Test:**
```
112 -TestId:GLD1001 -InitialWait:60
-JWORKLOAD(Repeat:3,Record:120,Wait:10)
-SOCWATCH(Repeat:3,Record:120,Wait:10)
-TYPEPERF(Repeat:3,Record:120,Wait:10)
```

This will:
1. Run JWORKLOAD 3 times (each 120s recording)
2. Run SOCWATCH 3 times (each 120s recording)
3. Run TYPEPERF 3 times (each 120s recording)
4. All synchronized with PACS power measurements

### 3. Debug Log Collection

The `collect_debug_logs()` function triggers collection of:

**Function Signature:**
```python
def collect_debug_logs(workload_name, mode, iteration):
    """
    Collect debug logs for specific workload
    
    Args:
        workload_name: Name of workload (JWORKLOAD, SOCWATCH, etc.)
        mode: "START" or "STOP"
        iteration: Current iteration number
    
    Actions:
        - Executes remote script via psexec
        - Logs are collected on SUT
        - Synchronized with PACS recording
    """
```

**Debug Log Types:**
- **Tool-specific logs**: SoCWatch output, TypePerf CSV
- **System state**: Running processes, services, drivers
- **Performance counters**: CPU, memory, disk usage
- **Event logs**: Windows event viewer exports

**Workflow:**
```
START Recording
  ↓
DEBUG START → Collect pre-test state
  ↓
[Test runs for 120s]
  ↓
DEBUG STOP → Collect post-test state
  ↓
STOP Recording
```

### 4. Temperature Control

Integration with temperature control system (test chamber):

**Function: Code 109 (Set Temperature)**
```python
# Set temperature to 25°C
send_command("109 25")

# Server executes:
subprocess.call(["python", "KSRTemp.py", "25"])
```

**Function: Code 110 (Get Temperature)**
```python
# Query current temperature
current_temp = send_command("110")
# Returns: "Current Temperature: 25.3°C"
```

**Use Case:**
Test device under controlled thermal conditions:
```
1. Set temperature to 25°C
2. Wait for stabilization (30 min)
3. Run power test
4. Set temperature to 35°C
5. Wait for stabilization
6. Run power test again
```

### 5. File Transfer Mechanism

Sophisticated file transfer for CSV results (Code 107):

**Transfer Protocol:**
```
Client → Server: "107 GLD1001_Nidaq_Result_JWORKLOAD_1"

Server Actions:
1. Locate folder in result_path
2. Find _summary.csv file
3. Send folder name (string)
4. Send file size (integer)
5. Send file data in 1024-byte chunks
6. Send completion signal

Client Actions:
1. Receive folder name
2. Receive file size
3. Create local file
4. Receive chunks until complete
5. Close file
```

**Error Handling:**
- Validates folder exists
- Checks for `_summary.csv` file
- Handles network interruptions
- Reports transfer status

**Example:**
```python
# Server side
folder_path = "C:\\Test\\results\\GLD1001_Nidaq_Result_JWORKLOAD_1"
csv_file = "GLD1001_Nidaq_Result_JWORKLOAD_1_summary.csv"

# Send file
with open(csv_file, 'rb') as f:
    while chunk := f.read(1024):
        client_socket.send(chunk)
```

### 6. Modern Standby Support (GLD1006)

Special handling for Connected Standby testing:

**Function: `mcs_ttk()`**
```python
def mcs_ttk(duration_minutes):
    """
    Control Modern Connected Standby via TTK
    
    Args:
        duration_minutes: How long system should sleep
    
    Actions:
        1. Validate network connectivity
        2. Execute TTK power button press (sleep)
        3. Wait for specified duration
        4. Execute TTK power button press (wake)
        5. Verify system wake
    """
```

**Workflow for GLD1006:**
```
1. Start PACS recording
2. Wait 30 seconds (system stable)
3. Trigger Modern Standby (via TTK)
   └─ System enters low-power state
4. Record power for X minutes
5. Wake system (via TTK)
6. Wait 30 seconds (system stable)
7. Stop PACS recording
```

**Network Validation:**
```python
# Before sleep
ping_result = subprocess.call(["ping", "-n", "1", DUT_IP])
if ping_result != 0:
    print_error("System not reachable before sleep")

# After wake
ping_result = subprocess.call(["ping", "-n", "1", DUT_IP])
if ping_result != 0:
    print_error("System not reachable after wake")
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
    Sleep with visual countdown
    
    Args:
        seconds: Duration to sleep
    
    Displays:
        Waiting: 120s remaining... (updates every second)
    """
    for i in range(seconds, 0, -1):
        print(f"\rWaiting: {i}s remaining...", end='', flush=True)
        time.sleep(1)
    print("\r" + " " * 50 + "\r", end='')  # Clear line
```

### 2. `psexec(cmd, ip, username, password)`
Remote command execution wrapper:

```python
def psexec(cmd, DUT_IP, DUT_username, DUT_pwd):
    """
    Execute command on remote system via PsExec
    
    Args:
        cmd: Command to execute
        DUT_IP: Target system IP
        DUT_username: Username
        DUT_pwd: Password
    
    Returns:
        Return code (0 = success)
    """
    psexec_cmd = [
        "psexec.exe",
        f"\\\\{DUT_IP}",
        "-u", DUT_username,
        "-p", DUT_pwd,
        "-accepteula",
        cmd
    ]
    
    return subprocess.call(psexec_cmd, timeout=300)
```

### 3. `collect_report()`
Background services reporting:

```python
def collect_report():
    """
    Collect system state reports
    
    Collects:
        - Running services
        - Active processes
        - System resource usage
    
    Saves to: C:\Test\reports\system_state_{timestamp}.txt
    """
    psexec(
        "powershell.exe Get-Service | Export-Csv C:\\Temp\\services.csv",
        DUT_IP, username, password
    )
    
    psexec(
        "powershell.exe Get-Process | Export-Csv C:\\Temp\\processes.csv",
        DUT_IP, username, password
    )
```

### 4. `power_mode(mode)`
Power slider control:

```python
def power_mode(mode):
    """
    Set Windows power mode
    
    Args:
        mode: "Best Performance" | "Balanced" | "Best Power Efficiency"
    
    Uses:
        PowerSlider.exe tool or Windows Registry
    """
    mode_map = {
        "Best Performance": 0,
        "Balanced": 1,
        "Best Power Efficiency": 2
    }
    
    mode_value = mode_map.get(mode, 1)
    
    psexec(
        f"C:\\Tools\\PowerSlider.exe {mode_value}",
        DUT_IP, username, password
    )
```

### 5. `collect_debug_logs(workload, mode, iteration)`
Debug data collection:

```python
def collect_debug_logs(workload_name, mode, iteration):
    """
    Collect debug logs for workload
    
    Args:
        workload_name: JWORKLOAD, SOCWATCH, etc.
        mode: "START" or "STOP"
        iteration: Current iteration number
    
    Collects:
        - Workload-specific logs
        - System event logs
        - Performance counters
    """
    log_script = f"C:\\Tools\\Collect_Logs.ps1"
    log_params = f"-Workload {workload_name} -Mode {mode} -Iteration {iteration}"
    
    psexec(
        f"powershell.exe -File {log_script} {log_params}",
        DUT_IP, username, password
    )
```

### 6. `mcs_ttk(duration_minutes)`
Modern Standby control:

```python
def mcs_ttk(duration_minutes):
    """
    Control Modern Connected Standby via TTK
    
    Args:
        duration_minutes: Sleep duration
    
    Process:
        1. Validate connectivity
        2. Press power button (sleep)
        3. Wait specified duration
        4. Press power button (wake)
        5. Verify wake
    """
    # Check connectivity
    ping = subprocess.call(["ping", "-n", "1", DUT_IP])
    if ping != 0:
        print_error("DUT not reachable")
        return
    
    # Sleep via TTK
    subprocess.call([
        "python", "KSR_CS_PowerButton.py",
        DUT_IP, "press"
    ])
    
    print_Info(f"System in Modern Standby for {duration_minutes} minutes")
    sleep_timer(duration_minutes * 60)
    
    # Wake via TTK
    subprocess.call([
        "python", "KSR_CS_PowerButton.py",
        DUT_IP, "press"
    ])
    
    # Verify wake
    time.sleep(30)
    ping = subprocess.call(["ping", "-n", "1", DUT_IP])
    if ping == 0:
        print_Info("System woke successfully")
    else:
        print_error("System did not wake")
```

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
