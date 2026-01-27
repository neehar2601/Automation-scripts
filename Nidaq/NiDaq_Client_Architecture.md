# NiDaq Client Architecture Documentation

**Version:** 1.9  
**Last Updated:** January 2026  
**Purpose:** Client-side test orchestration and power measurement coordination

---

## Table of Contents
1. [Overview](#overview)
2. [Architecture Pattern](#architecture-pattern)
3. [Configuration Management](#configuration-management)
4. [Command Protocol](#command-protocol)
5. [Command Implementations](#command-implementations)
6. [Power Slider Integration](#power-slider-integration)
7. [File Management](#file-management)
8. [Network Drive Operations](#network-drive-operations)
9. [Execution Flow](#execution-flow)
10. [Helper Functions](#helper-functions)
11. [Error Handling](#error-handling)

---

## Overview

### Purpose
NiDaq Client is a **command-line driven, single-execution** tool that:
- Communicates with NiDaq Server for power measurement coordination
- Creates and manages test case execution scripts
- Handles file transfers between server and client
- Manages power slider configurations
- Coordinates with PACS (Power Analysis and Characterization System)

### Key Characteristics
- **Execution Model:** Single command execution (not a continuous service)
- **Communication:** TCP socket client connecting to NiDaq Server
- **Configuration:** INI-based configuration file
- **Logging:** Date-stamped log files with dual output (file + console)

### Version Information
- **Current Version:** 1.9
- **Log Format:** `NiDaq_Client_Log_YYYY-MM-DD.log`
- **Configuration File:** `config.ini`

---

## Architecture Pattern

### Execution Model
```
┌─────────────────────────────────────────────────────────────┐
│                    Single Command Execution                 │
│                                                             │
│  User/Script → NiDaq_Client.exe <code> [parameters]         │
│                        ↓                                    │
│                 Parse & Validate                            │
│                        ↓                                    │
│              ┌─────────┴─────────┐                          │
│              │                   │                          │
│         Local Action      Server Communication              │
│         (102, 108, 109)   (101, 103-107, 110-113)           │
│              │                   │                          │
│              ↓                   ↓                          │
│         File Operations    Socket Connection                │
│         KPI List Updates   Request → Response               │
│                                                             │
│                        Exit                                 │
└─────────────────────────────────────────────────────────────┘
```

### Client vs Server Operations
| Operation Type | Commands | Execution |
|---------------|----------|-----------|
| **Client-Side Only** | 102, 108, 109, 113 | No server connection, local file operations |
| **Server Communication** | 101, 103-107, 110-112 | Establishes socket connection to server |
| **Hybrid** | 102 (with RUNEXECUTABLE) | Local execution, may trigger reboot |

---

## Configuration Management

### Configuration File Structure (config.ini)
```ini
[Server]
host = 192.168.0.3
port = 55555
username = intel
password = intel@123

[Paths]
kpi_file_path = KPI_TestCase_List.txt
test_case_filename = TestCase_Run.cmd
SendToHost_filename = SendToHost.OVR
RunExecutable_filename = RunExecutable.OVR
RunExecutableRestartOVR_filename = RunExecutableRestart.OVR
```

### Hard-Coded Paths
```python
gld_folder_path = "GLD"
master_path = r"C:\KSR_Package\KSR\Test_Run_KR"
result_path = r"Results\Golden_Results"
test_id_filename = "test_id.txt"
test_param_filename = "test_param.txt"
powerslider_exe_path = r'C:\KSR_Package\KSR\Test_Run_KR\KSRPowerSlider.exe'
```

### Configuration Validation
- Validates existence of `config.ini`
- Checks for required parameters (host, port, KPI file path)
- Validates KPI Test Case List file existence
- Exits with error if configuration is incomplete

---

## Command Protocol

### Command Code Range
**Valid Range:** 101-113

### Command Categories

| Code | Name | Type | Description |
|------|------|------|-------------|
| **101** | Server Ping | Server | Check if server is online |
| **102** | Create TestCase | Client | Parse KPI list and generate test scripts |
| **103** | Start PACS | Server | Initialize PACS on server |
| **104** | Get PACS Status | Server | Query PACS status (-1 to 5) |
| **105** | Start Recording | Server | Begin power measurement recording |
| **106** | Stop PACS | Server | Stop PACS and save results |
| **107** | File Transfer | Server | Receive CSV files from server |
| **108** | Mark Complete | Client | Update KPI list (mark test as done) |
| **109** | Set Temperature | Client/Server | Extract and send temperature to server |
| **110** | Get Temperature | Server | Fetch current temperature from server |
| **111** | Copy Results | Server | Legacy file transfer via network mount |
| **112** | Advanced Orchestration | Server | Complex multi-workload execution |
| **113** | Network Transfer | Client | Receive results via network drive |

### Command Validation
```python
value = int(message)
if not 101 <= value <= 113:
    print_error(f"Invalid code. {message}")
    sys.exit()
```

---

## Command Implementations

### Code 102: Create TestCase Script

**Purpose:** Parse first uncommented line from KPI list and generate execution scripts

**Execution Flow:**
```
1. Read KPI_TestCase_List.txt
2. Find first line not starting with "::"
3. Parse test case format and parameters
4. Generate appropriate script files
5. Clean up old override files
```

**Test Case Format Detection:**

#### 1. SENDTOHOST Pattern
```
-SENDTOHOST CMD:"command" [parameters]
```
**Generated Files:**
- `NiDaq_Record.cmd`: Contains `NiDaq_Client.exe 112 "testCase"`
- `SendToHost.OVR`: Override file for SENDTOHOST execution

#### 2. RUNEXECUTABLE with RESTART
```
-RUNEXECUTABLE CMD:"command" -RESTART
```
**Behavior:**
- Extracts command from `CMD:"([^"]+)"` regex
- Executes command immediately
- Comments out line in KPI list (prepends "::")
- **Triggers system reboot** (`shutdown /r /t 0`)

#### 3. RUNEXECUTABLE without RESTART
```
-RUNEXECUTABLE CMD:"command"
```
**Behavior:**
- Extracts command from `cmd:\s*"?([^"\s]+)"?` regex
- Creates `NiDaq_Record.cmd` with: `command && Client.cmd`

#### 4. Standard Test Case Format
```
-TestId:GLD-XXXX -Param W:R: or W:R:W:R:
```

**Parameter Extraction:**
```python
# Extract TestId and Param
testcase_file = re.findall(r"-(?:\w+:)?(\w[\w\-]*)", testCase)
testId = testcase_file[0].replace("-", "")  # e.g., "GLD1001"
test_param = testcase_file[1]

# Save to files
test_id.txt → testId
test_param.txt → test_param
```

**W:R: Format Detection:**
```python
parts = testCase.split()
last_part = parts[-1].upper()

# Check if last part contains W, R, or : (but not a parameter flag)
if any(char in last_part for char in ["W", "R", ":"]) and not last_part.startswith("-"):
    # Create NiDaq_Record.cmd with: NiDaq_Client.exe 105 <W:R: format>
    # Remove W:R: from TestCase_Run.cmd
```

**W:R: Format Processing:**
```python
# If format is W1:R2:W3:R4 (4 parts), remove first 2 parts
# If format is W1:R2:W3 (3 parts), remove first part
# Rejoin remaining parts and append to test case
```

**Generated Files:**
- `TestCase_Run.cmd`: Main test execution command
- `NiDaq_Record.cmd`: Recording command (105 or 112)
- `test_id.txt`: Test ID for reference
- `test_param.txt`: Test parameters

---

### Code 108: Update KPI List

**Purpose:** Mark current test case as completed

**Implementation:**
```python
with open(KPI_FilePath, "r") as file:
    lines = file.readlines()

# Find first uncommented line
for i, line in enumerate(lines):
    if not line.strip().startswith("::"):
        testCaseLine = i
        break

# Comment out the line
lines[testCaseLine] = "::" + line

# Write back to file
with open(KPI_FilePath, "w") as file:
    file.writelines(lines)
```

**Result:** Test case is marked complete and won't be processed again

---

### Code 109: Fetch and Send Temperature

**Purpose:** Extract temperature from GLD bat file and send to server

**Execution Flow:**

#### 1. Get TestID
```python
# Priority 1: From command line argument
if len(sys.argv) > 2:
    testid = sys.argv[2].replace("GLD","GLD-")

# Priority 2: From KPI list (first uncommented line)
else:
    with open(KPI_FilePath, "r") as file:
        for line in file:
            if not line.strip().startswith("::"):
                testCase = line.strip()
                break
    match = re.search(r"GLD-\d+", testCase)
    testid = match.group()
```

#### 2. Read GLD Bat File
```python
bat_file_path = os.path.join(gld_folder_path, f"{testid}.bat")
with open(bat_file_path, "r") as bat_file:
    bat_content = bat_file.read()
```

#### 3. Extract Temperature
```python
temp_pattern = r"SET\s+Temperature\s*=\s*(\d+)"
temperature = re.search(temp_pattern, bat_content)
if temperature:
    temp_data = f"{temperature.group(1)}"
```

#### 4. Send to Server
```python
client.connect((host, port))
client.send("109".encode("utf-8"))
# Server responds: "Waiting for Temperature...."
client.send(temp_data.encode("utf-8"))
# Server responds: "Temperature Values received..."
# Wait for: "Temperature has been successfully set"
```

---

### Code 107: File Transfer from Server

**Purpose:** Receive CSV result files from server via socket transfer

**Protocol Flow:**

```
Client                          Server
  │                               │
  │─────── "107" ────────────────→│
  │                               │
  │←─── "START FILE TRANSFER" ─── │
  │                               │
  │─── "Send folder count" ──────→│
  │                               │
  │←────── folder_count ──────────│
  │                               │
  ╞═══════ For each folder ═══════╡
  │                               │
  │─── "Send the Size" ──────────→│
  │                               │
  │←────── file_size ─────────────│
  │                               │
  │─── "Send the filename" ──────→│
  │                               │
  │←────── file_name ─────────────│
  │                               │
  │─── "Received file Content" ──→│
  │                               │
  │←────── file_data ─────────────│
  │      (1024 byte chunks)       │
  │                               │
  ╞═══════════════════════════════╡
```

**Implementation Details:**

#### File Naming Logic
```python
# Get TestID from test_id.txt or command line
testid = sys.argv[2].strip().replace('-','') if len(sys.argv) >= 3 else read_from_file()

# Base filename
file_name = testid + '_Nidaq_Result.csv'
new_file_path = os.path.join("NiDaq_Result", file_name)

# Handle duplicates by appending suffix
suffix = 1
while os.path.exists(new_file_path):
    name, ext = os.path.splitext(file_name)
    new_file_path = os.path.join("NiDaq_Result", f"{name}_{suffix}{ext}")
    suffix += 1
```

#### Receiving File Data
```python
received_data = 0
with open(new_file_path, "wb") as file:
    client.send("Received the file Content".encode('utf-8'))
    while received_data < file_size:
        chunk = client.recv(1024)
        if not chunk:
            break
        file.write(chunk)
        received_data += len(chunk)

# Verify complete transfer
if received_data == file_size:
    print_Info("File received and saved successfully.")
```

#### Result File Organization
```python
# Copy to final destination
result_path = r"Results\Golden_Results"
if not os.path.exists(result_path + r"\\" + testid):
    os.makedirs(result_path + r"\\" + testid)

# Copy received file to organized location
shutil.copy(new_file_path, result_path + r"\\" + testid)
```

---

### Code 113: Network Drive File Transfer

**Purpose:** Receive results from server via network drive mount (alternative to socket transfer)

**Execution Flow:**

#### 1. Mount Network Drive
```python
mount_command = rf'net use K: \\{host}\Test /user:{username} {password}'
os.system(mount_command)
print_Info("K: Drive Mounted Successfully")
```

#### 2. Process Result Folders
```python
result_folders = [
    folder for folder in os.listdir("K:\\results")
    if os.path.isdir(os.path.join("K:\\results", folder))
]

for folder in result_folders:
    folder_path = os.path.join("K:\\results\\", folder)
    expected_filename = f"{folder}_summary.csv"
    full_file_path = os.path.join(folder_path, expected_filename)
```

#### 3. File Naming and Organization
```python
# Clean filename
new_file_name = expected_filename.replace('_summary','').replace('_JWORKLOAD','')

# Extract TestID
match = re.search(r'(GLD\d+)', folder)
Testid = match.group(1)

# Destination path
result_folder_path = master_path + "\\" + result_path + "\\" + Testid
```

#### 4. Handle Duplicate Files
```python
if os.path.exists(result_folder_path + "\\" + new_file_name):
    name, ext = os.path.splitext(new_file_name)
    counter = 1
    while True:
        match = re.search(r'_(\d+)$', name)
        if match:
            # Increment existing number
            current_num = int(match.group(1))
            base_name = name[:match.start()]
            new_num = current_num + 1
            name = f"{base_name}_{new_num}"
        else:
            # Add first suffix
            name = name + "_1"
        
        new_filename = f"{name}{ext}"
        new_full_path = os.path.join(result_folder_path, new_filename)
        
        if not os.path.exists(new_full_path):
            break
        counter += 1
    
    new_result_path = new_full_path
else:
    new_result_path = result_folder_path + "\\" + new_file_name
```

#### 5. Copy Files
```python
copy_cmd = rf"xcopy {full_file_path} {new_result_path} /-I"
os.system(copy_cmd)
print_Info("CSV file copied successfully.")
```

#### 6. Handle ETL Files
```python
etl_file_path = master_path + "\\" + result_path + "\\" + "ETL"

if os.path.exists(etl_file_path):
    get_power_slider()  # Get current power mode
    etl_result_path = f"K:\\{log_date}\\" + "Golden_Results_" + Power_Slider + "\\ETL"
    copy_cmd = rf"xcopy {etl_file_path} {etl_result_path} /I /Y && rmdir {etl_file_path} /s /q"
    os.system(copy_cmd)
```

#### 7. Unmount Drive
```python
os.system("net use K: /delete")
print_Info("K: Drive UnMounted Successfully")
```

---

## Power Slider Integration

### Purpose
Captures current Windows power mode and slider setting to organize results by power configuration.

### Power Slider Executable
```python
powerslider_exe_path = r'C:\KSR_Package\KSR\Test_Run_KR\KSRPowerSlider.exe'
```

### Function Implementation
```python
def get_power_slider():
    args = ['', 'GLD', 'GLD']
    
    Power_sliders = {
        "Best Power Efficiency" : 'BPE',
        "Balanced" : 'BAL',
        "Best Performance" : 'BP'
    }
    global Power_Slider
    
    result = subprocess.run([powerslider_exe_path] + args, capture_output=True, text=True)
    
    if not result.stderr:
        result = result.stdout
        result = result.split(':')
        result = result[-1].split('-')
        
        Power_Mode = result[0].strip()    # e.g., "AC" or "DC"
        slider = result[1].strip()         # e.g., "Balanced"
        
        Slider = Power_sliders.get(slider)
        Power_Slider = Power_Mode + "_" + Slider  # e.g., "AC_BAL"
        print(Power_Slider)
```

### Output Format
```
Power_Mode: AC or DC
Slider: BPE, BAL, or BP
Combined: AC_BPE, AC_BAL, AC_BP, DC_BPE, DC_BAL, DC_BP
```

### Usage in Result Organization
Used in Code 113 to organize ETL files:
```python
etl_result_path = f"K:\\{log_date}\\Golden_Results_{Power_Slider}\\ETL"
```

---

## File Management

### KPI Test Case List Management

**File:** `KPI_TestCase_List.txt`

**Format:**
```
-TestId:GLD-1001 -Param W10:R30
-TestId:GLD-1002 -Param W5:R20:W5:R10
::-TestId:GLD-1003 -Param W15:R25    ← Completed test
-RUNEXECUTABLE CMD:"C:\Tool\Setup.exe"
-SENDTOHOST CMD:"..." -PARAM
```

**Processing Rules:**
1. Lines starting with `::` are skipped (completed tests)
2. First uncommented line is the current test case
3. After completion (Code 108), line is prepended with `::`

### Generated Script Files

#### TestCase_Run.cmd
**Purpose:** Main test execution command
**Example Content:**
```batch
-TestId:GLD-1001 -Param W:R:
```

#### NiDaq_Record.cmd
**Purpose:** Power recording command
**Example Content:**
```batch
NiDaq_Client.exe 105 W10:R30
```
or for Code 112:
```batch
NiDaq_Client.exe 112 "-TestId:GLD-1006 -InitialWait:60 ..."
```

#### Override Files (.OVR)
- **SendToHost.OVR**: Created when SENDTOHOST pattern detected
- **RunExecutable.OVR**: Created when RUNEXECUTABLE pattern detected
- **RunExecutableRestart.OVR**: Created for restart scenarios

**Purpose:** Override files signal specific execution paths to calling scripts

### Test Identification Files

#### test_id.txt
**Content:** Test ID without hyphen (e.g., `GLD1001`)

#### test_param.txt
**Content:** Test parameter extracted from test case

---

## Network Drive Operations

### Network Mount Format
```python
mount_command = rf'net use K: \\{host}\Test /user:{username} {password}'
os.system(mount_command)
```

### Network Unmount
```python
os.system("net use K: /delete")
```

### Network Path Structure
```
\\{host}\Test\results\
    ├── NiDaqResult1\
    │   └── NiDaqResult1_summary.csv
    ├── NiDaqResult2\
    │   └── NiDaqResult2_summary.csv
    └── ...
```

### Error Handling
```python
try:
    # Network operations
except FileNotFoundError:
    print_Info(f"Error: File not found - {full_file_path}")
except OSError as e:
    print_Info(f"Filesystem error with {full_file_path}: {e}")
```

---

## Execution Flow

### Standard Execution Pattern

```
┌──────────────────────────────────────────────────────────┐
│  1. Program Start                                        │
│     - Load configuration from config.ini                 │
│     - Initialize logging                                 │
│     - Validate command line arguments                    │
└────────────────────┬─────────────────────────────────────┘
                     ↓
┌──────────────────────────────────────────────────────────┐
│  2. Command Validation                                   │
│     - Check code is in range 101-113                     │
│     - Parse additional parameters if present             │
└────────────────────┬─────────────────────────────────────┘
                     ↓
          ┌──────────┴──────────┐
          ↓                     ↓
┌──────────────────┐  ┌────────────────────────┐
│  3a. Local       │  │  3b. Server            │
│      Processing  │  │      Communication     │
│                  │  │                        │
│  - 102: Create   │  │  - 101: Ping           │
│    TestCase      │  │  - 103: Start PACS     │
│  - 108: Update   │  │  - 104: Status         │
│    KPI List      │  │  - 105: Record         │
│  - 109: Extract  │  │  - 106: Stop           │
│    Temp (part)   │  │  - 107: Receive Files  │
│  - 113: Network  │  │  - 110: Get Temp       │
│    Transfer      │  │  - 111: Copy Results   │
│                  │  │  - 112: Orchestrate    │
└──────────────────┘  └────────────────────────┘
          │                     │
          └──────────┬──────────┘
                     ↓
┌──────────────────────────────────────────────────────────┐
│  4. Cleanup and Exit                                     │
│     - Close socket connection (if opened)                │
│     - Flush logs                                         │
│     - Exit with status code                              │
└──────────────────────────────────────────────────────────┘
```

### Code 102 Detailed Flow

```
Read KPI_TestCase_List.txt
        ↓
Find first uncommented line
        ↓
    ┌───┴────────────────────────────────────────┐
    │                                            │
    ↓                                            ↓
SENDTOHOST?                              RUNEXECUTABLE?
    │                                            │
    YES                                          YES
    ↓                                            ↓
Create NiDaq_Record.cmd            ┌─────────────┴──────────┐
(112 command)                      │                        │
Create SendToHost.OVR              ↓                        ↓
    │                           -RESTART?               No -RESTART
    │                              │                        │
    │                              YES                      ↓
    │                              ↓                    Extract CMD
    │                          Extract CMD              Create NiDaq_Record.cmd
    │                          Execute immediately      (command && Client.cmd)
    │                          Comment line in KPI      
    │                          Reboot system            
    │                              │                        │
    └──────────────────┬───────────┴────────────────────────┘
                       ↓
                Standard Test Case?
                       │
                       YES
                       ↓
            Extract TestId and Param
            Create test_id.txt
            Create test_param.txt
                       ↓
            Check for W:R: format in last part
                       │
              ┌────────┴────────┐
              ↓                 ↓
           Found             Not Found
              │                 │
              ↓                 ↓
    Create NiDaq_Record.cmd    Create NiDaq_Record.cmd
    (105 with W:R:)            (105 without params)
    Remove W:R: from           
    TestCase_Run.cmd           
              │                 │
              └────────┬────────┘
                       ↓
            Create TestCase_Run.cmd
                       ↓
                     Done
```

### Socket Communication Flow

```
Client Side                         Server Side

Create socket
Connect to host:port ──────────────→ Accept connection
        ↓                                   ↓
Send command code  ────────────────→ Receive command
        ↓                                   ↓
Wait for response                    Process command
        ↓                                   ↓
Receive response   ←──────────────── Send response
        ↓                                  │
Additional exchanges (for 107, 109, etc)   │
        ↓                                  ↓
Close socket       ←───────────────→ Close connection
```

---

## Helper Functions

### print_Info()
**Purpose:** Log informational messages
```python
def print_Info(message):
    logging.info(message)
```
**Output:** `2026-01-22 10:15:30 - INFO - Message`

### print_error()
**Purpose:** Log error messages
```python
def print_error(message):
    logging.error(message)
```
**Output:** `2026-01-22 10:15:30 - ERROR - Message`

### get_power_slider()
**Purpose:** Get current Windows power mode and slider setting
**Returns:** Sets global variable `Power_Slider`
**Format:** `{AC|DC}_{BPE|BAL|BP}`

### Regex Patterns Used

#### Test ID Extraction
```python
# GLD format with hyphen
r"GLD-\d+"        # Matches: GLD-1001, GLD-2005

# TestId parameter extraction
r"-TestId:(\w+-\d+)"  # Matches: -TestId:GLD-1001

# General parameter extraction
r"-(?:\w+:)?(\w[\w\-]*)"  # Matches: -TestId:GLD-1001, -Param, etc.
```

#### Command Extraction
```python
# CMD with quotes
r'CMD:"([^"]+)"'      # Matches: CMD:"C:\Tool\Setup.exe"

# CMD with optional quotes
r'cmd:\s*"?([^"\s]+)"?'  # Matches: cmd:Setup.exe or cmd:"Setup.exe"
```

#### Parameter Extraction
```python
# JWORKLOAD pattern
r"-JWORKLOAD\(([^)]+)\)"  # Matches: -JWORKLOAD(Repeat:5,Record:30,Wait:10)

# Temperature value
r"SET\s+Temperature\s*=\s*(\d+)"  # Matches: SET Temperature = 25
```

#### File Naming
```python
# Extract TestID from folder name
r'(GLD\d+)'           # Matches: GLD1001 in "NiDaqResult_GLD1001_summary"

# Check for existing number suffix
r'_(\d+)$'            # Matches: _1, _2, etc. at end of filename
```

---

## Error Handling

### Configuration Errors
```python
if not os.path.exists(config_file):
    print_error(f"Configuration file '{config_file}' does not exist.")
    print(help_config)  # Show sample config
    sys.exit()
```

### Command Validation Errors
```python
try:
    value = int(message)
    if not 101 <= value <= 113:
        print_error(f"Invalid code. {message}")
        print(help_message)
        sys.exit()
except ValueError:
    print_error(f"Invalid code. {message}")
    print(help_message)
    sys.exit()
```

### Socket Communication Errors
```python
try:
    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client.connect((host, port))
    # ... communication ...
except socket.timeout:
    print_error("Client Timeout")
except socket.error as e:
    print_error(f"Failed to connect to the server: {host}")
finally:
    client.close()
```

### File Operation Errors
```python
try:
    # File operations
except FileNotFoundError:
    print_Info(f"Error: File not found - {full_file_path}")
except OSError as e:
    print_Info(f"Filesystem error with {full_file_path}: {e}")
```

### Test Case Processing Errors
```python
try:
    # Code 102 processing
except Exception as e:
    print_error(f"Create TestCase run file block:{e}")
    sys.exit()
```

---

## Key Differences from Server

### 1. Execution Model
- **Client:** Single-execution, command-driven tool
- **Server:** Continuous loop waiting for connections

### 2. Socket Role
- **Client:** Initiates connection, sends requests
- **Server:** Accepts connections, processes requests

### 3. File Operations
- **Client:** Creates test scripts, manages KPI list, receives results
- **Server:** Executes tests via PsExec, manages PACS, sends results

### 4. Scope
- **Client:** Test orchestration, file management, local operations
- **Server:** Power measurement, remote execution, hardware control

### 5. Dependencies
- **Client:** Minimal (socket, filesystem, subprocess)
- **Server:** PACS (__pyPACS), PsExec, TTK, KSRTemp

---

## Usage Examples

### Basic Server Ping
```batch
NiDaq_Client.exe 101
```
**Output:** `Received: PACS Version X.Y.Z`

### Create Test Case from KPI List
```batch
NiDaq_Client.exe 102
```
**Result:** Generates `TestCase_Run.cmd` and `NiDaq_Record.cmd`

### Start Power Recording
```batch
NiDaq_Client.exe 105
```
**Result:** Server begins PACS recording with default delay

### Advanced Recording with W:R: Format
```batch
NiDaq_Client.exe 105 W10:R30:W5:R20
```
**Result:** Wait 10s, Record 30s, Wait 5s, Record 20s

### Receive Result Files
```batch
NiDaq_Client.exe 107
```
**Result:** CSV files transferred from server to `NiDaq_Result\` folder

### Mark Test Complete
```batch
NiDaq_Client.exe 108
```
**Result:** Current test line in KPI list commented out

### Set Temperature
```batch
NiDaq_Client.exe 109
```
or with explicit test ID:
```batch
NiDaq_Client.exe 109 GLD-1001
```
**Result:** Temperature extracted from GLD bat file and sent to server

### Advanced Orchestration
```batch
NiDaq_Client.exe 112 "-TestId:GLD-1006 -InitialWait:60 -WorkloadInitialWait:30 ..."
```
**Result:** Server executes complex multi-workload test with debug tools

### Network Drive Transfer
```batch
NiDaq_Client.exe 113
```
**Result:** Results copied via network mount, organized by power slider setting

---

## KPI Short Name Dictionary

**Purpose:** Convert full KPI category names to abbreviated codes

```python
KPI_ShortName_dict = {
    "Audio": "AUD",
    "Benchmark": "BMK",
    "Camera": "CAM",
    "CAI": "CAI",
    "CPU": "CPU",
    "Graphics": "GFX",
    "Storage": "STG",
}
```

**Usage:** Result file naming and organization
**Example:** `Audio-1001` → `AUD1001`

---

## Logging

### Log File Format
**Filename:** `NiDaq_Client_Log_YYYY-MM-DD.log`
**Example:** `NiDaq_Client_Log_2026-01-22.log`

### Log Configuration
```python
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)
```

### Log Levels Used
- **INFO:** Normal operations, status messages
- **ERROR:** Configuration errors, command validation failures, socket errors

### Sample Log Output
```
2026-01-22 10:15:30 - INFO - NiDaq Client Ver.1.9
2026-01-22 10:15:31 - INFO - Received Code: 102
2026-01-22 10:15:31 - INFO - Creating Test case script file!
2026-01-22 10:15:32 - INFO - File created TestCase_Run.cmd content: -TestId:GLD-1001 -Param
2026-01-22 10:15:33 - INFO - Message send : 102!
2026-01-22 10:15:33 - INFO - Received: TESTCASE CREATED
```

---

## Best Practices

### 1. KPI List Management
- Always comment out completed tests with `::`
- Keep one active test at a time (first uncommented line)
- Use descriptive test parameters in KPI list

### 2. Error Handling
- Check log files for detailed error messages
- Verify configuration before running commands
- Ensure network connectivity for server commands

### 3. File Organization
- Use test IDs consistently in all scripts
- Organize results by power slider settings
- Archive old result folders with timestamps

### 4. Socket Communication
- Set appropriate timeouts for long operations
- Handle connection failures gracefully
- Close sockets properly after use

### 5. Test Execution
- Use Code 102 to generate scripts before execution
- Use Code 108 to mark tests complete after execution
- Verify test_id.txt and test_param.txt are created correctly

---

## Troubleshooting

### Common Issues

#### 1. Configuration File Not Found
**Error:** `Configuration file 'config.ini' does not exist.`
**Solution:** Create config.ini with required parameters (see sample above)

#### 2. Invalid Command Code
**Error:** `Invalid code. <code>`
**Solution:** Use codes in range 101-113 only

#### 3. Failed to Connect to Server
**Error:** `Failed to connect to the server: <host>`
**Solution:** 
- Verify server is running
- Check host and port in config.ini
- Verify network connectivity

#### 4. KPI File Not Found
**Error:** `KPI Test Case List file '<path>' does not exist.`
**Solution:** Create KPI_TestCase_List.txt or update path in config.ini

#### 5. No Uncommented Tests in KPI List
**Symptom:** Code 102 fails to create test case
**Solution:** Remove `::` from at least one test line in KPI list

#### 6. File Transfer Incomplete
**Symptom:** `Expected X bytes but received Y bytes.`
**Solution:** 
- Check network stability
- Verify server has complete result files
- Retry file transfer

#### 7. Power Slider Error
**Symptom:** `Error in fetching Power Mode..`
**Solution:** Verify KSRPowerSlider.exe exists at configured path

---

## Version History

### Version 1.9 (Current)
- Network drive file transfer (Code 113)
- Power slider integration
- Enhanced duplicate file handling
- ETL file organization by power mode

### Known Limitations
1. Single-threaded execution (no concurrent operations)
2. No automatic retry mechanism for failed operations
3. Limited error recovery for network issues
4. Relies on external tools (KSRPowerSlider, power measurement tools)

---

## Future Enhancements

### Potential Improvements
1. **Async Socket Communication:** Non-blocking operations for better performance
2. **Automatic Retry Logic:** Handle transient network failures
3. **Progress Indicators:** Show file transfer progress
4. **Configuration Validation:** More comprehensive config checking
5. **Test Queue Management:** Support multiple test queuing
6. **Result Verification:** Checksum verification for file transfers

---

## Contact and Support

**Team:** Kingsriver Team  
**Website:** https://kingsriver.intel.com  
**Help Command:** `NiDaq_Client.exe /?` or `NiDaq_Client.exe help`

---

*End of NiDaq Client Architecture Documentation*
