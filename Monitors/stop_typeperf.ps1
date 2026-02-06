#==============================================================================
# Script Name:       stop_typeperf.ps1
# Description:       Stop TYPEPERF data collection and timestamp output
# Original Author:   Sriram Ranganathan
# Modified by:       Sriram Ranganathan
# Date:              November 7, 2024
# Version:           1.0
#==============================================================================

<#
.SYNOPSIS
  Stops typeperf performance counter data collection

.DESCRIPTION
  Terminates the typeperf data collection process initiated by start_typeperf.ps1 and
  properly timestamps the output CSV files. This script ensures clean shutdown of
  performance monitoring and data integrity.

.PARAMETER LogDirectory
  The directory where the performance counter CSV file is being saved

.PARAMETER FileName
  The base name for the performance counter CSV file

.EXAMPLE
  .\stop_typeperf.ps1
  Stops typeperf data collection with default settings

.EXAMPLE
  .\stop_typeperf.ps1 -LogDirectory "C:\Logs" -FileName "PerfCounters"
  Stops typeperf with matching directory and filename from start command

.NOTES
  This script should be paired with start_typeperf.ps1 to complete the data collection process
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$LogDirectory,

    [Parameter(Mandatory=$false)]
    [string]$FileName
)

#----------------------------------------------
# HELP AND USAGE EXAMPLES
#----------------------------------------------
# 
# This script stops the active TYPEPERF tracing session.
# 
# 1. Default Usage (No parameters - Recommended):
#    - Reads the 'typeperf_last_session_dir.txt' pointer file to find the active trace folder.
#    - Example: 
#    .\stop_typeperf.ps1
#
# 2. Explicitly specify the trace folder:
#    - Looks for session metadata inside the specified TYPEPERF trace directory.
#    - Example: 
#    .\stop_typeperf.ps1 -LogDirectory "C:\PerfLogs\MyAppMetrics"
#
# 3. Explicitly specify the output file path:
#    - Stops the trace, and renames the output file to the specified path/name, 
#      e.g., "D:\Final\FinishedMetrics.csv".
#    - Example: 
#    .\stop_typeperf.ps1 -FileName "C:\Final\MetricsRun_A.csv"
#
#----------------------------------------------


#---------------------------------------------------------------------------------------------------------
# Function: Write-Log (Injected Helper)
# Purpose: Provides standardized, color-coded logging for Telemetry scripts.
#---------------------------------------------------------------------------------------------------------
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("INFO", "ERROR", "RESULT", "WARNING", "DEBUG")]
        [string]$Level,

        [Parameter(Mandatory=$true)]
        [string]$Module,

        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    # Define color mapping
    $ColorMap = @{
        "INFO"    = "Gray";
        "ERROR"   = "Red";
        "RESULT"  = "Green";
        "WARNING" = "Yellow";
        "DEBUG"   = "DarkGray";
    }

    # Use the color map, defaulting to White if the level is not defined (shouldn't happen with ValidateSet)
    $ForegroundColor = $ColorMap[$Level] -as [System.ConsoleColor]

    # Format the output string: [Telemetry][MODULE][LEVEL] - <Message>
    $FormattedMessage = "[Telemetry][$($Module.ToUpper())][$($Level.ToUpper())] - $Message"

    # Write to host using the determined color
    Write-Host $FormattedMessage -ForegroundColor $ForegroundColor
}


#----------------------------------------------
# 1. Resolve session metadata file locations
#----------------------------------------------
$metadataBaseDir = $null
$PointerFileScript = Join-Path -Path $PSScriptRoot -ChildPath "typeperf_last_session_dir.txt"

if ([string]::IsNullOrEmpty($LogDirectory)) {
    # Default path: read pointer file from script root
    if (Test-Path $PointerFileScript) {
        $metadataBaseDir = (Get-Content $PointerFileScript -Raw).Trim()
        Write-Log -Level INFO -Module TYPEPERF -Message "Using pointer file to locate session metadata: $metadataBaseDir"
    }
} else {
    # LogDirectory provided: check for pointer file in LogDirectory first, then script root
    $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "typeperf_last_session_dir.txt"
    
    if (Test-Path $PointerFileCustom) {
        $metadataBaseDir = (Get-Content $PointerFileCustom -Raw).Trim()
        Write-Log -Level INFO -Module TYPEPERF -Message "Using custom LogDirectory pointer file for session metadata: $metadataBaseDir"
    } elseif (Test-Path $PointerFileScript) {
        $metadataBaseDir = (Get-Content $PointerFileScript -Raw).Trim()
        Write-Log -Level INFO -Module TYPEPERF -Message "Using script root pointer file for session metadata: $metadataBaseDir"
    } else {
        # No pointer file found, use LogDirectory directly as session location
        $metadataBaseDir = $LogDirectory
        Write-Log -Level INFO -Module TYPEPERF -Message "Using provided LogDirectory directly for session metadata: $metadataBaseDir"
    }
}

# Ensure a directory was found
if ([string]::IsNullOrEmpty($metadataBaseDir) -or !(Test-Path $metadataBaseDir)) {
    Write-Log -Level WARNING -Module TYPEPERF -Message "No active TYPEPERF session info or LogDirectory found. Run start_typeperf.ps1 first."
    exit
}

# The metadata files are directly in $metadataBaseDir (the TYPEPERF trace folder)
$sessionFile    = Join-Path $metadataBaseDir "typeperf_current_session.txt"
$dirFile        = Join-Path $metadataBaseDir "typeperf_current_outputdir.txt"
$pidFile        = Join-Path $metadataBaseDir "typeperf_current_pid.txt"
$outputFileInfo = Join-Path $metadataBaseDir "typeperf_current_outputfile.txt"

# Check if the metadata files exist
if (!(Test-Path $sessionFile) -or !(Test-Path $pidFile)) {
    Write-Log -Level WARNING -Module TYPEPERF -Message "No active TYPEPERF session info found in '$metadataBaseDir'. Run start_typeperf.ps1 first."
    exit
}

#----------------------------------------------
# 2. Read metadata
#----------------------------------------------
$SessionName = (Get-Content $sessionFile -Raw).Trim()
$OutputDir   = (Get-Content $dirFile -Raw).Trim()
$typeperfPid = (Get-Content $pidFile -Raw).Trim()

# Read the output filename if available (for orchestrator mode)
$OutputFileName = "typeperf_Output.csv"  # default
if (Test-Path $outputFileInfo) {
    $OutputFileName = (Get-Content $outputFileInfo -Raw).Trim()
}

Write-Log -Level INFO -Module TYPEPERF -Message "Stopping TYPEPERF session: $SessionName"
Write-Log -Level INFO -Module TYPEPERF -Message "Output directory: $OutputDir"

#----------------------------------------------
# 3. Stop TYPEPERF process
#----------------------------------------------
if ($typeperfPid) {
    try {
        $proc = Get-Process -Id $typeperfPid -ErrorAction Stop
        Write-Log -Level INFO -Module TYPEPERF -Message "Found TYPEPERF process with PID $typeperfPid. Stopping..."
        Stop-Process -Id $typeperfPid -Force
    } catch {
        Write-Log -Level WARNING -Module TYPEPERF -Message "TYPEPERF process $typeperfPid not found; it may have exited already."
    }
}

# Wait a bit for CSV file release
Write-Log -Level INFO -Module TYPEPERF -Message "Waiting briefly for file lock release..."
Start-Sleep -Seconds 1

#----------------------------------------------
# 4. Archive the CSV file
#----------------------------------------------
$originalFile = Join-Path $OutputDir $OutputFileName

# Determine final rename path
if ([string]::IsNullOrEmpty($FileName)) {
    $timestamp    = Get-Date -Format "yyyyMMdd_HHmmss"
    $renamedFile  = Join-Path $OutputDir "typeperf_Output_$timestamp.csv"
} else {
    # Use explicit filename provided by user parameter, ensure it has .csv extension and is in correct directory
    $fileNameWithExt = if ($FileName.EndsWith(".csv")) { $FileName } else { "$FileName.csv" }
    if (-not [string]::IsNullOrEmpty($LogDirectory)) {
        $renamedFile = Join-Path $LogDirectory $fileNameWithExt
    } else {
        $renamedFile = Join-Path $OutputDir $fileNameWithExt
    }
}

if (Test-Path $originalFile) {
    Write-Log -Level INFO -Module TYPEPERF -Message "Renaming typeperf output file..."
    $maxWaitSeconds = 10
    $waitTime = 0
    $fileRenamed = $false

    do {
        try {
            # Note: We must rename to the final desired name here.
            Rename-Item -Path $originalFile -NewName (Split-Path -Leaf $renamedFile) -Force -ErrorAction Stop
            $fileRenamed = $true
            break
        } catch {
            $waitTime += 0.5
            if ($waitTime -ge $maxWaitSeconds) {
                Write-Log -Level ERROR -Module TYPEPERF -Message "Timeout reached. File may still be locked."
                break
            }
            Start-Sleep -Milliseconds 500
        }
    } while (-not $fileRenamed)

    if ($fileRenamed) {
        Write-Log -Level RESULT -Module TYPEPERF -Message "TYPEPERF output archived as: $(Split-Path -Leaf $renamedFile)"
    }
} else {
    Write-Log -Level WARNING -Module TYPEPERF -Message "typeperf_Output.csv not found in $OutputDir. Skipping rename/archive."
}

#----------------------------------------------
# 5. Clean up metadata
#----------------------------------------------
Write-Log -Level INFO -Module TYPEPERF -Message "Cleaning up TYPEPERF session metadata..."
Remove-Item $sessionFile -ErrorAction SilentlyContinue
Remove-Item $dirFile     -ErrorAction SilentlyContinue
Remove-Item $pidFile     -ErrorAction SilentlyContinue
Remove-Item $outputFileInfo -ErrorAction SilentlyContinue

# Remove pointer files from both possible locations
if (Test-Path $PointerFileScript) {
    Remove-Item $PointerFileScript -ErrorAction SilentlyContinue
}

if (-not [string]::IsNullOrEmpty($LogDirectory)) {
    $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "typeperf_last_session_dir.txt"
    if (Test-Path $PointerFileCustom) {
        Remove-Item $PointerFileCustom -ErrorAction SilentlyContinue
    }
}

Write-Log -Level RESULT -Module TYPEPERF -Message "TYPEPERF data collection stopped successfully. Final data saved to: $OutputDir"
exit 0