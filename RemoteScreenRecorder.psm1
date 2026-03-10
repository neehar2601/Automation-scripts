<#
.SYNOPSIS
    PowerShell module for remote screen recorder control.

.DESCRIPTION
    This module provides functions to start, stop, and check status of 
    screen_recorder.py on remote Windows machines via PowerShell Remoting.

.NOTES
    Version: 1.0
    Author: Screen Recorder Team
    Date: February 25, 2026
#>

# Private helper function to build Python command
function Build-PythonCommand {
    param(
        [string]$ScriptPath,
        [string]$Command,
        [hashtable]$Parameters
    )

    $pythonCmd = "python `"$ScriptPath`" $Command"

    if ($Command -eq "start") {
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
    }

    return $pythonCmd
}

# Private helper function to test remote connection
function Test-RemoteConnection {
    param(
        [string]$ComputerName,
        [System.Management.Automation.PSCredential]$Credential
    )

    try {
        $testParams = @{
            ComputerName = $ComputerName
            ErrorAction = 'Stop'
        }
        if ($Credential) {
            $testParams.Credential = $Credential
        }

        $null = Test-WSMan @testParams
        return $true
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
    Starts screen recording on a remote computer.

.DESCRIPTION
    Connects to a remote computer and starts the Python screen recorder with specified parameters.

.PARAMETER ComputerName
    The name or IP address of the remote computer.

.PARAMETER ScriptPath
    Full path to screen_recorder.py on the remote machine.

.PARAMETER RecordingName
    Optional name for the recording. If not provided, auto-generated.

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
    PSCredential object for authentication. If not provided, will use current credentials.

.EXAMPLE
    Start-RemoteScreenRecorder -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py"

.EXAMPLE
    Start-RemoteScreenRecorder -ComputerName "PC01" -ScriptPath "C:\Scripts\screen_recorder.py" -RecordingName "meeting" -Mode continuous

.EXAMPLE
    Start-RemoteScreenRecorder -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py" -Mode interval -Duration 30 -Interval 300
#>
function Start-RemoteScreenRecorder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,

        [Parameter(Mandatory=$false)]
        [string]$RecordingName = "",

        [Parameter(Mandatory=$false)]
        [ValidateSet('continuous', 'interval')]
        [string]$Mode = "continuous",

        [Parameter(Mandatory=$false)]
        [int]$Duration = 30,

        [Parameter(Mandatory=$false)]
        [int]$Interval = 60,

        [Parameter(Mandatory=$false)]
        [ValidateSet('single', 'multiple')]
        [string]$SaveMode = "single",

        [Parameter(Mandatory=$false)]
        [int]$FPS = 20,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Start Remote Screen Recorder" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Target: $ComputerName" -ForegroundColor Yellow
    Write-Host "Script: $ScriptPath" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Test connection
    Write-Host "Testing connection to $ComputerName..." -ForegroundColor Yellow
    if (-not (Test-RemoteConnection -ComputerName $ComputerName -Credential $Credential)) {
        Write-Host "[ERROR] Cannot connect to $ComputerName" -ForegroundColor Red
        Write-Host "Ensure PowerShell Remoting is enabled on the remote machine" -ForegroundColor Gray
        return $false
    }
    Write-Host "[SUCCESS] Connection established" -ForegroundColor Green
    Write-Host ""

    # Build parameters
    $params = @{
        RecordingName = $RecordingName
        Mode = $Mode
        Duration = $Duration
        Interval = $Interval
        SaveMode = $SaveMode
        FPS = $FPS
    }

    # Build command
    $pythonCmd = Build-PythonCommand -ScriptPath $ScriptPath -Command "start" -Parameters $params

    # Display parameters
    Write-Host "Recording Parameters:" -ForegroundColor Green
    Write-Host "  Mode: $Mode" -ForegroundColor Gray
    if ($Mode -eq "interval") {
        Write-Host "  Duration: $Duration seconds" -ForegroundColor Gray
        Write-Host "  Interval: $Interval seconds" -ForegroundColor Gray
        Write-Host "  Save Mode: $SaveMode" -ForegroundColor Gray
    }
    Write-Host "  FPS: $FPS" -ForegroundColor Gray
    Write-Host ""

    Write-Host "Starting recorder on remote machine..." -ForegroundColor Green
    Write-Host "Command: $pythonCmd" -ForegroundColor Gray
    Write-Host ""

    try {
        $scriptBlock = {
            param($command, $scriptPath)
            
            $scriptDir = Split-Path -Parent $scriptPath
            Set-Location $scriptDir
            
            $output = Invoke-Expression $command 2>&1
            
            return @{
                Output = $output
                ExitCode = $LASTEXITCODE
            }
        }

        $invokeParams = @{
            ComputerName = $ComputerName
            ScriptBlock = $scriptBlock
            ArgumentList = $pythonCmd, $ScriptPath
            ErrorAction = 'Stop'
        }
        if ($Credential) {
            $invokeParams.Credential = $Credential
        }

        $result = Invoke-Command @invokeParams

        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Result" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        if ($result.Output) {
            Write-Host $result.Output
        }
        
        Write-Host ""
        Write-Host "Exit Code: $($result.ExitCode)" -ForegroundColor $(if ($result.ExitCode -eq 0) { "Green" } else { "Red" })
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""

        if ($result.ExitCode -eq 0) {
            Write-Host "[COMPLETED] Screen recorder started successfully on $ComputerName" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERROR] Failed to start screen recorder" -ForegroundColor Red
            return $false
        }

    } catch {
        Write-Host ""
        Write-Host "[ERROR] Failed to execute command" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

<#
.SYNOPSIS
    Stops screen recording on a remote computer.

.DESCRIPTION
    Connects to a remote computer and stops the running Python screen recorder.

.PARAMETER ComputerName
    The name or IP address of the remote computer.

.PARAMETER ScriptPath
    Full path to screen_recorder.py on the remote machine.

.PARAMETER Credential
    PSCredential object for authentication. If not provided, will use current credentials.

.EXAMPLE
    Stop-RemoteScreenRecorder -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py"

.EXAMPLE
    Stop-RemoteScreenRecorder -ComputerName "PC01" -ScriptPath "C:\Scripts\screen_recorder.py" -Credential (Get-Credential)
#>
function Stop-RemoteScreenRecorder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Stop Remote Screen Recorder" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Target: $ComputerName" -ForegroundColor Yellow
    Write-Host "Script: $ScriptPath" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Test connection
    Write-Host "Testing connection to $ComputerName..." -ForegroundColor Yellow
    if (-not (Test-RemoteConnection -ComputerName $ComputerName -Credential $Credential)) {
        Write-Host "[ERROR] Cannot connect to $ComputerName" -ForegroundColor Red
        return $false
    }
    Write-Host "[SUCCESS] Connection established" -ForegroundColor Green
    Write-Host ""

    $pythonCmd = "python `"$ScriptPath`" stop"

    Write-Host "Stopping recorder on remote machine..." -ForegroundColor Green
    Write-Host ""

    try {
        $scriptBlock = {
            param($command, $scriptPath)
            
            $scriptDir = Split-Path -Parent $scriptPath
            Set-Location $scriptDir
            
            $output = Invoke-Expression $command 2>&1
            
            return @{
                Output = $output
                ExitCode = $LASTEXITCODE
            }
        }

        $invokeParams = @{
            ComputerName = $ComputerName
            ScriptBlock = $scriptBlock
            ArgumentList = $pythonCmd, $ScriptPath
            ErrorAction = 'Stop'
        }
        if ($Credential) {
            $invokeParams.Credential = $Credential
        }

        $result = Invoke-Command @invokeParams

        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Result" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        if ($result.Output) {
            Write-Host $result.Output
        }
        
        Write-Host ""
        Write-Host "Exit Code: $($result.ExitCode)" -ForegroundColor $(if ($result.ExitCode -eq 0) { "Green" } else { "Red" })
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""

        if ($result.ExitCode -eq 0) {
            Write-Host "[COMPLETED] Screen recorder stopped successfully on $ComputerName" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERROR] Failed to stop screen recorder" -ForegroundColor Red
            return $false
        }

    } catch {
        Write-Host ""
        Write-Host "[ERROR] Failed to execute command" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

<#
.SYNOPSIS
    Checks the status of screen recorder on a remote computer.

.DESCRIPTION
    Connects to a remote computer and checks if the Python screen recorder is running.

.PARAMETER ComputerName
    The name or IP address of the remote computer.

.PARAMETER ScriptPath
    Full path to screen_recorder.py on the remote machine.

.PARAMETER Credential
    PSCredential object for authentication. If not provided, will use current credentials.

.EXAMPLE
    Get-RemoteScreenRecorderStatus -ComputerName "192.168.1.100" -ScriptPath "C:\Scripts\screen_recorder.py"

.EXAMPLE
    Get-RemoteScreenRecorderStatus -ComputerName "PC01" -ScriptPath "C:\Scripts\screen_recorder.py" -Credential (Get-Credential)
#>
function Get-RemoteScreenRecorderStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Remote Screen Recorder Status" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Target: $ComputerName" -ForegroundColor Yellow
    Write-Host "Script: $ScriptPath" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Test connection
    Write-Host "Testing connection to $ComputerName..." -ForegroundColor Yellow
    if (-not (Test-RemoteConnection -ComputerName $ComputerName -Credential $Credential)) {
        Write-Host "[ERROR] Cannot connect to $ComputerName" -ForegroundColor Red
        return $false
    }
    Write-Host "[SUCCESS] Connection established" -ForegroundColor Green
    Write-Host ""

    $pythonCmd = "python `"$ScriptPath`" status"

    Write-Host "Checking status on remote machine..." -ForegroundColor Green
    Write-Host ""

    try {
        $scriptBlock = {
            param($command, $scriptPath)
            
            $scriptDir = Split-Path -Parent $scriptPath
            Set-Location $scriptDir
            
            $output = Invoke-Expression $command 2>&1
            
            return @{
                Output = $output
                ExitCode = $LASTEXITCODE
            }
        }

        $invokeParams = @{
            ComputerName = $ComputerName
            ScriptBlock = $scriptBlock
            ArgumentList = $pythonCmd, $ScriptPath
            ErrorAction = 'Stop'
        }
        if ($Credential) {
            $invokeParams.Credential = $Credential
        }

        $result = Invoke-Command @invokeParams

        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Result" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        if ($result.Output) {
            Write-Host $result.Output
        }
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""

        return $result.ExitCode -eq 0

    } catch {
        Write-Host ""
        Write-Host "[ERROR] Failed to execute command" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

<#
.SYNOPSIS
    Starts screen recording on multiple remote computers simultaneously.

.DESCRIPTION
    Connects to multiple remote computers and starts the Python screen recorder on all of them.

.PARAMETER ComputerNames
    Array of computer names or IP addresses.

.PARAMETER ScriptPath
    Full path to screen_recorder.py on the remote machines.

.PARAMETER RecordingName
    Optional name for the recording. If not provided, auto-generated.

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
    PSCredential object for authentication. If not provided, will use current credentials.

.EXAMPLE
    Start-RemoteScreenRecorderBatch -ComputerNames @("PC01", "PC02", "PC03") -ScriptPath "C:\Scripts\screen_recorder.py"

.EXAMPLE
    Start-RemoteScreenRecorderBatch -ComputerNames @("192.168.1.100", "192.168.1.101") -ScriptPath "C:\Scripts\screen_recorder.py" -Mode interval -Duration 30 -Interval 300
#>
function Start-RemoteScreenRecorderBatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerNames,

        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,

        [Parameter(Mandatory=$false)]
        [string]$RecordingName = "",

        [Parameter(Mandatory=$false)]
        [ValidateSet('continuous', 'interval')]
        [string]$Mode = "continuous",

        [Parameter(Mandatory=$false)]
        [int]$Duration = 30,

        [Parameter(Mandatory=$false)]
        [int]$Interval = 60,

        [Parameter(Mandatory=$false)]
        [ValidateSet('single', 'multiple')]
        [string]$SaveMode = "single",

        [Parameter(Mandatory=$false)]
        [int]$FPS = 20,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Batch Remote Screen Recorder Start" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Targets: $($ComputerNames.Count) computers" -ForegroundColor Yellow
    Write-Host "Script: $ScriptPath" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $results = @{}

    foreach ($computer in $ComputerNames) {
        Write-Host "Processing: $computer" -ForegroundColor Yellow
        
        $success = Start-RemoteScreenRecorder `
            -ComputerName $computer `
            -ScriptPath $ScriptPath `
            -RecordingName $RecordingName `
            -Mode $Mode `
            -Duration $Duration `
            -Interval $Interval `
            -SaveMode $SaveMode `
            -FPS $FPS `
            -Credential $Credential

        $results[$computer] = $success
        Write-Host ""
    }

    # Summary
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Batch Operation Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
    $failCount = $results.Count - $successCount

    foreach ($computer in $results.Keys) {
        $status = if ($results[$computer]) { "[SUCCESS]" } else { "[FAILED]" }
        $color = if ($results[$computer]) { "Green" } else { "Red" }
        Write-Host "$status $computer" -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "Total: $($results.Count) | Success: $successCount | Failed: $failCount" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    return $results
}

<#
.SYNOPSIS
    Stops screen recording on multiple remote computers simultaneously.

.DESCRIPTION
    Connects to multiple remote computers and stops the Python screen recorder on all of them.

.PARAMETER ComputerNames
    Array of computer names or IP addresses.

.PARAMETER ScriptPath
    Full path to screen_recorder.py on the remote machines.

.PARAMETER Credential
    PSCredential object for authentication. If not provided, will use current credentials.

.EXAMPLE
    Stop-RemoteScreenRecorderBatch -ComputerNames @("PC01", "PC02", "PC03") -ScriptPath "C:\Scripts\screen_recorder.py"
#>
function Stop-RemoteScreenRecorderBatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerNames,

        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Batch Remote Screen Recorder Stop" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Targets: $($ComputerNames.Count) computers" -ForegroundColor Yellow
    Write-Host "Script: $ScriptPath" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $results = @{}

    foreach ($computer in $ComputerNames) {
        Write-Host "Processing: $computer" -ForegroundColor Yellow
        
        $success = Stop-RemoteScreenRecorder `
            -ComputerName $computer `
            -ScriptPath $ScriptPath `
            -Credential $Credential

        $results[$computer] = $success
        Write-Host ""
    }

    # Summary
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Batch Operation Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
    $failCount = $results.Count - $successCount

    foreach ($computer in $results.Keys) {
        $status = if ($results[$computer]) { "[SUCCESS]" } else { "[FAILED]" }
        $color = if ($results[$computer]) { "Green" } else { "Red" }
        Write-Host "$status $computer" -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "Total: $($results.Count) | Success: $successCount | Failed: $failCount" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    return $results
}

# Export module functions
Export-ModuleMember -Function @(
    'Start-RemoteScreenRecorder',
    'Stop-RemoteScreenRecorder',
    'Get-RemoteScreenRecorderStatus',
    'Start-RemoteScreenRecorderBatch',
    'Stop-RemoteScreenRecorderBatch'
)
