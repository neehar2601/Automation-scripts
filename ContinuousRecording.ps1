<#
.SYNOPSIS
    Continuous 1-Hour Recording Loop Script

.DESCRIPTION
    This script runs the Python screen recorder in continuous cycles of 1 hour.
    It will keep recording 1 hour, stop, then start again until you stop the script.
    
    Each recording will be saved as a separate file with timestamp.

.PARAMETER RecorderPath
    Path to the screen recorder directory. Default: Current directory

.PARAMETER PythonCommand
    Python command to use. Default: python

.PARAMETER ConfigFile
    Configuration file to use. Default: None (uses command-line args)

.PARAMETER RecordingDuration
    Duration of each recording cycle in seconds. Default: 3600 (1 hour)

.PARAMETER LogFile
    Path to log file. Default: recording_log.txt

.EXAMPLE
    .\ContinuousRecording.ps1
    Runs continuous 1-hour recordings with default settings.

.EXAMPLE
    .\ContinuousRecording.ps1 -RecordingDuration 1800
    Runs continuous 30-minute recordings.

.EXAMPLE
    .\ContinuousRecording.ps1 -RecorderPath "C:\ScreenRecorder" -PythonCommand "python3"
    Runs with custom path and Python command.

.NOTES
    Author: Screen Recorder Continuous Loop
    Version: 1.0
    Date: February 25, 2026
    
    To stop: Press Ctrl+C in the PowerShell window
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$RecorderPath = ".",
    
    [Parameter(Mandatory = $false)]
    [string]$PythonCommand = "python",
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = $null,
    
    [Parameter(Mandatory = $false)]
    [int]$RecordingDuration = 3600,  # 1 hour in seconds
    
    [Parameter(Mandatory = $false)]
    [string]$LogFile = "recording_log.txt"
)

# Function to write log messages
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console with color
    switch ($Level) {
        "INFO"    { Write-Host $logMessage -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        default   { Write-Host $logMessage }
    }
    
    # Write to log file
    $logMessage | Out-File -FilePath $LogFile -Append
}

# Function to format duration
function Format-Duration {
    param([int]$Seconds)
    
    $hours = [math]::Floor($Seconds / 3600)
    $minutes = [math]::Floor(($Seconds % 3600) / 60)
    $secs = $Seconds % 60
    
    return ("{0:D2}:{1:D2}:{2:D2}" -f [int]$hours, [int]$minutes, [int]$secs)
}

# Function to start recording
function Start-Recording {
    param(
        [string]$FileName
    )
    
    # Make sure no previous PID file exists
    $pidFile = Join-Path $RecorderPath ".screen_recorder.pid"
    if (Test-Path $pidFile) {
        Write-Log "Cleaning up stale PID file..." "WARNING"
        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    }
    
    # Make sure no stop file exists
    $stopFile = Join-Path $RecorderPath ".screen_recorder.stop"
    if (Test-Path $stopFile) {
        Remove-Item $stopFile -Force -ErrorAction SilentlyContinue
    }
    
    Write-Log "Starting recording: $FileName" "INFO"
    
    # Build command arguments
    $arguments = @("screen_recorder.py", "start", $FileName)
    
    if ($ConfigFile) {
        $arguments += @("-c", $ConfigFile)
    } else {
        # Use command-line arguments for continuous mode
        $arguments += @("--mode", "continuous")
    }
    
    $argumentString = $arguments -join " "
    
    Write-Log "Command: $PythonCommand $argumentString" "INFO"
    
    try {
        # Start Python recorder in background
        $process = Start-Process -FilePath $PythonCommand `
                                 -ArgumentList $argumentString `
                                 -WorkingDirectory $RecorderPath `
                                 -PassThru `
                                 -NoNewWindow `
                                 -RedirectStandardOutput "recorder_output.log" `
                                 -RedirectStandardError "recorder_error.log"
        
        # Wait a moment to check if process started successfully
        Start-Sleep -Seconds 3
        
        if ($process.HasExited) {
            Write-Log "Recording process failed to start or exited immediately" "ERROR"
            
            # Check error log
            if (Test-Path "recorder_error.log") {
                $errorContent = Get-Content "recorder_error.log" -Raw
                if ($errorContent) {
                    Write-Log "Error details: $errorContent" "ERROR"
                }
            }
            
            return $null
        }
        
        # Verify PID file was created
        Start-Sleep -Seconds 1
        if (-not (Test-Path $pidFile)) {
            Write-Log "Warning: PID file not created, recording may not have started properly" "WARNING"
        }
        
        Write-Log "Recording started successfully (PID: $($process.Id))" "SUCCESS"
        return $process
    }
    catch {
        Write-Log "Error starting recording: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Function to stop recording
function Stop-Recording {
    Write-Log "Sending stop signal to recorder..." "INFO"
    
    $arguments = @("screen_recorder.py", "stop")
    $argumentString = $arguments -join " "
    
    try {
        $output = & $PythonCommand $argumentString 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Stop signal sent successfully" "SUCCESS"
        } else {
            Write-Log "Stop command completed with warnings" "WARNING"
        }
        
        # Wait for recording to actually stop and cleanup
        Start-Sleep -Seconds 3
        
        # Verify PID file is gone
        $pidFile = Join-Path $RecorderPath ".screen_recorder.pid"
        $maxWait = 10
        $waited = 0
        
        while ((Test-Path $pidFile) -and ($waited -lt $maxWait)) {
            Write-Log "Waiting for recorder to cleanup (PID file still exists)..." "INFO"
            Start-Sleep -Seconds 1
            $waited++
        }
        
        if (Test-Path $pidFile) {
            Write-Log "PID file still exists after $maxWait seconds, forcing cleanup..." "WARNING"
            Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
        }
        
        # Also cleanup stop file if it exists
        $stopFile = Join-Path $RecorderPath ".screen_recorder.stop"
        if (Test-Path $stopFile) {
            Remove-Item $stopFile -Force -ErrorAction SilentlyContinue
        }
        
        Write-Log "Recording stopped and cleaned up" "SUCCESS"
        
        return $true
    }
    catch {
        Write-Log "Error stopping recording: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to check if recorder is running
function Test-RecorderRunning {
    $pidFile = Join-Path $RecorderPath ".screen_recorder.pid"
    
    if (Test-Path $pidFile) {
        try {
            $pid = Get-Content $pidFile
            $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
            
            if ($process) {
                return $true
            }
        }
        catch {
            # PID file exists but process doesn't
        }
    }
    
    return $false
}

# Cleanup function for when script is stopped
function Cleanup {
    Write-Log "Cleanup initiated..." "WARNING"
    
    if (Test-RecorderRunning) {
        Write-Log "Stopping active recording..." "INFO"
        Stop-Recording | Out-Null
    }
    
    Write-Log "Script stopped by user" "WARNING"
    
    if ($cycleCount -gt 0) {
        Write-Log "Total recording cycles completed: $cycleCount" "INFO"
        $totalTime = $cycleCount * $RecordingDuration
        Write-Log "Total recording time: $(Format-Duration $totalTime)" "INFO"
    }
}

# Register cleanup on Ctrl+C
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Cleanup
}

# Trap Ctrl+C
trap {
    Cleanup
    break
}

# Main script
try {
    # Change to recorder directory
    Push-Location $RecorderPath
    
    Write-Log "=====================================" "INFO"
    Write-Log "Continuous Recording Loop Started" "SUCCESS"
    Write-Log "=====================================" "INFO"
    Write-Log "Recording Duration: $(Format-Duration $RecordingDuration)" "INFO"
    Write-Log "Recorder Path: $((Get-Location).Path)" "INFO"
    Write-Log "Python Command: $PythonCommand" "INFO"
    Write-Log "Log File: $LogFile" "INFO"
    Write-Log "" "INFO"
    Write-Log "Press Ctrl+C to stop the recording loop" "WARNING"
    Write-Log "=====================================" "INFO"
    Write-Log "" "INFO"
    
    $cycleCount = 0
    $scriptStartTime = Get-Date
    
    # Continuous loop
    while ($true) {
        $cycleCount++
        $cycleStartTime = Get-Date
        
        # Generate filename with timestamp and cycle number
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = "recording_cycle${cycleCount}_${timestamp}"
        
        Write-Log "=====================================" "INFO"
        Write-Log "Starting Recording Cycle #$cycleCount" "INFO"
        Write-Log "Filename: $fileName" "INFO"
        Write-Log "Duration: $(Format-Duration $RecordingDuration)" "INFO"
        Write-Log "=====================================" "INFO"
        
        # Start recording
        $recordingProcess = Start-Recording -FileName $fileName
        
        if (-not $recordingProcess) {
            Write-Log "Failed to start recording. Retrying in 10 seconds..." "ERROR"
            Start-Sleep -Seconds 10
            continue
        }
        
        # Wait for the specified duration
        Write-Log "Recording in progress... Will stop in $(Format-Duration $RecordingDuration)" "INFO"
        
        # Display countdown every minute
        $elapsed = 0
        $updateInterval = 60  # Update every 60 seconds
        
        while ($elapsed -lt $RecordingDuration) {
            Start-Sleep -Seconds 1
            $elapsed++
            
            # Update status every minute
            if ($elapsed % $updateInterval -eq 0) {
                $remaining = $RecordingDuration - $elapsed
                Write-Log "Cycle #$cycleCount - Elapsed: $(Format-Duration $elapsed) | Remaining: $(Format-Duration $remaining)" "INFO"
            }
            
            # Check if process is still running
            if ($recordingProcess.HasExited) {
                Write-Log "Recording process exited unexpectedly!" "ERROR"
                break
            }
        }
        
        Write-Log "Recording duration reached. Stopping cycle #$cycleCount..." "INFO"
        
        # Stop recording
        $stopSuccess = Stop-Recording
        
        if ($stopSuccess) {
            $cycleEndTime = Get-Date
            $cycleDuration = ($cycleEndTime - $cycleStartTime).TotalSeconds
            
            Write-Log "Cycle #$cycleCount completed successfully" "SUCCESS"
            Write-Log "Actual cycle duration: $(Format-Duration ([int]$cycleDuration))" "INFO"
            
            # Brief pause before next cycle
            Write-Log "Waiting 10 seconds before next cycle..." "INFO"
            Start-Sleep -Seconds 10
        } else {
            Write-Log "Error stopping cycle #$cycleCount. Waiting 10 seconds..." "ERROR"
            Start-Sleep -Seconds 10
        }
        
        Write-Log "" "INFO"
    }
}
catch {
    Write-Log "Unexpected error: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
}
finally {
    Cleanup
    Pop-Location
}
