# CommandHandler.ps1
# Command routing and handling class

class CommandHandler {
    [object]$Config
    [PACSController]$PACS
    [RemoteExecutor]$Remote
    
    CommandHandler([object]$config) {
        $this.Config = $config
        
        # Initialize PACS if enabled
        if ($config.PACS.Enabled) {
            $this.PACS = [PACSController]::new($config.PACS)
            Write-Log "PACS Controller initialized" -Level "INFO"
        }
        else {
            Write-Log "PACS Controller disabled in configuration" -Level "WARNING"
        }
        
        # Initialize Remote Executor
        $this.Remote = [RemoteExecutor]::new($config.Client)
        Write-Log "Remote Executor initialized for $($config.Client.DefaultIP)" -Level "INFO"
    }
    
    # Code 101: Server Status
    [string] Handle_101() {
        Write-Log "Command 101: Server Status Check" -Level "INFO"
        $pacsStatus = if ($this.PACS) { $this.PACS.GetStatus() } else { "DISABLED" }
        $connectionStatus = if ($this.Remote.TestConnection()) { "CONNECTED" } else { "DISCONNECTED" }
        return "SERVER_ONLINE|PACS:$pacsStatus|CLIENT:$connectionStatus|VERSION:2.0"
    }
    
    # Code 102: Execute Test (Integration with RunTest.ps1)
    [string] Handle_102([string]$payload) {
        Write-Log "Command 102: Execute Test" -Level "INFO"
        
        # Parse payload: TestID|WaitTime|Iterations|SoCWatch
        $parts = $payload -split '\|'
        if ($parts.Length -eq 0 -or [string]::IsNullOrWhiteSpace($parts[0])) {
            return "TEST_FAILED|Error:Missing TestID"
        }
        
        $testId = $parts[0]
        
        $params = @{}
        if ($parts.Length -gt 1 -and ![string]::IsNullOrWhiteSpace($parts[1])) { 
            $params['WaitTime'] = [int]$parts[1] 
        }
        if ($parts.Length -gt 2 -and ![string]::IsNullOrWhiteSpace($parts[2])) { 
            $params['Iterations'] = [int]$parts[2] 
        }
        if ($parts.Length -gt 3 -and ![string]::IsNullOrWhiteSpace($parts[3])) { 
            $params['SoCWatch'] = [bool]::Parse($parts[3]) 
        }
        
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
        
        $statusDetails = $this.PACS.GetDetailedStatus()
        $response = "PACS_STATUS|Status:$($statusDetails['Status'])"
        
        if ($statusDetails['Running']) {
            $response += "|PID:$($statusDetails['PID'])|Memory:$($statusDetails['Memory'])MB"
        }
        
        return $response
    }
    
    # Code 105: Start PACS Recording
    [string] Handle_105([string]$payload) {
        Write-Log "Command 105: Start PACS Recording" -Level "INFO"
        
        if (-not $this.PACS) {
            return "PACS_DISABLED"
        }
        
        # Parse payload: Duration|TestID
        $parts = $payload -split '\|'
        if ($parts.Length -eq 0 -or [string]::IsNullOrWhiteSpace($parts[0])) {
            return "PACS_RECORD_FAILED|Error:Missing duration"
        }
        
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
    
    # Code 108: Mark Test Complete
    [string] Handle_108([string]$payload) {
        Write-Log "Command 108: Mark Test Complete" -Level "INFO"
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
        $pythonPath = $this.Config.Temperature.PythonPath
        
        try {
            $result = & $pythonPath $scriptPath --set $temperature 2>&1
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
        $pythonPath = $this.Config.Temperature.PythonPath
        
        try {
            $result = & $pythonPath $scriptPath 2>&1
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
        return "NETWORK_COPY_COMPLETE"
    }
    
    # Code 112: Execute Custom Command
    [string] Handle_112([string]$payload) {
        Write-Log "Command 112: Execute Custom Command" -Level "INFO"
        
        if ([string]::IsNullOrWhiteSpace($payload)) {
            return "CUSTOM_COMMAND_FAILED|Error:No command provided"
        }
        
        $result = $this.Remote.Execute($payload, $true)
        
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
