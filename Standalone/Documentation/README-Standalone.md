# NiDaq Server - Standalone Version

## Quick Start

### 1. Start the Server
```batch
REM Double-click or run:
Start-Server.bat
```

### 2. Test Connection
```batch
REM From another terminal:
Test-Connection.bat
```

### 3. Run a Test
```powershell
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015"
```

---

## File Structure

```
C:\NiDaq_Server_PS\                          # Installation directory
│
├── 📘 Documentation
│   ├── README-Standalone.md                 # This file (quick start)
│   ├── STANDALONE-SERVER-GUIDE.md          # Complete guide (1000+ lines)
│   └── COMPARISON-Standalone-vs-Modular.md # Architecture comparison
│
├── 🚀 Main Files
│   ├── NiDaqServer.ps1                     # Server script (671 lines)
│   ├── NiDaqClient.ps1                     # Client tool
│   └── ServerConfig.json                   # Configuration file
│
├── 🔧 Helper Scripts
│   ├── Start-Server.bat                    # Launch server (with admin check)
│   └── Test-Connection.bat                 # Test connectivity
│
└── 📁 Auto-Created Directories
    └── Logs\                               # Server logs
        └── NiDaqServer_2026-01-28.log
```

---

## Prerequisites

### On Server Machine (Control PC)
- ✅ Windows 10/11 or Server 2016+
- ✅ PowerShell 5.1+
- ✅ PsExec.exe (download from Sysinternals)
- ✅ Administrator privileges
- ✅ Network access to DUTs

### On DUT Machines (Test PCs)
- ✅ Windows 10/11 or Server 2016+
- ✅ RunTest.ps1 framework at `C:\GLD\New_Flow_5\RunTest.ps1`
- ✅ Test configs (GLD-*.bat) at `C:\GLD\`
- ✅ Remote access enabled

---

## Configuration

### Edit ServerConfig.json

```json
{
  "Server": {
    "Host": "0.0.0.0",      // Listen on all interfaces
    "Port": 55555           // TCP port
  },
  "Client": {
    "DefaultIP": "192.168.1.100",  // ⚠️ CHANGE THIS to your DUT IP
    "Username": "Administrator",    // ⚠️ CHANGE THIS to DUT username
    "Password": "",                // ⚠️ SET THIS to DUT password
    "WorkingPath": "C:\\GLD"       // Working directory on DUT
  },
  "PACS": {
    "Enabled": true         // Set to false if you don't have PACS
  }
}
```

### Key Settings to Change

| Setting | Default | Change To |
|---------|---------|-----------|
| `Client.DefaultIP` | `192.168.1.100` | Your DUT's IP address |
| `Client.Username` | `Administrator` | Your DUT's username |
| `Client.Password` | `""` | Your DUT's password |
| `PACS.Enabled` | `true` | `false` if no PACS |

---

## Command Reference

### Basic Commands

| Code | Command | Example | Description |
|------|---------|---------|-------------|
| 101 | Status | `.\NiDaqClient.ps1 -Command 101` | Check server |
| 102 | Run Test | `.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015"` | Execute test |
| 103 | Start PACS | `.\NiDaqClient.ps1 -Command 103` | Start PACS |
| 104 | PACS Status | `.\NiDaqClient.ps1 -Command 104` | Check PACS |
| 106 | Stop PACS | `.\NiDaqClient.ps1 -Command 106` | Stop PACS |

### Advanced Test Execution

```powershell
# Simple test
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015"

# Test with wait time (60 seconds)
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015|60"

# Test with wait + iterations
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015|60|3"

# Test with all parameters (wait|iterations|SoCWatch)
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015|60|3|true"
```

---

## How It Works

### Architecture
```
┌─────────────┐         ┌──────────────────┐         ┌─────────────┐
│   Client    │  TCP    │  NiDaq Server    │  PsExec │   DUT       │
│  (Your PC)  │ ──────► │  (Control PC)    │ ──────► │  (Test PC)  │
└─────────────┘ 55555   └──────────────────┘         └─────────────┘
                                 │
                                 │ Controls
                                 ▼
                        ┌─────────────────┐
                        │  PACS System    │
                        │  (Optional)     │
                        └─────────────────┘
```

### Execution Flow

1. **Client sends command** → `102|GLD-1015` to Server
2. **Server receives** → Parses command and payload
3. **Server builds command** → `powershell.exe RunTest.ps1 -TestID GLD-1015`
4. **PsExec executes** → Runs command on remote DUT
5. **Server responds** → `TEST_SCHEDULED|TestID:GLD-1015|Status:Running`
6. **Test runs on DUT** → Results saved on DUT

### Where Tests Run

⚠️ **IMPORTANT**: Tests run on the **DUT (Device Under Test)**, NOT on the server!

- **Server Machine**: Receives commands, orchestrates execution
- **DUT Machine**: Actually runs the tests (via PsExec)
- **Client Machine**: Sends commands to server

---

## File Paths on DUT

The following paths must exist on your DUT machine:

| Path | Purpose | Required? |
|------|---------|-----------|
| `C:\GLD\New_Flow_5\RunTest.ps1` | Test runner | ✅ Yes |
| `C:\GLD\GLD-*.bat` | Test configs | ✅ Yes |
| `C:\Results\` | Test outputs | Auto-created |

---

## Network Configuration

### IP Address Examples

#### Scenario 1: Server and Client on Same PC (Testing)
```
Server IP: 127.0.0.1 (localhost)
DUT IP: 192.168.1.100

In ServerConfig.json:
  "Server": { "Host": "127.0.0.1" }
  "Client": { "DefaultIP": "192.168.1.100" }

Connect with:
  .\NiDaqClient.ps1 -ServerIP 127.0.0.1 -Command 101
```

#### Scenario 2: Separate Control PC (Production)
```
Control PC (Server): 192.168.1.50
DUT: 192.168.1.100
Your PC (Client): 192.168.1.10

In ServerConfig.json:
  "Server": { "Host": "0.0.0.0" }  # Listen on all IPs
  "Client": { "DefaultIP": "192.168.1.100" }

Connect with:
  .\NiDaqClient.ps1 -ServerIP 192.168.1.50 -Command 101
```

### Required Ports

| Port | Service | Purpose |
|------|---------|---------|
| 55555 | NiDaq Server | TCP commands |
| 135, 445 | RPC/SMB | PsExec connections |

### Firewall Rules

```powershell
# On Server: Allow inbound TCP 55555
New-NetFirewallRule -DisplayName "NiDaq Server" `
    -Direction Inbound -LocalPort 55555 -Protocol TCP -Action Allow

# On DUT: Allow PsExec (optional, usually enabled by default)
New-NetFirewallRule -DisplayName "Remote Admin" `
    -Direction Inbound -Program "C:\Windows\System32\psexesvc.exe" -Action Allow
```

---

## Troubleshooting

### Server Won't Start

**Check PowerShell version:**
```powershell
$PSVersionTable.PSVersion  # Should be 5.1 or higher
```

**Check if port is in use:**
```powershell
netstat -an | Select-String "55555"
```

**Run with admin privileges:**
- Right-click `Start-Server.bat` → Run as administrator

### Cannot Connect to Server

**Test network connectivity:**
```powershell
Test-NetConnection -ComputerName <ServerIP> -Port 55555
```

**Check firewall:**
```powershell
Get-NetFirewallRule -DisplayName "NiDaq Server"
```

**Check server is running:**
```powershell
Get-Process -Name powershell | Where-Object { $_.MainWindowTitle -like "*NiDaq*" }
```

### PsExec Errors

**"Access Denied":**
- Verify username/password in ServerConfig.json
- Ensure server is running as Administrator
- Check DUT allows remote connections

**"Path not found":**
- Verify RunTest.ps1 exists on DUT at `C:\GLD\New_Flow_5\RunTest.ps1`
- Check WorkingPath in ServerConfig.json

**"PsExec not found":**
```powershell
# Download from: https://live.sysinternals.com/psexec.exe
# Place in: C:\Windows\System32\PsExec.exe
```

### Test Not Running

**Verify test config exists on DUT:**
```powershell
# From server, check remote file:
psexec \\192.168.1.100 -u Administrator -p YourPassword cmd /c "dir C:\GLD\GLD-1015.bat"
```

**Check logs:**
```powershell
Get-Content .\Logs\NiDaqServer_*.log -Tail 50
```

---

## Logs

### Location
```
C:\NiDaq_Server_PS\Logs\NiDaqServer_YYYY-MM-DD.log
```

### View Live Logs
```powershell
Get-Content .\Logs\NiDaqServer_2026-01-28.log -Wait
```

### Log Format
```
2026-01-28 14:30:15 [INFO] Server listening on 0.0.0.0:55555
2026-01-28 14:30:22 [INFO] Client connected: 192.168.1.10:52341
2026-01-28 14:30:22 [INFO] Received: 102|GLD-1015
2026-01-28 14:30:22 [INFO] Command 102: Execute Test
2026-01-28 14:30:22 [INFO] Starting test GLD-1015 with parameters: -TestID 'GLD-1015'
2026-01-28 14:30:23 [SUCCESS] Response sent: TEST_SCHEDULED|TestID:GLD-1015|Status:Running
```

---

## Best Practices

### Security
✅ Use strong passwords in ServerConfig.json  
✅ Protect ServerConfig.json file permissions  
✅ Use firewall rules to restrict access  
✅ Run server as Administrator only when needed  

### Reliability
✅ Monitor logs regularly  
✅ Backup ServerConfig.json  
✅ Test connectivity before running tests  
✅ Use Test-Connection.bat to verify setup  

### Performance
✅ Close unused network connections  
✅ Clean old logs periodically  
✅ Use appropriate timeout values  
✅ Run tests sequentially, not in parallel  

---

## Getting Help

### Check Documentation
1. **This file**: Quick reference
2. **STANDALONE-SERVER-GUIDE.md**: Complete 1000+ line guide
3. **COMPARISON-Standalone-vs-Modular.md**: Architecture details

### Debug Steps
1. Check server logs in `Logs\` directory
2. Run `Test-Connection.bat` to verify connectivity
3. Test PsExec manually: `psexec \\DUT_IP cmd /c echo Test`
4. Verify DUT paths exist
5. Check network firewall rules

### Common Commands
```powershell
# View server status
.\NiDaqClient.ps1 -Command 101

# Check logs
Get-Content .\Logs\NiDaqServer_*.log -Tail 20

# Test DUT connectivity
Test-Connection 192.168.1.100

# Test PsExec
psexec \\192.168.1.100 -u Administrator -p YourPassword cmd /c "echo Test"
```

---

## Next Steps

### For Testing
1. ✅ Edit ServerConfig.json with your DUT IP
2. ✅ Run `Start-Server.bat`
3. ✅ Run `Test-Connection.bat`
4. ✅ Try `.\NiDaqClient.ps1 -Command 101`
5. ✅ Run a test: `.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015"`

### For Production
1. ✅ Set up dedicated Control PC
2. ✅ Configure firewall rules
3. ✅ Set strong passwords
4. ✅ Test all DUTs individually
5. ✅ Create automation scripts
6. ✅ Set up log monitoring

### For Multiple DUTs
1. ✅ Create separate config files (ServerConfig-DUT1.json, etc.)
2. ✅ Run multiple server instances on different ports
3. ✅ Document IP address mappings
4. ✅ Create batch scripts for each DUT

---

## Version Information

- **Version**: 2.0 (Standalone Edition)
- **File**: NiDaqServer.ps1 (671 lines, single file)
- **Architecture**: Monolithic (all-in-one)
- **PowerShell**: Requires 5.1+
- **Last Updated**: January 2026

---

## License & Support

This is an internal tool for test automation.  
For questions or issues, refer to the complete guide in `STANDALONE-SERVER-GUIDE.md`.

---

*For modular version, see modular documentation files.*
