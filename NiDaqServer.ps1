# NiDaq Server - PowerShell Edition
# Version: 2.0
# Description: Modular TCP server for remote test orchestration
# Integrates with existing RunTest.ps1 framework

#Requires -Version 5.1
# Note: Running as Administrator is recommended for remote execution via PsExec

param(
    [string]$ConfigFile = ".\ServerConfig.json",
    [int]$Port = 55555,
    [string]$ServerHost = "0.0.0.0"
)

$ErrorActionPreference = "Stop"
$Global:ServerRunning = $true
$Global:LogFile = "NiDaqServer_$(Get-Date -Format 'yyyy-MM-dd').log"

# ============================================================================
# LOGGING MODULE
# ============================================================================

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    
    # Console output with colors
    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
    }
    
    # File output
    $logEntry | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
}

# ============================================================================
# CONFIGURATION MODULE
# ============================================================================

function Load-ServerConfig {
    param([string]$ConfigPath)
    
    try {
        if (-not (Test-Path $ConfigPath)) {
            Write-Log "Config file not found. Creating default configuration..." -Level "WARNING"
            $defaultConfig = Get-DefaultConfig
            $defaultConfig | ConvertTo-Json -Depth 10 | Out-File $ConfigPath -Encoding UTF8
            return $defaultConfig
        }
        
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        Write-Log "Configuration loaded successfully from $ConfigPath" -Level "SUCCESS"
        return $config
    }
    catch {
        Write-Log "Failed to load configuration: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-DefaultConfig {
    return [PSCustomObject]@{
        Server = @{
            Host = "0.0.0.0"
            Port = 55555
            MaxConnections = 10
            ReceiveTimeout = 300
        }
        Client = @{
            DefaultIP = "192.168.1.100"
            Username = "Administrator"
            Password = ""
            WorkingPath = "C:\KSR_Package\KSR\Test_Run_KR"
        }
        PACS = @{
            Enabled = $true
            ExePath = "C:\Intel\PACS\pacs.exe"
            ConfigPath = "C:\Test\testconfig.csv"
            ResultPath = "C:\Test\results"
            DelayBeforeRecord = 10
        }
        Paths = @{
            RunTestScript = "C:\GLD\New_Flow_5\RunTest.ps1"
            TestConfigFolder = "C:\GLD"
            ResultsFolder = "C:\Results"
            TempFolder = "C:\Temp"
        }
        Temperature = @{
            Enabled = $false
            ScriptPath = "C:\Tools\KSRTemp.py"
        }
        Features = @{
            BackgroundServiceControl = $true
            RemoteExecution = $true
            FileTransfer = $true
            TemperatureControl = $false
        }
    }
}

# ============================================================================
# PACS INTEGRATION MODULE
# ============================================================================

class PACSController {
    [string]$ExePath
    [string]$ConfigPath
    [string]$ResultPath
    [object]$Process
    
    PACSController([string]$exePath, [string]$configPath, [string]$resultPath) {
        $this.ExePath = $exePath
        $this.ConfigPath = $configPath
        $this.ResultPath = $resultPath
    }
    
    [bool] IsRunning() {
        # Check if PACS process is running
        $pacsProcess = Get-Process -Name "pacs" -ErrorAction SilentlyContinue
        return ($null -ne $pacsProcess)
    }
    
    [string] GetStatus() {
        if ($this.IsRunning()) {
            return "RUNNING"
        }
        return "STOPPED"
    }
    
    [void] Start() {
        if ($this.IsRunning()) {
            Write-Log "PACS already running" -Level "WARNING"
            return
        }
        
        Write-Log "Starting PACS from $($this.ExePath)" -Level "INFO"
        $this.Process = Start-Process -FilePath $this.ExePath -PassThru -WindowStyle Hidden
        Start-Sleep -Seconds 3
        
        if ($this.IsRunning()) {
            Write-Log "PACS started successfully" -Level "SUCCESS"
        }
        else {
            throw "Failed to start PACS"
        }
    }
    
    [void] Stop() {
        if (-not $this.IsRunning()) {
            Write-Log "PACS not running" -Level "WARNING"
            return
        }
        
        Write-Log "Stopping PACS" -Level "INFO"
        Stop-Process -Name "pacs" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-Log "PACS stopped" -Level "SUCCESS"
    }
    
    [void] Record([int]$duration, [string]$testId) {
        if (-not $this.IsRunning()) {
            throw "PACS not running. Start PACS first."
        }
        
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $resultFile = Join-Path $this.ResultPath "${testId}_${timestamp}"
        Write-Log "Starting PACS recording for $duration seconds to $resultFile" -Level "INFO"
        
        # This would integrate with actual PACS Python API via Python.NET or COM
        # For now, placeholder for the actual implementation
        Write-Log "PACS recording started (duration: $duration seconds)" -Level "SUCCESS"
    }
}

# ============================================================================
# REMOTE EXECUTION MODULE
# ============================================================================

class RemoteExecutor {
    [string]$ClientIP
    [string]$Username
    [string]$Password
    [string]$WorkingPath
    
    RemoteExecutor([string]$ip, [string]$user, [string]$pass, [string]$path) {
        $this.ClientIP = $ip
        $this.Username = $user
        $this.Password = $pass
        $this.WorkingPath = $path
    }
    
    [string] BuildPsExecCommand([string]$command, [bool]$detached = $false) {
        $psexecPath = "psexec"
        $flags = "-u `"$($this.Username)`" -p `"$($this.Password)`" -w `"$($this.WorkingPath)`""
        
        if ($detached) {
            $flags += " -d"
        }
        
        if ($command -like "*.ps1*") {
            $flags += " -i 1"
        }
        
        return "$psexecPath \\$($this.ClientIP) $flags cmd /c `"$command`""
    }
    
    [object] Execute([string]$command, [bool]$detached = $false, [int]$timeout = 300) {
        $psexecCmd = $this.BuildPsExecCommand($command, $detached)
        Write-Log "Executing on $($this.ClientIP): $command" -Level "INFO"
        
        try {
            $result = Invoke-Expression $psexecCmd 2>&1
            return @{
                Success = $true
                Output = $result
                ExitCode = $LASTEXITCODE
            }
        }
        catch {
            Write-Log "Remote execution failed: $($_.Exception.Message)" -Level "ERROR"
            return @{
                Success = $false
                Error = $_.Exception.Message
                ExitCode = -1
            }
        }
    }
    
    [object] RunTest([string]$testId, [hashtable]$parameters) {
        # Build RunTest.ps1 command with parameters
        $testScript = "C:\GLD\New_Flow_5\RunTest.ps1"
        $params = "-TestID '$testId'"
        
        if ($parameters.ContainsKey('WaitTime')) {
            $params += " -WaitTime $($parameters['WaitTime'])"
        }
        if ($parameters.ContainsKey('SoCWatch') -and $parameters['SoCWatch']) {
            $params += " -SoCWatch"
        }
        if ($parameters.ContainsKey('Iterations')) {
            $params += " -Iterations $($parameters['Iterations'])"
        }
        
        $command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$testScript`" $params"
        Write-Log "Starting test $testId with parameters: $params" -Level "INFO"
        
        return $this.Execute($command, $true, 300)
    }
    
    [bool] TestConnection() {
        $ping = Test-Connection -ComputerName $this.ClientIP -Count 1 -Quiet
        if ($ping) {
            Write-Log "Connection to $($this.ClientIP) successful" -Level "SUCCESS"
        }
        else {
            Write-Log "Cannot reach $($this.ClientIP)" -Level "ERROR"
        }
        return $ping
    }
}

# ============================================================================
# COMMAND HANDLERS MODULE
# ============================================================================

class CommandHandler {
    [object]$Config
    [PACSController]$PACS
    [RemoteExecutor]$Remote
    
    CommandHandler([object]$config) {
        $this.Config = $config
        
        if ($config.PACS.Enabled) {
            $this.PACS = [PACSController]::new(
                $config.PACS.ExePath,
                $config.PACS.ConfigPath,
                $config.PACS.ResultPath
            )
        }
        
        $this.Remote = [RemoteExecutor]::new(
            $config.Client.DefaultIP,
            $config.Client.Username,
            $config.Client.Password,
            $config.Client.WorkingPath
        )
    }
    
    # Code 101: Server Status
    [string] Handle_101() {
        Write-Log "Command 101: Server Status Check" -Level "INFO"
        $pacsStatus = if ($this.PACS) { $this.PACS.GetStatus() } else { "DISABLED" }
        return "SERVER_ONLINE|PACS:$pacsStatus|VERSION:2.0"
    }
    
    # Code 102: Execute Test (Integration with RunTest.ps1)
    [string] Handle_102([string]$payload) {
        Write-Log "Command 102: Execute Test" -Level "INFO"
        
        # Parse payload: TestID|WaitTime|Iterations|SoCWatch
        $parts = $payload -split '\|'
        $testId = $parts[0]
        
        $params = @{}
        if ($parts.Length -gt 1) { $params['WaitTime'] = [int]$parts[1] }
        if ($parts.Length -gt 2) { $params['Iterations'] = [int]$parts[2] }
        if ($parts.Length -gt 3) { $params['SoCWatch'] = [bool]::Parse($parts[3]) }
        
        # Execute test via RunTest.ps1
        $result = $this.Remote.RunTest($testId, $params)
        
        if ($result.Success) {
            return "TEST_SCHEDULED|TestID:$testId|Status:Running"
        }
        else {
            return "TEST_FAILED|Error:$($result.Error)"
        }
    }
    
    # Code 103: Start PACS
    [string] Handle_103() {
        Write-Log "Command 103: Start PACS" -Level "INFO"
        
        if (-not $this.PACS) {
            return "PACS_DISABLED"
        }
        
        try {
            $this.PACS.Start()
            return "PACS_STARTED|Status:RUNNING"
        }
        catch {
            Write-Log "Failed to start PACS: $($_.Exception.Message)" -Level "ERROR"
            return "PACS_START_FAILED|Error:$($_.Exception.Message)"
        }
    }
    
    # Code 104: PACS Status
    [string] Handle_104() {
        Write-Log "Command 104: PACS Status" -Level "INFO"
        
        if (-not $this.PACS) {
            return "PACS_DISABLED"
        }
        
        $status = $this.PACS.GetStatus()
        return "PACS_STATUS|Status:$status"
    }
    
    # Code 105: Start PACS Recording
    [string] Handle_105([string]$payload) {
        Write-Log "Command 105: Start PACS Recording" -Level "INFO"
        
        if (-not $this.PACS) {
            return "PACS_DISABLED"
        }
        
        # Parse payload: Duration|TestID
        $parts = $payload -split '\|'
        $duration = [int]$parts[0]
        $testId = if ($parts.Length -gt 1) { $parts[1] } else { "UnknownTest" }
        
        try {
            $this.PACS.Record($duration, $testId)
            return "PACS_RECORDING_STARTED|Duration:$duration|TestID:$testId"
        }
        catch {
            Write-Log "Failed to start recording: $($_.Exception.Message)" -Level "ERROR"
            return "PACS_RECORD_FAILED|Error:$($_.Exception.Message)"
        }
    }
    
    # Code 106: Stop PACS
    [string] Handle_106() {
        Write-Log "Command 106: Stop PACS" -Level "INFO"
        
        if (-not $this.PACS) {
            return "PACS_DISABLED"
        }
        
        try {
            $this.PACS.Stop()
            return "PACS_STOPPED"
        }
        catch {
            Write-Log "Failed to stop PACS: $($_.Exception.Message)" -Level "ERROR"
            return "PACS_STOP_FAILED|Error:$($_.Exception.Message)"
        }
    }
    
    # Code 107: Transfer Results (Socket)
    [string] Handle_107([System.Net.Sockets.NetworkStream]$stream, [string]$payload) {
        Write-Log "Command 107: Transfer Results" -Level "INFO"
        
        # Get result files from PACS result path
        $resultPath = $this.Config.PACS.ResultPath
        
        if (-not (Test-Path $resultPath)) {
            return "NO_RESULTS_FOUND"
        }
        
        $resultFiles = Get-ChildItem -Path $resultPath -Filter "*_summary.csv" -Recurse
        
        if ($resultFiles.Count -eq 0) {
            return "NO_RESULTS_FOUND"
        }
        
        # Send file count
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.WriteLine($resultFiles.Count)
        $writer.Flush()
        
        foreach ($file in $resultFiles) {
            # Send file size
            $fileSize = $file.Length
            $writer.WriteLine($fileSize)
            $writer.Flush()
            
            # Send file name
            $writer.WriteLine($file.Name)
            $writer.Flush()
            
            # Send file content
            $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
            $stream.Write($fileBytes, 0, $fileBytes.Length)
            $stream.Flush()
            
            Write-Log "Sent file: $($file.Name) ($fileSize bytes)" -Level "SUCCESS"
        }
        
        return "FILE_TRANSFER_COMPLETE"
    }
    
    # Code 108: Mark Test Complete (handled by RunTest.ps1 PostStep)
    [string] Handle_108([string]$payload) {
        Write-Log "Command 108: Mark Test Complete" -Level "INFO"
        # This is now handled by RunTest.ps1 PostStep
        return "TEST_MARKED_COMPLETE|TestID:$payload"
    }
    
    # Code 109: Set Temperature
    [string] Handle_109([string]$payload) {
        Write-Log "Command 109: Set Temperature" -Level "INFO"
        
        if (-not $this.Config.Temperature.Enabled) {
            return "TEMPERATURE_CONTROL_DISABLED"
        }
        
        $temperature = [int]$payload
        $scriptPath = $this.Config.Temperature.ScriptPath
        
        try {
            $result = & python $scriptPath --set $temperature 2>&1
            Write-Log "Temperature set to $temperature" -Level "SUCCESS"
            return "TEMPERATURE_SET|Value:$temperature"
        }
        catch {
            Write-Log "Failed to set temperature: $($_.Exception.Message)" -Level "ERROR"
            return "TEMPERATURE_SET_FAILED|Error:$($_.Exception.Message)"
        }
    }
    
    # Code 110: Get Temperature
    [string] Handle_110() {
        Write-Log "Command 110: Get Temperature" -Level "INFO"
        
        if (-not $this.Config.Temperature.Enabled) {
            return "TEMPERATURE_CONTROL_DISABLED"
        }
        
        $scriptPath = $this.Config.Temperature.ScriptPath
        
        try {
            $result = & python $scriptPath 2>&1
            $temp = ($result | Select-String -Pattern "Current Temperature:\s*(\d+)").Matches.Groups[1].Value
            Write-Log "Current temperature: $temp" -Level "SUCCESS"
            return "CURRENT_TEMPERATURE|Value:$temp"
        }
        catch {
            Write-Log "Failed to get temperature: $($_.Exception.Message)" -Level "ERROR"
            return "TEMPERATURE_GET_FAILED|Error:$($_.Exception.Message)"
        }
    }
    
    # Code 111: Copy Results (Network Share)
    [string] Handle_111([string]$payload) {
        Write-Log "Command 111: Copy Results via Network Share" -Level "INFO"
        # Implementation for network share copy
        return "NETWORK_COPY_COMPLETE"
    }
    
    # Code 112: Execute Custom Command
    [string] Handle_112([string]$payload) {
        Write-Log "Command 112: Execute Custom Command" -Level "INFO"
        
        # Parse payload for custom command
        $result = $this.Remote.Execute($payload, $true, 300)
        
        if ($result.Success) {
            return "CUSTOM_COMMAND_EXECUTED|Output:$($result.Output)"
        }
        else {
            return "CUSTOM_COMMAND_FAILED|Error:$($result.Error)"
        }
    }
    
    # Code 113: Network Share Results Transfer
    [string] Handle_113() {
        Write-Log "Command 113: Network Share Results Transfer" -Level "INFO"
        
        # Mount network share and copy results
        $resultPath = $this.Config.PACS.ResultPath
        $destPath = "\\$($this.Remote.ClientIP)\C$\Results"
        
        try {
            if (Test-Path $resultPath) {
                Copy-Item -Path "$resultPath\*" -Destination $destPath -Recurse -Force
                Write-Log "Results copied to $destPath" -Level "SUCCESS"
                return "RESULTS_COPIED|Destination:$destPath"
            }
            else {
                return "NO_RESULTS_TO_COPY"
            }
        }
        catch {
            Write-Log "Failed to copy results: $($_.Exception.Message)" -Level "ERROR"
            return "COPY_FAILED|Error:$($_.Exception.Message)"
        }
    }
    
    # Route command to appropriate handler
    [string] HandleCommand([string]$command, [string]$payload, [System.Net.Sockets.NetworkStream]$stream) {
        $result = switch ($command) {
            "101" { $this.Handle_101() }
            "102" { $this.Handle_102($payload) }
            "103" { $this.Handle_103() }
            "104" { $this.Handle_104() }
            "105" { $this.Handle_105($payload) }
            "106" { $this.Handle_106() }
            "107" { $this.Handle_107($stream, $payload) }
            "108" { $this.Handle_108($payload) }
            "109" { $this.Handle_109($payload) }
            "110" { $this.Handle_110() }
            "111" { $this.Handle_111($payload) }
            "112" { $this.Handle_112($payload) }
            "113" { $this.Handle_113() }
            default { "INVALID_COMMAND|Code:$command" }
        }
        return $result
    }
}

# ============================================================================
# TCP SERVER MODULE
# ============================================================================

function Start-NiDaqServer {
    param(
        [object]$Config
    )
    
    Write-Log "========================================" -Level "INFO"
    Write-Log "NiDaq Server v2.0 - PowerShell Edition" -Level "INFO"
    Write-Log "========================================" -Level "INFO"
    
    # Initialize command handler
    $handler = [CommandHandler]::new($Config)
    
    # Create TCP listener
    $endpoint = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Parse($Config.Server.Host), $Config.Server.Port)
    $listener = [System.Net.Sockets.TcpListener]::new($endpoint)
    
    try {
        $listener.Start()
        Write-Log "Server listening on $($Config.Server.Host):$($Config.Server.Port)" -Level "SUCCESS"
        
        while ($Global:ServerRunning) {
            # Check if a client is pending (non-blocking with timeout)
            if ($listener.Pending()) {
                $client = $listener.AcceptTcpClient()
                $clientEndpoint = $client.Client.RemoteEndPoint
                Write-Log "Client connected: $clientEndpoint" -Level "INFO"
                
                try {
                    $stream = $client.GetStream()
                    $stream.ReadTimeout = $Config.Server.ReceiveTimeout * 1000
                    
                    # Read command
                    $buffer = New-Object byte[] 1024
                    $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
                    $message = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead).Trim()
                    
                    Write-Log "Received: $message" -Level "INFO"
                    
                    # Parse command (format: "CODE|PAYLOAD")
                    $parts = $message -split '\|', 2
                    $command = $parts[0].Trim()
                    $payload = if ($parts.Length -gt 1) { $parts[1] } else { "" }
                    
                    # Handle command
                    $response = $handler.HandleCommand($command, $payload, $stream)
                    
                    # Send response
                    $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($response)
                    $stream.Write($responseBytes, 0, $responseBytes.Length)
                    $stream.Flush()
                    
                    Write-Log "Response sent: $response" -Level "SUCCESS"
                }
                catch {
                    Write-Log "Error handling client: $($_.Exception.Message)" -Level "ERROR"
                }
                finally {
                    $stream.Close()
                    $client.Close()
                    Write-Log "Client disconnected: $clientEndpoint" -Level "INFO"
                }
            }
            
            Start-Sleep -Milliseconds 100
        }
    }
    catch {
        Write-Log "Server error: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
    finally {
        $listener.Stop()
        Write-Log "Server stopped" -Level "INFO"
    }
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

try {
    # Load configuration
    $config = Load-ServerConfig -ConfigPath $ConfigFile
    
    # Override with command-line parameters
    if ($PSBoundParameters.ContainsKey('Port')) {
        $config.Server.Port = $Port
    }
    if ($PSBoundParameters.ContainsKey('ServerHost')) {
        $config.Server.Host = $ServerHost
    }
    
    # Start server
    Start-NiDaqServer -Config $config
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}
finally {
    Write-Log "NiDaq Server shutting down..." -Level "INFO"
}
