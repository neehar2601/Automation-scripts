# NiDaq Complete System Architecture

**Combined Server-Client Documentation**  
**Server Version:** 1.13 | **Client Version:** 1.9  
**Last Updated:** January 22, 2026  
**Purpose:** Comprehensive distributed power measurement and test orchestration system

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture & Communication Model](#architecture--communication-model)
3. [Component Roles & Responsibilities](#component-roles--responsibilities)
4. [Execution Models](#execution-models)
5. [Command Protocol & Workflows](#command-protocol--workflows)
6. [Complete Test Execution Scenarios](#complete-test-execution-scenarios)
7. [Communication Patterns](#communication-patterns)
8. [File Transfer Mechanisms](#file-transfer-mechanisms)
9. [Test Orchestration Flow](#test-orchestration-flow)
10. [Error Handling & Recovery](#error-handling--recovery)
11. [Deployment Architecture](#deployment-architecture)
12. [Comparison Matrix](#comparison-matrix)

---

## System Overview

### What is NiDaq System?

The **NiDaq System** is a distributed power measurement and test orchestration platform consisting of two complementary components:

- **NiDaq Server**: Continuous TCP server controlling PACS hardware and orchestrating remote test execution
- **NiDaq Client**: Command-line tool for test script generation, coordination, and result management

### Purpose

**Primary Goals:**
1. Automated power measurement during workload execution
2. Remote test orchestration across networked systems
3. Multi-workload coordination with debug tool integration
4. Temperature-controlled testing environments
5. Centralized result collection and organization

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         COMPLETE NIDAC SYSTEM                               │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────┐                        ┌─────────────────────┐
    │   Test Operator     │                        │  Temperature        │
    │   (Human/Script)    │                        │  Chamber            │
    └──────────┬──────────┘                        └──────────┬──────────┘
               │                                              │
               │ Invokes Commands                             │ RS232/USB
               ↓                                              ↓
    ┌──────────────────────────────────────────────────────────────────────┐
    │                      CLIENT SYSTEM (SUT)                             │
    │  ┌────────────────────────────────────────────────────────────────┐  │
    │  │  NiDaq_Client.exe (Single Execution)                           │  │
    │  │  - Parse KPI list                                              │  │
    │  │  - Generate test scripts                                       │  │
    │  │  - Coordinate with server                                      │  │
    │  │  - Collect results                                             │  │
    │  └───────────┬──────────────────────────────────────┬─────────────┘  │
    │              │                                       │               │
    │              │ Generates                             │ Executes      │
    │              ↓                                       ↓               │
    │  ┌──────────────────────┐           ┌──────────────────────────────┐ │
    │  │ TestCase_Run.cmd     │           │  Test Framework              │ │
    │  │ NiDaq_Record.cmd     │           │  - JWORKLOAD execution       │ │
    │  │ test_id.txt          │           │  - SoCWatch monitoring       │ │
    │  │ test_param.txt       │           │  - WLC/TypePerf/ETL          │ │
    │  └──────────────────────┘           └──────────────────────────────┘ │
    │              │                                       │               │
    │              │ KPI List Management                   │ Results       │
    │              ↓                                       ↓               │
    │  ┌────────────────────────────────────────────────────────────────┐  │
    │  │  KPI_TestCase_List.txt                                         │  │
    │  │  Results/Golden_Results/{TestID}/                              │  │
    │  │  NiDaq_Result/                                                 │  │
    │  └────────────────────────────────────────────────────────────────┘  │
    └──────────────────────────────┬───────────────────────────────────────┘
                                   │
                                   │ TCP Socket (Port 55555)
                                   │ Commands: 101-113
                                   │
    ┌──────────────────────────────┴───────────────────────────────────────┐
    │                      SERVER SYSTEM (PACS Host)                       │
    │  ┌────────────────────────────────────────────────────────────────┐  │
    │  │  NiDaq_Server.py (Continuous Loop)                             │  │
    │  │  - Accept connections                                          │  │
    │  │  - Parse commands (101-113)                                    │  │
    │  │  - Control PACS hardware                                       │  │
    │  │  - Execute remote commands (PsExec)                            │  │
    │  │  - Transfer result files                                       │  │
    │  └───────────┬──────────────────────┬───────────────────┬─────────┘  │
    │              │                      │                   │            │
    │              │ Controls             │ Executes          │ Monitors   │
    │              ↓                      ↓                   ↓            │
    │  ┌──────────────────┐  ┌────────────────────┐  ┌─────────────────┐   │
    │  │  PACS Hardware   │  │  PsExec            │  │  KSRTemp.py     │   │
    │  │  (__pyPACS lib)  │  │  (Remote Exec)     │  │  (Temp Control) │   │
    │  │  - Load config   │  │  - Start workloads │  │  - Set temp     │   │
    │  │  - Start DAQ     │  │  - Collect logs    │  │  - Get temp     │   │
    │  │  - Record power  │  │  - Run reports     │  │  - Monitor      │   │
    │  │  - Stop/Exit     │  │  - Post scripts    │  │                 │   │
    │  └──────────────────┘  └────────────────────┘  └─────────────────┘   │
    │              │                                                       │
    │              │ Stores Results                                        │
    │              ↓                                                       │
    │  ┌────────────────────────────────────────────────────────────────┐  │
    │  │  C:\Test\results\                                              │  │
    │  │  ├── NiDaqResult1/                                             │  │
    │  │  │   └── NiDaqResult1_summary.csv                              │  │ 
    │  │  ├── GLD1015_Nidaq_Result_JWORKLOAD_1/                         │  │ 
    │  │  │   └── GLD1015_Nidaq_Result_JWORKLOAD_1_summary.csv          │  │
    │  │  └── GLD1015_Nidaq_Result_SOCWATCH_1/                          │  │ 
    │  │      └── GLD1015_Nidaq_Result_SOCWATCH_1_summary.csv           │  │
    │  └────────────────────────────────────────────────────────────────┘  │
    └──────────────────────────────────────────────────────────────────────┘

                        ┌────────────────────────┐
                        │  Network Share/Drive   │
                        │  (Optional Transfer)   │
                        │  K:\results\           │
                        └────────────────────────┘
```

---

## Architecture & Communication Model

### Network Topology

```
┌──────────────────────────────────────────────────────────────────┐
│                      Network: 192.168.0.0/24                     │
└──────────────────────────────────────────────────────────────────┘

    Client System (SUT)                Server System (PACS Host)
    ┌─────────────────┐                ┌──────────────────┐
    │  192.168.0.100  │◄──────────────►│  192.168.0.3     │
    │                 │   TCP Socket   │                  │
    │  NiDaq_Client   │   Port: 55555  │  NiDaq_Server    │
    │                 │                │                  │
    │  Role: SUT      │                │  Role: PACS Host │
    │  Initiates      │                │  Accepts         │
    │  Connection     │                │  Connection      │
    └─────────────────┘                └──────────────────┘
           │                                    │
           │                                    │
           ↓                                    ↓
    ┌─────────────────┐                ┌──────────────────┐
    │  Test Workload  │                │  PACS Hardware   │
    │  Execution      │                │  Power Meter     │
    │  - JWORKLOAD    │                │  - Voltage       │
    │  - Benchmarks   │                │  - Current       │
    │  - Applications │                │  - Power         │
    └─────────────────┘                └──────────────────┘
```

### Communication Protocol

**Protocol:** TCP/IP  
**Port:** 55555 (configurable)  
**Pattern:** Request-Response (Synchronous)  
**Data Format:** Text-based commands + Binary file transfer

**Communication Flow:**
```
Client                                    Server
  │                                         │
  │──── TCP Connect ─────────────────────→  │ (Accept)
  │                                         │
  │──── Command Code (e.g., "103") ───────→ │ (Parse)
  │                                         │
  │                                         │ (Process)
  │                                         │ (Execute)
  │                                         │
  │◄─── Response Message ────────────────── │ (Send)
  │                                         │
  │──── Additional Data (if needed) ──────→ │
  │                                         │
  │◄─── Response/Files ──────────────────── │
  │                                         │
  │──── TCP Close ───────────────────────── │ (Close)
  │                                         │
```

---

## Component Roles & Responsibilities

### NiDaq Server (Continuous Service)

**Primary Role:** Power measurement orchestrator and remote execution controller

**Key Responsibilities:**

| Category | Responsibilities |
|----------|------------------|
| **Hardware Control** | • Control PACS hardware via __pyPACS library<br>• Manage power measurement recording<br>• Start/stop data acquisition |
| **Remote Execution** | • Execute commands on client via PsExec<br>• Start/stop workloads remotely<br>• Collect debug logs from client<br>• Run pre/post test scripts |
| **Data Management** | • Store power measurement CSV files<br>• Organize results by test ID and workload<br>• Transfer files to client via socket or network share |
| **Temperature Control** | • Interface with thermal chamber (KSRTemp.py)<br>• Set target temperature<br>• Monitor current temperature |
| **Test Orchestration** | • Parse complex test parameters (Code 112)<br>• Coordinate multi-workload execution<br>• Synchronize timing between workloads and measurements |
| **Modern Standby** | • Control TTK hardware for power button emulation<br>• Put system into Connected Standby<br>• Wake system from sleep |

**Execution Mode:** Continuous loop, single-threaded, blocking I/O

---

### NiDaq Client (Command-Line Tool)

**Primary Role:** Test script generator and result coordinator

**Key Responsibilities:**

| Category | Responsibilities |
|----------|------------------|
| **Test Script Generation** | • Parse KPI test case list<br>• Generate TestCase_Run.cmd<br>• Create NiDaq_Record.cmd<br>• Handle special patterns (SENDTOHOST, RUNEXECUTABLE) |
| **KPI List Management** | • Read first uncommented test case<br>• Mark completed tests (prepend ::)<br>• Manage test queue |
| **Server Communication** | • Send commands to server (101-113)<br>• Receive responses and status<br>• Handle file transfers |
| **Result Collection** | • Receive CSV files from server<br>• Organize results by test ID<br>• Handle duplicate file naming<br>• Copy results via network share |
| **Power Mode Tracking** | • Query Windows power slider setting<br>• Organize results by power mode (AC/DC)<br>• Track power plan (BPE/BAL/BP) |
| **Temperature Extraction** | • Read GLD bat files<br>• Extract temperature settings<br>• Send to server for chamber control |

**Execution Mode:** Single command execution, exits after completion

---

## Execution Models

### Server Execution Model: Continuous Loop

```python
# Simplified server execution model
while True:  # ← Runs forever
    # 1. Wait for client connection (blocking)
    client_socket, client_address = server.accept()
    
    # 2. Receive command (blocking)
    message = client_socket.recv(1024).decode("utf-8")
    
    # 3. Process command
    if message == "103":
        # Start PACS (may take 5-10 seconds)
    elif message == "112":
        # Advanced test (may take HOURS)
    
    # 4. Send response
    client_socket.send(response.encode("utf-8"))
    
    # 5. Close connection
    client_socket.close()
    
    # 6. Loop back to step 1
```

**Characteristics:**
- ✅ Always running, always listening
- ✅ Handles one client at a time (single-threaded)
- ✅ Command execution can take seconds to hours
- ❌ New connections blocked during command processing
- ❌ No concurrent client support

---

### Client Execution Model: Single Command

```batch
# Simplified client execution model
C:\> NiDaq_Client.exe 102
    │
    ├─ Parse command line arguments
    ├─ Load configuration
    ├─ Validate command code (101-113)
    │
    ├─ Execute command:
    │  ├─ Local operation (102, 108, 109, 113)
    │  │  └─ File operations, script generation
    │  │
    │  └─ Server communication (101, 103-107, 110-112)
    │     ├─ Connect to server
    │     ├─ Send command
    │     ├─ Receive response
    │     └─ Close connection
    │
    └─ Exit (Program terminates)
```

**Characteristics:**
- ✅ Fast startup and execution
- ✅ Can be called from scripts/batch files
- ✅ Multiple clients can run sequentially
- ❌ Does not persist between commands
- ❌ Must reconnect for each operation

---

### Execution Model Comparison

| Aspect | Server | Client |
|--------|--------|--------|
| **Lifetime** | Continuous (runs indefinitely) | Transient (exits after command) |
| **Startup** | Once per deployment | Every command invocation |
| **State** | Maintains PACS state between commands | Stateless (no memory between runs) |
| **Concurrency** | Single client at a time | Multiple instances possible (different commands) |
| **Blocking** | Blocks on accept() and command execution | Blocks on socket communication only |
| **Resource Usage** | Persistent (always consuming resources) | Minimal (only during execution) |
| **Restart** | Manual (if crashes) | Automatic (each invocation is fresh) |

---

## Command Protocol & Workflows

### Command Categories

```
┌─────────────────────────────────────────────────────────────┐
│              Command Code Distribution (101-113)            │
└─────────────────────────────────────────────────────────────┘

CLIENT-ONLY Commands (No Server Connection)
├── 102: Create TestCase (Parse KPI list, generate scripts)
├── 108: Mark Complete (Comment out test in KPI list)
└── 113: Network Transfer (Mount drive, copy files, unmount)

SERVER Communication Commands
├── 101: Ping (Check server online)
├── 103: Start PACS (Initialize power measurement)
├── 104: PACS Status (Query state: -1 to 5)
├── 105: Record (Start power recording with W:R: format)
├── 106: Stop PACS (Stop recording, exit PACS)
├── 107: File Transfer (Socket-based CSV transfer)
├── 110: Get Temperature (Query thermal chamber)
└── 112: Advanced Orchestration (Multi-workload test)

HYBRID Commands (Client + Server)
└── 109: Set Temperature (Client extracts from file, server sets)
```

---

### Command 102: Create TestCase (Client-Only)

**Purpose:** Parse KPI list and generate test execution scripts

**Workflow:**
```
┌─────────────────────────────────────────────────────────────┐
│  1. User/Script Invokes                                     │
│     C:\> NiDaq_Client.exe 102                               │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  2. Read KPI_TestCase_List.txt                              │
│     Find first uncommented line                             │
│                                                             │
│     Example KPI List:                                       │
│     ::-TestId:GLD-1001 -Param W10:R30    ← Completed        │
│     -TestId:GLD-1002 -Param W5:R20       ← Current          │
│     -TestId:GLD-1003 -Param W15:R25      ← Pending          │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  3. Parse Test Case Format                                  │
│     Detect pattern type:                                    │
│     • Standard: -TestId:GLD-XXXX -Param                     │
│     • SENDTOHOST: -SENDTOHOST CMD:"..."                     │
│     • RUNEXECUTABLE: -RUNEXECUTABLE CMD:"..."               │
│     • RUNEXECUTABLE + RESTART: ... -RESTART                 │
└────────────────────┬────────────────────────────────────────┘
                     ↓
        ┌────────────┴────────────┐
        │                         │
        ↓                         ↓
┌─────────────────┐      ┌─────────────────────┐
│  Standard Test  │      │  Special Pattern    │
└────────┬────────┘      └──────────┬──────────┘
         │                          │
         ↓                          ↓
┌─────────────────────────────────────────────────────────────┐
│  4. Generate Files                                          │
│                                                             │
│  Standard Test:                                             │
│  ├── TestCase_Run.cmd                                       │
│  │   Content: -TestId:GLD-1002 -Param                       │
│  ├── NiDaq_Record.cmd                                       │
│  │   Content: NiDaq_Client.exe 105 W5:R20                   │
│  ├── test_id.txt                                            │
│  │   Content: GLD1002                                       │
│  └── test_param.txt                                         │
│      Content: W5:R20                                        │
│                                                             │
│  SENDTOHOST:                                                │
│  ├── NiDaq_Record.cmd                                       │
│  │   Content: NiDaq_Client.exe 112 "..."                    │
│  └── SendToHost.OVR (override file)                         │
│                                                             │
│  RUNEXECUTABLE (No Restart):                                │
│  └── NiDaq_Record.cmd                                       │
│      Content: command && Client.cmd                         │
│                                                             │
│  RUNEXECUTABLE + RESTART:                                   │
│  ├── Execute command immediately                            │
│  ├── Comment out line in KPI list                           │
│  └── Reboot system (shutdown /r /t 0)                       │
└─────────────────────────────────────────────────────────────┘
```

**No Server Communication:** This command runs entirely on the client side.

---

### Command 105: Simple Recording (Server Communication)

**Purpose:** Start PACS power recording with wait/record timing

**Workflow:**
```
CLIENT SIDE                             SERVER SIDE
┌────────────────────┐                  ┌────────────────────┐
│ User invokes:      │                  │ Server listening   │
│ NiDaq_Client 105   │                  │ on port 55555      │
│ W10:R30:W5:R20     │                  │                    │
└──────────┬─────────┘                  └──────────┬─────────┘
           │                                       │
           │ 1. Connect to server                  │
           │────────────────────────────────────→  │
           │                                       │
           │                                       │ 2. Accept connection
           │                                       │    Log client IP
           │                                       │
           │ 3. Send "105 W10:R30:W5:R20"          │
           │────────────────────────────────────→  │
           │                                       │
           │                                       │ 4. Parse command
           │                                       │    Split by space
           │                                       │    Extract: ["W10","R30","W5","R20"]
           │                                       │
           │                                       │ 5. Check PACS status
           │                                       │    if status != "2":
           │                                       │        Send error
           │                                       │    else:
           │                                       │        Continue
           │                                       │
           │ 6. Receive acknowledgment             │
           │◄────────────────────────────────────  │
           │   "Waiting for W10:R30:W5:R20..."     │
           │                                       │
           │                                       │ 7. Execute timing sequence:
           │                                       │    ┌──────────────────┐
           │                                       │    │ W10: Wait 10s    │
           │                                       │    └────────┬─────────┘
           │                                       │             ↓
           │                                       │    ┌──────────────────┐
           │                                       │    │ R30: Record 30s  │
           │                                       │    │ p.record(...)    │
           │                                       │    │ time.sleep(28)   │
           │                                       │    │ p.stop()         │
           │                                       │    └────────┬─────────┘
           │                                       │             ↓
           │                                       │    ┌──────────────────┐
           │                                       │    │ W5: Wait 5s      │
           │                                       │    └────────┬─────────┘
           │                                       │             ↓
           │                                       │    ┌──────────────────┐
           │                                       │    │ R20: Record 20s  │
           │                                       │    │ p.record(...)    │
           │                                       │    │ time.sleep(18)   │
           │                                       │    │ p.stop()         │
           │                                       │    └────────┬─────────┘
           │                                       │
           │ 8. Connection closed by server        │
           │◄────────────────────────────────────  │
           │                                       │
┌──────────┴─────────┐                  ┌──────────┴─────────┐
│ Client exits       │                  │ Server ready for   │
│                    │                  │ next connection    │
└────────────────────┘                  └────────────────────┘
```

**Result Files on Server:**
```
C:\Test\results\
├── NiDaqResult1\
│   └── NiDaqResult1_summary.csv  (30 seconds of data)
└── NiDaqResult2\
    └── NiDaqResult2_summary.csv  (20 seconds of data)
```

---

### Command 112: Advanced Orchestration (Most Complex)

**Purpose:** Multi-workload test with debug tools and synchronized power measurement

**Example Command:**
```
NiDaq_Client.exe 112 "-TestId:GLD1015 -InitialWait:60 -WorkloadInitialWait:30 
-JWORKLOAD(InitialWait:10,Repeat:3,Record:120,Wait:10) 
-SOCWATCH(Repeat:3,Record:120,Wait:10) 
-WLC(Repeat:2,Record:60,Wait:5) 
-RESTART"
```

**Complete Workflow:**
```
CLIENT                          SERVER                          CLIENT SUT
  │                               │                               │
  │ 1. Send "112 ..."             │                               │
  │──────────────────────────────→│                               │
  │                               │                               │
  │                               │ 2. Parse parameters           │
  │                               │    TestId: GLD1015            │
  │                               │    InitialWait: 60            │
  │                               │    WorkloadInitialWait: 30    │
  │                               │    Workloads: JWORKLOAD,      │
  │                               │               SOCWATCH, WLC   │
  │                               │    Restart: True              │
  │                               │                               │
  │ 3. Receive "command received" │                               │
  │◄──────────────────────────────│                               │
  │                               │                               │
  │                               │ 4. Stop PACS if running       │
  │                               │    p.stop()                   │
  │                               │    p.exit()                   │
  │                               │                               │
  │                               │ 5. Wait 60s (InitialWait)     │
  │                               │    sleep_timer(60)            │
  │                               │                               │
  │                               │ 6. Start PACS                 │
  │                               │    p.runPACS()                │
  │                               │    p.loadConfig()             │
  │                               │    p.startDAQ()               │
  │                               │                               │
  │                               │ 7. Test-specific pre-script   │
  │                               │    (if GLD1001/5001/5002/     │
  │                               │     6001/6002)                │
  │                               │                               │
  │                               │ 8. Wait 30s (WorkloadInit)    │
  │                               │    sleep_timer(30)            │
  │                               │                               │
  │                               │ ═══════════════════════════════
  │                               │ 9. JWORKLOAD Processing       │
  │                               │ ═══════════════════════════════
  │                               │                               │
  │                               │ 9a. Log power mode start      │
  │                               │     power_mode("JWORKLOAD_    │
  │                               │                Started")      │
  │                               │     │                         │
  │                               │     └────────────────────────→│
  │                               │                               │ PsExec:
  │                               │                               │ KSRPowerSlider
  │                               │                               │
  │                               │ Loop: Repeat 3 times          │
  │                               │ ┌───────────────────────────┐ │
  │                               │ │ Iteration 1               │ │
  │                               │ │                           │ │
  │                               │ │ 9b. Wait 10s (InitialWait)│ │
  │                               │ │     sleep_timer(10)       │ │
  │                               │ │                           │ │
  │                               │ │ 9c. Pre-check (optional)  │ │
  │                               │ │     Verify workload ready │ │
  │                               │ │                           │ │
  │                               │ │ 9d. Start recording       │ │
  │                               │ │     p.record(result_path, │ │
  │                               │ │     "GLD1015_Nidaq_Result │ │
  │                               │ │     _JWORKLOAD_1")        │ │
  │                               │ │                           │ │
  │                               │ │ 9e. Record for 120s       │ │
  │                               │ │     time.sleep(118)       │ │
  │                               │ │     p.stop()              │ │
  │                               │ │                           │ │
  │                               │ │ 9f. Start debug tool      │ │
  │                               │ │     collect_debug_logs(   │ │
  │                               │ │     "JWORKLOAD","START")  │ │
  │                               │ │     │                     │ │
  │                               │ │     └────────────────────→│
  │                               │ │                           │ PsExec:
  │                               │ │                           │ Tool.bat
  │                               │ │                           │ JWORKLOAD
  │                               │ │                           │ START
  │                               │ │                           │
  │                               │ │ 9g. Stop debug tool       │ │
  │                               │ │     collect_debug_logs(   │ │
  │                               │ │     "JWORKLOAD","STOP")   │ │
  │                               │ │     │                     │ │
  │                               │ │     └────────────────────→│
  │                               │ │                           │ PsExec:
  │                               │ │                           │ Tool.bat
  │                               │ │                           │ JWORKLOAD
  │                               │ │                           │ STOP
  │                               │ │                           │
  │                               │ │ 9h. Wait 10s              │ │
  │                               │ │     sleep_timer(10)       │ │
  │                               │ │                           │ │
  │                               │ └───────────────────────────┘ │
  │                               │                               │
  │                               │ Iterations 2 and 3 (same)     │
  │                               │                               │
  │                               │ 9i. Log power mode end        │
  │                               │     power_mode("JWORKLOAD_    │
  │                               │                Ended")        │
  │                               │     │                         │
  │                               │     └────────────────────────→│
  │                               │                               │
  │                               │ ═══════════════════════════════
  │                               │ 10. SOCWATCH Processing       │
  │                               │ ═══════════════════════════════
  │                               │                               │
  │                               │ (Same pattern as JWORKLOAD:   │
  │                               │  power_mode, 3 iterations,    │
  │                               │  record, debug logs, wait)    │
  │                               │                               │
  │                               │ ═══════════════════════════════
  │                               │ 11. WLC Processing            │
  │                               │ ═══════════════════════════════
  │                               │                               │
  │                               │ (Same pattern, 2 iterations)  │
  │                               │                               │
  │                               │ 12. Stop PACS                 │
  │                               │     time.sleep(10)            │
  │                               │     p.stop()                  │
  │                               │     p.exit()                  │
  │                               │                               │
  │                               │ 13. Test-specific post-script │
  │                               │     (if GLD5001/5002)         │
  │                               │                               │
  │                               │ 14. Execute post script       │
  │                               │     post_str = rf'psexec ...  │
  │                               │     Client_Post.cmd Restart'  │
  │                               │     │                         │
  │                               │     └────────────────────────→│
  │                               │                               │ Execute:
  │                               │                               │ Client_Post
  │                               │                               │ Restart
  │                               │                               │
  │ 15. Connection closed         │                               │ System
  │◄──────────────────────────────│                               │ reboots
  │                               │                               │
  │ Client exits                  │ Server ready for next         │
  │                               │ connection                    │
```

**Result Files After Execution:**
```
Server (C:\Test\results\):
├── GLD1015_Nidaq_Result_JWORKLOAD_1\
│   └── GLD1015_Nidaq_Result_JWORKLOAD_1_summary.csv
├── GLD1015_Nidaq_Result_JWORKLOAD_2\
│   └── GLD1015_Nidaq_Result_JWORKLOAD_2_summary.csv
├── GLD1015_Nidaq_Result_JWORKLOAD_3\
│   └── GLD1015_Nidaq_Result_JWORKLOAD_3_summary.csv
├── GLD1015_Nidaq_Result_SOCWATCH_1\
│   └── GLD1015_Nidaq_Result_SOCWATCH_1_summary.csv
├── GLD1015_Nidaq_Result_SOCWATCH_2\
│   └── GLD1015_Nidaq_Result_SOCWATCH_2_summary.csv
├── GLD1015_Nidaq_Result_SOCWATCH_3\
│   └── GLD1015_Nidaq_Result_SOCWATCH_3_summary.csv
├── GLD1015_Nidaq_Result_WLC_1\
│   └── GLD1015_Nidaq_Result_WLC_1_summary.csv
└── GLD1015_Nidaq_Result_WLC_2\
    └── GLD1015_Nidaq_Result_WLC_2_summary.csv

Client (C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1015\):
├── GLD1015_JWORKLOAD_debug.log
├── GLD1015_SOCWATCH_debug.log
├── GLD1015_WLC_debug.log
├── GLD1015_events.log (power mode timestamps)
├── GLD1015_services.csv (background report)
└── GLD1015_system_info.txt
```

---

## Complete Test Execution Scenarios

### Scenario 1: Simple Idle Power Test

**Goal:** Measure idle power for 60 seconds

**Steps:**

```
Step 1: Check Server Availability
C:\> NiDaq_Client.exe 101
Response: PACS Version 2.5.1

Step 2: Start PACS
C:\> NiDaq_Client.exe 103
Response: PACS RUNNING

Step 3: Start Recording (60 second)
C:\> NiDaq_Client.exe 105 R60
Response: Waiting for 10 seconds to start recording...
[Server records for 60 seconds]

Step 4: Transfer Results
C:\> NiDaq_Client.exe 107
Response: START FILE TRANSFER
[Files transferred to NiDaq_Result\GLD1001_Nidaq_Result.csv]

Step 5: Stop PACS
C:\> NiDaq_Client.exe 106
Response: PACS STOPPED! STATUS:-1
```

**Timeline:**
```
0s    : Command 101 (ping) → Response: < 1s
1s    : Command 103 (start) → PACS initialization: 5-10s
11s   : Command 105 (record) → Wait 10s + Record 60s = 70s total
81s   : Command 107 (transfer) → File transfer: 5-10s (depends on size)
91s   : Command 106 (stop) → PACS shutdown: 2-5s
96s   : Complete
```

**Result:**
- File: `NiDaq_Result\GLD1001_Nidaq_Result.csv`
- Contains: 60 seconds of power data (voltage, current, power, temperature)

---

### Scenario 2: KPI List Automation

**Goal:** Execute tests from a KPI list automatically

**KPI_TestCase_List.txt:**
```
-TestId:GLD-1001 -Param W10:R30
-TestId:GLD-1002 -Param W5:R20:W5:R10
-TestId:GLD-1003 -Param W15:R60
```

**Master Script (RunAllTests.bat):**
```batch
@echo off
echo Starting NiDaq Automated Test Suite
echo ====================================

:LOOP
REM Check if more tests exist
findstr /V "^::" KPI_TestCase_List.txt > nul
if %ERRORLEVEL% NEQ 0 (
    echo All tests completed!
    goto END
)

REM Create test case
echo Creating test case...
NiDaq_Client.exe 102

REM Check if server is online
echo Checking server...
NiDaq_Client.exe 101
if %ERRORLEVEL% NEQ 0 (
    echo Server not responding!
    goto END
)

REM Start PACS
echo Starting PACS...
NiDaq_Client.exe 103

REM Execute test (calls TestCase_Run.cmd which runs workload)
echo Running test workload...
call TestCase_Run.cmd

REM Start recording (calls NiDaq_Record.cmd)
echo Starting power recording...
call NiDaq_Record.cmd

REM Transfer results
echo Transferring results...
NiDaq_Client.exe 107

REM Mark test complete
echo Marking test complete...
NiDaq_Client.exe 108

REM Stop PACS
echo Stopping PACS...
NiDaq_Client.exe 106

echo Test complete. Moving to next test...
echo.
goto LOOP

:END
echo Test suite finished!
pause
```

**Execution Flow:**
```
Iteration 1: GLD-1001
├─ 102: Create TestCase_Run.cmd, NiDaq_Record.cmd
├─ 101: Ping server
├─ 103: Start PACS
├─ TestCase_Run.cmd executes (workload runs)
├─ NiDaq_Record.cmd executes (105 W10:R30)
├─ 107: Transfer GLD1001_Nidaq_Result.csv
├─ 108: Comment out GLD-1001 in KPI list
└─ 106: Stop PACS

KPI_TestCase_List.txt now:
::-TestId:GLD-1001 -Param W10:R30    ← Completed
-TestId:GLD-1002 -Param W5:R20:W5:R10 ← Next
-TestId:GLD-1003 -Param W15:R60

Iteration 2: GLD-1002
[Same flow...]

Iteration 3: GLD-1003
[Same flow...]

All tests completed!
```

---

### Scenario 3: Temperature-Controlled Power Test

**Goal:** Measure power at multiple temperature points

**Script (TempSweep.bat):**
```batch
@echo off
echo Temperature Sweep Power Test
echo ==============================

REM Set base temperature
echo Setting temperature to 20C...
NiDaq_Client.exe 109 GLD-1010
timeout /t 1800 /nobreak >nul
REM Wait 30 minutes for stabilization

REM Verify temperature
echo Verifying temperature...
NiDaq_Client.exe 110

REM Run power test
echo Running power test at 20C...
NiDaq_Client.exe 103
NiDaq_Client.exe 105 W60:R300
NiDaq_Client.exe 107 GLD1010_20C
NiDaq_Client.exe 106

REM Set temperature to 30C
echo Setting temperature to 30C...
NiDaq_Client.exe 109 GLD-1011
timeout /t 1800 /nobreak >nul
REM Wait 30 minutes for stabilization

REM Verify temperature
echo Verifying temperature...
NiDaq_Client.exe 110

REM Run power test
echo Running power test at 30C...
NiDaq_Client.exe 103
NiDaq_Client.exe 105 W60:R300
NiDaq_Client.exe 107 GLD1010_30C
NiDaq_Client.exe 106

echo Temperature sweep complete!
```

**Server-Side Flow (Code 109):**
```
Client sends: "109"
Server responds: "Waiting for Temperature...."

Client sends: "20" (extracted from GLD-1010.bat)
Server responds: "Temperature Values received..."

Server executes: python KSRTemp.py --set 20
[Thermal chamber adjusts to 20°C]

Server responds: "Temperature has been successfully set"
Client receives and logs success
```

**Results:**
- `GLD1010_20C_Nidaq_Result.csv` (300s of power data at 20°C)
- `GLD1010_30C_Nidaq_Result.csv` (300s of power data at 30°C)

---

### Scenario 4: Modern Standby (Connected Standby) Test

**Goal:** Measure power during Modern Standby with multiple sleep/wake cycles

**Command:**
```batch
NiDaq_Client.exe 112 "-TestId:GLD1006 -InitialWait:60 -WorkloadInitialWait:30 
-JWORKLOAD(Repeat:5,Record:600,Wait:30) 
-SOCWATCH(Repeat:5,Record:600,Wait:30)"
```

**Server-Side Special Handling (GLD1006):**
```python
if test_id == "GLD1006":
    # Calculate total CS runtime
    # JWORKLOAD: (600+30) * 5 + 30 = 3180s (53 minutes)
    # SOCWATCH: (600+30) * 5 = 3150s
    
    cs_total_runtime = ((int(record)+int(wait))*int(repeat)) + int(workload_initial_wait)
    
    # Check for TTK hardware
    if os.path.exists(r"C:\SVshare\user_apps\ttk3\api\python\FrontPanel.py"):
        print_Info("TTK found - Using hardware power button")
        print_Info("Putting System into Sleep....")
        mcs_ttk()  # Press power button via TTK
        ttk = True
    else:
        logging.error("TTK not found - Cannot enter Modern Standby")
        sys.exit(1)
```

**Execution Flow:**
```
Server                          Client SUT                   PACS Hardware
  │                               │                             │
  │ 1. Wait 60s (InitialWait)     │                             │
  │                               │                             │
  │ 2. Start PACS                 │                             │
  │────────────────────────────────────────────────────────────→│
  │                               │                             │ Initialize DAQ
  │                               │                             │
  │ 3. Verify TTK present         │                             │
  │                               │                             │
  │ 4. Calculate CS runtime       │                             │
  │    53 minutes total           │                             │
  │                               │                             │
  │ 5. Put system to sleep        │                             │
  │────────────────────────────→  │                             │
  │                               │ TTK presses power button    │
  │                               │ System enters S0ix          │
  │                               │ (Modern Standby)            │
  │                               │                             │
  │ 6. Wait 30s (WorkloadInit)    │                             │
  │                               │                             │
  │ Loop: 5 iterations            │                             │
  │ ┌─────────────────────────┐   │                             │
  │ │ Iteration 1             │   │                             │
  │ │                         │   │                             │
  │ │ 7. Start PACS recording │   │                             │
  │ │────────────────────────────────────────────────────────→  │
  │ │                         │   │                             │ Record power
  │ │                         │   │ [System sleeping]           │ for 600s
  │ │                         │   │                             │
  │ │ 8. Record for 600s      │   │                             │
  │ │    (System in S0ix)     │   │                             │
  │ │                         │   │                             │
  │ │ 9. Stop recording       │   │                             │
  │ │────────────────────────────────────────────────────────→  │
  │ │                         │   │                             │ Stop
  │ │                         │   │                             │
  │ │ 10. Wait 30s            │   │                             │
  │ │                         │   │                             │
  │ └─────────────────────────┘   │                             │
  │                               │                             │
  │ [Iterations 2-5 repeat]       │                             │
  │                               │                             │
  │ 11. Wake system               │                             │
  │────────────────────────────→  │                             │
  │                               │ TTK releases power button   │
  │                               │ System wakes from S0ix      │
  │                               │                             │
  │ 12. Stop PACS                 │                             │
  │────────────────────────────────────────────────────────────→│
  │                               │                             │ Exit
```

**SOCWATCH Processing:**
```
[Similar to JWORKLOAD, but SOCWATCH tool collects additional platform metrics]

For each iteration:
├─ Start SOCWATCH tool remotely (collect_debug_logs)
├─ Start PACS recording
├─ Record for 600s (system sleeping)
├─ Stop PACS recording
├─ Stop SOCWATCH tool remotely
└─ Wait 30s
```

**Result Files:**
```
Server (C:\Test\results\):
├── GLD1006_Nidaq_Result_JWORKLOAD_1\
│   └── GLD1006_Nidaq_Result_JWORKLOAD_1_summary.csv (600s CS power)
├── GLD1006_Nidaq_Result_JWORKLOAD_2\
├── GLD1006_Nidaq_Result_JWORKLOAD_3\
├── GLD1006_Nidaq_Result_JWORKLOAD_4\
├── GLD1006_Nidaq_Result_JWORKLOAD_5\
├── GLD1006_Nidaq_Result_SOCWATCH_1\
│   └── GLD1006_Nidaq_Result_SOCWATCH_1_summary.csv (600s CS power)
├── GLD1006_Nidaq_Result_SOCWATCH_2\
├── GLD1006_Nidaq_Result_SOCWATCH_3\
├── GLD1006_Nidaq_Result_SOCWATCH_4\
└── GLD1006_Nidaq_Result_SOCWATCH_5\

Client (C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1006\):
├── GLD1006_SOCWATCH_1.csv (platform power breakdown)
├── GLD1006_SOCWATCH_2.csv
├── GLD1006_SOCWATCH_3.csv
├── GLD1006_SOCWATCH_4.csv
└── GLD1006_SOCWATCH_5.csv
```

**Total Test Duration:** ~60 minutes (53 min CS runtime + initialization/cleanup)

---

## Communication Patterns

### Pattern 1: Simple Request-Response

**Used by:** 101, 103, 104, 106, 110

```
Client                          Server
  │                               │
  │──── Command ─────────────────→│
  │                               │ Process (quick)
  │◄─── Response ──────────────── │
  │                               │
  └─ Close                        └─ Ready for next
```

**Example (Code 101 - Ping):**
```
Client sends: "101"
Server responds: "PACS Version 2.5.1" (immediate)
Connection closes
Duration: < 1 second
```

---

### Pattern 2: Command with Parameters

**Used by:** 105, 112

```
Client                          Server
  │                               │
  │──── "105 W10:R30" ───────────→│
  │                               │ Parse parameters
  │◄─── Acknowledgment ────────── │
  │                               │
  │                               │ Execute (may take time)
  │                               │ - Wait 10s
  │                               │ - Record 30s
  │                               │
  │ (Connection may stay open     │
  │  or close depending on        │
  │  command)                     │
```

---

### Pattern 3: Multi-Stage Exchange (File Transfer)

**Used by:** 107

```
Client                                    Server
  │                                         │
  │──── "107" ─────────────────────────────→│
  │                                         │
  │◄─── "START FILE TRANSFER" ──────────────│
  │                                         │
  │──── "Send folder count" ───────────────→│
  │                                         │
  │◄─── "2" (folder count) ─────────────────│
  │                                         │
  │──── "Send the Size" ───────────────────→│
  │                                         │
  │◄─── "52480" (bytes) ────────────────────│
  │                                         │
  │──── "Send the filename" ───────────────→│
  │                                         │
  │◄─── "GLD1001_summary.csv" ──────────────│
  │                                         │
  │──── "Received file Content" ───────────→│
  │                                         │
  │◄─── [Binary data chunks] ───────────────│
  │◄─── [Binary data chunks] ───────────────│
  │◄─── [Binary data chunks] ───────────────│
  │     (until all bytes received)          │
  │                                         │
  │──── "Send the Size" ───────────────────→│ (Folder 2)
  │                                         │
  [Repeat for second folder]                │
  │                                         │
  └─ Close                                  └─ Ready
```

---

### Pattern 4: Hybrid Client-Server (Temperature)

**Used by:** 109

```
Client Side                     Server Side                 Thermal Chamber
  │                               │                             │
  │ 1. Read GLD-1010.bat          │                             │
  │    Extract: Temperature=25    │                             │
  │                               │                             │
  │ 2. Connect to server          │                             │
  │──────────────────────────────→│                             │
  │                               │                             │
  │ 3. Send "109"                 │                             │
  │──────────────────────────────→│                             │
  │                               │                             │
  │◄─ "Waiting for Temperature" ──│                             │
  │                               │                             │
  │ 4. Send "25"                  │                             │
  │──────────────────────────────→│                             │
  │                               │                             │
  │◄─ "Temperature received" ─────│                             │
  │                               │                             │
  │                               │ 5. Execute KSRTemp.py       │
  │                               │    python KSRTemp.py        │
  │                               │    --set 25                 │
  │                               │─────────────────────────────→│
  │                               │                             │ Set temp
  │                               │                             │ to 25°C
  │                               │                             │
  │                               │◄────────────────────────────│
  │                               │   "Temperature set"         │
  │                               │                             │
  │◄─ "Temperature successfully"──│                             │
  │    "set"                      │                             │
  │                               │                             │
  └─ Close                        └─ Ready                      │
                                                                │
                                                                │ Maintains
                                                                │ 25°C
```

---

## File Transfer Mechanisms

### Mechanism 1: Socket-Based Transfer (Command 107)

**Advantages:**
- ✅ Direct communication over TCP
- ✅ No network share required
- ✅ Works across different networks/VLANs
- ✅ Binary transfer (efficient)

**Disadvantages:**
- ❌ Custom protocol implementation
- ❌ Requires handshake for each file
- ❌ No resume capability on failure

**Transfer Protocol:**
```
┌────────────────────────────────────────────────────────┐
│  Phase 1: Initiation                                   │
│  Client: "107"                                         │
│  Server: "START FILE TRANSFER"                         │
└────────────────────────────────────────────────────────┘
                        ↓
┌────────────────────────────────────────────────────────┐
│  Phase 2: Folder Count                                 │
│  Client: "Send the folder count"                       │
│  Server: "5" (number of result folders)                │
└────────────────────────────────────────────────────────┘
                        ↓
┌────────────────────────────────────────────────────────┐
│  Phase 3: For Each Folder (Loop)                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Step A: File Size                               │  │
│  │  Client: "Send the Size"                         │  │
│  │  Server: "52480" (bytes)                         │  │
│  └──────────────────────────────────────────────────┘  │
│                        ↓                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Step B: Filename                                │  │
│  │  Client: "Send the filename"                     │  │
│  │  Server: "GLD1001_summary.csv"                   │  │
│  └──────────────────────────────────────────────────┘  │
│                        ↓                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Step C: File Content                            │  │
│  │  Client: "Received the file Content"             │  │
│  │  Server: [Binary data in 1024-byte chunks]       │  │
│  │          [chunk] [chunk] [chunk] ...             │  │
│  │          (until all bytes sent)                  │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
                        ↓
┌────────────────────────────────────────────────────────┐
│  Phase 4: Completion                                   │
│  All folders transferred                               │
│  Connection closes                                     │
└────────────────────────────────────────────────────────┘
```

**Client-Side Implementation:**
```python
# Receive file
received_data = 0
with open(new_file_path, "wb") as file:
    client.send("Received the file Content".encode('utf-8'))
    while received_data < file_size:
        chunk = client.recv(1024)
        if not chunk:
            break
        file.write(chunk)
        received_data += len(chunk)

if received_data == file_size:
    print_Info("File received and saved successfully.")
else:
    print_error(f"Expected {file_size} bytes but received {received_data} bytes.")
```

**Server-Side Implementation:**
```python
# Send file
with open(full_file_path, 'rb') as file:
    while chunk := file.read(1024):
        client_socket.send(chunk)
print_Info("CSV file sent successfully.")
```

---

### Mechanism 2: Network Share Transfer (Command 113)

**Advantages:**
- ✅ Standard Windows file sharing
- ✅ Simple implementation (xcopy)
- ✅ Automatic retry on transient failures
- ✅ No custom protocol needed

**Disadvantages:**
- ❌ Requires network share configuration
- ❌ Firewall rules needed (SMB ports)
- ❌ Authentication required
- ❌ Less portable across different environments

**Transfer Flow:**
```
┌────────────────────────────────────────────────────────┐
│  Phase 1: Mount Network Drive                          │
│  Client executes:                                      │
│  net use K: \\192.168.0.3\Test /user:intel intel@123   │
│                                                        │
│  Result: K: drive mapped to \\server\Test              │
└────────────────────────────────────────────────────────┘
                        ↓
┌────────────────────────────────────────────────────────┐
│  Phase 2: Browse and Copy Files                        │
│  Client navigates: K:\results\                         │
│  Find folders: GLD1001_Result, GLD1002_Result, ...     │
│                                                        │
│  For each folder:                                      │
│  ┌────────────────────────────────────────────────┐    │
│  │ - Extract TestID from folder name             │     │
│  │ - Find _summary.csv file                      │     │
│  │ - Clean filename (remove _summary, _JWORKLOAD)│     │
│  │ - Check for duplicates                        │     │
│  │ - Execute: xcopy K:\...\file C:\...\file /-I  │     │
│  └────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────┘
                        ↓
┌────────────────────────────────────────────────────────┐
│  Phase 3: Handle ETL Files                             │
│  If ETL folder exists:                                 │
│  ┌────────────────────────────────────────────────┐    │
│  │ - Get power slider setting (AC_BAL, etc.)     │     │
│  │ - Create dated folder with power mode         │     │
│  │ - Copy ETL files                              │     │
│  │ - Delete source ETL folder                    │     │
│  └────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────┘
                        ↓
┌────────────────────────────────────────────────────────┐
│  Phase 4: Unmount Drive                                │
│  Client executes: net use K: /delete                   │
│                                                        │
│  Result: K: drive unmapped, connection closed          │
└────────────────────────────────────────────────────────┘
```

**Server-Side Network Share Setup:**
```powershell
# Create share
New-SmbShare -Name "Test" -Path "C:\Test" -FullAccess "intel"

# Set permissions
Grant-SmbShareAccess -Name "Test" -AccountName "intel" -AccessRight Full
```

**Client-Side File Organization:**
```
K:\results\GLD1001_Nidaq_Result_JWORKLOAD_1\
└── GLD1001_Nidaq_Result_JWORKLOAD_1_summary.csv

Copied to:
C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1001\
└── GLD1001_JWORKLOAD_1.csv
```

---

### Transfer Mechanism Comparison

| Feature | Socket Transfer (107) | Network Share (113) |
|---------|----------------------|---------------------|
| **Network Requirements** | TCP port 55555 open | SMB ports (445, 139) open |
| **Authentication** | None (open socket) | Windows credentials required |
| **Firewall Impact** | Minimal (single port) | Higher (SMB ports) |
| **Cross-Platform** | Yes (TCP is universal) | Windows-specific (SMB) |
| **Implementation** | Custom protocol | Standard Windows commands |
| **Error Recovery** | Manual retry needed | Built-in retry in xcopy |
| **File Filtering** | Server-side (only _summary.csv) | Client-side (regex filtering) |
| **Performance** | Direct transfer (fast) | Network share overhead |
| **Use Case** | Production tests (controlled env) | Development/lab (flexible) |

---

## Test Orchestration Flow

### Complete Test Lifecycle

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     COMPLETE TEST LIFECYCLE                                 │
└─────────────────────────────────────────────────────────────────────────────┘

Phase 1: Preparation
──────────────────────
    ┌──────────────────────────────────────────────────┐
    │ Test Engineer creates KPI_TestCase_List.txt      │
    │                                                  │
    │ -TestId:GLD-1001 -Param W10:R30                  │
    │ -TestId:GLD-1002 -Param W5:R20:W5:R10            │
    │ -TestId:GLD-1003 -Param W15:R60                  │
    └──────────────────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────────────────┐
    │ Configure Server (config.ini)                    │
    │ - Start NiDaq_Server.py                          │
    │ - Server listens on port 55555                   │
    └──────────────────────────────────────────────────┘
                        ↓

Phase 2: Test Execution (Per Test Case)
────────────────────────────────────────
    ┌──────────────────────────────────────────────────┐
    │ A. Create Test Case (Client)                     │
    │    NiDaq_Client.exe 102                          │
    │    ├─ Read first uncommented line from KPI list  │
    │    ├─ Parse test parameters                      │
    │    ├─ Generate TestCase_Run.cmd                  │
    │    └─ Generate NiDaq_Record.cmd                  │
    └──────────────────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────────────────┐
    │ B. Verify Server (Client)                        │
    │    NiDaq_Client.exe 101                          │
    │    └─ Server responds with PACS version          │
    └──────────────────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────────────────┐
    │ C. Initialize PACS (Client → Server)             │
    │    NiDaq_Client.exe 103                          │
    │    Server actions:                               │
    │    ├─ Start PACS application                     │
    │    ├─ Load configuration file                    │
    │    └─ Start data acquisition                     │
    └──────────────────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────────────────┐
    │ D. Execute Test Workload (Client Local)          │
    │    call TestCase_Run.cmd                         │
    │    ├─ Launch test application                    │
    │    ├─ Execute benchmark                          │
    │    └─ Workload runs for specified duration       │
    └──────────────────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────────────────┐
    │ E. Record Power (Client → Server)                │
    │    call NiDaq_Record.cmd                         │
    │    (which calls: NiDaq_Client.exe 105 W10:R30)   │
    │    Server actions:                               │
    │    ├─ Wait 10 seconds                            │
    │    ├─ Start power recording                      │
    │    ├─ Record for 30 seconds                      │
    │    └─ Stop recording                             │
    └──────────────────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────────────────┐
    │ F. Transfer Results (Client → Server)            │
    │    NiDaq_Client.exe 107                          │
    │    Server actions:                               │
    │    ├─ Find CSV files in result_path              │
    │    ├─ Send file count                            │
    │    ├─ For each file:                             │
    │    │  ├─ Send file size                          │
    │    │  ├─ Send filename                           │
    │    │  └─ Send binary data                        │
    │    Client actions:                               │
    │    ├─ Receive files                              │
    │    ├─ Save to NiDaq_Result\                      │
    │    └─ Organize by TestID                         │
    └──────────────────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────────────────┐
    │ G. Mark Test Complete (Client)                   │
    │    NiDaq_Client.exe 108                          │
    │    ├─ Find current test line in KPI list         │
    │    ├─ Prepend "::" to mark complete              │
    │    └─ Save updated KPI list                      │
    │                                                  │
    │ KPI_TestCase_List.txt becomes:                   │
    │ ::-TestId:GLD-1001 -Param W10:R30  ← Completed   │
    │ -TestId:GLD-1002 -Param W5:R20...  ← Next        │
    └──────────────────────────────────────────────────┘
                        ↓
    ┌──────────────────────────────────────────────────┐
    │ H. Stop PACS (Client → Server)                   │
    │    NiDaq_Client.exe 106                          │
    │    Server actions:                               │
    │    ├─ Stop any active recording                  │
    │    └─ Exit PACS application                      │
    └──────────────────────────────────────────────────┘
                        ↓

Phase 3: Iteration
──────────────────
    ┌──────────────────────────────────────────────────┐
    │ Check if more tests exist                        │
    │ (uncommented lines in KPI list)                  │
    │                                                  │
    │ If YES: Go back to Phase 2                       │
    │ If NO:  Proceed to Phase 4                       │
    └──────────────────────────────────────────────────┘
                        ↓

Phase 4: Completion & Analysis
───────────────────────────────
    ┌──────────────────────────────────────────────────┐
    │ All tests complete                               │
    │                                                  │
    │ Results available in:                            │
    │ ├─ Client: NiDaq_Result\                         │
    │ │  ├─ GLD1001_Nidaq_Result.csv                   │
    │ │  ├─ GLD1002_Nidaq_Result.csv                   │
    │ │  └─ GLD1003_Nidaq_Result.csv                   │
    │ │                                                │
    │ └─ Server: C:\Test\results\                      │
    │    ├─ NiDaqResult1\                              │
    │    ├─ NiDaqResult2\                              │
    │    └─ NiDaqResult3\                              │
    │                                                  │
    │ Next steps:                                      │
    │ ├─ Analyze CSV files (power, voltage, current)   │
    │ ├─ Generate reports                              │
    │ └─ Archive results                               │
    └──────────────────────────────────────────────────┘
```

---

## Error Handling & Recovery

### Server-Side Error Scenarios

#### 1. PACS Initialization Failure

**Scenario:** PACS fails to start (Code 103)

```
Error Detection:
├─ Check p.status() after runPACS()
├─ If status remains "-1", PACS didn't start
└─ Log error and notify client

Recovery:
├─ Check PACS executable path
├─ Verify PACS license
├─ Check hardware connection
└─ Restart PACS manually if needed
```

**Server Response:**
```python
if p.status() == "-1":
    response = "PACS NOT IN READY STATE! STATUS: -1"
    client_socket.send(response.encode("utf-8"))
    print_error(response)
```

---

#### 2. Remote Execution Timeout

**Scenario:** PsExec command hangs or times out

```
Error Detection:
├─ subprocess.run() with timeout=300 (5 minutes)
├─ If timeout expires, TimeoutExpired exception raised
└─ Log error with command details

Recovery:
├─ Check network connectivity to client
├─ Verify client system is responsive
├─ Check if command is valid
└─ Retry with longer timeout if needed
```

**Server Implementation:**
```python
try:
    result = subprocess.run(cmd, shell=True, capture_output=True, 
                          text=True, timeout=300)
except subprocess.TimeoutExpired:
    print_error(f"Command timed out after 300 seconds: {cmd}")
    # Kill process, cleanup, notify client
```

---

#### 3. File Transfer Interruption

**Scenario:** Network disconnection during file transfer (Code 107)

```
Error Detection:
├─ socket.error during send()
├─ Client disconnects mid-transfer
└─ Log incomplete transfer

Recovery:
├─ Client can re-request file (Code 107 again)
├─ Server will resend from beginning
└─ No partial file support (all-or-nothing)
```

**Server Handling:**
```python
try:
    with open(full_file_path, 'rb') as file:
        while chunk := file.read(1024):
            client_socket.send(chunk)
except socket.error as se:
    print_Info(f"Socket error during file transfer: {se}")
    # Close connection, file remains on server for retry
```

---

### Client-Side Error Scenarios

#### 1. Server Connection Failure

**Scenario:** Cannot connect to server (any command)

```
Error Detection:
├─ socket.error on connect()
├─ Connection refused or timeout
└─ Log error with server address

Recovery:
├─ Verify server is running
├─ Check network connectivity (ping server)
├─ Verify firewall rules (port 55555)
└─ Retry connection after delay
```

**Client Implementation:**
```python
try:
    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client.connect((host, port))
except socket.error as e:
    print_error(f"Failed to connect to the server: {host}")
    sys.exit(1)
```

---

#### 2. KPI List Parsing Error

**Scenario:** Malformed line in KPI_TestCase_List.txt (Code 102)

```
Error Detection:
├─ Regex match fails
├─ Missing required parameters
└─ Invalid format

Recovery:
├─ Log error with line content
├─ Skip to next line
└─ Manual correction required
```

**Client Handling:**
```python
try:
    testcase_file = re.findall(r"-(?:\w+:)?(\w[\w\-]*)", testCase)
    testId = testcase_file[0]
except (IndexError, AttributeError) as e:
    print_error(f"Failed to parse test case: {testCase}")
    print_error(f"Error: {e}")
    sys.exit(1)
```

---

#### 3. File Transfer Incomplete

**Scenario:** Received bytes don't match expected size (Code 107)

```
Error Detection:
├─ Compare received_data with file_size
├─ If mismatch, log error
└─ File saved but marked as incomplete

Recovery:
├─ Delete incomplete file
├─ Re-run Code 107 to retry transfer
└─ Check network stability
```

**Client Handling:**
```python
if received_data == file_size:
    print_Info("File received and saved successfully.")
else:
    print_error(f"Expected {file_size} bytes but received {received_data} bytes.")
    os.remove(new_file_path)  # Delete incomplete file
```

---

### Error Recovery Best Practices

#### Test Framework Level

```batch
REM Master test script with error recovery

:RETRY_LOOP
set RETRY_COUNT=0
set MAX_RETRIES=3

:TEST_START
REM Increment retry counter
set /a RETRY_COUNT=%RETRY_COUNT%+1

REM Try to ping server
NiDaq_Client.exe 101
if %ERRORLEVEL% NEQ 0 (
    echo Server not responding, attempt %RETRY_COUNT% of %MAX_RETRIES%
    if %RETRY_COUNT% LSS %MAX_RETRIES% (
        timeout /t 30 /nobreak >nul
        goto TEST_START
    ) else (
        echo Max retries reached, aborting test
        goto ERROR_EXIT
    )
)

REM Server is online, proceed with test
NiDaq_Client.exe 102
NiDaq_Client.exe 103
REM ... rest of test commands ...

goto SUCCESS_EXIT

:ERROR_EXIT
echo Test failed after %RETRY_COUNT% attempts
exit /b 1

:SUCCESS_EXIT
echo Test completed successfully
exit /b 0
```

---

## Deployment Architecture

### Production Deployment

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Production Test Lab Setup                            │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌───────────────────────────────────────────────────────────────────┐
    │                         Network: 192.168.0.0/24                   │
    │                         VLAN: Test Lab                            │
    └───────────────────────────────────────────────────────────────────┘

    ┌─────────────────────┐      ┌─────────────────────┐
    │ PACS Host Server    │      │ Temperature Chamber │
    │ (NiDaq Server)      │      │ Control Unit        │
    ├─────────────────────┤      ├─────────────────────┤
    │ IP: 192.168.0.3     │      │ Serial: COM1        │
    │ OS: Windows 10 Pro  │◄─────│ Interface: RS232    │
    │ CPU: 8 cores        │      └─────────────────────┘
    │ RAM: 16 GB          │
    │ Storage: 500 GB SSD │
    │                     │
    │ Software:           │
    │ - Python 3.9+       │      ┌─────────────────────┐
    │ - NiDaq_Server.py   │      │ PACS Hardware       │
    │ - __pyPACS library  │◄─────│ (Power Analyzer)    │
    │ - KSRTemp.py        │      │ - Voltage channels  │
    │ - PsExec            │      │ - Current sensors   │
    │                     │      │ - Data acquisition  │
    │ Network Share:      │      └─────────────────────┘
    │ \\192.168.0.3\Test  │
    └──────────┬──────────┘
               │
               │ TCP Port 55555
               │ PsExec Remote Execution
               │
    ┌──────────┴──────────────────────────────────────────────────┐
    │                                                              │
┌───┴──────────────────┐  ┌────────────────────────┐  ┌────────────────────┐
│ SUT 1 (Client)       │  │ SUT 2 (Client)         │  │ SUT 3 (Client)     │
├──────────────────────┤  ├────────────────────────┤  ├────────────────────┤
│ IP: 192.168.0.100    │  │ IP: 192.168.0.101      │  │ IP: 192.168.0.102  │
│ OS: Windows 11       │  │ OS: Windows 11         │  │ OS: Windows 11     │
│                      │  │                        │  │                    │
│ Software:            │  │ Software:              │  │ Software:          │
│ - NiDaq_Client.exe   │  │ - NiDaq_Client.exe     │  │ - NiDaq_Client.exe │
│ - Test Framework     │  │ - Test Framework       │  │ - Test Framework   │
│ - JWORKLOAD          │  │ - JWORKLOAD            │  │ - JWORKLOAD        │
│ - SoCWatch           │  │ - SoCWatch             │  │ - SoCWatch         │
│ - Debug Tools        │  │ - Debug Tools          │  │ - Debug Tools      │
│                      │  │                        │  │                    │
│ TTK Hardware:        │  │ TTK Hardware:          │  │ TTK Hardware:      │
│ - Power button ctrl  │  │ - Power button ctrl    │  │ - Power button ctrl│
└──────────────────────┘  └────────────────────────┘  └────────────────────┘

    Each SUT runs tests independently, connecting to same PACS server
    (One at a time due to single-threaded server)
```

### Multi-Instance Deployment (Concurrent Testing)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                  Multi-Instance for Concurrent Testing                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌───────────────────────┐  ┌───────────────────────┐  ┌───────────────────────┐
│ PACS Host 1           │  │ PACS Host 2           │  │ PACS Host 3           │
├───────────────────────┤  ├───────────────────────┤  ├───────────────────────┤
│ IP: 192.168.0.10      │  │ IP: 192.168.0.20      │  │ IP: 192.168.0.30      │
│ Port: 55555           │  │ Port: 55555           │  │ Port: 55555           │
│ NiDaq_Server.py       │  │ NiDaq_Server.py       │  │ NiDaq_Server.py       │
│ PACS Instance 1       │  │ PACS Instance 2       │  │ PACS Instance 3       │
└───────────┬───────────┘  └───────────┬───────────┘  └───────────┬───────────┘
            │                          │                          │
            │                          │                          │
            ↓                          ↓                          ↓
┌───────────────────────┐  ┌───────────────────────┐  ┌───────────────────────┐
│ SUT 1                 │  │ SUT 2                 │  │ SUT 3                 │
│ Tests: GLD-1001-1005  │  │ Tests: GLD-2001-2005  │  │ Tests: GLD-3001-3005  │
│ Client → 192.168.0.10 │  │ Client → 192.168.0.20 │  │ Client → 192.168.0.30 │
└───────────────────────┘  └───────────────────────┘  └───────────────────────┘

Benefits:
✅ 3x test throughput (parallel execution)
✅ No client blocking (each has dedicated server)
✅ Independent PACS instances (no interference)

Drawbacks:
❌ 3x hardware cost (PACS + Server)
❌ 3x resource usage
❌ More complex management
```

---

## Comparison Matrix

### Detailed Feature Comparison

| Feature | NiDaq Server | NiDaq Client |
|---------|--------------|--------------|
| **Execution Model** | Continuous loop (while True) | Single execution (exits) |
| **Startup Time** | Once per deployment | Every command invocation |
| **Process Lifetime** | Indefinite (until stopped) | Seconds to minutes |
| **Socket Role** | Server (accept connections) | Client (initiate connections) |
| **Concurrency** | One client at a time | Multiple instances possible |
| **State Persistence** | Yes (PACS state) | No (stateless) |
| **Hardware Control** | Yes (PACS, TTK, Temp) | No (only coordinates) |
| **Remote Execution** | Yes (PsExec to client) | No (local only) |
| **File Generation** | No | Yes (TestCase scripts) |
| **Result Storage** | Yes (CSV files) | Yes (received from server) |
| **Temperature Control** | Yes (KSRTemp.py) | Extracts values only |
| **Power Measurement** | Yes (primary function) | No (requests from server) |
| **KPI List Management** | No | Yes (read/update) |
| **Network Share Access** | Hosts share (\\server\Test) | Mounts and accesses |
| **Configuration** | config.ini (paths, delays) | config.ini (server, paths) |
| **Logging** | Server_Log_YYYY-MM-DD.log | Client_Log_YYYY-MM-DD.log |
| **Dependencies** | __pyPACS, PsExec, KSRTemp, TTK | Socket, subprocess, shutil |
| **Primary Language** | Python | Python |
| **Version** | 1.13 | 1.9 |

### Command Processing Matrix

| Command | Server Processing | Client Processing | Network Communication |
|---------|-------------------|-------------------|----------------------|
| **101** | Return PACS version | Connect, receive | Yes (request-response) |
| **102** | None | Parse KPI, generate scripts | No (client-only) |
| **103** | Start PACS, load config | Send command, receive status | Yes (request-response) |
| **104** | Query PACS status | Send command, receive status | Yes (request-response) |
| **105** | Parse W:R:, record power | Send W:R: parameters | Yes (request-response) |
| **106** | Stop PACS, exit | Send command, receive status | Yes (request-response) |
| **107** | Send CSV files (binary) | Receive files, save locally | Yes (multi-stage exchange) |
| **108** | None | Comment out line in KPI list | No (client-only) |
| **109** | Receive temp, call KSRTemp | Extract from file, send value | Yes (multi-stage exchange) |
| **110** | Call KSRTemp, return value | Send command, receive temp | Yes (request-response) |
| **111** | Send status | Network mount, copy files | Minimal (status only) |
| **112** | Complex orchestration | Send parameters, receive status | Yes (complex multi-stage) |
| **113** | None | Network mount, copy, unmount | No (client-only) |

### Data Flow Matrix

| Data Type | Origin | Storage Location | Transfer Method | Format |
|-----------|--------|------------------|-----------------|---------|
| **Power Measurements** | PACS Hardware | Server: C:\Test\results\ | Socket (107) or Network (113) | CSV (summary files) |
| **Test Scripts** | Client (generated) | Client: local directory | None (local only) | Batch files (.cmd) |
| **KPI List** | Test Engineer | Client: KPI_TestCase_List.txt | None (local only) | Text file |
| **Debug Logs** | Client SUT tools | Client: Results\Golden_Results\ | None (local only) | CSV/ETL/Log files |
| **Test Parameters** | KPI List | Client: test_id.txt, test_param.txt | None (local only) | Text files |
| **Power Mode Events** | Client execution | Client: Results\events.log | None (local only) | Log file |
| **Temperature Data** | Thermal Chamber | Server (via KSRTemp.py) | Query (110) or Set (109) | Numeric value |
| **PACS Configuration** | Test Engineer | Server: testconfig.csv | None (pre-configured) | CSV |
| **Server Logs** | Server operations | Server: NiDaq_Server_Log_DATE.log | None (server only) | Log file |
| **Client Logs** | Client operations | Client: NiDaq_Client_Log_DATE.log | None (client only) | Log file |

---

## Summary

### System Characteristics

**NiDaq System is:**
- ✅ **Distributed**: Client and server run on separate systems
- ✅ **Synchronized**: Power measurement synchronized with workload execution
- ✅ **Flexible**: Supports simple to complex test scenarios
- ✅ **Automated**: KPI list enables unattended test execution
- ✅ **Scalable**: Multiple clients can use same server (sequentially)

**Key Strengths:**
1. **Precise Power Measurement**: PACS hardware provides accurate voltage/current/power data
2. **Remote Control**: Server can execute commands on client without user intervention
3. **Multi-Workload Support**: Simultaneously collect power data and debug tool metrics
4. **Temperature Control**: Integrated thermal chamber for environmental testing
5. **Modern Standby**: Special support for low-power state testing with TTK

**Known Limitations:**
1. **Single-Threaded Server**: One client at a time (no concurrent testing)
2. **No Automatic Retry**: Failed operations require manual restart
3. **Platform-Specific**: Windows-only (PsExec, network shares, TTK)
4. **No Authentication**: Open socket (security concerns in production)
5. **Manual Recovery**: Most errors require human intervention

### Recommended Use Cases

**Ideal For:**
- ✅ Automated power measurement testing
- ✅ Multi-iteration benchmark power analysis
- ✅ Temperature-controlled power characterization
- ✅ Modern Standby / Connected Standby validation
- ✅ Long-running unattended test suites

**Not Recommended For:**
- ❌ High-throughput testing (use multi-instance deployment)
- ❌ Real-time power monitoring (use direct PACS API)
- ❌ Cross-platform testing (Windows only)
- ❌ Security-sensitive environments (no authentication)

---

## Contact & Support

**Development Team:** Kingsriver Team  
**Documentation:** https://kingsriver.intel.com  
**Help Command:**  
- Server: `python NiDaq_Server.py --help`
- Client: `NiDaq_Client.exe /?`

**Log Files:**
- Server: `NiDaq_Server_Log_YYYY-MM-DD.log`
- Client: `NiDaq_Client_Log_YYYY-MM-DD.log`

**Configuration Files:**
- Server: `config.ini` (server section + paths)
- Client: `config.ini` (server connection + client paths)

---

*End of NiDaq Complete System Architecture Documentation*
