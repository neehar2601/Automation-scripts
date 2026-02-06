#==============================================================================
# Script Name:       stop_wpr.ps1
# Description:       Stop WPR trace and save ETL with timestamp
# Original Author:   Sriram Ranganathan
# Modified by:       Sriram Ranganathan
# Date:              November 7, 2024
# Version:           1.0
#==============================================================================

<#
.SYNOPSIS
  Stops Windows Performance Recorder (WPR) trace and saves ETL file

.DESCRIPTION
  Terminates an active WPR tracing session and saves the captured trace data to an ETL file
  with timestamp. This script is part of the RBR telemetry collection framework for
  performance analysis and debugging.

.PARAMETER LogDirectory
  The directory where the ETL trace file will be saved. If not specified, uses current directory.

.PARAMETER FileName
  The base name for the ETL trace file. Timestamp will be automatically appended.

.EXAMPLE
  .\stop_wpr.ps1
  Stops WPR trace and saves ETL file in current directory with default naming

.EXAMPLE
  .\stop_wpr.ps1 -LogDirectory "C:\Logs" -FileName "MyTrace"
  Stops WPR trace and saves ETL file to C:\Logs with custom name

.NOTES
  This script should be paired with start_wpr.ps1 to complete the trace collection process
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$LogDirectory,

    [Parameter(Mandatory=$false)]
    [string]$FileName
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
# This script stops the active WPR tracing session.
#
# 1. Default Usage (No parameters - Recommended):
#    - Reads the 'wpr_last_session_dir.txt' pointer file to find the active trace folder.
#    - Example:
#    .\stop_wpr.ps1
#
# 2. Explicitly specify the trace folder:
#    - Looks for session metadata inside the specified WPR trace directory.
#    - Example:
#    .\stop_wpr.ps1 -LogDirectory "C:\PerfTraces\Trace_12345"
#
# 3. Explicitly specify the output file path:
#    - Stops the trace, saves the ETL to the specified full path/name,
#      e.g., "D:\Final\WPRRun_A.etl".
#    - Example:
#    .\stop_wpr.ps1 -FileName "C:\Final\WPRRun_A.etl"
#
#----------------------------------------------

#----------------------------------------------
# 1. Resolve session metadata file locations
#----------------------------------------------
$metadataBaseDir = $null
$PointerFileScript = Join-Path -Path $PSScriptRoot -ChildPath "wpr_last_session_dir.txt"

if ([string]::IsNullOrEmpty($LogDirectory)) {
    # Default path: read pointer file from script root
    if (Test-Path $PointerFileScript) {
        $metadataBaseDir = (Get-Content $PointerFileScript -Raw).Trim()
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "Using pointer file to locate session metadata: $metadataBaseDir"
    }
} else {
    # LogDirectory provided: check for pointer file in LogDirectory first, then script root
    $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "wpr_last_session_dir.txt"
    
    if (Test-Path $PointerFileCustom) {
        $metadataBaseDir = (Get-Content $PointerFileCustom -Raw).Trim()
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "Using custom LogDirectory pointer file for session metadata: $metadataBaseDir"
    } elseif (Test-Path $PointerFileScript) {
        $metadataBaseDir = (Get-Content $PointerFileScript -Raw).Trim()
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "Using script root pointer file for session metadata: $metadataBaseDir"
    } else {
        # No pointer file found, use LogDirectory directly as session location
        $metadataBaseDir = $LogDirectory
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "Using provided LogDirectory directly for session metadata: $metadataBaseDir"
    }
}

# Ensure a directory was found
if ([string]::IsNullOrEmpty($metadataBaseDir) -or !(Test-Path $metadataBaseDir)) {
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "No active WPR session info or LogDirectory found. Run start_wpr.ps1 first."
    exit
}

# The metadata files are directly in $metadataBaseDir (the WPR trace folder)
$sessionFile = Join-Path $metadataBaseDir "current_session.txt"
$dirFile     = Join-Path $metadataBaseDir "current_outputdir.txt"
$logFile     = Join-Path $metadataBaseDir "current_logfilepath.txt" # This holds the final expected .etl name

# Check if the metadata files exist
if (!(Test-Path $sessionFile) -or !(Test-Path $dirFile)) {
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "No active WPR session info found in '$metadataBaseDir'. Run start_wpr.ps1 first."
    exit
}

#----------------------------------------------
# 2. Read session information
#----------------------------------------------
# WPR uses the session name stored here to stop the trace
$SessionName = (Get-Content $sessionFile -Raw).Trim()
$OutputDir   = (Get-Content $dirFile -Raw).Trim()
# $LogFilePath is the original, full path expected by WPR
$OriginalLogPath = (Get-Content $logFile -Raw).Trim()

Write-LogEntry -Module TELEMETRY -Type INFO -Message "Stopping WPR session: $SessionName"
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Temporary recording location: $OutputDir"

#----------------------------------------------
# 3. Determine final output path
#----------------------------------------------
$etlFile = $null

if ([string]::IsNullOrEmpty($FileName)) {
    # Default: Use the original log file path, but add a timestamp to the end of the name for archiving
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($OriginalLogPath)
    $ext = [System.IO.Path]::GetExtension($OriginalLogPath)
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $etlFile = Join-Path $OutputDir "${baseName}_$timestamp$ext"
} else {
    # Override: Use the user-provided filename, but ensure it has .etl extension and is in the correct directory
    $fileNameWithExt = if ($FileName.EndsWith(".etl")) { $FileName } else { "$FileName.etl" }
    if (-not [string]::IsNullOrEmpty($LogDirectory)) {
        $etlFile = Join-Path $LogDirectory $fileNameWithExt
    } else {
        $etlFile = Join-Path $OutputDir $fileNameWithExt
    }
}

Write-LogEntry -Module TELEMETRY -Type INFO -Message "Saving final trace to: $etlFile"

#----------------------------------------------
# 4. Stop WPR
#----------------------------------------------
# Note: WPR -stop requires the full final output path
try {
    wpr -stop "$etlFile" -compress 
    Write-LogEntry -Module TELEMETRY -Type RESULT -Message "Trace successfully saved and compressed as: $etlFile"
} catch {
    Write-LogEntry -Module TELEMETRY -Type ERROR -Message "WPR -stop command failed. Details: $($_.Exception.Message)"
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "You may need to run 'wpr -cancel' to clean up the session manually."
    exit 1
}

#----------------------------------------------
# 5. Cleanup
#----------------------------------------------
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Cleaning up WPR session metadata..."

# Remove session files from the trace folder
Remove-Item $sessionFile -ErrorAction SilentlyContinue
Remove-Item $dirFile -ErrorAction SilentlyContinue
Remove-Item $logFile -ErrorAction SilentlyContinue

# Remove pointer files from both possible locations
if (Test-Path $PointerFileScript) {
    Remove-Item $PointerFileScript -ErrorAction SilentlyContinue
}

if (-not [string]::IsNullOrEmpty($LogDirectory)) {
    $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "wpr_last_session_dir.txt"
    if (Test-Path $PointerFileCustom) {
        Remove-Item $PointerFileCustom -ErrorAction SilentlyContinue
    }
}

Write-LogEntry -Module TELEMETRY -Type RESULT -Message "WPR session stopped and cleanup complete."
exit 0