#==============================================================================
# Script Name:       stop_socwatch.ps1
# Description:       Stop SoCWatch monitoring and save results
# Original Author:   Sriram Ranganathan
# Modified by:       Sriram Ranganathan
# Date:              November 12, 2025
# Version:           1.0
#==============================================================================

<#
.SYNOPSIS
  Stops SoCWatch monitoring and saves results

.DESCRIPTION
  Terminates an active SoCWatch monitoring session and ensures the captured 
  SoC telemetry data is saved to the results directory. This script is part 
  of the RBR telemetry collection framework for SoC performance analysis.

.PARAMETER LogDirectory
  The directory where the SoCWatch results are located. If not specified, uses pointer file.

.PARAMETER FileName
  The base name for the SoCWatch results folder.

.EXAMPLE
  .\stop_socwatch.ps1
  Stops SoCWatch monitoring and saves results using session metadata

.EXAMPLE
  .\stop_socwatch.ps1 -LogDirectory "C:\Logs" -FileName "MySoCTrace"
  Stops SoCWatch monitoring with custom directory

.NOTES
  This script should be paired with start_socwatch.ps1 to complete the data collection process
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] [string]$LogDirectory,
    [Parameter(Mandatory=$false)] [string]$FileName,
    [Parameter(Mandatory=$false)] [switch]$SocDiag  # Renamed from -Debug to avoid common parameter collision
)

#---------------------------------------------------------------------------------------------------------
# Function: Write-LogEntry (Injected Helper)
# Purpose: Provides standardized, color-coded logging for Telemetry scripts.
#---------------------------------------------------------------------------------------------------------
function Write-LogEntry {
    param(
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("ORCH", "TELEMETRY", "TEST", "HELPER", "STRESSOR", "POSTPROCESS","PREPROCESS","SETENV")]
        [string]$Module,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "RESULT")]
        [string]$Type = "INFO",

        [Parameter(Mandatory = $true)]
        [string]$Message

    )

    $ColorMap = @{
        "INFO"    = "Gray"
        "WARNING" = "Yellow"
        "ERROR"   = "Red"
        "RESULT"  = "Green"
    }

    $Color = $ColorMap[$Type]

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp][$($Module.ToUpper())][$($Type.ToUpper())] $Message"

    Write-Host $logMessage -ForegroundColor $Color
}

#----------------------------------------------
# HELP AND USAGE EXAMPLES
#----------------------------------------------
#
# This script stops the active SoCWatch monitoring session.
#
# 1. Default Usage (No parameters - Recommended):
#    - Reads the 'socwatch_last_session_dir.txt' pointer file to find the active session folder.
#    - Example:
#    .\stop_socwatch.ps1
#
# 2. Explicitly specify the session folder:
#    - Looks for session metadata inside the specified SoCWatch monitoring directory.
#    - Example:
#    .\stop_socwatch.ps1 -LogDirectory "C:\SoCWatch_Data\Trace_12345"
#
# 3. Explicitly specify the output directory:
#    - Stops the session and validates results at the specified location.
#    - Example:
#    .\stop_socwatch.ps1 -FileName "C:\Final\SoCWatchRun_A"
#
#----------------------------------------------

#----------------------------------------------
###############################################
# STATELESS STOP LOGIC
# Reconstruct output directory from LogDirectory + FileName (normalizing suffix).
# No metadata/pointer file usage.
###############################################
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Stopping SoCWatch (stateless). Incoming: LogDirectory='${LogDirectory}' FileName='${FileName}' SocDiag='${SocDiag}'"

if ([string]::IsNullOrEmpty($LogDirectory)) {
    Write-LogEntry -Module TELEMETRY -Type ERROR -Message "LogDirectory is required for stateless stop."
    exit 1
}
if ([string]::IsNullOrEmpty($FileName)) {
    Write-LogEntry -Module TELEMETRY -Type ERROR -Message "FileName (test id) is required for stateless stop."
    exit 1
}

$BaseTestId = $FileName -replace '_socwatch$',''
$SessionFolderName = if ($FileName -match '_socwatch$') { $FileName } else { "$BaseTestId`_socwatch" }
$SessionName = $SessionFolderName
$logLeaf = Split-Path -Path $LogDirectory -Leaf
if ($logLeaf -like "$BaseTestId*" -and $logLeaf -notlike "*$SessionFolderName") {
    # LogDirectory already points to test run folder; no nested session subfolder
    $ResultsDir = $LogDirectory
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Using provided LogDirectory directly for results (leaf '$logLeaf' matches test id)."
} else {
    $ResultsDir = Join-Path -Path $LogDirectory -ChildPath $SessionFolderName
}
$TestId = $BaseTestId

Write-LogEntry -Module TELEMETRY -Type INFO -Message "Resolved results directory: $ResultsDir (TestId: $TestId, Leaf='$logLeaf')"

#----------------------------------------------
if (!(Test-Path $ResultsDir)) {
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "Results directory does not exist yet: $ResultsDir (collection may have failed)."
}

#----------------------------------------------
# 4. Find and Stop SoCWatch
#----------------------------------------------
# Find SoCWatchHelper.exe
$socwatchExe = "SoCWatchHelper.exe"

# Check if SoCWatchHelper.exe exists in PATH
$socwatchPath = Get-Command $socwatchExe -ErrorAction SilentlyContinue
if (-not $socwatchPath) {
    # Search in common Intel installation locations
    $commonPaths = @(
        "C:\Tools\socwatch\64",
        "C:\Program Files\Intel Corporation\Intel(R) System Scope Tool",
        "C:\Program Files\Intel\SoCWatch\bin",
        "C:\Program Files (x86)\Intel\SoCWatch\bin",
        "C:\Intel\SoCWatch\bin",
        "C:\Tools\SoCWatch\bin"
    )
    
    foreach ($path in $commonPaths) {
        $fullPath = Join-Path $path $socwatchExe
        if (Test-Path $fullPath) {
            $socwatchExe = $fullPath
            Write-LogEntry -Module TELEMETRY -Type INFO -Message "Found SoCWatchHelper at: $socwatchExe"
            break
        }
    }
    
    # If still not found, check if it's in the script directory
    if (-not (Test-Path $socwatchExe)) {
        $localPath = Join-Path $PSScriptRoot $socwatchExe
        if (Test-Path $localPath) {
            $socwatchExe = $localPath
            Write-LogEntry -Module TELEMETRY -Type INFO -Message "Found SoCWatchHelper in script directory: $socwatchExe"
        } else {
            Write-LogEntry -Module TELEMETRY -Type ERROR -Message "SoCWatchHelper.exe not found. Please install Intel SoCWatch or add it to PATH."
            Write-LogEntry -Module TELEMETRY -Type ERROR -Message "Searched locations: PATH, Program Files\Intel\SoCWatch\bin, and script directory"
            exit 1
        }
    }
} else {
    $socwatchExe = $socwatchPath.Source
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Found SoCWatchHelper in PATH: $socwatchExe"
}

Write-LogEntry -Module TELEMETRY -Type INFO -Message "Stopping SoCWatch monitoring..."

# Use SoCWatchHelper to stop (simpler - no job/PID cleanup needed)
$psi = [System.Diagnostics.ProcessStartInfo]::new()
$psi.FileName = $socwatchExe
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

    if ($stdout) { 
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "SoCWatchHelper output: $($stdout.Trim())" 
    }
    if ($stderr) { 
        Write-LogEntry -Module TELEMETRY -Type WARNING -Message "SoCWatchHelper stderr: $($stderr.Trim())" 
    }

    if ($proc.ExitCode -eq 0) {
        Write-LogEntry -Module TELEMETRY -Type RESULT -Message "SoCWatch monitoring stopped successfully"
    } else {
        Write-LogEntry -Module TELEMETRY -Type ERROR -Message "SoCWatchHelper returned exit code: $($proc.ExitCode)"
        exit $proc.ExitCode
    }

    $proc.Dispose()
} catch {
    Write-LogEntry -Module TELEMETRY -Type ERROR -Message "Failed to stop SoCWatch: $($_.Exception.Message)"
    exit 1
}
$pidFile = Join-Path $ResultsDir "socwatch.pid"
if (Test-Path $pidFile) { Remove-Item -Path $pidFile -ErrorAction SilentlyContinue }

#----------------------------------------------
# 5. Verify results and CSV files were created (single-directory model)
#----------------------------------------------
if (Test-Path $ResultsDir) {
    $allFiles  = Get-ChildItem -Path $ResultsDir -File -Recurse
    $fileCount = ($allFiles | Measure-Object).Count
    $totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
    $csvFiles  = $allFiles | Where-Object { $_.Extension -eq '.csv' }
    $csvCount  = ($csvFiles | Measure-Object).Count

    if ($fileCount -eq 0) {
        Write-LogEntry -Module TELEMETRY -Type WARNING -Message "No output files detected in: $ResultsDir"
    } elseif ($csvCount -gt 0) {
    Write-LogEntry -Module TELEMETRY -Type RESULT -Message "SoCWatch results saved to: $ResultsDir (TestId: $TestId)"
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "Results summary: $fileCount files ($csvCount CSV), Total size: $([math]::Round($totalSize/1MB, 2)) MB"
        foreach ($csv in $csvFiles) {
            Write-LogEntry -Module TELEMETRY -Type INFO -Message "  - $($csv.Name) ($([math]::Round($csv.Length/1KB, 2)) KB)"
        }
    } else {
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "Results directory: $ResultsDir contains $fileCount files (no CSV). ETL capture succeeded; CSV post-processing not invoked."
    }
} else {
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "Results directory not found: $ResultsDir"
}

#----------------------------------------------
# 6. Cleanup
#----------------------------------------------
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Cleanup: removed PID file if present (stateless mode)."

if ($SocDiag) {
    $summary = @{
        Timestamp    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        LogDirectory = $LogDirectory
        SessionName  = $SessionName
        TestId       = $TestId
        ResultsDir   = $ResultsDir
        FileCount    = if (Test-Path $ResultsDir) { (Get-ChildItem -Path $ResultsDir -File -Recurse | Measure-Object).Count } else { 0 }
    } | ConvertTo-Json -Depth 3
    $summary | Out-File -FilePath (Join-Path $ResultsDir "socwatch_stop_debug.json") -Encoding utf8 -Force
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "SocDiag summary written."
}

Write-LogEntry -Module TELEMETRY -Type RESULT -Message "SoCWatch monitoring stopped (stateless mode)."
exit 0
