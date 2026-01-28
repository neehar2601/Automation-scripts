# RemoteExecutor.ps1
# Remote execution class using PsExec

class RemoteExecutor {
    [string]$ClientIP
    [string]$Username
    [string]$Password
    [string]$WorkingPath
    [string]$PsExecPath
    
    RemoteExecutor([object]$config) {
        $this.ClientIP = $config.DefaultIP
        $this.Username = $config.Username
        $this.Password = $config.Password
        $this.WorkingPath = $config.WorkingPath
        $this.PsExecPath = "psexec"
    }
    
    [string] BuildPsExecCommand([string]$command, [bool]$detached = $false) {
        $flags = "-accepteula -u `"$($this.Username)`" -p `"$($this.Password)`" -w `"$($this.WorkingPath)`""
        
        if ($detached) {
            $flags += " -d"
        }
        
        if ($command -like "*.ps1*") {
            $flags += " -i 1"
        }
        
        return "$($this.PsExecPath) \\$($this.ClientIP) $flags cmd /c `"$command`""
    }
    
    [hashtable] Execute([string]$command, [bool]$detached = $false, [int]$timeout = 300) {
        $psexecCmd = $this.BuildPsExecCommand($command, $detached)
        Write-Log "Executing on $($this.ClientIP): $command" -Level "INFO"
        
        try {
            $startTime = Get-Date
            $result = Invoke-Expression $psexecCmd 2>&1
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            return @{
                Success = $true
                Output = $result
                ExitCode = $LASTEXITCODE
                Duration = $duration
                StartTime = $startTime
                EndTime = $endTime
            }
        }
        catch {
            Write-Log "Remote execution failed: $($_.Exception.Message)" -Level "ERROR"
            return @{
                Success = $false
                Error = $_.Exception.Message
                ExitCode = -1
                Duration = 0
            }
        }
    }
    
    [hashtable] RunTest([string]$testId, [hashtable]$parameters) {
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
        
        return $this.Execute($command, $true)
    }
    
    [bool] TestConnection() {
        Write-Log "Testing connection to $($this.ClientIP)..." -Level "INFO"
        $ping = Test-Connection -ComputerName $this.ClientIP -Count 2 -Quiet -ErrorAction SilentlyContinue
        
        if ($ping) {
            Write-Log "Connection to $($this.ClientIP) successful" -Level "SUCCESS"
        }
        else {
            Write-Log "Cannot reach $($this.ClientIP)" -Level "ERROR"
        }
        return $ping
    }
    
    [hashtable] GetRemoteSystemInfo() {
        Write-Log "Retrieving system information from $($this.ClientIP)" -Level "INFO"
        
        try {
            $result = $this.Execute("systeminfo", $false, 30)
            
            if ($result.Success) {
                return @{
                    Success = $true
                    SystemInfo = $result.Output
                }
            }
            else {
                return @{
                    Success = $false
                    Error = $result.Error
                }
            }
        }
        catch {
            return @{
                Success = $false
                Error = $_.Exception.Message
            }
        }
    }
    
    [bool] FileExists([string]$remotePath) {
        $result = $this.Execute("if exist `"$remotePath`" (echo EXISTS) else (echo NOT_FOUND)", $false, 10)
        return ($result.Success -and $result.Output -like "*EXISTS*")
    }
}
