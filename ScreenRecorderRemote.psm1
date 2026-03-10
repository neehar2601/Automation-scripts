<#
.SYNOPSIS
    Remote Screen Recorder Controller - PowerShell Module

.DESCRIPTION
    This module allows you to remotely control the Python screen recorder on multiple computers.
    It can start, stop, and check status of screen recorders across your network.

.NOTES
    Author: Screen Recorder Remote Control
    Version: 1.0
    Date: February 23, 2026
    Requires: PowerShell Remoting enabled on target computers
#>

# Module-level variables
$script:DefaultRecorderPath = "C:\ScreenRecorder"
$script:DefaultPythonCommand = "python"
$script:DefaultConfigFile = "config.json"

<#
.SYNOPSIS
    Starts screen recording on one or more remote computers.

.DESCRIPTION
    Initiates screen recording on specified remote computers using the Python screen recorder script.

.PARAMETER ComputerName
    One or more computer names or IP addresses where recording should start.

.PARAMETER RecorderPath
    Path to the screen recorder directory on remote computers. Default: C:\ScreenRecorder

.PARAMETER Credential
    Credentials to use for remote connection. If not specified, uses current user credentials.

.PARAMETER FileName
    Optional custom filename for the recording. If not specified, auto-generates timestamp-based name.

.PARAMETER ConfigFile
    Path to the configuration file to use. Default: config.json

.PARAMETER Async
    If specified, starts recording asynchronously without waiting for completion.

.EXAMPLE
    Start-RemoteScreenRecorder -ComputerName "PC01", "PC02"
    Starts recording on PC01 and PC02 with default settings.

.EXAMPLE
    Start-RemoteScreenRecorder -ComputerName "PC01" -FileName "meeting_recording" -ConfigFile "config_interval.json"
    Starts recording on PC01 with custom filename and config file.

.EXAMPLE
    $cred = Get-Credential
    Start-RemoteScreenRecorder -ComputerName "PC01", "PC02", "PC03" -Credential $cred -Async
    Starts recording on multiple PCs with specified credentials asynchronously.
#>
function Start-RemoteScreenRecorder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Computer", "CN", "Server")]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string]$RecorderPath = $script:DefaultRecorderPath,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$FileName,

        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = $script:DefaultConfigFile,

        [Parameter(Mandatory = $false)]
        [switch]$Async
    )

    begin {
        Write-Verbose "Starting remote screen recorder operation"
        $results = @()
    }

    process {
        foreach ($computer in $ComputerName) {
            Write-Host "[$computer] Starting screen recorder..." -ForegroundColor Cyan

            $scriptBlock = {
                param($RecorderPath, $FileName, $ConfigFile, $PythonCmd)
                
                Set-Location $RecorderPath
                
                $arguments = @("screen_recorder.py", "start")
                
                if ($FileName) {
                    $arguments += $FileName
                }
                
                if ($ConfigFile) {
                    $arguments += @("-c", $ConfigFile)
                }
                
                $argumentString = $arguments -join " "
                
                # Start the recorder in a new process
                $startInfo = New-Object System.Diagnostics.ProcessStartInfo
                $startInfo.FileName = $PythonCmd
                $startInfo.Arguments = $argumentString
                $startInfo.WorkingDirectory = $RecorderPath
                $startInfo.UseShellExecute = $false
                $startInfo.RedirectStandardOutput = $true
                $startInfo.RedirectStandardError = $true
                $startInfo.CreateNoWindow = $true
                
                $process = New-Object System.Diagnostics.Process
                $process.StartInfo = $startInfo
                $process.Start() | Out-Null
                
                # Wait a moment and capture initial output
                Start-Sleep -Seconds 2
                $output = $process.StandardOutput.ReadToEnd()
                $error = $process.StandardError.ReadToEnd()
                
                return @{
                    Success = $true
                    Output = $output
                    Error = $error
                    ProcessId = $process.Id
                }
            }

            try {
                $params = @{
                    ComputerName = $computer
                    ScriptBlock = $scriptBlock
                    ArgumentList = @($RecorderPath, $FileName, $ConfigFile, $script:DefaultPythonCommand)
                }

                if ($Credential) {
                    $params.Add("Credential", $Credential)
                }

                if ($Async) {
                    $job = Invoke-Command @params -AsJob
                    Write-Host "[$computer] Recording started asynchronously (Job ID: $($job.Id))" -ForegroundColor Green
                    
                    $results += [PSCustomObject]@{
                        ComputerName = $computer
                        Status = "Started"
                        JobId = $job.Id
                        Message = "Recording started in background"
                    }
                } else {
                    $result = Invoke-Command @params
                    
                    if ($result.Success) {
                        Write-Host "[$computer] Recording started successfully" -ForegroundColor Green
                        if ($result.Output) {
                            Write-Verbose "[$computer] Output: $($result.Output)"
                        }
                    } else {
                        Write-Host "[$computer] Failed to start recording" -ForegroundColor Red
                        if ($result.Error) {
                            Write-Warning "[$computer] Error: $($result.Error)"
                        }
                    }
                    
                    $results += [PSCustomObject]@{
                        ComputerName = $computer
                        Status = if ($result.Success) { "Started" } else { "Failed" }
                        ProcessId = $result.ProcessId
                        Output = $result.Output
                        Error = $result.Error
                    }
                }
            }
            catch {
                Write-Host "[$computer] Error: $($_.Exception.Message)" -ForegroundColor Red
                
                $results += [PSCustomObject]@{
                    ComputerName = $computer
                    Status = "Error"
                    Error = $_.Exception.Message
                }
            }
        }
    }

    end {
        return $results
    }
}

<#
.SYNOPSIS
    Stops screen recording on one or more remote computers.

.DESCRIPTION
    Stops the running screen recorder on specified remote computers.

.PARAMETER ComputerName
    One or more computer names or IP addresses where recording should stop.

.PARAMETER RecorderPath
    Path to the screen recorder directory on remote computers. Default: C:\ScreenRecorder

.PARAMETER Credential
    Credentials to use for remote connection.

.EXAMPLE
    Stop-RemoteScreenRecorder -ComputerName "PC01", "PC02"
    Stops recording on PC01 and PC02.

.EXAMPLE
    $cred = Get-Credential
    Stop-RemoteScreenRecorder -ComputerName "PC01" -Credential $cred
    Stops recording on PC01 with specified credentials.
#>
function Stop-RemoteScreenRecorder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Computer", "CN", "Server")]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string]$RecorderPath = $script:DefaultRecorderPath,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    begin {
        Write-Verbose "Stopping remote screen recorder operation"
        $results = @()
    }

    process {
        foreach ($computer in $ComputerName) {
            Write-Host "[$computer] Stopping screen recorder..." -ForegroundColor Cyan

            $scriptBlock = {
                param($RecorderPath, $PythonCmd)
                
                Set-Location $RecorderPath
                
                $output = & $PythonCmd screen_recorder.py stop 2>&1
                
                return @{
                    Success = $LASTEXITCODE -eq 0
                    Output = $output -join "`n"
                }
            }

            try {
                $params = @{
                    ComputerName = $computer
                    ScriptBlock = $scriptBlock
                    ArgumentList = @($RecorderPath, $script:DefaultPythonCommand)
                }

                if ($Credential) {
                    $params.Add("Credential", $Credential)
                }

                $result = Invoke-Command @params
                
                if ($result.Success) {
                    Write-Host "[$computer] Recording stopped successfully" -ForegroundColor Green
                } else {
                    Write-Host "[$computer] Stop command completed with warnings" -ForegroundColor Yellow
                }
                
                if ($result.Output) {
                    Write-Verbose "[$computer] Output: $($result.Output)"
                }
                
                $results += [PSCustomObject]@{
                    ComputerName = $computer
                    Status = if ($result.Success) { "Stopped" } else { "Warning" }
                    Output = $result.Output
                }
            }
            catch {
                Write-Host "[$computer] Error: $($_.Exception.Message)" -ForegroundColor Red
                
                $results += [PSCustomObject]@{
                    ComputerName = $computer
                    Status = "Error"
                    Error = $_.Exception.Message
                }
            }
        }
    }

    end {
        return $results
    }
}

<#
.SYNOPSIS
    Checks the status of screen recorder on one or more remote computers.

.DESCRIPTION
    Retrieves the current status of the screen recorder on specified remote computers.

.PARAMETER ComputerName
    One or more computer names or IP addresses to check status.

.PARAMETER RecorderPath
    Path to the screen recorder directory on remote computers. Default: C:\ScreenRecorder

.PARAMETER Credential
    Credentials to use for remote connection.

.EXAMPLE
    Get-RemoteScreenRecorderStatus -ComputerName "PC01", "PC02"
    Checks recorder status on PC01 and PC02.

.EXAMPLE
    "PC01", "PC02", "PC03" | Get-RemoteScreenRecorderStatus
    Checks status on multiple computers via pipeline.
#>
function Get-RemoteScreenRecorderStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Computer", "CN", "Server")]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string]$RecorderPath = $script:DefaultRecorderPath,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    begin {
        Write-Verbose "Checking remote screen recorder status"
        $results = @()
    }

    process {
        foreach ($computer in $ComputerName) {
            Write-Host "[$computer] Checking status..." -ForegroundColor Cyan

            $scriptBlock = {
                param($RecorderPath, $PythonCmd)
                
                Set-Location $RecorderPath
                
                $output = & $PythonCmd screen_recorder.py status 2>&1
                $outputString = $output -join "`n"
                
                # Parse the output to determine status
                $isRunning = $outputString -match "Recorder is RUNNING.*PID:\s*(\d+)"
                $pid = if ($Matches) { $Matches[1] } else { $null }
                
                return @{
                    Output = $outputString
                    IsRunning = $isRunning
                    ProcessId = $pid
                }
            }

            try {
                $params = @{
                    ComputerName = $computer
                    ScriptBlock = $scriptBlock
                    ArgumentList = @($RecorderPath, $script:DefaultPythonCommand)
                }

                if ($Credential) {
                    $params.Add("Credential", $Credential)
                }

                $result = Invoke-Command @params
                
                $statusColor = if ($result.IsRunning) { "Green" } else { "Yellow" }
                $statusText = if ($result.IsRunning) { "RUNNING (PID: $($result.ProcessId))" } else { "NOT RUNNING" }
                
                Write-Host "[$computer] Status: $statusText" -ForegroundColor $statusColor
                
                $results += [PSCustomObject]@{
                    ComputerName = $computer
                    IsRunning = $result.IsRunning
                    ProcessId = $result.ProcessId
                    Output = $result.Output
                }
            }
            catch {
                Write-Host "[$computer] Error: $($_.Exception.Message)" -ForegroundColor Red
                
                $results += [PSCustomObject]@{
                    ComputerName = $computer
                    IsRunning = $false
                    Error = $_.Exception.Message
                }
            }
        }
    }

    end {
        return $results
    }
}

<#
.SYNOPSIS
    Copies screen recorder files to remote computers.

.DESCRIPTION
    Deploys the screen recorder Python script and configuration files to remote computers.

.PARAMETER ComputerName
    One or more computer names or IP addresses where files should be copied.

.PARAMETER SourcePath
    Local path where screen recorder files are located.

.PARAMETER DestinationPath
    Remote path where files should be copied. Default: C:\ScreenRecorder

.PARAMETER Credential
    Credentials to use for remote connection.

.PARAMETER IncludeConfig
    If specified, also copies configuration files.

.EXAMPLE
    Copy-ScreenRecorderToRemote -ComputerName "PC01", "PC02" -SourcePath "C:\Local\ScreenRecorder"
    Copies screen recorder to PC01 and PC02.
#>
function Copy-ScreenRecorderToRemote {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $false)]
        [string]$DestinationPath = $script:DefaultRecorderPath,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeConfig
    )

    foreach ($computer in $ComputerName) {
        Write-Host "[$computer] Copying screen recorder files..." -ForegroundColor Cyan

        try {
            # Test connection
            if (-not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
                Write-Host "[$computer] Computer is not reachable" -ForegroundColor Red
                continue
            }

            # Create remote session
            $sessionParams = @{
                ComputerName = $computer
            }
            if ($Credential) {
                $sessionParams.Add("Credential", $Credential)
            }

            $session = New-PSSession @sessionParams

            # Create destination directory
            Invoke-Command -Session $session -ScriptBlock {
                param($DestPath)
                if (-not (Test-Path $DestPath)) {
                    New-Item -Path $DestPath -ItemType Directory -Force | Out-Null
                }
            } -ArgumentList $DestinationPath

            # Copy Python script
            $pythonScript = Join-Path $SourcePath "screen_recorder.py"
            if (Test-Path $pythonScript) {
                Copy-Item -Path $pythonScript -Destination $DestinationPath -ToSession $session -Force
                Write-Host "[$computer] Copied screen_recorder.py" -ForegroundColor Green
            }

            # Copy requirements.txt
            $requirements = Join-Path $SourcePath "requirements.txt"
            if (Test-Path $requirements) {
                Copy-Item -Path $requirements -Destination $DestinationPath -ToSession $session -Force
                Write-Host "[$computer] Copied requirements.txt" -ForegroundColor Green
            }

            # Copy config files if requested
            if ($IncludeConfig) {
                $configFiles = Get-ChildItem -Path $SourcePath -Filter "*.json"
                foreach ($config in $configFiles) {
                    Copy-Item -Path $config.FullName -Destination $DestinationPath -ToSession $session -Force
                    Write-Host "[$computer] Copied $($config.Name)" -ForegroundColor Green
                }
            }

            Remove-PSSession -Session $session
            Write-Host "[$computer] Deployment completed successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "[$computer] Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

<#
.SYNOPSIS
    Retrieves recorded files from remote computers.

.DESCRIPTION
    Downloads recorded video files from remote computers to a local directory.

.PARAMETER ComputerName
    One or more computer names or IP addresses to retrieve recordings from.

.PARAMETER RecorderPath
    Path to the screen recorder directory on remote computers. Default: C:\ScreenRecorder

.PARAMETER LocalDestination
    Local path where files should be downloaded.

.PARAMETER Credential
    Credentials to use for remote connection.

.PARAMETER FileFilter
    Filter for files to download. Default: *.mp4

.EXAMPLE
    Get-RemoteRecordings -ComputerName "PC01" -LocalDestination "C:\Downloads\Recordings"
    Downloads all recordings from PC01.
#>
function Get-RemoteRecordings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string]$RecorderPath = $script:DefaultRecorderPath,

        [Parameter(Mandatory = $true)]
        [string]$LocalDestination,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$FileFilter = "*.mp4"
    )

    # Create local destination if it doesn't exist
    if (-not (Test-Path $LocalDestination)) {
        New-Item -Path $LocalDestination -ItemType Directory -Force | Out-Null
    }

    foreach ($computer in $ComputerName) {
        Write-Host "[$computer] Retrieving recordings..." -ForegroundColor Cyan

        try {
            $sessionParams = @{
                ComputerName = $computer
            }
            if ($Credential) {
                $sessionParams.Add("Credential", $Credential)
            }

            $session = New-PSSession @sessionParams

            # Get list of recording files
            $remoteRecordingsPath = Join-Path $RecorderPath "recordings"
            $files = Invoke-Command -Session $session -ScriptBlock {
                param($Path, $Filter)
                if (Test-Path $Path) {
                    Get-ChildItem -Path $Path -Filter $Filter
                }
            } -ArgumentList $remoteRecordingsPath, $FileFilter

            if ($files) {
                # Create computer-specific subfolder
                $computerFolder = Join-Path $LocalDestination $computer
                if (-not (Test-Path $computerFolder)) {
                    New-Item -Path $computerFolder -ItemType Directory -Force | Out-Null
                }

                foreach ($file in $files) {
                    $remotePath = $file.FullName
                    $localPath = Join-Path $computerFolder $file.Name
                    
                    Copy-Item -Path $remotePath -Destination $localPath -FromSession $session -Force
                    Write-Host "[$computer] Downloaded: $($file.Name) ($([math]::Round($file.Length/1MB, 2)) MB)" -ForegroundColor Green
                }
            } else {
                Write-Host "[$computer] No recordings found" -ForegroundColor Yellow
            }

            Remove-PSSession -Session $session
        }
        catch {
            Write-Host "[$computer] Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

<#
.SYNOPSIS
    Sets module configuration defaults.

.DESCRIPTION
    Configures default settings for the remote screen recorder module.

.PARAMETER RecorderPath
    Default path to screen recorder on remote computers.

.PARAMETER PythonCommand
    Python command to use (python, python3, etc.).

.PARAMETER ConfigFile
    Default configuration file name.

.EXAMPLE
    Set-RemoteRecorderConfig -RecorderPath "D:\Tools\ScreenRecorder" -PythonCommand "python3"
#>
function Set-RemoteRecorderConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$RecorderPath,

        [Parameter(Mandatory = $false)]
        [string]$PythonCommand,

        [Parameter(Mandatory = $false)]
        [string]$ConfigFile
    )

    if ($RecorderPath) {
        $script:DefaultRecorderPath = $RecorderPath
        Write-Host "Default recorder path set to: $RecorderPath" -ForegroundColor Green
    }

    if ($PythonCommand) {
        $script:DefaultPythonCommand = $PythonCommand
        Write-Host "Default Python command set to: $PythonCommand" -ForegroundColor Green
    }

    if ($ConfigFile) {
        $script:DefaultConfigFile = $ConfigFile
        Write-Host "Default config file set to: $ConfigFile" -ForegroundColor Green
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Start-RemoteScreenRecorder',
    'Stop-RemoteScreenRecorder',
    'Get-RemoteScreenRecorderStatus',
    'Copy-ScreenRecorderToRemote',
    'Get-RemoteRecordings',
    'Set-RemoteRecorderConfig'
)
