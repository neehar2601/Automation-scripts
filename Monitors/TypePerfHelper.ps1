# ----------------------------------------------------------------------------------
# TypePerf Helper - Tool Controller
# Direct control of typeperf.exe with PID tracking
# ----------------------------------------------------------------------------------

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Start', 'Stop', 'GetResults')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$LogDirectory = "C:\Results",
    
    [Parameter(Mandatory=$false)]
    [string]$FileName = "test",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('TP', 'SC')]
    [string]$Mode = "TP",
    
    [Parameter(Mandatory=$false)]
    [int]$WaitTime = 0,
    
    [Parameter(Mandatory=$false)]
    [int]$RunTime = 0
)

# Base paths
$typePerfExe = "typeperf.exe"
$counterBasePath = "C:\KSR_Package\KSR\Test_Run_KR"

switch ($Action) {
    'Start' {
        try {
            # Determine counter file based on mode
            $counterFile = if ($Mode -eq "SC") { 
                Join-Path $counterBasePath "subsetcounters.txt" 
            } else { 
                Join-Path $counterBasePath "typeperfinputKSR.txt" 
            }
            
            # Validate counter file exists
            if (-not (Test-Path $counterFile)) {
                Write-Host "  [ERROR] Counter file not found: $counterFile" -ForegroundColor Red
                throw "Counter file not found: $counterFile"
            }
            
            $outputFile = Join-Path $LogDirectory "$($FileName)_typeperf_$Mode.csv"
            $pidFile = Join-Path $LogDirectory "$($FileName)_typeperf_$Mode.pid"
            
            Write-Host "  [TypePerf Helper] Starting TypePerf ($Mode mode)..." -ForegroundColor Cyan
            Write-Host "    Counter file: $counterFile" -ForegroundColor Gray
            Write-Host "    Output: $outputFile" -ForegroundColor Gray
            
            # Build arguments
            $arguments = @(
                "-cf", "`"$counterFile`""
                "-o", "`"$outputFile`""
            )
            
            # Add runtime limit if specified
            if ($RunTime -gt 0) {
                $arguments += "-sc", $RunTime
                Write-Host "    Sample count: $RunTime" -ForegroundColor Gray
            }
            
            # Start TypePerf in minimized window
            $process = Start-Process -FilePath $typePerfExe `
                -ArgumentList $arguments `
                -WindowStyle Minimized `
                -PassThru `
                -ErrorAction Stop
            
            # Save PID for stopping later
            $process.Id | Out-File -FilePath $pidFile -Force
            
            Write-Host "    [OK] TypePerf started (PID: $($process.Id))" -ForegroundColor Green
            Write-Host "    Window: Minimized" -ForegroundColor Gray
        }
        catch {
            Write-Host "  [ERROR] Failed to start TypePerf: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
    }
    
    'Stop' {
        try {
            $pidFile = Join-Path $LogDirectory "$($FileName)_typeperf_$Mode.pid"
            
            if (Test-Path $pidFile) {
                $pid = Get-Content $pidFile -ErrorAction SilentlyContinue
                
                if ($pid) {
                    Write-Host "  [TypePerf Helper] Stopping TypePerf (PID: $pid)..." -ForegroundColor Yellow
                    
                    # Stop the process gracefully first
                    try {
                        $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
                        if ($process) {
                            $process.CloseMainWindow() | Out-Null
                            Start-Sleep -Milliseconds 500
                            
                            # Force stop if still running
                            if (-not $process.HasExited) {
                                Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                            }
                        }
                    }
                    catch {
                        # Fallback to force stop
                        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                    }
                    
                    # Wait for graceful shutdown
                    Start-Sleep -Seconds 1
                    
                    # Cleanup PID file
                    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
                    
                    Write-Host "    [OK] TypePerf stopped" -ForegroundColor Green
                } else {
                    Write-Host "  [WARNING] PID file is empty" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  [WARNING] PID file not found, attempting to stop all typeperf processes..." -ForegroundColor Yellow
                Get-Process -Name "typeperf" -ErrorAction SilentlyContinue | Stop-Process -Force
            }
        }
        catch {
            Write-Host "  [ERROR] Failed to stop TypePerf: $($_.Exception.Message)" -ForegroundColor Red
            # Force kill as fallback
            Get-Process -Name "typeperf" -ErrorAction SilentlyContinue | Stop-Process -Force
        }
    }
    
    'GetResults' {
        try {
            $outputFile = Join-Path $LogDirectory "$($FileName)_typeperf_$Mode.csv"
            
            Write-Host "`n  [TypePerf Results] ================================" -ForegroundColor Cyan
            
            if (Test-Path $outputFile) {
                $fileInfo = Get-Item $outputFile
                Write-Host "    Output file: $outputFile" -ForegroundColor White
                Write-Host "    File size: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor Gray
                
                # Try to count samples
                try {
                    $lines = (Get-Content $outputFile | Measure-Object -Line).Lines
                    $samples = $lines - 1  # Subtract header
                    Write-Host "    Samples collected: $samples" -ForegroundColor Gray
                    
                    if ($samples -gt 0) {
                        # Calculate duration (1 sample per second by default)
                        $durationMinutes = [math]::Round($samples / 60, 2)
                        Write-Host "    Monitoring duration: ~$durationMinutes minutes" -ForegroundColor Gray
                        Write-Host "    [OK] TypePerf results collected successfully" -ForegroundColor Green
                    } else {
                        Write-Host "    [WARNING] No data samples found" -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-Host "    [WARNING] Could not parse CSV: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "    [ERROR] Output file not found: $outputFile" -ForegroundColor Red
            }
            
            Write-Host "  =================================================" -ForegroundColor Cyan
        }
        catch {
            Write-Host "  [ERROR] Failed to get TypePerf results: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
