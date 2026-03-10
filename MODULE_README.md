# RemoteScreenRecorder PowerShell Module

A PowerShell module for remotely controlling screen_recorder.py on Windows machines via PowerShell Remoting.

## Module Overview

This module provides functions to:
- Start screen recording on remote computers
- Stop screen recording on remote computers
- Check recorder status on remote computers
- Batch operations on multiple computers simultaneously

## Installation

### Option 1: Import Module Directly
```powershell
Import-Module .\RemoteScreenRecorder.psm1
```

### Option 2: Install to PowerShell Modules Directory
```powershell
# Copy to user modules directory
$modulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\RemoteScreenRecorder"
New-Item -ItemType Directory -Path $modulePath -Force
Copy-Item .\RemoteScreenRecorder.psm1 -Destination $modulePath

# Import module
Import-Module RemoteScreenRecorder
```

## Prerequisites

1. **PowerShell Remoting** must be enabled on remote machines:
```powershell
Enable-PSRemoting -Force
```

2. **Python and screen_recorder.py** must be installed on remote machines

3. **Network access** and appropriate **credentials** for remote machines

## Functions

### 1. Start-RemoteScreenRecorder

Starts screen recording on a single remote computer.

**Parameters:**
- `ComputerName` - Remote computer name or IP (required)
- `ScriptPath` - Full path to screen_recorder.py on remote machine (required)
- `RecordingName` - Optional recording name
- `Mode` - Recording mode: continuous or interval (default: continuous)
- `Duration` - Duration in seconds for interval mode (default: 30)
- `Interval` - Interval in seconds for interval mode (default: 60)
- `SaveMode` - Save mode: single or multiple (default: single)
- `FPS` - Frames per second (default: 20)
- `Credential` - Credentials for authentication

**Examples:**
```powershell
# Basic continuous recording
Start-RemoteScreenRecorder -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py"

# Named recording
Start-RemoteScreenRecorder -ComputerName "PC01" -ScriptPath "C:\Scripts\screen_recorder.py" -RecordingName "meeting"

# Interval mode
Start-RemoteScreenRecorder -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py" -Mode interval -Duration 30 -Interval 300

# With credentials
$cred = Get-Credential
Start-RemoteScreenRecorder -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py" -Credential $cred
```

---

### 2. Stop-RemoteScreenRecorder

Stops screen recording on a remote computer.

**Parameters:**
- `ComputerName` - Remote computer name or IP (required)
- `ScriptPath` - Full path to screen_recorder.py on remote machine (required)
- `Credential` - Credentials for authentication

**Examples:**
```powershell
# Stop recording
Stop-RemoteScreenRecorder -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py"

# With credentials
Stop-RemoteScreenRecorder -ComputerName "PC01" -ScriptPath "C:\Scripts\screen_recorder.py" -Credential $cred
```

---

### 3. Get-RemoteScreenRecorderStatus

Checks if screen recorder is running on a remote computer.

**Parameters:**
- `ComputerName` - Remote computer name or IP (required)
- `ScriptPath` - Full path to screen_recorder.py on remote machine (required)
- `Credential` - Credentials for authentication

**Examples:**
```powershell
# Check status
Get-RemoteScreenRecorderStatus -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py"

# With credentials
Get-RemoteScreenRecorderStatus -ComputerName "PC01" -ScriptPath "C:\Scripts\screen_recorder.py" -Credential $cred
```

---

### 4. Start-RemoteScreenRecorderBatch

Starts screen recording on multiple remote computers simultaneously.

**Parameters:**
- `ComputerNames` - Array of computer names or IPs (required)
- `ScriptPath` - Full path to screen_recorder.py on remote machines (required)
- All other parameters same as Start-RemoteScreenRecorder

**Examples:**
```powershell
# Start recording on multiple computers
$computers = @("PC01", "PC02", "PC03")
Start-RemoteScreenRecorderBatch -ComputerNames $computers -ScriptPath "C:\Scripts\screen_recorder.py"

# Interval mode on multiple computers
$computers = @("192.168.1.100", "192.168.1.101", "192.168.1.102")
Start-RemoteScreenRecorderBatch -ComputerNames $computers -ScriptPath "C:\Scripts\screen_recorder.py" -Mode interval -Duration 30 -Interval 300

# With credentials
$cred = Get-Credential
Start-RemoteScreenRecorderBatch -ComputerNames $computers -ScriptPath "C:\Scripts\screen_recorder.py" -Credential $cred
```

---

### 5. Stop-RemoteScreenRecorderBatch

Stops screen recording on multiple remote computers simultaneously.

**Parameters:**
- `ComputerNames` - Array of computer names or IPs (required)
- `ScriptPath` - Full path to screen_recorder.py on remote machines (required)
- `Credential` - Credentials for authentication

**Examples:**
```powershell
# Stop recording on multiple computers
$computers = @("PC01", "PC02", "PC03")
Stop-RemoteScreenRecorderBatch -ComputerNames $computers -ScriptPath "C:\Scripts\screen_recorder.py"

# With credentials
Stop-RemoteScreenRecorderBatch -ComputerNames $computers -ScriptPath "C:\Scripts\screen_recorder.py" -Credential $cred
```

## Complete Workflow Examples

### Example 1: Single Computer Recording Session
```powershell
# Import module
Import-Module .\RemoteScreenRecorder.psm1

# Start recording
Start-RemoteScreenRecorder -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py" -RecordingName "training_session"

# Check status
Get-RemoteScreenRecorderStatus -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py"

# Stop recording when done
Stop-RemoteScreenRecorder -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py"
```

### Example 2: Batch Recording Multiple Computers
```powershell
# Import module
Import-Module .\RemoteScreenRecorder.psm1

# Define computers
$computers = @("PC01", "PC02", "PC03", "PC04")

# Start recording on all
$results = Start-RemoteScreenRecorderBatch -ComputerNames $computers -ScriptPath "C:\Scripts\screen_recorder.py" -Mode continuous

# Wait for recording to complete...
Start-Sleep -Seconds 3600  # Record for 1 hour

# Stop recording on all
Stop-RemoteScreenRecorderBatch -ComputerNames $computers -ScriptPath "C:\Scripts\screen_recorder.py"
```

### Example 3: Interval Recording with Credentials
```powershell
# Import module
Import-Module .\RemoteScreenRecorder.psm1

# Get credentials once
$cred = Get-Credential

# Start interval recording
Start-RemoteScreenRecorder `
    -ComputerName "192.168.1.100" `
    -ScriptPath "C:\Scripts\screen_recorder.py" `
    -Mode interval `
    -Duration 30 `
    -Interval 300 `
    -SaveMode multiple `
    -FPS 20 `
    -Credential $cred

# Check status periodically
Get-RemoteScreenRecorderStatus -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py" -Credential $cred

# Stop when done
Stop-RemoteScreenRecorder -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py" -Credential $cred
```

### Example 4: Recording with Error Handling
```powershell
Import-Module .\RemoteScreenRecorder.psm1

$computers = @("PC01", "PC02", "PC03")
$scriptPath = "C:\Scripts\screen_recorder.py"

# Start batch recording
$startResults = Start-RemoteScreenRecorderBatch -ComputerNames $computers -ScriptPath $scriptPath

# Check which ones succeeded
$successfulComputers = $startResults.Keys | Where-Object { $startResults[$_] -eq $true }
$failedComputers = $startResults.Keys | Where-Object { $startResults[$_] -eq $false }

Write-Host "Started successfully on: $($successfulComputers -join ', ')" -ForegroundColor Green
if ($failedComputers.Count -gt 0) {
    Write-Host "Failed to start on: $($failedComputers -join ', ')" -ForegroundColor Red
}

# Later, stop only the successful ones
if ($successfulComputers.Count -gt 0) {
    Stop-RemoteScreenRecorderBatch -ComputerNames $successfulComputers -ScriptPath $scriptPath
}
```

## Troubleshooting

### Error: Cannot connect to remote computer
**Solution:**
1. Verify the computer is online: `Test-Connection -ComputerName "192.168.1.100"`
2. Enable PowerShell Remoting on remote machine: `Enable-PSRemoting -Force`
3. Check firewall allows WinRM (ports 5985/5986)

### Error: Access is denied
**Solution:**
1. Use credentials with administrator privileges
2. Add `-Credential (Get-Credential)` parameter
3. Verify user has access to remote machine

### Error: Python command not found
**Solution:**
1. Ensure Python is installed on remote machine
2. Add Python to PATH on remote machine
3. Or use full path to python.exe in the module

### Error: screen_recorder.py not found
**Solution:**
1. Verify the ScriptPath is correct
2. Use absolute paths (e.g., `C:\Scripts\screen_recorder.py`)
3. Ensure the script exists on the remote machine

## Module Functions Summary

| Function | Purpose | Single/Batch |
|----------|---------|--------------|
| Start-RemoteScreenRecorder | Start recording | Single |
| Stop-RemoteScreenRecorder | Stop recording | Single |
| Get-RemoteScreenRecorderStatus | Check status | Single |
| Start-RemoteScreenRecorderBatch | Start recording | Batch |
| Stop-RemoteScreenRecorderBatch | Stop recording | Batch |

## Features

- Clean output with color-coded status messages
- Connection testing before execution
- Error handling with descriptive messages
- Batch operations for multiple computers
- Support for all screen recorder modes
- Credential management
- Exit code validation

## Best Practices

1. **Import once per session:** Import the module at the start of your PowerShell session
2. **Use credentials securely:** Store credentials in variables rather than typing repeatedly
3. **Test connection first:** Use `Test-Connection` before batch operations
4. **Handle errors:** Check return values for batch operations
5. **Use absolute paths:** Always use full paths for ScriptPath parameter

## Version History

- **v1.0** (February 25, 2026) - Initial release
  - Five core functions
  - Batch operations support
  - Full parameter support for all recording modes

---

**Note:** This module requires PowerShell 5.1 or higher and uses PowerShell Remoting (WinRM).
