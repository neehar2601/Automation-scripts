# NiDaq Server - Modular Edition

## Overview
This is the modular version of the NiDaq Server v2.0, reorganized into separate modules and classes for better maintainability and extensibility.

## Directory Structure

```
NiDaq_Server_PS/
├── NiDaqServer-Modular.ps1      # Main entry point
├── Start-ModularServer.bat       # Quick launcher
├── ServerConfig.json             # Configuration file
├── Modules/                      # PowerShell modules
│   ├── LoggingModule.psm1       # Logging functionality
│   ├── ConfigurationModule.psm1 # Configuration management
│   └── TCPServerModule.psm1     # TCP server engine
├── Classes/                      # PowerShell classes
│   ├── PACSController.ps1       # PACS integration
│   ├── RemoteExecutor.ps1       # Remote execution via PsExec
│   └── CommandHandler.ps1       # Command routing
├── Logs/                         # Log files directory
└── README-Modular.md            # This file
```

## Modules

### LoggingModule.psm1
**Functions:**
- `Write-Log` - Write log messages to console and file
- `Set-LogFile` - Set custom log file path
- `Get-LogFile` - Get current log file path

**Features:**
- Color-coded console output
- File logging with timestamps
- Multiple log levels (INFO, WARNING, ERROR, SUCCESS, DEBUG)

### ConfigurationModule.psm1
**Functions:**
- `Load-ServerConfig` - Load configuration from JSON
- `Save-ServerConfig` - Save configuration to JSON
- `Get-DefaultConfig` - Get default configuration
- `Test-ServerConfig` - Validate configuration

**Features:**
- Auto-generate default config if missing
- Configuration validation
- Structured JSON format

### TCPServerModule.psm1
**Functions:**
- `Start-TCPServer` - Start TCP server listener
- `Stop-TCPServer` - Stop TCP server

**Features:**
- Non-blocking client handling
- Configurable timeouts and buffer sizes
- Connection tracking and logging

## Classes

### PACSController
**Methods:**
- `IsRunning()` - Check if PACS is running
- `GetStatus()` - Get simple status string
- `GetDetailedStatus()` - Get detailed status with metrics
- `Start()` - Start PACS process
- `Stop()` - Stop PACS process
- `Restart()` - Restart PACS process
- `Record()` - Start PACS recording

**Features:**
- Process monitoring
- Memory and CPU tracking
- Auto-create result directories

### RemoteExecutor
**Methods:**
- `Execute()` - Execute command on remote machine
- `RunTest()` - Execute RunTest.ps1 with parameters
- `TestConnection()` - Test connectivity to remote machine
- `GetRemoteSystemInfo()` - Get remote system information
- `FileExists()` - Check if file exists on remote machine
- `BuildPsExecCommand()` - Build PsExec command string

**Features:**
- PsExec integration
- Execution timing and metrics
- Error handling with detailed results

### CommandHandler
**Methods:**
- `HandleCommand()` - Route commands to appropriate handlers
- `Handle_101()` to `Handle_113()` - Individual command handlers

**Supported Commands:**
- 101: Server Status
- 102: Execute Test
- 103: Start PACS
- 104: PACS Status
- 105: Start PACS Recording
- 106: Stop PACS
- 107: Transfer Results
- 108: Mark Test Complete
- 109: Set Temperature
- 110: Get Temperature
- 111: Copy Results (Network Share)
- 112: Execute Custom Command
- 113: Network Share Results Transfer

## Quick Start

### 1. Start the Server
```batch
Start-ModularServer.bat
```

Or using PowerShell directly:
```powershell
.\NiDaqServer-Modular.ps1
```

### 2. With Custom Parameters
```powershell
.\NiDaqServer-Modular.ps1 -Port 5000 -ServerHost "192.168.1.50"
```

### 3. Test Connection
```powershell
.\NiDaqClient.ps1 -Command 101
```

## Configuration

Edit `ServerConfig.json` to customize:

```json
{
  "Server": {
    "Host": "0.0.0.0",
    "Port": 55555,
    "MaxConnections": 10,
    "ReceiveTimeout": 300
  },
  "Client": {
    "DefaultIP": "192.168.1.100",
    "Username": "Administrator",
    "Password": "",
    "WorkingPath": "C:\\Test"
  },
  "PACS": {
    "Enabled": true,
    "ExePath": "C:\\Intel\\PACS\\pacs.exe",
    "ResultPath": "C:\\Test\\results"
  }
}
```

## Benefits of Modular Design

### 1. **Separation of Concerns**
- Each module has a single responsibility
- Easier to understand and maintain
- Clear module boundaries

### 2. **Reusability**
- Modules can be used independently
- Classes can be instantiated multiple times
- Easy to extend with new modules

### 3. **Testability**
- Each module can be tested in isolation
- Mock dependencies easily
- Better unit test coverage

### 4. **Maintainability**
- Smaller, focused files
- Easy to locate and fix bugs
- Clear code organization

### 5. **Extensibility**
- Add new modules without touching existing code
- Extend classes with inheritance
- Plugin-style architecture

## Development

### Adding a New Module
1. Create new `.psm1` file in `Modules/` directory
2. Define functions with proper documentation
3. Export functions using `Export-ModuleMember`
4. Import in `NiDaqServer-Modular.ps1`

Example:
```powershell
# Modules/DatabaseModule.psm1

function Connect-Database {
    param([string]$ConnectionString)
    # Implementation
}

Export-ModuleMember -Function Connect-Database
```

### Adding a New Class
1. Create new `.ps1` file in `Classes/` directory
2. Define class with methods and properties
3. Dot-source in `NiDaqServer-Modular.ps1`

Example:
```powershell
# Classes/DatabaseController.ps1

class DatabaseController {
    [string]$ConnectionString
    
    DatabaseController([string]$connStr) {
        $this.ConnectionString = $connStr
    }
    
    [void] Connect() {
        # Implementation
    }
}
```

### Adding a New Command Handler
1. Add method to `CommandHandler` class
2. Add case to `HandleCommand()` switch statement
3. Update documentation

Example:
```powershell
# In CommandHandler.ps1

[string] Handle_114() {
    Write-Log "Command 114: New Feature" -Level "INFO"
    # Implementation
    return "FEATURE_EXECUTED"
}

# In HandleCommand method, add:
"114" { $this.Handle_114() }
```

## Troubleshooting

### Module Not Found
Ensure you're running from the correct directory:
```powershell
cd "C:\Users\nnellika\OneDrive - Intel Corporation\Documents\GLD\NiDaq_Server_PS"
.\NiDaqServer-Modular.ps1
```

### Class Definition Error
Ensure classes are loaded before CommandHandler:
- PACSController.ps1 first
- RemoteExecutor.ps1 second
- CommandHandler.ps1 last

### Log File Permissions
If log writing fails, ensure `Logs/` directory exists and is writable.

## Comparison: Monolithic vs Modular

| Aspect | Monolithic | Modular |
|--------|-----------|---------|
| File Count | 1 file (670 lines) | 7 files (~100-200 lines each) |
| Maintainability | Hard to navigate | Easy to find and fix |
| Testability | Difficult | Each module testable |
| Reusability | Low | High |
| Extensibility | Requires editing main file | Add new modules |
| Code Organization | Single file | Logical separation |
| Debugging | Hard to isolate issues | Easy to trace |

## Next Steps

1. **Configure** - Edit `ServerConfig.json` with your settings
2. **Test** - Run the test suite to validate setup
3. **Deploy** - Copy to production environment
4. **Monitor** - Check logs in `Logs/` directory
5. **Extend** - Add custom modules as needed

## Support

For issues or questions:
- Check logs in `Logs/` directory
- Review configuration in `ServerConfig.json`
- Ensure all modules are present in correct directories
- Verify PowerShell version 5.1+

## Version History

- **v2.0-Modular** - Modular architecture with separated modules and classes
- **v2.0** - Monolithic PowerShell version (original)
- **v1.13** - Python version (legacy)
