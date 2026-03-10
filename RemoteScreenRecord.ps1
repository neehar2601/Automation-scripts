<#
.SYNOPSIS
    Simple remote screen recorder controller for executing Python screen recorder on remote machines.

.DESCRIPTION
    Connects to a remote computer and executes the screen_recorder.py script.
    Supports start, stop, and status commands with customizable recording parameters.

.PARAMETER ComputerName
    The name or IP address of the remote computer.

.PARAMETER Command
    The command to execute: start, stop, or status.

.PARAMETER ScriptPath
    Full path to screen_recorder.py on the remote machine.

.PARAMETER RecordingName
    Name for the recording (used with start command).

.PARAMETER Mode
    Recording mode: continuous or interval (default: continuous).

.PARAMETER Duration
    Recording duration in seconds for interval mode (default: 30).

.PARAMETER Interval
    Interval in seconds for interval mode (default: 60).

.PARAMETER SaveMode
    Save mode for interval recording: single or multiple (default: single).

.PARAMETER FPS
    Frames per second (default: 20).

.PARAMETER Credential
    PSCredential object for authentication. If not provided, will prompt.

.EXAMPLE
    .\RemoteScreenRecord.ps1 -ComputerName "192.168.1.100" -Command start -ScriptPath "C:\Scripts\screen_recorder.py"

.EXAMPLE
    .\RemoteScreenRecord.ps1 -ComputerName "DESKTOP-PC" -Command start -RecordingName "meeting" -Mode continuous -ScriptPath "C:\Tools\screen_recorder.py"

.EXAMPLE
    .\RemoteScreenRecord.ps1 -ComputerName "192.168.1.100" -Command start -Mode interval -Duration 30 -Interval 300 -ScriptPath "C:\Scripts\screen_recorder.py"

.EXAMPLE
    .\RemoteScreenRecord.ps1 -ComputerName "192.168.1.100" -Command stop -ScriptPath "C:\Scripts\screen_recorder.py"

.EXAMPLE
    .\RemoteScreenRecord.ps1 -ComputerName "192.168.1.100" -Command status -ScriptPath "C:\Scripts\screen_recorder.py"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Remote computer name or IP address")]
    [string]$ComputerName,

    [Parameter(Mandatory=$true, HelpMessage="Command to execute: start, stop, or status")]
    [ValidateSet('start', 'stop', 'status')]
    [string]$Command,

    [Parameter(Mandatory=$true, HelpMessage="Full path to screen_recorder.py on remote machine")]
    [string]$ScriptPath,

    [Parameter(Mandatory=$false, HelpMessage="Recording name (for start command)")]
    [string]$RecordingName = "",

    [Parameter(Mandatory=$false, HelpMessage="Recording mode: continuous or interval")]
    [ValidateSet('continuous', 'interval')]
    [string]$Mode = "continuous",

    [Parameter(Mandatory=$false, HelpMessage="Duration in seconds (interval mode)")]
    [int]$Duration = 30,

    [Parameter(Mandatory=$false, HelpMessage="Interval in seconds (interval mode)")]
    [int]$Interval = 60,

    [Parameter(Mandatory=$false, HelpMessage="Save mode: single or multiple (interval mode)")]
    [ValidateSet('single', 'multiple')]
    [string]$SaveMode = "single",

    [Parameter(Mandatory=$false, HelpMessage="Frames per second")]
    [int]$FPS = 20,

    [Parameter(Mandatory=$false, HelpMessage="Credential for remote authentication")]
    [System.Management.Automation.PSCredential]$Credential
)

# Function to execute command on remote machine
function Invoke-RemoteScreenRecorder {
    param(
        [string]$Computer,
        [string]$PythonScript,
        [string]$Cmd,
        [hashtable]$Parameters,
        [System.Management.Automation.PSCredential]$Cred
    )

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Remote Screen Recorder" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Target Computer: $Computer" -ForegroundColor Yellow
    Write-Host "Command: $Cmd" -ForegroundColor Yellow
    Write-Host "Script Path: $PythonScript" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Build Python command
    $pythonCmd = "python `"$PythonScript`" $Cmd"

    if ($Cmd -eq "start") {
        if ($Parameters.RecordingName) {
            $pythonCmd += " $($Parameters.RecordingName)"
        }
        $pythonCmd += " --mode $($Parameters.Mode)"
        
        if ($Parameters.Mode -eq "interval") {
            $pythonCmd += " --duration $($Parameters.Duration)"
            $pythonCmd += " --interval $($Parameters.Interval)"
            $pythonCmd += " --save-mode $($Parameters.SaveMode)"
        }
        
        $pythonCmd += " --fps $($Parameters.FPS)"

        Write-Host "Recording Parameters:" -ForegroundColor Green
        Write-Host "  Mode: $($Parameters.Mode)" -ForegroundColor Gray
        if ($Parameters.Mode -eq "interval") {
            Write-Host "  Duration: $($Parameters.Duration) seconds" -ForegroundColor Gray
            Write-Host "  Interval: $($Parameters.Interval) seconds" -ForegroundColor Gray
            Write-Host "  Save Mode: $($Parameters.SaveMode)" -ForegroundColor Gray
        }
        Write-Host "  FPS: $($Parameters.FPS)" -ForegroundColor Gray
        Write-Host ""
    }

    Write-Host "Executing command on remote machine..." -ForegroundColor Green
    Write-Host "Command: $pythonCmd" -ForegroundColor Gray
    Write-Host ""

    try {
        # Test remote connection first
        Write-Host "Testing connection to $Computer..." -ForegroundColor Yellow
        
        $testParams = @{
            ComputerName = $Computer
            ErrorAction = 'Stop'
        }
        if ($Cred) {
            $testParams.Credential = $Cred
        }

        $testResult = Test-WSMan @testParams
        Write-Host "[SUCCESS] Connection successful!" -ForegroundColor Green
        Write-Host ""

        # Execute command on remote machine
        $scriptBlock = {
            param($command)
            
            # Change to script directory
            $scriptDir = Split-Path -Parent $using:PythonScript
            Set-Location $scriptDir
            
            # Execute command and capture output
            $output = Invoke-Expression $command 2>&1
            
            return @{
                Output = $output
                ExitCode = $LASTEXITCODE
            }
        }

        $invokeParams = @{
            ComputerName = $Computer
            ScriptBlock = $scriptBlock
            ArgumentList = $pythonCmd
            ErrorAction = 'Stop'
        }
        if ($Cred) {
            $invokeParams.Credential = $Cred
        }

        $result = Invoke-Command @invokeParams

        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Remote Execution Result" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        if ($result.Output) {
            Write-Host $result.Output
        }
        
        Write-Host ""
        Write-Host "Exit Code: $($result.ExitCode)" -ForegroundColor $(if ($result.ExitCode -eq 0) { "Green" } else { "Red" })
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""

        return $result.ExitCode -eq 0

    } catch {
        Write-Host ""
        Write-Host "[ERROR] Failed to execute command on remote machine" -ForegroundColor Red
        Write-Host "Error Details: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Message -like "*Access is denied*") {
            Write-Host ""
            Write-Host "Troubleshooting:" -ForegroundColor Yellow
            Write-Host "1. Ensure you have administrator privileges on the remote machine" -ForegroundColor Gray
            Write-Host "2. Use -Credential parameter to provide authentication" -ForegroundColor Gray
            Write-Host "3. Example: -Credential (Get-Credential)" -ForegroundColor Gray
        } elseif ($_.Exception.Message -like "*cannot be resolved*") {
            Write-Host ""
            Write-Host "Troubleshooting:" -ForegroundColor Yellow
            Write-Host "1. Verify the computer name or IP address is correct" -ForegroundColor Gray
            Write-Host "2. Ensure the remote machine is powered on and network accessible" -ForegroundColor Gray
            Write-Host "3. Try using IP address instead of hostname" -ForegroundColor Gray
        } elseif ($_.Exception.Message -like "*WinRM*") {
            Write-Host ""
            Write-Host "Troubleshooting:" -ForegroundColor Yellow
            Write-Host "1. Enable PowerShell Remoting on remote machine:" -ForegroundColor Gray
            Write-Host "   Enable-PSRemoting -Force" -ForegroundColor Gray
            Write-Host "2. Check Windows Remote Management service is running" -ForegroundColor Gray
            Write-Host "3. Configure firewall to allow WinRM (port 5985/5986)" -ForegroundColor Gray
        }
        
        Write-Host ""
        return $false
    }
}

# Main execution
try {
    # Prompt for credentials if not provided
    if (-not $Credential) {
        Write-Host "No credentials provided. You may be prompted for authentication..." -ForegroundColor Yellow
        Write-Host "Tip: Use -Credential (Get-Credential) to provide credentials upfront" -ForegroundColor Gray
        Write-Host ""
    }

    # Build parameters hashtable
    $params = @{
        RecordingName = $RecordingName
        Mode = $Mode
        Duration = $Duration
        Interval = $Interval
        SaveMode = $SaveMode
        FPS = $FPS
    }

    # Execute remote command
    $success = Invoke-RemoteScreenRecorder `
        -Computer $ComputerName `
        -PythonScript $ScriptPath `
        -Cmd $Command `
        -Parameters $params `
        -Cred $Credential

    if ($success) {
        Write-Host "[COMPLETED] Command completed successfully!" -ForegroundColor Green
        
        if ($Command -eq "start") {
            Write-Host ""
            Write-Host "The screen recorder is now running on $ComputerName" -ForegroundColor Green
            Write-Host "To stop it, run:" -ForegroundColor Yellow
            Write-Host "  .\RemoteScreenRecord.ps1 -ComputerName `"$ComputerName`" -Command stop -ScriptPath `"$ScriptPath`"" -ForegroundColor Gray
        }
    } else {
        Write-Host "[ERROR] Command failed!" -ForegroundColor Red
        exit 1
    }

} catch {
    Write-Host ""
    Write-Host "[FATAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

