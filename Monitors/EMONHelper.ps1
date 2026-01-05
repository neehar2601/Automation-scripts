# ----------------------------------------------------------------------------------
# EMON Helper - Combined Start/Stop/Results
# Simplified interface for EMON monitoring with minimized window
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
  Combined EMON control script

.DESCRIPTION
  Controls EMON monitoring sessions with start, stop, and results retrieval.
  EMON runs in a new minimized window for easy monitoring.

.PARAMETER Action
  Action to perform: Start, Stop, or GetResults

.PARAMETER LogDirectory
  Directory where EMON results will be stored

.PARAMETER FileName
  Base name for the EMON results file (will add .dat extension)

.EXAMPLE
  .\EMONHelper.ps1 -Action Start -LogDirectory "C:\Results" -FileName "GLD1015"

.EXAMPLE
  .\EMONHelper.ps1 -Action Stop -LogDirectory "C:\Results" -FileName "GLD1015"

.EXAMPLE
  .\EMONHelper.ps1 -Action GetResults -LogDirectory "C:\Results" -FileName "GLD1015"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Start", "Stop", "GetResults")]
    [string]$Action,

    [Parameter(Mandatory=$true)]
    [string]$LogDirectory,

    [Parameter(Mandatory=$true)]
    [string]$FileName
)

# Ensure .dat extension
$FileNameWithExt = if ($FileName.EndsWith(".dat")) { $FileName } else { "$FileName.dat" }
$OutputDir = $LogDirectory

# Find EMON executable
function Find-EMONExe {
    $emonPath = (Get-Command emon -ErrorAction SilentlyContinue).Path
    
    if ($emonPath) {
        return $emonPath
    }
    
    $commonPaths = @(
        "C:\Program Files\Intel\VTune Profiler\bin64",
        "C:\Program Files (x86)\Intel\VTune Profiler\bin64",
        "C:\Intel\VTune\bin64",
        "C:\Tools\EMON",
        "C:\KSR_Package\KSR\Test_Run_KR\tools\emon"
    )
    
    foreach ($path in $commonPaths) {
        $fullPath = Join-Path $path "emon.exe"
        if (Test-Path $fullPath) {
            return $fullPath
        }
    }
    
    throw "Could not find emon.exe in PATH or common locations"
}

# ============================================================================
# START ACTION
# ============================================================================
if ($Action -eq "Start") {
    Write-Host "[EMON] Starting monitoring session" -ForegroundColor Cyan
    
    # Create output directory
    if (!(Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    # Find emon.exe
    $emonExe = Find-EMONExe
    Write-Host "[EMON] Using: $emonExe" -ForegroundColor Gray
    
    # EMON arguments for EDP collection
    $emonArgs = "-collect-edp -f Emon_Output.dat"
    
    Write-Host "[EMON] Mode: EDP collection" -ForegroundColor Gray
    Write-Host "[EMON] Output: $OutputDir" -ForegroundColor Gray
    
    # Metadata files
    $sessionFile = Join-Path $OutputDir "emon_current_session.txt"
    $dirFile = Join-Path $OutputDir "emon_current_outputdir.txt"
    $pidFile = Join-Path $OutputDir "emon_current_pid.txt"
    $requestedNameFile = Join-Path $OutputDir "emon_requested_filename.txt"
    $pointerFile = Join-Path $PSScriptRoot "emon_last_session_dir.txt"
    
    # Start EMON in minimized window
    try {
        $proc = Start-Process -FilePath $emonExe `
                              -ArgumentList $emonArgs `
                              -WorkingDirectory $OutputDir `
                              -PassThru `
                              -WindowStyle Minimized
        
        if ($proc -and $proc.Id) {
            # Save session metadata
            "EMON_Session" | Out-File -FilePath $sessionFile -Encoding ascii
            $OutputDir | Out-File -FilePath $dirFile -Encoding ascii
            $proc.Id | Out-File -FilePath $pidFile -Encoding ascii
            $FileNameWithExt | Out-File -FilePath $requestedNameFile -Encoding ascii
            $OutputDir | Out-File -FilePath $pointerFile -Encoding ascii
            
            Write-Host "[EMON] Started in minimized window (PID: $($proc.Id))" -ForegroundColor Green
            Write-Host "[EMON] Session metadata saved" -ForegroundColor Gray
        } else {
            Write-Host "[EMON] Started in minimized window" -ForegroundColor Green
        }
    } catch {
        Write-Host "[EMON] Failed to start: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    
    exit 0
}

# ============================================================================
# STOP ACTION
# ============================================================================
if ($Action -eq "Stop") {
    Write-Host "[EMON] Stopping monitoring session" -ForegroundColor Cyan
    
    # Read session metadata
    $pointerFile = Join-Path $PSScriptRoot "emon_last_session_dir.txt"
    
    if (Test-Path $pointerFile) {
        $metadataDir = (Get-Content $pointerFile -Raw).Trim()
    } else {
        $metadataDir = $OutputDir
    }
    
    $sessionFile = Join-Path $metadataDir "emon_current_session.txt"
    $pidFile = Join-Path $metadataDir "emon_current_pid.txt"
    $requestedNameFile = Join-Path $metadataDir "emon_requested_filename.txt"
    
    if (!(Test-Path $sessionFile)) {
        Write-Host "[EMON] No active session found" -ForegroundColor Yellow
        exit 0
    }
    
    # Try to stop by PID first
    $stoppedByPid = $false
    if (Test-Path $pidFile) {
        $emonPid = (Get-Content $pidFile -Raw).Trim()
        if ($emonPid) {
            try {
                $proc = Get-Process -Id $emonPid -ErrorAction Stop
                Write-Host "[EMON] Stopping process (PID: $emonPid)..." -ForegroundColor Yellow
                Stop-Process -Id $emonPid -Force
                Start-Sleep -Seconds 2
                $stoppedByPid = $true
                Write-Host "[EMON] Process stopped successfully" -ForegroundColor Green
            } catch {
                Write-Host "[EMON] Process not found (may have already exited)" -ForegroundColor Yellow
            }
        }
    }
    
    # Fallback: use emon -stop command
    if (-not $stoppedByPid) {
        Write-Host "[EMON] Attempting fallback 'emon -stop' command..." -ForegroundColor Yellow
        try {
            $emonExe = Find-EMONExe
            Push-Location $metadataDir
            & $emonExe -stop *>&1 | Out-Null
            Write-Host "[EMON] Stop command executed" -ForegroundColor Green
            Pop-Location
        } catch {
            Write-Host "[EMON] Stop command failed: $($_.Exception.Message)" -ForegroundColor Red
            Pop-Location
        }
    }
    
    # Wait for output file and rename it
    $originalFile = Join-Path $metadataDir "Emon_Output.dat"
    $maxWaitSeconds = 30
    $waitTime = 0
    $fileRenamed = $false
    
    # Determine final filename
    if (Test-Path $requestedNameFile) {
        $requestedName = (Get-Content $requestedNameFile -Raw).Trim()
        $renamedFile = Join-Path $metadataDir $requestedName
    } else {
        $renamedFile = Join-Path $metadataDir $FileNameWithExt
    }
    
    if (Test-Path $originalFile) {
        Write-Host "[EMON] Waiting for file to be released..." -ForegroundColor Gray
        
        do {
            try {
                Rename-Item -Path $originalFile -NewName (Split-Path -Leaf $renamedFile) -Force -ErrorAction Stop
                $fileRenamed = $true
                break
            } catch {
                $waitTime += 0.5
                if ($waitTime -ge $maxWaitSeconds) {
                    Write-Host "[EMON] Timeout: Could not rename output file (may be locked)" -ForegroundColor Red
                    break
                }
                Start-Sleep -Milliseconds 500
            }
        } while (-not $fileRenamed)
        
        if ($fileRenamed) {
            Write-Host "[EMON] Output file saved as: $(Split-Path -Leaf $renamedFile)" -ForegroundColor Green
        }
    } else {
        Write-Host "[EMON] Warning: Output file not found at $originalFile" -ForegroundColor Yellow
    }
    
    # Clean up metadata files
    Write-Host "[EMON] Cleaning up session metadata..." -ForegroundColor Gray
    Remove-Item $sessionFile -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $metadataDir "emon_current_outputdir.txt") -ErrorAction SilentlyContinue
    Remove-Item $pidFile -ErrorAction SilentlyContinue
    Remove-Item $requestedNameFile -ErrorAction SilentlyContinue
    Remove-Item $pointerFile -ErrorAction SilentlyContinue
    
    Write-Host "[EMON] Session stopped. Results saved to: $metadataDir" -ForegroundColor Green
    
    exit 0
}

# ============================================================================
# GET RESULTS ACTION
# ============================================================================
if ($Action -eq "GetResults") {
    Write-Host "[EMON] Retrieving results information" -ForegroundColor Cyan
    
    if (!(Test-Path $OutputDir)) {
        Write-Host "[EMON] Results directory not found: $OutputDir" -ForegroundColor Red
        exit 1
    }
    
    # Look for .dat files
    $datFiles = Get-ChildItem -Path $OutputDir -Filter "*.dat" -File
    $datCount = ($datFiles | Measure-Object).Count
    
    # Get all files for total size
    $allFiles = Get-ChildItem -Path $OutputDir -File -Recurse
    $totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
    
    Write-Host "`n[EMON] Results Summary" -ForegroundColor Cyan
    Write-Host "  Location  : $OutputDir" -ForegroundColor White
    Write-Host "  DAT Files : $datCount" -ForegroundColor White
    Write-Host "  Total Size: $([math]::Round($totalSize/1MB, 2)) MB" -ForegroundColor White
    
    if ($datFiles) {
        Write-Host "`n[EMON] Data Files:" -ForegroundColor Cyan
        foreach ($file in $datFiles) {
            Write-Host "  - $($file.Name) ($([math]::Round($file.Length/1MB, 2)) MB)" -ForegroundColor Gray
        }
    } else {
        Write-Host "`n[EMON] No .dat files found" -ForegroundColor Yellow
    }
    
    # Return results as object for pipeline use
    $results = @{
        OutputDirectory = $OutputDir
        DATFiles = $datCount
        TotalSizeMB = [math]::Round($totalSize/1MB, 2)
        Files = $datFiles | Select-Object Name, Length, FullName
    }
    
    return $results
}
