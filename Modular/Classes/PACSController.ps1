# PACSController.ps1
# PACS integration class

class PACSController {
    [string]$ExePath
    [string]$ConfigPath
    [string]$ResultPath
    [string]$ProcessName
    [object]$Process
    
    PACSController([object]$config) {
        $this.ExePath = $config.ExePath
        $this.ConfigPath = $config.ConfigPath
        $this.ResultPath = $config.ResultPath
        $this.ProcessName = if ($config.ProcessName) { $config.ProcessName } else { "pacs" }
    }
    
    [bool] IsRunning() {
        # Check if PACS process is running
        $pacsProcess = Get-Process -Name $this.ProcessName -ErrorAction SilentlyContinue
        return ($null -ne $pacsProcess)
    }
    
    [string] GetStatus() {
        if ($this.IsRunning()) {
            return "RUNNING"
        }
        return "STOPPED"
    }
    
    [hashtable] GetDetailedStatus() {
        $isRunning = $this.IsRunning()
        $status = @{
            Running = $isRunning
            Status = if ($isRunning) { "RUNNING" } else { "STOPPED" }
            ProcessName = $this.ProcessName
            ExePath = $this.ExePath
        }
        
        if ($isRunning) {
            $proc = Get-Process -Name $this.ProcessName -ErrorAction SilentlyContinue | Select-Object -First 1
            $status['PID'] = $proc.Id
            $status['StartTime'] = $proc.StartTime
            $status['CPU'] = $proc.CPU
            $status['Memory'] = [math]::Round($proc.WorkingSet64 / 1MB, 2)
        }
        
        return $status
    }
    
    [void] Start() {
        if ($this.IsRunning()) {
            Write-Log "PACS already running" -Level "WARNING"
            return
        }
        
        Write-Log "Starting PACS from $($this.ExePath)" -Level "INFO"
        
        if (-not (Test-Path $this.ExePath)) {
            throw "PACS executable not found: $($this.ExePath)"
        }
        
        $this.Process = Start-Process -FilePath $this.ExePath -PassThru -WindowStyle Hidden
        Start-Sleep -Seconds 3
        
        if ($this.IsRunning()) {
            Write-Log "PACS started successfully (PID: $($this.Process.Id))" -Level "SUCCESS"
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
        Stop-Process -Name $this.ProcessName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        if (-not $this.IsRunning()) {
            Write-Log "PACS stopped successfully" -Level "SUCCESS"
        }
        else {
            Write-Log "Failed to stop PACS cleanly" -Level "WARNING"
        }
    }
    
    [void] Restart() {
        Write-Log "Restarting PACS" -Level "INFO"
        $this.Stop()
        Start-Sleep -Seconds 2
        $this.Start()
    }
    
    [void] Record([int]$duration, [string]$testId) {
        if (-not $this.IsRunning()) {
            throw "PACS not running. Start PACS first."
        }
        
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $resultFile = Join-Path $this.ResultPath "${testId}_${timestamp}"
        Write-Log "Starting PACS recording for $duration seconds to $resultFile" -Level "INFO"
        
        # Ensure result directory exists
        if (-not (Test-Path $this.ResultPath)) {
            New-Item -ItemType Directory -Path $this.ResultPath -Force | Out-Null
            Write-Log "Created result directory: $($this.ResultPath)" -Level "INFO"
        }
        
        # This would integrate with actual PACS Python API via Python.NET or COM
        # For now, placeholder for the actual implementation
        Write-Log "PACS recording started (duration: $duration seconds)" -Level "SUCCESS"
    }
}
