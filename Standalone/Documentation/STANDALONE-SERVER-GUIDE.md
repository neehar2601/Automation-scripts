# NiDaq Server - Standalone Version Guide

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [File Paths & Structure](#file-paths--structure)
- [Running the Server](#running-the-server)
- [Using the Client](#using-the-client)
- [Command Reference](#command-reference)
- [Troubleshooting](#troubleshooting)
- [Network Configuration](#network-configuration)

---

## Overview

The **Standalone NiDaq Server** is a single-file PowerShell TCP server for remote test orchestration. It integrates with your existing RunTest.ps1 framework and provides centralized control over multiple test systems (DUTs - Devices Under Test).

### Key Features
- ✅ Single file deployment (671 lines, no dependencies)
- ✅ TCP server for remote command execution
- ✅ Integration with RunTest.ps1 test framework
- ✅ PACS (Power Analysis Control System) support
- ✅ Remote execution via PsExec
- ✅ Temperature control (optional)
- ✅ File transfer capabilities
- ✅ JSON-based configuration

### Use Cases
- Remote test execution on multiple DUTs
- Centralized test orchestration
- Power analysis integration (PACS)
- Automated test workflows
- Temperature chamber control

---

## Architecture

### How It Works

```
┌─────────────┐           ┌──────────────────┐           ┌─────────────┐
│   Client    │  TCP/IP   │  NiDaq Server    │  PsExec   │   DUT       │
│  (Control   │ ◄────────►│  (Control PC)    │ ────────► │  (Test PC)  │
│   Machine)  │  Port     │                  │  Network  │             │
└─────────────┘  55555    └──────────────────┘           └─────────────┘
                                    │
                                    │ Monitors/Controls
                                    ▼
                           ┌─────────────────┐
                           │  PACS System    │
                           │  (Power Meter)  │
                           └─────────────────┘
```

### Components
1. **NiDaq Server** - Listens for TCP connections, processes commands
2. **NiDaq Client** - Sends commands to server
3. **RunTest.ps1** - Existing test framework (runs on DUT)
4. **PsExec** - Remote execution tool (Sysinternals)
5. **PACS** - Optional power analysis system
6. **ServerConfig.json** - Configuration file

### Execution Flow
1. Client sends command to Server (e.g., "102|GLD-1015")
2. Server parses command and payload
3. Server builds PsExec command to run on DUT
4. PsExec executes RunTest.ps1 on remote DUT
5. Server returns acknowledgment to Client
6. Test runs on DUT, results stored locally

---

## Installation

### Prerequisites

#### On Server Machine (Control PC)
- ✅ Windows 10/11 or Windows Server 2016+
- ✅ PowerShell 5.1 or higher
- ✅ Network connectivity to all DUTs
- ✅ PsExec.exe from Sysinternals Suite
- ✅ Administrator privileges (for PsExec)
- ✅ PACS software (optional, if using power analysis)

#### On DUT Machines (Test PCs)
- ✅ Windows 10/11 or Windows Server 2016+
- ✅ PowerShell 5.1 or higher
- ✅ RunTest.ps1 framework installed
- ✅ Test configurations (GLD-xxxx.bat files)
- ✅ Remote execution enabled (allow PsExec connections)
- ✅ Administrator account accessible

### Installation Steps

#### 1. Download Required Files
```powershell
# On Server Machine
cd C:\NiDaq_Server
# Copy these files:
# - NiDaqServer.ps1
# - NiDaqClient.ps1
# - ServerConfig.json
```

#### 2. Install PsExec
```powershell
# Download from: https://live.sysinternals.com/psexec.exe
# Or install Sysinternals Suite

# Place PsExec in system PATH or same directory
Copy-Item PsExec.exe C:\Windows\System32\
# OR
Copy-Item PsExec.exe C:\NiDaq_Server\
```

#### 3. Configure Firewall
```powershell
# Allow TCP port 55555 on Server
New-NetFirewallRule -DisplayName "NiDaq Server" `
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

#### 4. Configure RunTest.ps1 on DUTs
```powershell
# On each DUT, ensure RunTest.ps1 is at expected location
Test-Path "C:\GLD\New_Flow_5\RunTest.ps1"  # Should return True

# Ensure test configs exist
Test-Path "C:\GLD\GLD-1015.bat"  # Should return True
```

---

## Configuration

### ServerConfig.json Structure

```json
{
  "Server": {
    "Host": "0.0.0.0",           // 0.0.0.0 = all interfaces, or specific IP
    "Port": 55555,               // TCP port for server
    "MaxConnections": 10,        // Max simultaneous clients
    "ReceiveTimeout": 300        // Timeout in seconds
  },
  "Client": {
    "DefaultIP": "192.168.1.100",     // DUT IP address
    "Username": "Administrator",      // DUT login username
    "Password": "",                   // DUT password (or blank for current)
    "WorkingPath": "C:\\KSR_Package\\KSR\\Test_Run_KR"  // Remote working directory
  },
  "PACS": {
    "Enabled": true,                        // Enable/disable PACS
    "ExePath": "C:\\Intel\\PACS\\pacs.exe", // Path to PACS executable
    "ConfigPath": "C:\\Test\\testconfig.csv",  // PACS config
    "ResultPath": "C:\\Test\\results",         // PACS results folder
    "DelayBeforeRecord": 10                    // Delay in seconds
  },
  "Paths": {
    "RunTestScript": "C:\\GLD\\New_Flow_5\\RunTest.ps1",  // Path on DUT
    "TestConfigFolder": "C:\\GLD",                        // Test configs
    "ResultsFolder": "C:\\Results",                       // Results folder
    "TempFolder": "C:\\Temp"                              // Temp folder
  },
  "Temperature": {
    "Enabled": false,                    // Enable temp control
    "ScriptPath": "C:\\Tools\\KSRTemp.py"  // Python script path
  },
  "Features": {
    "BackgroundServiceControl": true,  // Windows service control
    "RemoteExecution": true,           // PsExec support
    "FileTransfer": true,              // Socket file transfer
    "TemperatureControl": false        // Chamber control
  }
}
```

### Configuration Examples

#### Single DUT Setup
```json
{
  "Client": {
    "DefaultIP": "192.168.1.100",
    "Username": "Administrator",
    "Password": "YourPassword",
    "WorkingPath": "C:\\GLD"
  }
}
```

#### Multiple DUTs (Switch in code or use different configs)
```json
// For DUT1: ServerConfig-DUT1.json
{ "Client": { "DefaultIP": "192.168.1.100" } }

// For DUT2: ServerConfig-DUT2.json
{ "Client": { "DefaultIP": "192.168.1.101" } }

// Run with: .\NiDaqServer.ps1 -ConfigFile ".\ServerConfig-DUT1.json"
```

#### PACS Disabled
```json
{
  "PACS": {
    "Enabled": false
  }
}
```

---

## File Paths & Structure

### Recommended Directory Layout

#### Server Machine (Control PC)
```
C:\NiDaq_Server\                    # Server installation directory
├── NiDaqServer.ps1                 # Main server script (671 lines)
├── NiDaqClient.ps1                 # Client tool for sending commands
├── ServerConfig.json               # Configuration file
├── ServerConfig-DUT1.json          # Optional: DUT-specific configs
├── ServerConfig-DUT2.json
├── Start-Server.bat                # Batch file to start server
├── PsExec.exe                      # Optional: Local copy
├── Logs\                           # Auto-created log directory
│   └── NiDaqServer_2026-01-28.log
└── Results\                        # Downloaded results (optional)
    └── PACS_results_summary.csv
```

#### DUT Machine (Test PC)
```
C:\GLD\                             # Test framework directory
├── New_Flow_5\
│   └── RunTest.ps1                 # Test execution script
├── GLD-1008.bat                    # Test configuration files
├── GLD-1009.bat
├── GLD-1015.bat
└── ... (all test configs)

C:\KSR_Package\KSR\Test_Run_KR\     # Working directory (referenced in config)

C:\Results\                         # Test results output
└── GLD-1015_2026-01-28_143022\
    ├── TestResults.log
    └── Summary.csv

C:\Test\results\                    # PACS results (if enabled)
└── GLD-1015_20260128_143022_summary.csv
```

### Required Paths on DUT

| Path | Purpose | Must Exist? |
|------|---------|-------------|
| `C:\GLD\New_Flow_5\RunTest.ps1` | Test runner | ✅ Required |
| `C:\GLD\GLD-*.bat` | Test configs | ✅ Required |
| `C:\KSR_Package\KSR\Test_Run_KR` | Working path | ✅ Required |
| `C:\Results` | Test output | Auto-created |
| `C:\Test\results` | PACS output | ✅ If PACS enabled |

### Network Requirements

| Connection | Protocol | Port | Purpose |
|------------|----------|------|---------|
| Client → Server | TCP | 55555 | Command/control |
| Server → DUT | SMB/RPC | 135, 445 | PsExec connection |
| Server → DUT | Ping | ICMP | Connectivity test |

---

## Running the Server

### Method 1: Direct PowerShell Execution
```powershell
# Navigate to server directory
cd C:\NiDaq_Server

# Run with default config
.\NiDaqServer.ps1

# Run with custom config
.\NiDaqServer.ps1 -ConfigFile ".\ServerConfig-DUT1.json"

# Override port
.\NiDaqServer.ps1 -Port 5000

# Override host (bind to specific IP)
.\NiDaqServer.ps1 -ServerHost "192.168.1.50"
```

### Method 2: Create Start-Server.bat
```batch
@echo off
echo Starting NiDaq Server...
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0NiDaqServer.ps1"
pause
```

### Method 3: Run as Administrator (Recommended for PsExec)
```powershell
# Right-click PowerShell → Run as Administrator
cd C:\NiDaq_Server
.\NiDaqServer.ps1
```

### Server Output
```
2026-01-28 14:30:15 [INFO] ========================================
2026-01-28 14:30:15 [INFO] NiDaq Server v2.0 - PowerShell Edition
2026-01-28 14:30:15 [INFO] ========================================
2026-01-28 14:30:15 [SUCCESS] Configuration loaded successfully from .\ServerConfig.json
2026-01-28 14:30:15 [SUCCESS] Server listening on 0.0.0.0:55555
2026-01-28 14:30:15 [INFO] Press Ctrl+C to stop
```

### Stopping the Server
- Press `Ctrl+C` to gracefully stop
- Or close the PowerShell window

---

## Using the Client

### NiDaqClient.ps1 Usage

#### Basic Syntax
```powershell
.\NiDaqClient.ps1 -ServerIP <IP> -ServerPort <Port> -Command <Code> [-Payload <Data>]
```

#### Examples

**1. Check Server Status**
```powershell
.\NiDaqClient.ps1 -Command 101
# Response: SERVER_ONLINE|PACS:RUNNING|VERSION:2.0
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

**4. Start PACS**
```powershell
.\NiDaqClient.ps1 -Command 103
# Response: PACS_STARTED|Status:RUNNING
```

**5. Start PACS Recording**
```powershell
# Format: Duration|TestID
.\NiDaqClient.ps1 -Command 105 -Payload "300|GLD-1015"
# Records for 300 seconds
```

**6. Check PACS Status**
```powershell
.\NiDaqClient.ps1 -Command 104
# Response: PACS_STATUS|Status:RUNNING
```

**7. Stop PACS**
```powershell
.\NiDaqClient.ps1 -Command 106
# Response: PACS_STOPPED
```

**8. Custom Remote Command**
```powershell
.\NiDaqClient.ps1 -Command 112 -Payload "dir C:\Results"
# Executes command on DUT via PsExec
```

**9. Connect to Remote Server**
```powershell
.\NiDaqClient.ps1 -ServerIP 192.168.1.50 -ServerPort 55555 -Command 101
```

---

## Command Reference

### Command Codes

| Code | Command | Payload Format | Description |
|------|---------|----------------|-------------|
| 101 | Server Status | (none) | Check if server is online |
| 102 | Execute Test | `TestID\|WaitTime\|Iterations\|SoCWatch` | Run test via RunTest.ps1 |
| 103 | Start PACS | (none) | Start PACS application |
| 104 | PACS Status | (none) | Check PACS status |
| 105 | Start Recording | `Duration\|TestID` | Start PACS recording |
| 106 | Stop PACS | (none) | Stop PACS application |
| 107 | Transfer Results | (none) | Download files via socket |
| 108 | Mark Complete | `TestID` | Mark test as complete |
| 109 | Set Temperature | `Temperature` | Set chamber temp (°C) |
| 110 | Get Temperature | (none) | Read current temperature |
| 111 | Copy Results | (none) | Copy via network share |
| 112 | Custom Command | `Command` | Execute arbitrary command |
| 113 | Network Transfer | (none) | Transfer via network share |

### Response Formats

| Response | Meaning |
|----------|---------|
| `SERVER_ONLINE\|...` | Server operational |
| `TEST_SCHEDULED\|...` | Test started successfully |
| `TEST_FAILED\|Error:...` | Test failed to start |
| `PACS_STARTED` | PACS running |
| `PACS_STOPPED` | PACS stopped |
| `PACS_DISABLED` | PACS not enabled in config |
| `ERROR\|...` | General error |

---

## Troubleshooting

### Common Issues

#### 1. "Connection Refused" or "Cannot Connect"

**Symptoms:**
```
Cannot connect to server: Connection refused
```

**Solutions:**
```powershell
# Check if server is running
Get-Process -Name powershell | Where-Object { $_.MainWindowTitle -like "*NiDaq*" }

# Check if port is listening
netstat -an | Select-String "55555"

# Verify firewall
Get-NetFirewallRule -DisplayName "NiDaq Server"

# Test connectivity
Test-NetConnection -ComputerName <ServerIP> -Port 55555
```

#### 2. "PsExec Access Denied"

**Symptoms:**
```
Remote execution failed: Access is denied
```

**Solutions:**
```powershell
# Run server as Administrator
# Verify credentials in ServerConfig.json
# Enable remote administration on DUT:

# On DUT:
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
```

#### 3. "RunTest.ps1 Not Found"

**Symptoms:**
```
TEST_FAILED|Error:Cannot find path
```

**Solutions:**
```powershell
# Verify path on DUT
# From Server, check remote path:
psexec \\192.168.1.100 -u Administrator -p YourPassword cmd /c "dir C:\GLD\New_Flow_5\RunTest.ps1"

# Ensure WorkingPath is correct in ServerConfig.json
```

#### 4. "PACS Not Starting"

**Symptoms:**
```
PACS_START_FAILED|Error:Failed to start PACS
```

**Solutions:**
```powershell
# Verify PACS path
Test-Path "C:\Intel\PACS\pacs.exe"

# Check if PACS is already running
Get-Process -Name "pacs" -ErrorAction SilentlyContinue

# Disable PACS if not needed
# In ServerConfig.json: "Enabled": false
```

#### 5. "Byte Array Constructor Error"

**Symptoms:**
```
Error: Cannot find an appropriate constructor for type byte[]
```

**Solution:**
This is fixed in the code (uses hardcoded buffer size `1024`). If you still see this, check PowerShell version:
```powershell
$PSVersionTable.PSVersion  # Should be 5.1 or higher
```

---

## Network Configuration

### IP Address Planning

#### Scenario 1: Single Server, Single DUT
```
Server (Control PC):  192.168.1.50
DUT (Test PC):        192.168.1.100
Client (Your PC):     192.168.1.10

ServerConfig.json:
  "Server": { "Host": "0.0.0.0", "Port": 55555 }
  "Client": { "DefaultIP": "192.168.1.100" }

Usage:
  From 192.168.1.10: .\NiDaqClient.ps1 -ServerIP 192.168.1.50 -Command 102 -Payload "GLD-1015"
```

#### Scenario 2: Single Server, Multiple DUTs
```
Server (Control PC):  192.168.1.50
DUT1:                 192.168.1.100
DUT2:                 192.168.1.101
DUT3:                 192.168.1.102

Create separate config files:
  ServerConfig-DUT1.json → "DefaultIP": "192.168.1.100"
  ServerConfig-DUT2.json → "DefaultIP": "192.168.1.101"
  ServerConfig-DUT3.json → "DefaultIP": "192.168.1.102"

Run separate server instances (different ports):
  .\NiDaqServer.ps1 -ConfigFile ServerConfig-DUT1.json -Port 55551
  .\NiDaqServer.ps1 -ConfigFile ServerConfig-DUT2.json -Port 55552
  .\NiDaqServer.ps1 -ConfigFile ServerConfig-DUT3.json -Port 55553
```

#### Scenario 3: Server and Client on Same Machine
```
Server & Client: localhost (127.0.0.1)

ServerConfig.json:
  "Server": { "Host": "127.0.0.1", "Port": 55555 }

Usage:
  .\NiDaqClient.ps1 -ServerIP 127.0.0.1 -Command 101
```

### Port Assignments

| Port | Service | Purpose |
|------|---------|---------|
| 55555 | NiDaq Server (default) | TCP command/control |
| 55551-55559 | Additional servers | For multiple DUT control |
| 135 | RPC | PsExec requirement |
| 445 | SMB | PsExec file access |

---

## Workflow Examples

### Example 1: Run Single Test
```powershell
# Step 1: Start server (on Control PC)
cd C:\NiDaq_Server
.\NiDaqServer.ps1

# Step 2: Check server status (from any PC)
.\NiDaqClient.ps1 -ServerIP 192.168.1.50 -Command 101
# Expected: SERVER_ONLINE|PACS:STOPPED|VERSION:2.0

# Step 3: Start PACS (if needed)
.\NiDaqClient.ps1 -ServerIP 192.168.1.50 -Command 103
# Expected: PACS_STARTED|Status:RUNNING

# Step 4: Execute test
.\NiDaqClient.ps1 -ServerIP 192.168.1.50 -Command 102 -Payload "GLD-1015"
# Expected: TEST_SCHEDULED|TestID:GLD-1015|Status:Running

# Step 5: Start PACS recording (300 seconds)
.\NiDaqClient.ps1 -ServerIP 192.168.1.50 -Command 105 -Payload "300|GLD-1015"
# Expected: PACS_RECORDING_STARTED|Duration:300|TestID:GLD-1015

# Wait for test to complete...

# Step 6: Stop PACS
.\NiDaqClient.ps1 -ServerIP 192.168.1.50 -Command 106
# Expected: PACS_STOPPED
```

### Example 2: Batch Testing
```powershell
# Create test batch script: RunBatchTests.ps1
$tests = @("GLD-1008", "GLD-1009", "GLD-1015", "GLD-1016")
$serverIP = "192.168.1.50"

foreach ($test in $tests) {
    Write-Host "Running $test..." -ForegroundColor Cyan
    
    # Start test
    $result = .\NiDaqClient.ps1 -ServerIP $serverIP -Command 102 -Payload "$test|60|1|false"
    Write-Host $result
    
    # Wait for test duration + buffer
    Start-Sleep -Seconds 120
}

Write-Host "Batch complete!" -ForegroundColor Green
```

### Example 3: Temperature Control Integration
```powershell
# Set chamber to 25°C
.\NiDaqClient.ps1 -Command 109 -Payload "25"
Start-Sleep -Seconds 300  # Wait for stabilization

# Run test at 25°C
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015|60|1|false"

# Set chamber to 85°C
.\NiDaqClient.ps1 -Command 109 -Payload "85"
Start-Sleep -Seconds 600  # Wait for stabilization

# Run test at 85°C
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015|60|1|false"
```

---

## Best Practices

### Security
1. ✅ **Use Strong Passwords** - Don't leave password blank in production
2. ✅ **Restrict Server Host** - Use specific IP instead of `0.0.0.0` if possible
3. ✅ **Firewall Rules** - Only allow specific IPs to connect
4. ✅ **Secure Config Files** - Protect ServerConfig.json (contains credentials)
5. ✅ **Use TLS/SSL** - For production, consider encrypting TCP traffic

### Reliability
1. ✅ **Monitor Logs** - Check `Logs\NiDaqServer_*.log` regularly
2. ✅ **Backup Configs** - Keep copies of ServerConfig.json
3. ✅ **Test Connectivity** - Use `Test-NetConnection` before tests
4. ✅ **Handle Timeouts** - Set appropriate `ReceiveTimeout` values
5. ✅ **Error Handling** - Always check response codes

### Performance
1. ✅ **Run as Administrator** - Improves PsExec performance
2. ✅ **Use Local Accounts** - Faster than domain accounts
3. ✅ **Close Unused Connections** - Server auto-closes after response
4. ✅ **Buffer Size** - 1024 bytes sufficient for most commands

### Maintenance
1. ✅ **Log Rotation** - Clean old logs periodically
2. ✅ **Result Archival** - Move old results off DUT
3. ✅ **Version Control** - Track config file changes
4. ✅ **Documentation** - Keep IP address mapping updated

---

## Advanced Configuration

### Custom Timeout Values
```json
{
  "Server": {
    "ReceiveTimeout": 600  // 10 minutes for long-running commands
  }
}
```

### Custom Ports
```powershell
# Run multiple servers for parallel testing
Start-Process powershell -ArgumentList "-File NiDaqServer.ps1 -Port 55551 -ConfigFile ServerConfig-DUT1.json"
Start-Process powershell -ArgumentList "-File NiDaqServer.ps1 -Port 55552 -ConfigFile ServerConfig-DUT2.json"
```

### Environment Variables
```powershell
# Set environment variables for PsExec
$env:PSEXEC_PATH = "C:\Tools\PsExec.exe"

# Use in script
& $env:PSEXEC_PATH \\192.168.1.100 ...
```

---

## Support & Resources

### Log Files
- **Location**: `C:\NiDaq_Server\Logs\NiDaqServer_YYYY-MM-DD.log`
- **Format**: Plain text, timestamped entries
- **Levels**: INFO, WARNING, ERROR, SUCCESS

### Error Codes
- Review response messages for error details
- Check server log for stack traces
- Verify network connectivity with `Test-NetConnection`

### Useful Commands
```powershell
# View live log
Get-Content .\Logs\NiDaqServer_2026-01-28.log -Wait

# Check server process
Get-Process -Name powershell | Where-Object { $_.MainWindowTitle -like "*NiDaq*" }

# Kill server
Stop-Process -Name powershell -Force

# Test DUT connectivity
Test-Connection -ComputerName 192.168.1.100 -Count 1

# Test PsExec
psexec \\192.168.1.100 -u Administrator -p YourPassword cmd /c "echo Test"
```

---

## Quick Reference Card

### Start Server
```powershell
cd C:\NiDaq_Server
.\NiDaqServer.ps1
```

### Check Status
```powershell
.\NiDaqClient.ps1 -Command 101
```

### Run Test
```powershell
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015"
```

### Key Files
- **Server**: `C:\NiDaq_Server\NiDaqServer.ps1`
- **Config**: `C:\NiDaq_Server\ServerConfig.json`
- **Logs**: `C:\NiDaq_Server\Logs\`
- **DUT Tests**: `C:\GLD\*.bat`

### Key Ports
- **Server**: TCP 55555
- **PsExec**: TCP 135, 445

### Default IPs
- **Server**: Configured in ServerConfig.json
- **DUT**: Configured in ServerConfig.json → Client.DefaultIP

---

## Version Information

- **Version**: 2.0 (Standalone Edition)
- **File**: NiDaqServer.ps1 (671 lines)
- **PowerShell**: Requires 5.1+
- **Last Updated**: January 2026

---

*For modular version documentation, see `MODULAR-SERVER-GUIDE.md`*
