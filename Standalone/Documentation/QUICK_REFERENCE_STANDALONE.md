# NiDaq Server - Quick Reference Card (Standalone Version)

## 🚀 Quick Start (3 Steps)

```batch
1. Edit ServerConfig.json → Set your DUT IP address
2. Double-click Start-Server.bat
3. Run: .\NiDaqClient.ps1 -Command 101
```

---

## 📁 File Locations

### Server Machine (Control PC)
```
C:\NiDaq_Server_PS\
├── NiDaqServer.ps1           # Main server (standalone, 671 lines)
├── NiDaqClient.ps1           # Client tool
├── ServerConfig.json         # Configuration ⚠️ EDIT THIS
├── Start-Server.bat          # Quick launcher
└── Test-Connection.bat       # Test connectivity
```

### DUT Machine (Test PC)
```
C:\GLD\New_Flow_5\RunTest.ps1   # Must exist
C:\GLD\GLD-*.bat                # Test configs (must exist)
C:\Results\                     # Auto-created for results
```

---

## ⚙️ Configuration (ServerConfig.json)

### Must Change These:
```json
{
  "Client": {
    "DefaultIP": "192.168.1.100",    // ⚠️ YOUR DUT IP
    "Username": "Administrator",      // ⚠️ YOUR DUT USERNAME  
    "Password": "",                   // ⚠️ YOUR DUT PASSWORD
    "WorkingPath": "C:\\GLD"
  },
  "PACS": {
    "Enabled": true                   // Set false if no PACS
  }
}
```

---

## 🌐 Network Setup

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
Your PC (Client): Any IP on network
Command: .\NiDaqClient.ps1 -ServerIP 192.168.1.50 -Command 101
```

### Required Ports
- **55555** - NiDaq Server (TCP)
- **135, 445** - PsExec (RPC/SMB)

---

## 💻 Command Reference

### Essential Commands

| Code | Description | Command |
|------|-------------|---------|
| **101** | Check server status | `.\NiDaqClient.ps1 -Command 101` |
| **102** | Run test | `.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015"` |
| **103** | Start PACS | `.\NiDaqClient.ps1 -Command 103` |
| **104** | PACS status | `.\NiDaqClient.ps1 -Command 104` |
| **106** | Stop PACS | `.\NiDaqClient.ps1 -Command 106` |

### Test Execution Formats

```powershell
# Simple test
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015"

# With wait time (60 seconds)
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015|60"

# With wait + iterations
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015|60|3"

# Full parameters: TestID|WaitTime|Iterations|SoCWatch
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015|60|3|false"
```

---

## 🔍 How It Works

```
Client PC → Server PC → DUT PC
  (You)    (Orchestrator)  (Runs Test)
  
  CMD 102  →  PsExec  →  RunTest.ps1
  
  ⚠️ TEST RUNS ON DUT, NOT ON SERVER!
```

### Execution Flow
1. You send: `102|GLD-1015`
2. Server receives and parses
3. Server builds: `psexec \\DUT cmd /c "powershell RunTest.ps1 -TestID GLD-1015"`
4. PsExec executes on DUT
5. Server responds: `TEST_SCHEDULED`
6. Test runs in background on DUT

---

## 🛠️ Troubleshooting

### Server Won't Start
```powershell
# Check PowerShell version (need 5.1+)
$PSVersionTable.PSVersion

# Check if port is available
netstat -an | Select-String "55555"

# Run as Administrator
Right-click Start-Server.bat → Run as administrator
```

### Cannot Connect
```powershell
# Test connectivity
Test-NetConnection -ComputerName <ServerIP> -Port 55555

# Check firewall
Get-NetFirewallRule -DisplayName "NiDaq Server"

# Or run test script
.\Test-Connection.bat
```

### PsExec Errors
```powershell
# "Access Denied" - Check credentials in ServerConfig.json
# "Path not found" - Verify RunTest.ps1 exists on DUT at C:\GLD\New_Flow_5\
# "PsExec not found" - Download from https://live.sysinternals.com/psexec.exe

# Test PsExec manually:
psexec \\192.168.1.100 -u Administrator -p YourPassword cmd /c "echo Test"
```

### View Logs
```powershell
# See recent log entries
Get-Content .\Logs\NiDaqServer_*.log -Tail 20

# Live log monitoring
Get-Content .\Logs\NiDaqServer_*.log -Wait
```

---

## 📊 Response Codes

| Response | Meaning |
|----------|---------|
| `SERVER_ONLINE\|...` | ✅ Server working |
| `TEST_SCHEDULED\|...` | ✅ Test started |
| `TEST_FAILED\|Error:...` | ❌ Test failed to start |
| `PACS_STARTED` | ✅ PACS running |
| `PACS_STOPPED` | ✅ PACS stopped |
| `PACS_DISABLED` | ⚠️ PACS not enabled |
| `ERROR\|...` | ❌ General error |

---

## 📖 Documentation Files

| File | Purpose |
|------|---------|
| `README-Standalone.md` | Quick start guide |
| `STANDALONE-SERVER-GUIDE.md` | Complete 1000+ line guide |
| `COMPARISON-Standalone-vs-Modular.md` | Architecture comparison |

---

## ✅ Pre-Flight Checklist

Before running tests:

**On Server Machine:**
- [ ] NiDaqServer.ps1 exists
- [ ] ServerConfig.json configured with DUT IP
- [ ] PsExec.exe installed (in PATH or same directory)
- [ ] Running as Administrator
- [ ] Firewall allows port 55555

**On DUT Machine:**
- [ ] RunTest.ps1 exists at `C:\GLD\New_Flow_5\RunTest.ps1`
- [ ] Test configs (GLD-*.bat) exist at `C:\GLD\`
- [ ] Remote access enabled
- [ ] Administrator account accessible

**Network:**
- [ ] Server and DUT can ping each other
- [ ] Port 55555 accessible
- [ ] Ports 135, 445 open (for PsExec)

---

## 🎯 Common Workflows

### Test a Single Test
```powershell
# 1. Start server
Start-Server.bat

# 2. Check status
.\NiDaqClient.ps1 -Command 101

# 3. Run test
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015"
```

### Test with PACS
```powershell
# 1. Start PACS
.\NiDaqClient.ps1 -Command 103

# 2. Start test
.\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015"

# 3. Start PACS recording (300 seconds)
.\NiDaqClient.ps1 -Command 105 -Payload "300|GLD-1015"

# 4. Wait for completion...

# 5. Stop PACS
.\NiDaqClient.ps1 -Command 106
```

### Run Multiple Tests
```powershell
# Create script: RunBatch.ps1
$tests = @("GLD-1008", "GLD-1009", "GLD-1015")
foreach ($test in $tests) {
    .\NiDaqClient.ps1 -Command 102 -Payload $test
    Start-Sleep -Seconds 120
}
```

---

## 🔐 Security Notes

⚠️ **IMPORTANT:**
- ServerConfig.json contains passwords
- Protect file permissions: `icacls ServerConfig.json /grant:r "%USERNAME%:F" /inheritance:r`
- Use strong passwords
- Restrict network access via firewall
- Consider separate configs for production

---

## 📞 Quick Help

**Server not responding?**
→ Check logs: `Get-Content .\Logs\*.log -Tail 20`

**PsExec failing?**
→ Test manually: `psexec \\DUT_IP cmd /c "echo Test"`

**Test not found?**
→ Verify on DUT: `Test-Path C:\GLD\GLD-1015.bat`

**Network issues?**
→ Run: `.\Test-Connection.bat`

**Need full guide?**
→ Read: `STANDALONE-SERVER-GUIDE.md`

---

## 🏗️ Architecture Summary

**Standalone = Single File (671 lines)**
- ✅ Easy to deploy (one file)
- ✅ No dependencies
- ✅ All features included
- ✅ Hardcoded buffer size (1024 bytes)
- ✅ Perfect for quick setup

**Modular = 7 Files (Modules + Classes)**
- ✅ Better organization
- ✅ Easier to maintain
- ✅ Configurable buffer size (4096 bytes)
- ✅ Unit testable
- ✅ Better for complex projects

---

## Version

**NiDaq Server v2.0 - Standalone Edition**
- File: NiDaqServer.ps1 (671 lines)
- PowerShell 5.1+
- Last Updated: January 2026

---

**Print this card and keep it handy!** 📄
