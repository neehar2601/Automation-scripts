# NiDaq Server - Modular Version Guide

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [File Paths & Structure](#file-paths--structure)
- [Running the Server](#running-the-server)
- [Using the Client](#using-the-client)
- [Module Reference](#module-reference)
- [Command Reference](#command-reference)
- [Troubleshooting](#troubleshooting)
- [Network Configuration](#network-configuration)
- [Development Guide](#development-guide)

---

## Overview

The **Modular NiDaq Server** is a professionally architected PowerShell TCP server with separated concerns, making it ideal for large-scale deployments and team development. It provides the same functionality as the standalone version but with better maintainability and testability.

### Key Features
- ✅ Modular architecture (3 modules + 3 classes)
- ✅ Easy to maintain and extend
- ✅ Unit testable components
- ✅ Configurable buffer size (4096 bytes default)
- ✅ Enhanced error handling
- ✅ Better code organization
- ✅ Same protocol as standalone version
- ✅ Production-ready structure

### Use Cases
- Enterprise test automation
- Team development environments
- Large-scale test orchestration
- Systems requiring customization
- Continuous integration pipelines
- Multi-DUT test farms

---

## Architecture

### Modular Structure

```
┌─────────────────────────────────────────────────────────┐
│                  NiDaqServer-Modular.ps1                │
│                    (Main Entry Point)                   │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   Logging    │   │Configuration │   │  TCP Server  │
│   Module     │   │   Module     │   │    Module    │
└──────────────┘   └──────────────┘   └──────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│    PACS      │   │   Remote     │   │   Command    │
│ Controller   │   │  Executor    │   │   Handler    │
└──────────────┘   └──────────────┘   └──────────────┘
```

### Component Overview

#### Modules (*.psm1)
1. **LoggingModule.psm1**
   - Centralized logging with color coding
   - Log file management
   - Functions: `Write-Log`, `Set-LogFile`, `Get-LogFile`

2. **ConfigurationModule.psm1**
   - JSON configuration loading/saving
   - Default config generation
   - Config validation
   - Functions: `Load-ServerConfig`, `Save-ServerConfig`, `Get-DefaultConfig`, `Test-ServerConfig`

3. **TCPServerModule.psm1**
   - TCP socket server
   - Client connection handling
   - Command routing
   - Functions: `Start-TCPServer`, `Stop-TCPServer`

#### Classes (*.ps1)
1. **PACSController.ps1**
   - PACS application lifecycle management
   - Process monitoring
   - Recording control

2. **RemoteExecutor.ps1**
   - PsExec command building
   - Remote command execution
   - RunTest.ps1 integration
   - Connection testing

3. **CommandHandler.ps1**
   - Command code routing (101-113)
   - Business logic implementation
   - Response formatting

### Data Flow

```
Client Request
     │
     ▼
NiDaqServer-Modular.ps1 (Entry)
     │
     ▼
TCPServerModule (Accept Connection)
     │
     ▼
CommandHandler (Route Command)
     │
     ├─► RemoteExecutor (Execute on DUT)
     │         │
     │         └─► PsExec ──► DUT ──► RunTest.ps1
     │
     └─► PACSController (Manage PACS)
           │
           └─► PACS Application
```

---

## Installation

### Prerequisites

#### On Server Machine (Control PC)
- ✅ Windows 10/11 or Windows Server 2016+
- ✅ PowerShell 5.1 or higher
- ✅ Network connectivity to all DUTs
- ✅ PsExec.exe from Sysinternals Suite
- ✅ Administrator privileges (for PsExec)
- ✅ PACS software (optional)

#### On DUT Machines (Test PCs)
- ✅ Windows 10/11 or Windows Server 2016+
- ✅ PowerShell 5.1 or higher
- ✅ RunTest.ps1 framework installed
- ✅ Test configurations (GLD-xxxx.bat files)
- ✅ Remote execution enabled

### Installation Steps

#### 1. Create Directory Structure
```powershell
# On Server Machine
cd C:\NiDaq_Server_PS
# Create subdirectories
New-Item -ItemType Directory -Path ".\Modules" -Force
New-Item -ItemType Directory -Path ".\Classes" -Force
New-Item -ItemType Directory -Path ".\Logs" -Force
```

#### 2. Copy Modular Files
```
C:\NiDaq_Server_PS\
├── NiDaqServer-Modular.ps1
├── NiDaqClient.ps1
├── ServerConfig.json
├── Modules\
│   ├── LoggingModule.psm1
│   ├── ConfigurationModule.psm1
│   └── TCPServerModule.psm1
└── Classes\
    ├── PACSController.ps1
    ├── RemoteExecutor.ps1
    └── CommandHandler.ps1
```

#### 3. Install PsExec
```powershell
# Download from: https://live.sysinternals.com/psexec.exe
# Place in system PATH
Copy-Item PsExec.exe C:\Windows\System32\

# Or place in same directory
Copy-Item PsExec.exe C:\NiDaq_Server_PS\
```

#### 4. Configure Firewall
```powershell
# Allow TCP port 55555 on Server
New-NetFirewallRule -DisplayName "NiDaq Server Modular" `
    -Direction Inbound `
    -LocalPort 55555 `
    -Protocol TCP `
    -Action Allow

# On DUT: Allow PsExec connections
New-NetFirewallRule -DisplayName "Remote Admin" `
    -Direction Inbound `
    -Program "C:\Windows\System32\psexesvc.exe" `
    -Action Allow
```

#### 5. Configure RunTest.ps1 on DUTs
```powershell
# On each DUT, ensure RunTest.ps1 exists
Test-Path "C:\GLD\New_Flow_5\RunTest.ps1"  # Should return True

# Ensure test configs exist
Test-Path "C:\GLD\GLD-1015.bat"  # Should return True
```

#### 6. Verify Module Loading
```powershell
# Test module imports
Import-Module .\Modules\LoggingModule.psm1 -Force
Import-Module .\Modules\ConfigurationModule.psm1 -Force
Import-Module .\Modules\TCPServerModule.psm1 -Force

# Check exported functions
Get-Command -Module LoggingModule
Get-Command -Module ConfigurationModule
Get-Command -Module TCPServerModule
```

---

## Configuration

### ServerConfig.json Structure

```json
{
  "Server": {
    "Host": "0.0.0.0",           // Bind address (0.0.0.0 = all interfaces)
    "Port": 55555,               // TCP port
    "MaxConnections": 10,        // Max simultaneous clients
    "ReceiveTimeout": 300,       // Socket timeout (seconds)
    "BufferSize": 4096,          // Buffer size (bytes) ⚠️ REQUIRED in modular
    "Comments": "BufferSize in bytes (4096 = 4KB)"
  },
  "Client": {
    "DefaultIP": "192.168.1.100",     // DUT IP address
    "Username": "Administrator",      // DUT login username
    "Password": "",                   // DUT password
    "WorkingPath": "C:\\KSR_Package\\KSR\\Test_Run_KR",  // Remote working dir
    "Comments": "Default DUT configuration"
  },
  "PACS": {
    "Enabled": true,                        // Enable/disable PACS
    "ExePath": "C:\\Intel\\PACS\\pacs.exe", // PACS executable
    "ConfigPath": "C:\\Test\\testconfig.csv",  // PACS config
    "ResultPath": "C:\\Test\\results",         // PACS results
    "DelayBeforeRecord": 10,                   // Delay before recording (seconds)
    "ProcessName": "pacs",                     // Process name for monitoring
    "Comments": "PACS power analysis integration"
  },
  "Paths": {
    "RunTestScript": "C:\\GLD\\New_Flow_5\\RunTest.ps1",  // Path on DUT
    "TestConfigFolder": "C:\\GLD",                        // Test configs
    "ResultsFolder": "C:\\Results",                       // Results folder
    "TempFolder": "C:\\Temp",                             // Temp folder
    "Comments": "Paths on DUT machine"
  },
  "Temperature": {
    "Enabled": true,                     // Enable temp control
    "ScriptPath": "C:\\Tools\\KSRTemp.py",  // Python script
    "PythonPath": "python",              // Python executable
    "Comments": "Temperature chamber control (optional)"
  },
  "Features": {
    "BackgroundServiceControl": true,  // Windows service control
    "RemoteExecution": true,           // PsExec support
    "FileTransfer": true,              // Socket file transfer
    "TemperatureControl": false,       // Chamber control
    "Comments": "Feature flags"
  },
  "Logging": {
    "LogLevel": "INFO",              // INFO, WARNING, ERROR, SUCCESS
    "LogPath": ".\\Logs",            // Log directory
    "MaxLogSizeMB": 100,             // Max log size
    "RetentionDays": 30,             // Log retention
    "Comments": "Logging configuration"
  }
}
```

### Key Differences from Standalone

| Setting | Standalone | Modular | Notes |
|---------|-----------|---------|-------|
| **BufferSize** | Hardcoded 1024 | Configurable 4096 | ⚠️ Must be in config |
| **ProcessName** | Hardcoded "pacs" | Configurable | Allows custom PACS |
| **PythonPath** | Hardcoded "python" | Configurable | Full path to Python |
| **LogPath** | Current dir | Configurable | Better organization |

### Configuration Examples

#### Minimal Configuration (Testing)
```json
{
  "Server": {
    "Host": "127.0.0.1",
    "Port": 55555,
    "BufferSize": 4096
  },
  "Client": {
    "DefaultIP": "192.168.1.100",
    "Username": "Administrator",
    "Password": "YourPassword",
    "WorkingPath": "C:\\GLD"
  },
  "PACS": {
    "Enabled": false
  }
}
```

#### Production Configuration
```json
{
  "Server": {
    "Host": "0.0.0.0",
    "Port": 55555,
    "MaxConnections": 50,
    "ReceiveTimeout": 600,
    "BufferSize": 8192
  },
  "Client": {
    "DefaultIP": "10.10.10.100",
    "Username": "TestAdmin",
    "Password": "SecurePassword123",
    "WorkingPath": "D:\\TestFramework"
  },
  "PACS": {
    "Enabled": true,
    "ExePath": "C:\\Intel\\PACS\\pacs.exe",
    "ResultPath": "D:\\PACS_Results",
    "ProcessName": "pacs"
  },
  "Logging": {
    "LogLevel": "INFO",
    "LogPath": "D:\\Logs\\NiDaqServer",
    "MaxLogSizeMB": 500,
    "RetentionDays": 90
  }
}
```

---

## File Paths & Structure

### Complete Directory Layout

#### Server Machine (Control PC)
```
C:\NiDaq_Server_PS\                     # Root installation directory
│
├── 📄 Main Entry Point
│   └── NiDaqServer-Modular.ps1         # Main server script (132 lines)
│
├── 📁 Modules\                         # PowerShell modules (.psm1)
│   ├── LoggingModule.psm1              # Logging functions (75 lines)
│   ├── ConfigurationModule.psm1        # Config management (140 lines)
│   └── TCPServerModule.psm1            # TCP server (138 lines)
│
├── 📁 Classes\                         # PowerShell classes (.ps1)
│   ├── PACSController.ps1              # PACS management (120 lines)
│   ├── RemoteExecutor.ps1              # PsExec wrapper (130 lines)
│   └── CommandHandler.ps1              # Command routing (312 lines)
│
├── 📁 Documentation\
│   ├── README-Modular.md               # This file
│   ├── MODULAR-SERVER-GUIDE.md         # Complete guide
│   ├── ARCHITECTURE.md                 # Architecture details
│   └── API-REFERENCE.md                # Module/class API
│
├── 📁 Scripts\                         # Helper scripts
│   ├── Start-Modular-Server.bat        # Quick launcher
│   ├── Test-Modules.ps1                # Module test script
│   └── Install-Dependencies.ps1        # Dependency installer
│
├── 📄 Configuration
│   ├── ServerConfig.json               # Main configuration
│   ├── ServerConfig-DUT1.json          # DUT-specific configs
│   ├── ServerConfig-DUT2.json
│   └── ServerConfig-Production.json
│
├── 📁 Logs\                            # Auto-created logs
│   ├── NiDaqServer_2026-01-28.log
│   └── ... (auto-rotated)
│
├── 📁 Tests\                           # Unit tests (optional)
│   ├── Test-LoggingModule.ps1
│   ├── Test-ConfigurationModule.ps1
│   └── Test-TCPServerModule.ps1
│
└── 📄 Client Tool
    └── NiDaqClient.ps1                 # Same client as standalone
```

#### DUT Machine (Test PC)
```
C:\GLD\                                 # Test framework directory
├── New_Flow_5\
│   └── RunTest.ps1                     # Test execution script
├── GLD-1008.bat                        # Test configuration files
├── GLD-1009.bat
├── GLD-1015.bat
└── ... (all test configs)

C:\KSR_Package\KSR\Test_Run_KR\         # Working directory

C:\Results\                             # Test results output
└── GLD-1015_2026-01-28_143022\
    ├── TestResults.log
    └── Summary.csv

C:\Test\results\                        # PACS results (if enabled)
└── GLD-1015_20260128_143022_summary.csv
```

### Module File Sizes

| File | Lines | Size | Purpose |
|------|-------|------|---------|
| NiDaqServer-Modular.ps1 | 132 | ~4 KB | Entry point |
| LoggingModule.psm1 | 75 | ~3 KB | Logging |
| ConfigurationModule.psm1 | 140 | ~5 KB | Config |
| TCPServerModule.psm1 | 138 | ~5 KB | TCP server |
| PACSController.ps1 | 120 | ~4 KB | PACS |
| RemoteExecutor.ps1 | 130 | ~5 KB | Remote exec |
| CommandHandler.ps1 | 312 | ~11 KB | Commands |
| **Total** | **1,047** | **~37 KB** | All modules |

### Required Paths on DUT

| Path | Purpose | Must Exist? |
|------|---------|-------------|
| `C:\GLD\New_Flow_5\RunTest.ps1` | Test runner | ✅ Required |
| `C:\GLD\GLD-*.bat` | Test configs | ✅ Required |
| `C:\KSR_Package\KSR\Test_Run_KR` | Working path | ✅ Required |
| `C:\Results` | Test output | Auto-created |
| `C:\Test\results` | PACS output | ✅ If PACS enabled |

---

## Running the Server

### Method 1: Direct PowerShell Execution
```powershell
# Navigate to server directory
cd C:\NiDaq_Server_PS

# Run with default config
.\NiDaqServer-Modular.ps1

# Run with custom config
.\NiDaqServer-Modular.ps1 -ConfigFile ".\ServerConfig-DUT1.json"

# Override port
.\NiDaqServer-Modular.ps1 -Port 5000

# Override host (bind to specific IP)
.\NiDaqServer-Modular.ps1 -ServerHost "192.168.1.50"

# Combine parameters
.\NiDaqServer-Modular.ps1 -ConfigFile ".\ServerConfig-Production.json" -Port 55560
```

### Method 2: Create Start-Modular-Server.bat
```batch
@echo off
echo Starting NiDaq Modular Server...
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0NiDaqServer-Modular.ps1"
pause
```

### Method 3: Run as Administrator (Recommended)
```powershell
# Right-click PowerShell → Run as Administrator
cd C:\NiDaq_Server_PS
.\NiDaqServer-Modular.ps1
```

### Server Startup Output
```
Loading NiDaq Server modules...
  [OK] LoggingModule loaded
  [OK] ConfigurationModule loaded
  [OK] TCPServerModule loaded
  [OK] PACSController class loaded
  [OK] RemoteExecutor class loaded
  [OK] CommandHandler class loaded

2026-01-28 14:30:15 [INFO] NiDaq Server v2.0 - Modular Edition
2026-01-28 14:30:15 [INFO] Starting server initialization...
2026-01-28 14:30:15 [INFO] Loading configuration from .\ServerConfig.json
2026-01-28 14:30:15 [SUCCESS] Configuration loaded successfully from .\ServerConfig.json
2026-01-28 14:30:15 [SUCCESS] Configuration validated successfully
2026-01-28 14:30:15 [INFO] Log file: C:\NiDaq_Server_PS\Logs\NiDaqServer_2026-01-28.log
2026-01-28 14:30:15 [INFO] Initializing command handler...
2026-01-28 14:30:15 [INFO] PACS Controller initialized
2026-01-28 14:30:15 [INFO] Remote Executor initialized for 192.168.1.100
2026-01-28 14:30:15 [SUCCESS] Command handler initialized successfully
2026-01-28 14:30:15 [INFO] Starting TCP server...
2026-01-28 14:30:15 [INFO] ========================================
2026-01-28 14:30:15 [INFO] NiDaq Server v2.0 - PowerShell Edition
2026-01-28 14:30:15 [INFO] ========================================
2026-01-28 14:30:15 [INFO] Server Host: 0.0.0.0
2026-01-28 14:30:15 [INFO] Server Port: 55555
2026-01-28 14:30:15 [INFO] Client IP: 192.168.1.100
2026-01-28 14:30:15 [INFO] PACS Enabled: True
2026-01-28 14:30:15 [INFO] ========================================
2026-01-28 14:30:15 [SUCCESS] Server listening on 0.0.0.0:55555
2026-01-28 14:30:15 [INFO] Press Ctrl+C to stop the server
```

### Stopping the Server
- Press `Ctrl+C` to gracefully stop
- Or close the PowerShell window
- Shutdown message will appear in logs

---

## Using the Client

### NiDaqClient.ps1 Usage

The client tool is **identical** for both standalone and modular versions.

#### Basic Syntax
```powershell
.\NiDaqClient.ps1 -ServerIP <IP> -ServerPort <Port> -Command <Code> [-Payload <Data>]
```

#### Examples

**1. Check Server Status**
```powershell
.\NiDaqClient.ps1 -Command 101
# Response: SERVER_ONLINE|PACS:RUNNING|CLIENT:CONNECTED|VERSION:2.0
```

**2. Execute Test (Simple)**
```powershell
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015"
# Response: TEST_SCHEDULED|TestID:GLD-1015|Status:Running
```

**3. Execute Test (With Parameters)**
```powershell
# Format: TestID|WaitTime|Iterations|SoCWatch
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015|60|1|false"
# Runs GLD-1015 with 60s wait, 1 iteration, no SoCWatch
```

**4. Connect to Remote Server**
```powershell
.\NiDaqClient.ps1 -ServerIP 192.168.1.50 -ServerPort 55555 -Command 101
```

---

## Module Reference

### LoggingModule.psm1

#### Exported Functions

**Write-Log**
```powershell
Write-Log -Message "Server started" -Level "INFO"
Write-Log -Message "Warning message" -Level "WARNING"
Write-Log -Message "Error occurred" -Level "ERROR"
Write-Log -Message "Operation successful" -Level "SUCCESS"
```

**Set-LogFile**
```powershell
Set-LogFile -Path "C:\Logs\MyLog.log"
```

**Get-LogFile**
```powershell
$logPath = Get-LogFile
Write-Host "Current log: $logPath"
```

#### Features
- Color-coded console output (Cyan, Yellow, Red, Green)
- Timestamped entries
- File and console output
- Auto-creates log directory
- Thread-safe logging

---

### ConfigurationModule.psm1

#### Exported Functions

**Load-ServerConfig**
```powershell
$config = Load-ServerConfig -ConfigPath ".\ServerConfig.json"
```

**Save-ServerConfig**
```powershell
Save-ServerConfig -Config $config -ConfigPath ".\ServerConfig.json"
```

**Get-DefaultConfig**
```powershell
$defaultConfig = Get-DefaultConfig
```

**Test-ServerConfig**
```powershell
if (Test-ServerConfig -Config $config) {
    Write-Host "Config is valid"
}
```

#### Features
- JSON parsing with error handling
- Default config generation
- Config validation
- Type checking
- Missing property detection

---

### TCPServerModule.psm1

#### Exported Functions

**Start-TCPServer**
```powershell
Start-TCPServer -Config $config -Handler $commandHandler
```

**Stop-TCPServer**
```powershell
Stop-TCPServer
```

#### Features
- Non-blocking client acceptance
- Configurable buffer size (from config)
- Timeout handling
- Connection logging
- Error isolation per client
- Graceful shutdown

---

### PACSController Class

#### Constructor
```powershell
$pacs = [PACSController]::new($config.PACS)
```

#### Methods

**IsRunning()**
```powershell
if ($pacs.IsRunning()) {
    Write-Host "PACS is running"
}
```

**GetStatus()**
```powershell
$status = $pacs.GetStatus()  # Returns "RUNNING" or "STOPPED"
```

**GetDetailedStatus()**
```powershell
$details = $pacs.GetDetailedStatus()
# Returns hashtable: Status, Running, PID, CPU, Memory
```

**Start()**
```powershell
$pacs.Start()  # Starts PACS application
```

**Stop()**
```powershell
$pacs.Stop()  # Stops PACS application
```

**Restart()**
```powershell
$pacs.Restart()  # Restarts PACS
```

**Record([int]$duration, [string]$testId)**
```powershell
$pacs.Record(300, "GLD-1015")  # Records for 300 seconds
```

---

### RemoteExecutor Class

#### Constructor
```powershell
$remote = [RemoteExecutor]::new($config.Client)
```

#### Methods

**BuildPsExecCommand([string]$command, [bool]$detached)**
```powershell
$psexecCmd = $remote.BuildPsExecCommand("dir C:\", $false)
```

**Execute([string]$command, [bool]$detached, [int]$timeout)**
```powershell
$result = $remote.Execute("systeminfo", $false, 30)
if ($result.Success) {
    Write-Host $result.Output
}
```

**RunTest([string]$testId, [hashtable]$parameters)**
```powershell
$params = @{ WaitTime = 60; Iterations = 1; SoCWatch = $false }
$result = $remote.RunTest("GLD-1015", $params)
```

**TestConnection()**
```powershell
if ($remote.TestConnection()) {
    Write-Host "DUT is reachable"
}
```

**VerifyRemotePath([string]$path)**
```powershell
if ($remote.VerifyRemotePath("C:\GLD\RunTest.ps1")) {
    Write-Host "Path exists on DUT"
}
```

---

### CommandHandler Class

#### Constructor
```powershell
$handler = [CommandHandler]::new($config)
```

#### Methods

**HandleCommand([string]$command, [string]$payload, [NetworkStream]$stream)**
```powershell
$response = $handler.HandleCommand("101", "", $stream)
```

**Individual Handlers**
- `Handle_101()` - Server status
- `Handle_102($payload)` - Execute test
- `Handle_103()` - Start PACS
- `Handle_104()` - PACS status
- `Handle_105($payload)` - Start recording
- `Handle_106()` - Stop PACS
- `Handle_107($stream, $payload)` - Transfer results
- `Handle_108($payload)` - Mark complete
- `Handle_109($payload)` - Set temperature
- `Handle_110()` - Get temperature
- `Handle_111($payload)` - Copy results
- `Handle_112($payload)` - Custom command
- `Handle_113()` - Network transfer

---

## Command Reference

### Command Codes (Same as Standalone)

| Code | Command | Payload Format | Description |
|------|---------|----------------|-------------|
| 101 | Server Status | (none) | Check if server is online |
| 102 | Execute Test | `TestID\|WaitTime\|Iterations\|SoCWatch` | Run test via RunTest.ps1 |
| 103 | Start PACS | (none) | Start PACS application |
| 104 | PACS Status | (none) | Check PACS status (enhanced in modular) |
| 105 | Start Recording | `Duration\|TestID` | Start PACS recording |
| 106 | Stop PACS | (none) | Stop PACS application |
| 107 | Transfer Results | (none) | Download files via socket |
| 108 | Mark Complete | `TestID` | Mark test as complete |
| 109 | Set Temperature | `Temperature` | Set chamber temp (°C) |
| 110 | Get Temperature | (none) | Read current temperature |
| 111 | Copy Results | (none) | Copy via network share |
| 112 | Custom Command | `Command` | Execute arbitrary command |
| 113 | Network Transfer | (none) | Transfer via network share |

### Enhanced Responses (Modular)

**Command 101 - Enhanced Status**
```
SERVER_ONLINE|PACS:RUNNING|CLIENT:CONNECTED|VERSION:2.0
```
Now includes CLIENT connection status (new in modular).

**Command 104 - Detailed PACS Status**
```
PACS_STATUS|Status:RUNNING|PID:12345|Memory:256MB
```
Now includes process details (new in modular).

---

## Troubleshooting

### Module Loading Errors

**Error: "Cannot find path to module"**
```powershell
# Solution: Ensure modules directory exists
Test-Path ".\Modules\LoggingModule.psm1"

# Check current directory
Get-Location

# Use absolute paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$scriptDir\Modules\LoggingModule.psm1" -Force
```

**Error: "Start-TCPServer command not found"**
```powershell
# Solution: Verify module exports
Get-Command -Module TCPServerModule

# Manually check exports
Get-Content .\Modules\TCPServerModule.psm1 | Select-String "Export-ModuleMember"

# Re-import with Force
Import-Module .\Modules\TCPServerModule.psm1 -Force -Verbose
```

### Configuration Errors

**Error: "BufferSize property not found"**
```powershell
# Solution: Add BufferSize to ServerConfig.json
{
  "Server": {
    "BufferSize": 4096  // ADD THIS LINE
  }
}

# Or regenerate config
$config = Get-DefaultConfig
$config | ConvertTo-Json -Depth 10 | Out-File ServerConfig.json
```

**Error: "Configuration validation failed"**
```powershell
# Solution: Test config manually
$config = Load-ServerConfig -ConfigPath ".\ServerConfig.json"
Test-ServerConfig -Config $config

# Check for missing required properties
$config.Server.BufferSize  # Should not be null
$config.Client.DefaultIP   # Should not be null
```

### Server Startup Errors

**Error: "Cannot bind to address"**
```powershell
# Solution: Check if port is in use
netstat -an | Select-String "55555"

# Find process using port
Get-NetTCPConnection -LocalPort 55555 -ErrorAction SilentlyContinue

# Kill process or use different port
.\NiDaqServer-Modular.ps1 -Port 55556
```

**Error: "PACSController initialization failed"**
```powershell
# Solution: Verify PACS config
Test-Path $config.PACS.ExePath

# Or disable PACS
# In ServerConfig.json:
{
  "PACS": {
    "Enabled": false
  }
}
```

### Runtime Errors

**Error: "Byte array constructor failed"**
```powershell
# Solution: Verify BufferSize in config
Get-Content .\ServerConfig.json | ConvertFrom-Json | Select -ExpandProperty Server

# Ensure BufferSize is a number, not null
# Should show: BufferSize : 4096
```

**Error: "RemoteExecutor failed to initialize"**
```powershell
# Solution: Check Client config
$config.Client.DefaultIP   # Should not be empty
$config.Client.Username    # Should not be empty
$config.Client.WorkingPath # Should not be empty

# Test DUT connectivity
Test-Connection -ComputerName $config.Client.DefaultIP -Count 1
```

### Debug Mode

**Enable Verbose Logging**
```powershell
# Run with verbose output
.\NiDaqServer-Modular.ps1 -Verbose

# Or modify LoggingModule to show DEBUG messages
# In LoggingModule.psm1, add DEBUG level
```

**Check Module Versions**
```powershell
# List all loaded modules
Get-Module

# Check specific module
Get-Module LoggingModule | Format-List

# Force reload all modules
Get-Module | Where-Object { $_.Name -like "*Module" } | Remove-Module -Force
```

---

## Network Configuration

### IP Address Planning (Same as Standalone)

#### Scenario 1: Single Server, Single DUT
```
Server (Control PC):  192.168.1.50
DUT (Test PC):        192.168.1.100
Client (Your PC):     192.168.1.10

ServerConfig.json:
  "Server": { "Host": "0.0.0.0", "Port": 55555 }
  "Client": { "DefaultIP": "192.168.1.100" }

Usage:
  .\NiDaqClient.ps1 -ServerIP 192.168.1.50 -Command 102 -Payload "GLD-1015"
```

#### Scenario 2: Multiple Servers for Multiple DUTs
```
Server1 (Port 55551): Controls DUT1 (192.168.1.100)
Server2 (Port 55552): Controls DUT2 (192.168.1.101)
Server3 (Port 55553): Controls DUT3 (192.168.1.102)

# Start multiple server instances
Start-Process powershell -ArgumentList "-File NiDaqServer-Modular.ps1 -Port 55551 -ConfigFile ServerConfig-DUT1.json"
Start-Process powershell -ArgumentList "-File NiDaqServer-Modular.ps1 -Port 55552 -ConfigFile ServerConfig-DUT2.json"
Start-Process powershell -ArgumentList "-File NiDaqServer-Modular.ps1 -Port 55553 -ConfigFile ServerConfig-DUT3.json"
```

### Port Requirements

| Port | Service | Purpose |
|------|---------|---------|
| 55555 | NiDaq Server (default) | TCP command/control |
| 55551-55559 | Additional servers | Multiple DUT control |
| 135 | RPC | PsExec requirement |
| 445 | SMB | PsExec file access |

---

## Development Guide

### Adding a New Module

1. **Create Module File**
```powershell
# Create new module: Modules\MyNewModule.psm1
function My-NewFunction {
    param([string]$Parameter)
    Write-Log "My new function called" -Level "INFO"
    return "Result"
}

Export-ModuleMember -Function My-NewFunction
```

2. **Import in Main Script**
```powershell
# In NiDaqServer-Modular.ps1
Import-Module "$ScriptDir\Modules\MyNewModule.psm1" -Force -ErrorAction Stop
Write-Host "  [OK] MyNewModule loaded" -ForegroundColor Green
```

3. **Use in Code**
```powershell
$result = My-NewFunction -Parameter "test"
```

### Adding a New Command

1. **Add Handler Method to CommandHandler.ps1**
```powershell
# In CommandHandler.ps1
[string] Handle_114([string]$payload) {
    Write-Log "Command 114: My New Command" -Level "INFO"
    # Your logic here
    return "COMMAND_114_SUCCESS|Result:$payload"
}
```

2. **Route Command**
```powershell
# In HandleCommand method, add case:
"114" { $this.Handle_114($payload) }
```

3. **Update Documentation**
- Add to command reference
- Add example usage
- Update client documentation

### Unit Testing

**Create Test File: Tests\Test-LoggingModule.ps1**
```powershell
# Import module
Import-Module ..\Modules\LoggingModule.psm1 -Force

# Test 1: Write-Log function exists
if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
    Write-Host "[PASS] Write-Log function exists" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Write-Log function not found" -ForegroundColor Red
}

# Test 2: Log file creation
Set-LogFile -Path ".\TestLog.log"
Write-Log -Message "Test message" -Level "INFO"
if (Test-Path ".\TestLog.log") {
    Write-Host "[PASS] Log file created" -ForegroundColor Green
    Remove-Item ".\TestLog.log"
} else {
    Write-Host "[FAIL] Log file not created" -ForegroundColor Red
}

# Test 3: Get-LogFile
$logPath = Get-LogFile
if ($logPath) {
    Write-Host "[PASS] Get-LogFile returns path" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Get-LogFile returns null" -ForegroundColor Red
}
```

### Best Practices

#### Module Development
✅ Keep modules focused (single responsibility)  
✅ Export only necessary functions  
✅ Use `Write-Log` for all logging  
✅ Handle errors gracefully  
✅ Document all public functions  
✅ Use type hints for parameters  

#### Class Development
✅ Initialize all properties in constructor  
✅ Validate input parameters  
✅ Return consistent types  
✅ Use hashtables for complex returns  
✅ Log important operations  
✅ Handle null/empty values  

#### Configuration
✅ Always validate config before use  
✅ Provide default values  
✅ Document all config properties  
✅ Use comments in JSON  
✅ Version your configs  
✅ Backup before changes  

---

## Workflow Examples

### Example 1: Run Single Test with PACS
```powershell
# 1. Start server
cd C:\NiDaq_Server_PS
.\NiDaqServer-Modular.ps1

# 2. Check status
.\NiDaqClient.ps1 -Command 101
# Expected: SERVER_ONLINE|PACS:STOPPED|CLIENT:CONNECTED|VERSION:2.0

# 3. Start PACS
.\NiDaqClient.ps1 -Command 103
# Expected: PACS_STARTED|Status:RUNNING

# 4. Execute test
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015|60|1|false"
# Expected: TEST_SCHEDULED|TestID:GLD-1015|Status:Running

# 5. Start PACS recording (300 seconds)
.\NiDaqClient.ps1 -Command 105 -Payload "300|GLD-1015"
# Expected: PACS_RECORDING_STARTED|Duration:300|TestID:GLD-1015

# Wait for test to complete...

# 6. Check PACS status (enhanced in modular)
.\NiDaqClient.ps1 -Command 104
# Expected: PACS_STATUS|Status:RUNNING|PID:12345|Memory:256MB

# 7. Stop PACS
.\NiDaqClient.ps1 -Command 106
# Expected: PACS_STOPPED
```

### Example 2: Batch Testing Script
```powershell
# Create: RunBatchTests.ps1
param(
    [string]$ServerIP = "127.0.0.1",
    [string[]]$Tests = @("GLD-1008", "GLD-1009", "GLD-1015", "GLD-1016")
)

foreach ($test in $Tests) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Running test: $test" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Execute test
    $result = .\NiDaqClient.ps1 -ServerIP $ServerIP -Command 102 -Payload "$test|60|1|false"
    Write-Host $result -ForegroundColor Green
    
    # Wait for test completion (adjust time as needed)
    Start-Sleep -Seconds 120
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Batch testing complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
```

---

## Performance Tuning

### Buffer Size Optimization

| Buffer Size | Use Case | Performance |
|-------------|----------|-------------|
| 1024 bytes | Small commands only | ⚡ Fastest startup |
| 4096 bytes | **Default, recommended** | ⚡⚡ Balanced |
| 8192 bytes | Large payloads | ⚡⚡ Good for bulk |
| 16384 bytes | File transfers | ⚡ Higher memory |
| 32768 bytes | Maximum data | ⚠️ Memory intensive |

**Configure in ServerConfig.json:**
```json
{
  "Server": {
    "BufferSize": 8192  // Adjust based on needs
  }
}
```

### Connection Pooling

For high-traffic scenarios:
```json
{
  "Server": {
    "MaxConnections": 50,      // Increase for more clients
    "ReceiveTimeout": 600      // Longer timeout for slow operations
  }
}
```

### Logging Performance

```json
{
  "Logging": {
    "LogLevel": "WARNING",     // Reduce logging in production
    "MaxLogSizeMB": 500,       // Larger log files
    "RetentionDays": 30        // Automatic cleanup
  }
}
```

---

## Comparison: Standalone vs Modular

| Feature | Standalone | Modular |
|---------|-----------|---------|
| **Files** | 1 file (671 lines) | 7 files (1047 lines) |
| **Buffer Size** | Hardcoded 1024 | Configurable 4096 |
| **Architecture** | Monolithic | Separated concerns |
| **Maintainability** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Testability** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Deployment** | ⭐⭐⭐⭐⭐ Easy | ⭐⭐⭐ More files |
| **Extensibility** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Team Development** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Code Reuse** | ⭐ | ⭐⭐⭐⭐⭐ |
| **Error Isolation** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Performance** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

### When to Use Modular

✅ Enterprise environments  
✅ Team development  
✅ Need customization  
✅ Long-term maintenance  
✅ Multiple developers  
✅ CI/CD pipelines  
✅ Unit testing required  
✅ Complex requirements  

### When to Use Standalone

✅ Quick deployment  
✅ Single developer  
✅ Simple requirements  
✅ One-time use  
✅ Proof of concept  
✅ Minimal maintenance  
✅ Copy-paste deployment  

---

## Version Information

- **Version**: 2.0 (Modular Edition)
- **Architecture**: Modular (3 modules + 3 classes)
- **Total Lines**: 1,047 lines across 7 files
- **PowerShell**: Requires 5.1+
- **Last Updated**: January 2026

---

## Support & Resources

### Documentation Files
- `README-Modular.md` - Quick start (this file)
- `MODULAR-SERVER-GUIDE.md` - Complete guide
- `ARCHITECTURE.md` - Architecture details
- `API-REFERENCE.md` - Module/class API

### Useful Commands
```powershell
# List loaded modules
Get-Module

# View module functions
Get-Command -Module LoggingModule

# Check configuration
Get-Content .\ServerConfig.json | ConvertFrom-Json | Format-List

# View logs
Get-Content .\Logs\NiDaqServer_*.log -Wait

# Test modules
.\Tests\Test-AllModules.ps1
```

---

*For standalone version documentation, see `STANDALONE-SERVER-GUIDE.md`*
