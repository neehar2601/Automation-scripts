# ----------------------------------------------------------------------------------
# PowerMeter Helper - SystemMeter Control
# Handles start, stop, and results retrieval for Intel SystemMeter
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
  PowerMeter (SystemMeter) control script

.DESCRIPTION
  Controls Intel SystemMeter monitoring sessions with RAPL and PAC counters

.PARAMETER Action
  Action to perform: Start, Stop, or GetResults

.PARAMETER LogDirectory
  Directory where power monitoring results will be stored

.PARAMETER FileName
  Base name for the power results (test ID)

.PARAMETER Duration
  Duration to collect power data (seconds)

.EXAMPLE
  .\PowerMeterHelper.ps1 -Action Start -LogDirectory "C:\Results" -FileName "GLD1015" -Duration 300

.EXAMPLE
  .\PowerMeterHelper.ps1 -Action Stop

.EXAMPLE
  .\PowerMeterHelper.ps1 -Action GetResults -LogDirectory "C:\Results" -FileName "GLD1015"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Start", "Stop", "GetResults")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$LogDirectory = "",
    
    [Parameter(Mandatory=$false)]
    [string]$FileName = "",
    
    [Parameter(Mandatory=$false)]
    [int]$Duration = 300
)

# Verify SystemMeter is available
$systemMeterCmd = Get-Command SystemMeter -ErrorAction SilentlyContinue
if (-not $systemMeterCmd) {
    Write-Host "[ERROR] SystemMeter command not found. Please ensure Intel SystemMeter is installed and in PATH." -ForegroundColor Red
    exit 1
}

# ============================================================================
# START ACTION
# ============================================================================
if ($Action -eq "Start") {
    if ([string]::IsNullOrWhiteSpace($LogDirectory) -or [string]::IsNullOrWhiteSpace($FileName)) {
        Write-Host "[ERROR] LogDirectory and FileName are required for Start action" -ForegroundColor Red
        exit 1
    }

    # Ensure output directory exists
    if (-not (Test-Path $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }

    # Build output file path
    $outputFile = Join-Path $LogDirectory "$FileName`_power.csv"
    $pidFile = Join-Path $LogDirectory "$FileName`_powermeter.pid"

    Write-Host "[PowerMeter] Starting SystemMeter..." -ForegroundColor Cyan
    Write-Host "[PowerMeter] Duration: $Duration seconds" -ForegroundColor Gray
    Write-Host "[PowerMeter] Output: $outputFile" -ForegroundColor Gray
    Write-Host "[PowerMeter] RAPL: Enabled" -ForegroundColor Gray
    Write-Host "[PowerMeter] PAC: Enabled" -ForegroundColor Gray

    try {
        # Start SystemMeter with RAPL and PAC counters
        $process = Start-Process -FilePath "SystemMeter" `
            -ArgumentList "-start", "-d=$Duration", "-rapl", "-pac", "-n=`"$outputFile`"" `
            -WindowStyle Hidden `
            -PassThru
        
        # Save process ID for later stop
        if ($process) {
            $process.Id | Out-File -FilePath $pidFile -Force
            Write-Host "[PowerMeter] Started successfully with PID: $($process.Id)" -ForegroundColor Green
        } else {
            # SystemMeter might not return a process object, just save a marker
            "SystemMeter" | Out-File -FilePath $pidFile -Force
            Write-Host "[PowerMeter] Started successfully (background)" -ForegroundColor Green
        }

        Write-Host "[PowerMeter] Monitoring in progress..." -ForegroundColor Cyan
    }
    catch {
        Write-Host "[ERROR] Failed to start SystemMeter: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# STOP ACTION
# ============================================================================
elseif ($Action -eq "Stop") {
    Write-Host "[PowerMeter] Stopping SystemMeter..." -ForegroundColor Cyan

    try {
        # Stop SystemMeter
        & SystemMeter -stop
        
        Write-Host "[PowerMeter] Stopped successfully" -ForegroundColor Green

        # Clean up PID file if LogDirectory provided
        if (-not [string]::IsNullOrWhiteSpace($LogDirectory) -and -not [string]::IsNullOrWhiteSpace($FileName)) {
            $pidFile = Join-Path $LogDirectory "$FileName`_powermeter.pid"
            if (Test-Path $pidFile) {
                Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
                Write-Host "[PowerMeter] Cleaned up PID file" -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-Host "[ERROR] Failed to stop SystemMeter: $($_.Exception.Message)" -ForegroundColor Red
        # Try force stop
        try {
            Stop-Process -Name "SystemMeter" -Force -ErrorAction SilentlyContinue
            Write-Host "[PowerMeter] Force stopped SystemMeter process" -ForegroundColor Yellow
        }
        catch {
            Write-Host "[WARNING] Could not force stop SystemMeter" -ForegroundColor Yellow
        }
        exit 1
    }
}

# ============================================================================
# GET RESULTS ACTION
# ============================================================================
elseif ($Action -eq "GetResults") {
    if ([string]::IsNullOrWhiteSpace($LogDirectory) -or [string]::IsNullOrWhiteSpace($FileName)) {
        Write-Host "[ERROR] LogDirectory and FileName are required for GetResults action" -ForegroundColor Red
        exit 1
    }

    $outputFile = Join-Path $LogDirectory "$FileName`_power.csv"

    Write-Host "[PowerMeter] Retrieving results..." -ForegroundColor Cyan
    Write-Host "[PowerMeter] Output file: $outputFile" -ForegroundColor Gray

    # Wait a moment for file to be fully written
    Start-Sleep -Seconds 2

    if (Test-Path $outputFile) {
        $fileInfo = Get-Item $outputFile
        Write-Host "[PowerMeter] Power monitoring results:" -ForegroundColor Green
        Write-Host "  File: $outputFile" -ForegroundColor White
        Write-Host "  Size: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor White
        Write-Host "  Modified: $($fileInfo.LastWriteTime)" -ForegroundColor White

        # Try to parse CSV and show summary
        try {
            $csvData = Import-Csv $outputFile -ErrorAction SilentlyContinue
            if ($csvData) {
                $recordCount = ($csvData | Measure-Object).Count
                Write-Host "  Records: $recordCount" -ForegroundColor White
                
                # Show available columns
                $columns = $csvData[0].PSObject.Properties.Name
                Write-Host "  Metrics: $($columns.Count) columns" -ForegroundColor White
                Write-Host "  Columns: $($columns -join ', ')" -ForegroundColor Gray

                # Try to show power summary if available
                if ($csvData[0].PSObject.Properties.Name -contains "Package Power (W)") {
                    $avgPower = ($csvData | Measure-Object -Property "Package Power (W)" -Average).Average
                    $maxPower = ($csvData | Measure-Object -Property "Package Power (W)" -Maximum).Maximum
                    Write-Host "`n  Power Summary:" -ForegroundColor Cyan
                    Write-Host "    Average: $([math]::Round($avgPower, 2)) W" -ForegroundColor White
                    Write-Host "    Maximum: $([math]::Round($maxPower, 2)) W" -ForegroundColor White
                }
            }
        }
        catch {
            Write-Host "  (Summary stats unavailable - file may still be processing)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "[PowerMeter] WARNING: No output file found" -ForegroundColor Yellow
        Write-Host "  Expected: $outputFile" -ForegroundColor Gray
    }
}

Write-Host "[PowerMeter] Action '$Action' completed`n" -ForegroundColor Cyan
