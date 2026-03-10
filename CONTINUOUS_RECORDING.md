# Continuous Recording - Quick Start Scripts

## Simple 1-Hour Recording Loop

This folder contains scripts for running continuous 1-hour recording cycles.

### Quick Start

#### Basic Usage (1-hour cycles):
```powershell
.\ContinuousRecording.ps1
```

This will:
1. Start recording in continuous mode
2. Record for 1 hour
3. Stop recording automatically
4. Start a new 1-hour recording
5. Repeat until you press Ctrl+C

### Files Created

Each recording cycle creates:
- `recordings/recording_cycle1_20260225_140530.mp4`
- `recordings/recording_cycle2_20260225_150535.mp4`
- `recordings/recording_cycle3_20260225_160540.mp4`
- etc.

### Customization Options

#### Change Recording Duration (30 minutes):
```powershell
.\ContinuousRecording.ps1 -RecordingDuration 1800
```

#### Change Recording Duration (2 hours):
```powershell
.\ContinuousRecording.ps1 -RecordingDuration 7200
```

#### Use Custom Recorder Path:
```powershell
.\ContinuousRecording.ps1 -RecorderPath "C:\ScreenRecorder"
```

#### Use Custom Python Command:
```powershell
.\ContinuousRecording.ps1 -PythonCommand "python3"
```

#### Use Config File:
```powershell
.\ContinuousRecording.ps1 -ConfigFile "config_continuous.json"
```

#### Custom Log File:
```powershell
.\ContinuousRecording.ps1 -LogFile "my_recording_log.txt"
```

#### All Options Combined:
```powershell
.\ContinuousRecording.ps1 `
    -RecorderPath "C:\ScreenRecorder" `
    -PythonCommand "python3" `
    -RecordingDuration 3600 `
    -LogFile "hourly_recording.log"
```

### Stopping the Script

To stop the continuous recording loop:
1. Press **Ctrl+C** in the PowerShell window
2. The script will automatically stop the current recording
3. All files will be saved properly

### Log Files

The script creates two types of logs:

1. **Main Log** (`recording_log.txt`):
   - Script events
   - Recording start/stop times
   - Cycle information
   - Errors and warnings

2. **Recorder Logs**:
   - `recorder_output.log` - Python recorder output
   - `recorder_error.log` - Python recorder errors

### Example Output

```
[2026-02-25 14:05:30] [SUCCESS] Continuous Recording Loop Started
[2026-02-25 14:05:30] [INFO] Recording Duration: 01:00:00
[2026-02-25 14:05:30] [INFO] Recorder Path: C:\ScreenRecorder
[2026-02-25 14:05:30] [WARNING] Press Ctrl+C to stop the recording loop

[2026-02-25 14:05:30] [INFO] Starting Recording Cycle #1
[2026-02-25 14:05:30] [INFO] Filename: recording_cycle1_20260225_140530
[2026-02-25 14:05:30] [INFO] Duration: 01:00:00
[2026-02-25 14:05:33] [SUCCESS] Recording started successfully (PID: 12345)
[2026-02-25 14:05:33] [INFO] Recording in progress... Will stop in 01:00:00

[2026-02-25 14:06:33] [INFO] Cycle #1 - Elapsed: 00:01:00 | Remaining: 00:59:00
[2026-02-25 14:07:33] [INFO] Cycle #1 - Elapsed: 00:02:00 | Remaining: 00:58:00
...
[2026-02-25 15:05:33] [INFO] Recording duration reached. Stopping cycle #1...
[2026-02-25 15:05:38] [SUCCESS] Cycle #1 completed successfully
[2026-02-25 15:05:38] [INFO] Actual cycle duration: 01:00:05

[2026-02-25 15:05:43] [INFO] Starting Recording Cycle #2
...
```

### Common Durations

| Duration | Seconds | PowerShell Command |
|----------|---------|-------------------|
| 15 minutes | 900 | `-RecordingDuration 900` |
| 30 minutes | 1800 | `-RecordingDuration 1800` |
| 45 minutes | 2700 | `-RecordingDuration 2700` |
| 1 hour | 3600 | `-RecordingDuration 3600` (default) |
| 1.5 hours | 5400 | `-RecordingDuration 5400` |
| 2 hours | 7200 | `-RecordingDuration 7200` |
| 3 hours | 10800 | `-RecordingDuration 10800` |

### Scheduling with Task Scheduler

To run automatically at startup or scheduled time:

1. Open Task Scheduler
2. Create New Task
3. Set Trigger (e.g., At startup, Daily at 8 AM)
4. Set Action:
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\ScreenRecorder\ContinuousRecording.ps1"`
   - Start in: `C:\ScreenRecorder`

### Troubleshooting

#### Script Won't Start
```powershell
# Check execution policy
Get-ExecutionPolicy

# If restricted, set to RemoteSigned (as Administrator)
Set-ExecutionPolicy RemoteSigned -Force
```

#### Python Not Found
```powershell
# Test Python
python --version

# If not found, specify full path
.\ContinuousRecording.ps1 -PythonCommand "C:\Python39\python.exe"
```

#### Recording Not Stopping
- Make sure you press Ctrl+C in the PowerShell window
- Check `recorder_error.log` for errors
- Manually stop: `python screen_recorder.py stop`

#### Check if Recording is Active
```powershell
# In another PowerShell window
python screen_recorder.py status
```

### Advanced: Run as Background Service

To run silently in the background:

```powershell
# Start hidden (no window)
Start-Process powershell.exe `
    -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File ContinuousRecording.ps1" `
    -WindowStyle Hidden

# To stop, find and kill the process
Get-Process powershell | Where-Object { $_.MainWindowTitle -like "*ContinuousRecording*" } | Stop-Process
```

### Monitoring Recording Cycles

Create a monitoring script:

```powershell
# Monitor.ps1
while ($true) {
    Clear-Host
    Write-Host "=== Recording Status ===" -ForegroundColor Cyan
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    
    # Check status
    python screen_recorder.py status
    
    # Show latest log entries
    Write-Host ""
    Write-Host "=== Latest Log Entries ===" -ForegroundColor Cyan
    Get-Content recording_log.txt -Tail 10
    
    Write-Host ""
    Write-Host "Refreshing in 30 seconds... (Ctrl+C to exit)" -ForegroundColor Gray
    Start-Sleep -Seconds 30
}
```

### File Management

Recordings can get large. Consider:

1. **Automatic Cleanup** (delete recordings older than 7 days):
```powershell
Get-ChildItem recordings\*.mp4 | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | 
    Remove-Item -Force
```

2. **Move to Archive**:
```powershell
$archivePath = "\\FileServer\Archive\Recordings\$(Get-Date -Format 'yyyy-MM')"
Move-Item recordings\*.mp4 -Destination $archivePath
```

3. **Compress Old Files**:
```powershell
Compress-Archive -Path recordings\*.mp4 -DestinationPath "recordings_$(Get-Date -Format 'yyyyMMdd').zip"
```

## Summary

The `ContinuousRecording.ps1` script provides:
- ✅ Automatic 1-hour recording cycles
- ✅ Automatic start/stop between cycles
- ✅ Detailed logging
- ✅ Clean shutdown on Ctrl+C
- ✅ Customizable duration
- ✅ Error handling and recovery
- ✅ Multiple recording cycles with unique filenames

Perfect for:
- All-day monitoring
- Continuous surveillance
- Long-term screen recording
- Automated recording schedules

---

**Version**: 1.0  
**Last Updated**: February 25, 2026
