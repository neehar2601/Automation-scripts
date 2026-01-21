# ----------------------------------------------------------------------------------
# SoCWatch Helper - Combined Start/Stop/Results
# Simplified interface for SoCWatch monitoring
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
  Combined SoCWatch control script

.DESCRIPTION
  Controls SoCWatch monitoring sessions with start, stop, and results retrieval

.PARAMETER Action
  Action to perform: Start, Stop, or GetResults

.PARAMETER LogDirectory
  Directory where SoCWatch results will be stored

.PARAMETER FileName
  Base name for the SoCWatch results (test ID)

.PARAMETER Flags
  SoCWatch collection flags (default: -f sys -f cpu -f gfx -f power -f temp)

.PARAMETER WaitTime
  Wait time before starting collection (seconds)

.PARAMETER RunTime
  Duration to collect data (0 = until stopped manually)

.EXAMPLE
  .\SoCWatchHelper.ps1 -Action Start -LogDirectory "C:\Results" -FileName "GLD1015"

.EXAMPLE
  .\SoCWatchHelper.ps1 -Action Stop -LogDirectory "C:\Results" -FileName "GLD1015"

.EXAMPLE
  .\SoCWatchHelper.ps1 -Action GetResults -LogDirectory "C:\Results" -FileName "GLD1015"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Start", "Stop", "GetResults")]
    [string]$Action,

    [Parameter(Mandatory=$true)]
    [string]$LogDirectory,

    [Parameter(Mandatory=$true)]
    [string]$FileName,

    [Parameter(Mandatory=$false)]
    [string]$Flags = "-f sys -f cpu -f gfx -f power -f temp -f display -f io",

    [Parameter(Mandatory=$false)]
    [int]$WaitTime = 0,

    [Parameter(Mandatory=$false)]
    [int]$RunTime = 0
)

# Resolve paths
$BaseTestId = $FileName -replace '_socwatch$', ''
$SessionFolderName = if ($FileName -match '_socwatch$') { $FileName } else { "$BaseTestId`_socwatch" }
$logLeaf = Split-Path -Path $LogDirectory -Leaf

if ($logLeaf -like "$BaseTestId*" -and $logLeaf -notlike "*$SessionFolderName") {
    $OutputDir = $LogDirectory
} else {
    $OutputDir = Join-Path -Path $LogDirectory -ChildPath $SessionFolderName
}

# Find SoCWatch executables
function Find-SoCWatchExe {
    param([string]$ExeName)
    
    $exePath = Get-Command $ExeName -ErrorAction SilentlyContinue
    if ($exePath) {
        return $exePath.Source
    }
    
    $commonPaths = @(
        "C:\KSR_Package\KSR\Test_Run_KR\tools\socwatch\64",
        "C:\Tools\socwatch\64",
        "C:\Program Files\Intel Corporation\Intel(R) System Scope Tool",
        "C:\Program Files\Intel\SoCWatch\bin",
        "C:\Program Files (x86)\Intel\SoCWatch\bin"
    )
    
    foreach ($path in $commonPaths) {
        $fullPath = Join-Path $path $ExeName
        if (Test-Path $fullPath) {
            return $fullPath
        }
    }
    
    throw "Could not find $ExeName in PATH or common locations"
}

# ============================================================================
# START ACTION
# ============================================================================
if ($Action -eq "Start") {
    Write-Host "[SoCWatch] Starting monitoring session" -ForegroundColor Cyan
    
    # Create output directory
    if (!(Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    # Find socwatch.exe
    $socwatchExe = Find-SoCWatchExe -ExeName "socwatch.exe"
    Write-Host "[SoCWatch] Using: $socwatchExe" -ForegroundColor Gray
    
    # Build arguments
    $socwatchPrefix = $SessionFolderName
    $socwatchArgs = "$Flags -o `"$socwatchPrefix`""
    
    if ($WaitTime -gt 0 -and $RunTime -gt 0) {
        $socwatchArgs += " -s $WaitTime -t $RunTime"
        Write-Host "[SoCWatch] Mode: Timed (Wait: $WaitTime`s, Run: $RunTime`s)" -ForegroundColor Gray
    } elseif ($WaitTime -gt 0 -and $RunTime -eq 0) {
        Write-Host "[SoCWatch] Mode: Wait for completion (Wait: $WaitTime`s)" -ForegroundColor Gray
    } else {
        Write-Host "[SoCWatch] Mode: Immediate start" -ForegroundColor Gray
    }
    
    Write-Host "[SoCWatch] Output: $OutputDir" -ForegroundColor Gray
    
    # Start SoCWatch in a new visible window
    $pidFile = Join-Path $OutputDir "socwatch.pid"
    
    # Launch SoCWatch in new window
    try {
        $proc = Start-Process -FilePath $socwatchExe `
                              -ArgumentList $socwatchArgs `
                              -WorkingDirectory $OutputDir `
                              -PassThru `
                              -WindowStyle Hidden
        
        # Save PID to file
        if ($proc -and $proc.Id) {
            $proc.Id | Set-Content -Path $pidFile -Encoding ascii -Force -ErrorAction SilentlyContinue
            Write-Host "[SoCWatch] Started in new window (PID: $($proc.Id))" -ForegroundColor Green
        } else {
            Write-Host "[SoCWatch] Started in new window" -ForegroundColor Green
        }
    } catch {
        Write-Host "[SoCWatch] Failed to start: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    
    exit 0
}

# ============================================================================
# STOP ACTION
# ============================================================================
if ($Action -eq "Stop") {
    Write-Host "[SoCWatch] Stopping monitoring session" -ForegroundColor Cyan
    
    # Find SoCWatchHelper.exe
    $socwatchHelper = Find-SoCWatchExe -ExeName "SoCWatchHelper.exe"
    Write-Host "[SoCWatch] Using: $socwatchHelper" -ForegroundColor Gray
    
    # Stop SoCWatch
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $socwatchHelper
    $psi.Arguments = "-stop"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    
    try {
        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()
        
        if ($proc.ExitCode -eq 0) {
            Write-Host "[SoCWatch] Stopped successfully" -ForegroundColor Green
        } else {
            Write-Host "[SoCWatch] Stop returned exit code: $($proc.ExitCode)" -ForegroundColor Yellow
            if ($stderr) { Write-Host "[SoCWatch] Error: $stderr" -ForegroundColor Red }
        }
        
        $proc.Dispose()
    } catch {
        Write-Host "[SoCWatch] Failed to stop: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    
    # Cleanup PID file
    $pidFile = Join-Path $OutputDir "socwatch.pid"
    if (Test-Path $pidFile) {
        Remove-Item -Path $pidFile -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "[SoCWatch] Results saved to: $OutputDir" -ForegroundColor Gray
    
    exit 0
}

# ============================================================================
# GET RESULTS ACTION
# ============================================================================
if ($Action -eq "GetResults") {
    Write-Host "[SoCWatch] Retrieving results information" -ForegroundColor Cyan
    
    if (!(Test-Path $OutputDir)) {
        Write-Host "[SoCWatch] Results directory not found: $OutputDir" -ForegroundColor Red
        exit 1
    }
    
    $allFiles = Get-ChildItem -Path $OutputDir -File -Recurse
    $fileCount = ($allFiles | Measure-Object).Count
    $totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
    $csvFiles = $allFiles | Where-Object { $_.Extension -eq '.csv' }
    $csvCount = ($csvFiles | Measure-Object).Count
    $etlFiles = $allFiles | Where-Object { $_.Extension -eq '.etl' }
    $etlCount = ($etlFiles | Measure-Object).Count
    
    Write-Host "`n[SoCWatch] Results Summary" -ForegroundColor Cyan
    Write-Host "  Location : $OutputDir" -ForegroundColor White
    Write-Host "  Files    : $fileCount total" -ForegroundColor White
    Write-Host "  CSV Files: $csvCount" -ForegroundColor White
    Write-Host "  ETL Files: $etlCount" -ForegroundColor White
    Write-Host "  Size     : $([math]::Round($totalSize/1MB, 2)) MB" -ForegroundColor White
    
    if ($csvFiles) {
        Write-Host "`n[SoCWatch] CSV Files:" -ForegroundColor Cyan
        foreach ($csv in $csvFiles) {
            Write-Host "  - $($csv.Name) ($([math]::Round($csv.Length/1KB, 2)) KB)" -ForegroundColor Gray
        }
    }
    
    if ($etlFiles) {
        Write-Host "`n[SoCWatch] ETL Files:" -ForegroundColor Cyan
        foreach ($etl in $etlFiles) {
            Write-Host "  - $($etl.Name) ($([math]::Round($etl.Length/1MB, 2)) MB)" -ForegroundColor Gray
        }
    }
    
    # Return results as object for pipeline use
    $results = @{
        OutputDirectory = $OutputDir
        TotalFiles = $fileCount
        CSVFiles = $csvCount
        ETLFiles = $etlCount
        TotalSizeMB = [math]::Round($totalSize/1MB, 2)
        Files = $allFiles | Select-Object Name, Length, Extension, FullName
    }
    
    return $results
}
