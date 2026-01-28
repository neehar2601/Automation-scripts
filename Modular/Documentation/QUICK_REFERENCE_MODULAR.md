# NiDaq Server - Quick Reference Card (Modular Version)

## 🚀 Quick Start (3 Steps)

```batch
1. Verify ServerConfig.json has "BufferSize": 4096
2. Double-click Start-Modular-Server.bat
3. Run: .\NiDaqClient.ps1 -Command 101
```

---

## 📁 File Locations

### Server Machine (Control PC)
```
C:\NiDaq_Server_PS\
├── NiDaqServer-Modular.ps1       # Main entry point
├── NiDaqClient.ps1               # Client tool
├── ServerConfig.json             # Configuration ⚠️ MUST have BufferSize
├── Start-Modular-Server.bat      # Quick launcher
│
├── Modules\                      # PowerShell modules
│   ├── LoggingModule.psm1
│   ├── ConfigurationModule.psm1
│   └── TCPServerModule.psm1
│
└── Classes\                      # PowerShell classes
    ├── PACSController.ps1
    ├── RemoteExecutor.ps1
    └── CommandHandler.ps1
```

### DUT Machine (Test PC)
```
C:\GLD\New_Flow_5\RunTest.ps1   # Must exist
C:\GLD\GLD-*.bat                # Test configs (must exist)
C:\Results\                     # Auto-created for results
```

---

## ⚙️ Configuration (ServerConfig.json)

### ⚠️ CRITICAL: BufferSize Required!
```json
{
  "Server": {
    "Host": "0.0.0.0",
    "Port": 55555,
    "BufferSize": 4096,              // ⚠️ REQUIRED in modular!
    "ReceiveTimeout": 300
  },
  "Client": {
    "DefaultIP": "192.168.1.100",    // ⚠️ YOUR DUT IP
    "Username": "Administrator",      // ⚠️ YOUR DUT USERNAME  
    "Password": "",                   // ⚠️ YOUR DUT PASSWORD
    "WorkingPath": "C:\\GLD"
  },
  "PACS": {
    "Enabled": true,                 // Set false if no PACS
    "ProcessName": "pacs"            // Custom process name (optional)
  }
}
```

### Key Differences from Standalone

| Property | Standalone | Modular |
|----------|-----------|---------|
| **BufferSize** | ❌ Not needed (hardcoded) | ✅ **REQUIRED** (4096) |
| **ProcessName** | ❌ Not configurable | ✅ Configurable |
| **PythonPath** | ❌ Hardcoded | ✅ Configurable |

---

## 🏗️ Modular Architecture

```
NiDaqServer-Modular.ps1 (Entry Point)
         │
    ┌────┴────┬────────────┬────────────┐
    │         │            │            │
    ▼         ▼            ▼            ▼
Logging  Configuration  TCPServer   Classes
Module     Module        Module    (3 files)
```

### File Count: 7 Files
1. **NiDaqServer-Modular.ps1** (132 lines) - Entry point
2. **LoggingModule.psm1** (75 lines) - Logging functions
3. **ConfigurationModule.psm1** (140 lines) - Config management
4. **TCPServerModule.psm1** (138 lines) - TCP server
5. **PACSController.ps1** (120 lines) - PACS management
6. **RemoteExecutor.ps1** (130 lines) - Remote execution
7. **CommandHandler.ps1** (312 lines) - Command routing

**Total: 1,047 lines** (vs 671 lines in standalone)

---

## 🌐 Network Setup (Same as Standalone)

### IP Address Examples

**Same PC Testing:**
```
Server: 127.0.0.1
DUT: 192.168.1.100
Command: .\NiDaqClient.ps1 -ServerIP 127.0.0.1 -Command 101
```

**Production Setup:**
```
Control PC (Server): 192.168.1.50
DUT: 192.168.1.100
Command: .\NiDaqClient.ps1 -ServerIP 192.168.1.50 -Command 101
```

### Required Ports
- **55555** - NiDaq Server (TCP)
- **135, 445** - PsExec (RPC/SMB)

---

## 💻 Command Reference (Same as Standalone)

### Essential Commands

| Code | Description | Command |
|------|-------------|---------|
| **101** | Check server status | `.\NiDaqClient.ps1 -Command 101` |
| **102** | Run test | `.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015"` |
| **103** | Start PACS | `.\NiDaqClient.ps1 -Command 103` |
| **104** | PACS status (enhanced!) | `.\NiDaqClient.ps1 -Command 104` |
| **106** | Stop PACS | `.\NiDaqClient.ps1 -Command 106` |

### Enhanced Responses (Modular Only!)

**Command 101 - Enhanced Status**
```
SERVER_ONLINE|PACS:RUNNING|CLIENT:CONNECTED|VERSION:2.0
                            ^^^^^^^^^^^^^ NEW!
```

**Command 104 - Detailed PACS Status**
```
PACS_STATUS|Status:RUNNING|PID:12345|Memory:256MB
                           ^^^^^^^^^^^^^^^^^^^^^^ NEW!
```

---

## 🔍 How It Works

```
Client → NiDaqServer-Modular.ps1
              │
              ├─► Modules (Logging, Config, TCPServer)
              │
              └─► Classes (PACS, Remote, Handler)
                       │
                       └─► PsExec → DUT → RunTest.ps1

⚠️ TEST RUNS ON DUT, NOT ON SERVER!
```

---

## 🛠️ Troubleshooting

### Module Loading Errors

**Error: "Cannot find path to module"**
```powershell
# Check if Modules directory exists
Test-Path ".\Modules"
Test-Path ".\Modules\LoggingModule.psm1"

# Ensure you're in correct directory
Get-Location  # Should be: C:\NiDaq_Server_PS
```

**Error: "Start-TCPServer command not found"**
```powershell
# Verify module exports
Import-Module .\Modules\TCPServerModule.psm1 -Force
Get-Command -Module TCPServerModule

# Should show: Start-TCPServer, Stop-TCPServer
```

### Configuration Errors

**Error: "Byte array constructor failed"** ⚠️ COMMON!
```powershell
# Solution: Add BufferSize to ServerConfig.json
{
  "Server": {
    "BufferSize": 4096  // ADD THIS LINE!
  }
}

# Verify it's there:
(Get-Content .\ServerConfig.json | ConvertFrom-Json).Server.BufferSize
# Should output: 4096
```

**Error: "Configuration validation failed"**
```powershell
# Test config manually
Import-Module .\Modules\ConfigurationModule.psm1 -Force
$config = Load-ServerConfig -ConfigPath ".\ServerConfig.json"
Test-ServerConfig -Config $config
```

### Server Startup Errors

**Error: "Cannot bind to address"**
```powershell
# Check if port is in use
netstat -an | Select-String "55555"

# Use different port
.\NiDaqServer-Modular.ps1 -Port 55556
```

**Modules not loading at startup**
```powershell
# Run with verbose to see what's failing
Import-Module .\Modules\LoggingModule.psm1 -Force -Verbose
Import-Module .\Modules\ConfigurationModule.psm1 -Force -Verbose
Import-Module .\Modules\TCPServerModule.psm1 -Force -Verbose
```

### View Logs
```powershell
# See recent log entries
Get-Content .\Logs\NiDaqServer_*.log -Tail 20

# Live log monitoring
Get-Content .\Logs\NiDaqServer_*.log -Wait
```

---

## 📊 Modular vs Standalone

| Feature | Standalone | Modular |
|---------|-----------|---------|
| **Files** | 1 file | 7 files |
| **Lines** | 671 | 1,047 |
| **BufferSize** | Hardcoded 1024 | Configurable 4096 |
| **Deployment** | ⭐⭐⭐⭐⭐ Easy | ⭐⭐⭐ Multiple files |
| **Maintainability** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Testability** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Team Dev** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Customization** | ⭐⭐ | ⭐⭐⭐⭐⭐ |

### ✅ Use Modular If:
- Enterprise environment
- Team development
- Need customization
- Long-term maintenance
- CI/CD pipelines
- Unit testing

### ✅ Use Standalone If:
- Quick deployment
- Single developer
- Simple requirements
- One-time use

---

## 📖 Module Quick Reference

### LoggingModule Functions
```powershell
Write-Log -Message "Text" -Level "INFO|WARNING|ERROR|SUCCESS"
Set-LogFile -Path "C:\Logs\MyLog.log"
$logPath = Get-LogFile
```

### ConfigurationModule Functions
```powershell
$config = Load-ServerConfig -ConfigPath ".\ServerConfig.json"
Save-ServerConfig -Config $config -ConfigPath ".\ServerConfig.json"
$default = Get-DefaultConfig
$isValid = Test-ServerConfig -Config $config
```

### TCPServerModule Functions
```powershell
Start-TCPServer -Config $config -Handler $handler
Stop-TCPServer
```

### PACSController Class
```powershell
$pacs = [PACSController]::new($config.PACS)
$pacs.IsRunning()         # Returns $true/$false
$pacs.GetStatus()         # Returns "RUNNING"/"STOPPED"
$pacs.GetDetailedStatus() # Returns hashtable with PID, Memory, etc.
$pacs.Start()
$pacs.Stop()
$pacs.Restart()
$pacs.Record(300, "GLD-1015")
```

### RemoteExecutor Class
```powershell
$remote = [RemoteExecutor]::new($config.Client)
$remote.TestConnection()                      # Ping DUT
$remote.VerifyRemotePath("C:\GLD\File.ps1")  # Check if path exists
$result = $remote.Execute("dir C:\", $false, 30)
$result = $remote.RunTest("GLD-1015", @{ WaitTime = 60 })
```

---

## 🎯 Common Workflows

### Test a Single Test
```powershell
# 1. Start server
.\NiDaqServer-Modular.ps1

# 2. Check status (enhanced!)
.\NiDaqClient.ps1 -Command 101
# Response: SERVER_ONLINE|PACS:STOPPED|CLIENT:CONNECTED|VERSION:2.0

# 3. Run test
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015"
```

### Test with PACS (Enhanced Status)
```powershell
# Start PACS
.\NiDaqClient.ps1 -Command 103

# Check detailed status (modular enhancement!)
.\NiDaqClient.ps1 -Command 104
# Response: PACS_STATUS|Status:RUNNING|PID:12345|Memory:256MB

# Run test
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015"

# Start recording
.\NiDaqClient.ps1 -Command 105 -Payload "300|GLD-1015"

# Stop PACS
.\NiDaqClient.ps1 -Command 106
```

### Multiple Server Instances (Modular Advantage)
```powershell
# Terminal 1: DUT1 on port 55551
.\NiDaqServer-Modular.ps1 -Port 55551 -ConfigFile ServerConfig-DUT1.json

# Terminal 2: DUT2 on port 55552
.\NiDaqServer-Modular.ps1 -Port 55552 -ConfigFile ServerConfig-DUT2.json

# Terminal 3: DUT3 on port 55553
.\NiDaqServer-Modular.ps1 -Port 55553 -ConfigFile ServerConfig-DUT3.json

# Control them separately:
.\NiDaqClient.ps1 -ServerIP 127.0.0.1 -ServerPort 55551 -Command 102 -Payload "GLD-1015"
.\NiDaqClient.ps1 -ServerIP 127.0.0.1 -ServerPort 55552 -Command 102 -Payload "GLD-1016"
.\NiDaqClient.ps1 -ServerIP 127.0.0.1 -ServerPort 55553 -Command 102 -Payload "GLD-1017"
```

---

## 🔧 Buffer Size Tuning

### Recommended Values

| Size | Use Case | Config |
|------|----------|--------|
| 1024 | Small commands | `"BufferSize": 1024` |
| **4096** | **Default (recommended)** | `"BufferSize": 4096` |
| 8192 | Large payloads | `"BufferSize": 8192` |
| 16384 | File transfers | `"BufferSize": 16384` |

### Change in ServerConfig.json:
```json
{
  "Server": {
    "BufferSize": 8192  // Adjust based on needs
  }
}
```

---

## ✅ Pre-Flight Checklist

**Modular-Specific Checks:**
- [ ] Modules\ directory exists with 3 .psm1 files
- [ ] Classes\ directory exists with 3 .ps1 files
- [ ] ServerConfig.json has "BufferSize" property
- [ ] All modules can be imported without errors

**General Checks:**
- [ ] NiDaqServer-Modular.ps1 exists
- [ ] ServerConfig.json configured with DUT IP
- [ ] PsExec.exe installed
- [ ] Running as Administrator
- [ ] Firewall allows port 55555

**On DUT:**
- [ ] RunTest.ps1 at `C:\GLD\New_Flow_5\RunTest.ps1`
- [ ] Test configs (GLD-*.bat) at `C:\GLD\`
- [ ] Remote access enabled

---

## 📞 Quick Help

**Module loading fails?**
→ Check: `Test-Path .\Modules\*.psm1`

**BufferSize error?**
→ Add to config: `"BufferSize": 4096`

**Function not found?**
→ Check: `Get-Command -Module TCPServerModule`

**Config invalid?**
→ Test: `Test-ServerConfig -Config $config`

**Need full guide?**
→ Read: `MODULAR-SERVER-GUIDE.md`

**Compare versions?**
→ Read: `COMPARISON-Standalone-vs-Modular.md`

---

## 🔐 Security Notes

⚠️ **IMPORTANT:**
- ServerConfig.json contains passwords
- Protect with file permissions
- Use strong passwords
- Restrict network access
- Consider encryption for production

---

## 🚀 Advanced Features (Modular Only)

### Custom Module Loading
```powershell
# Add your own module
Import-Module ".\Modules\MyCustomModule.psm1" -Force
```

### Config Validation
```powershell
# Validate before starting
if (Test-ServerConfig -Config $config) {
    Start-TCPServer -Config $config -Handler $handler
}
```

### Enhanced Error Handling
```powershell
# Modular version has better error isolation
# Each module fails independently without crashing server
```

### Unit Testing Support
```powershell
# Test individual modules
.\Tests\Test-LoggingModule.ps1
.\Tests\Test-ConfigurationModule.ps1
.\Tests\Test-TCPServerModule.ps1
```

---

## Version

**NiDaq Server v2.0 - Modular Edition**
- Architecture: Modular (3 modules + 3 classes)
- Total Lines: 1,047 lines across 7 files
- Buffer Size: Configurable (default 4096 bytes)
- PowerShell 5.1+
- Last Updated: January 2026

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `README-Modular.md` | Quick start guide |
| `MODULAR-SERVER-GUIDE.md` | Complete 1500+ line guide |
| `QUICK_REFERENCE_MODULAR.md` | This cheat sheet |
| `COMPARISON-Standalone-vs-Modular.md` | Architecture comparison |

---

**Print this card and keep it handy!** 📄

**Tip:** If you're migrating from standalone, main difference is:
1. 7 files instead of 1
2. **Must add `"BufferSize": 4096`** to ServerConfig.json
3. Enhanced status responses for commands 101 and 104
