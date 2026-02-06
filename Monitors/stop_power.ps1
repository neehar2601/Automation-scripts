#==============================================================================
# Script Name:       stop_power.ps1
# Description:       Stop SystemMeter power monitoring and save CSV data
# Original Author:   Sriram Ranganathan
# Modified by:       Sriram Ranganathan
# Date:              November 12, 2025
# Version:           1.0
#==============================================================================

<#
.SYNOPSIS
  Stops SystemMeter power monitoring and saves CSV file

.DESCRIPTION
  Terminates an active SystemMeter power monitoring session and ensures the captured 
  power data is saved to a CSV file. This script is part of the RBR telemetry 
  collection framework for power analysis and debugging.

.PARAMETER LogDirectory
  The directory where the CSV power data file is located. If not specified, uses pointer file.

.PARAMETER FileName
  The base name for the CSV power data file.

.EXAMPLE
  .\stop_power.ps1
  Stops SystemMeter power monitoring and saves CSV file using session metadata

.EXAMPLE
  .\stop_power.ps1 -LogDirectory "C:\Logs" -FileName "MyPowerTrace"
  Stops SystemMeter power monitoring with custom directory

.NOTES
  This script should be paired with start_power.ps1 to complete the power data collection process
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
# This script stops the active SystemMeter power monitoring session.
#
# 1. Default Usage (No parameters - Recommended):
#    - Reads the 'power_last_session_dir.txt' pointer file to find the active session folder.
#    - Example:
#    .\stop_power.ps1
#
# 2. Explicitly specify the session folder:
#    - Looks for session metadata inside the specified power monitoring directory.
#    - Example:
#    .\stop_power.ps1 -LogDirectory "C:\PowerData\Trace_12345"
#
# 3. Explicitly specify the output file path:
#    - Stops the session and validates the CSV file at the specified location.
#    - Example:
#    .\stop_power.ps1 -FileName "C:\Final\PowerRun_A.csv"
#
#----------------------------------------------

#----------------------------------------------
# 1. Resolve session metadata file locations
#----------------------------------------------
$metadataBaseDir = $null
$PointerFileScript = Join-Path -Path $PSScriptRoot -ChildPath "power_last_session_dir.txt"

if ([string]::IsNullOrEmpty($LogDirectory)) {
    # Default path: read pointer file from script root
    if (Test-Path $PointerFileScript) {
        $metadataBaseDir = (Get-Content $PointerFileScript -Raw).Trim()
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "Using pointer file to locate session metadata: $metadataBaseDir"
    }
} else {
    # LogDirectory provided: check for pointer file in LogDirectory first, then script root
    $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "power_last_session_dir.txt"
    
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
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "No active SystemMeter session info or LogDirectory found. Run start_power.ps1 first."
    exit
}

# The metadata files are directly in $metadataBaseDir (the power monitoring folder)
$sessionFile = Join-Path $metadataBaseDir "current_session.txt"
$dirFile     = Join-Path $metadataBaseDir "current_outputdir.txt"
$logFile     = Join-Path $metadataBaseDir "current_logfilepath.txt"

# Check if the metadata files exist
if (!(Test-Path $sessionFile) -or !(Test-Path $dirFile)) {
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "No active SystemMeter session info found in '$metadataBaseDir'. Run start_power.ps1 first."
    exit
}

#----------------------------------------------
# 2. Read session information
#----------------------------------------------
$SessionName = (Get-Content $sessionFile -Raw).Trim()
$OutputDir   = (Get-Content $dirFile -Raw).Trim()
$OriginalLogPath = (Get-Content $logFile -Raw).Trim()

Write-LogEntry -Module TELEMETRY -Type INFO -Message "Stopping SystemMeter power monitoring session: $SessionName"
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Power data recording location: $OutputDir"

#----------------------------------------------
# 3. Determine final output path
#----------------------------------------------
$csvFile = $null

if ([string]::IsNullOrEmpty($FileName)) {
    # Default: Use the original log file path from start script
    $csvFile = $OriginalLogPath
} else {
    # Override: Use the user-provided filename, but ensure it has .csv extension and is in the correct directory
    $fileNameWithExt = if ($FileName.EndsWith(".csv")) { $FileName } else { "$FileName.csv" }
    if (-not [string]::IsNullOrEmpty($LogDirectory)) {
        $csvFile = Join-Path $LogDirectory $fileNameWithExt
    } else {
        $csvFile = Join-Path $OutputDir $fileNameWithExt
    }
}

Write-LogEntry -Module TELEMETRY -Type INFO -Message "Power data file location: $csvFile"

#----------------------------------------------
# 4. Stop SystemMeter
#----------------------------------------------
try {
    SystemMeter -stop
    Write-LogEntry -Module TELEMETRY -Type RESULT -Message "SystemMeter power monitoring stopped successfully."
} catch {
    Write-LogEntry -Module TELEMETRY -Type ERROR -Message "SystemMeter -stop command failed. Details: $($_.Exception.Message)"
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "You may need to manually stop SystemMeter or check if it's still running."
    exit 1
}

# Give SystemMeter time to finalize and flush the CSV file to disk
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Waiting for SystemMeter to finalize data file..."
Start-Sleep -Seconds 3

#----------------------------------------------
# 5. Verify CSV file was created
#----------------------------------------------
if (Test-Path $csvFile) {
    $fileSize = (Get-Item $csvFile).Length
    Write-LogEntry -Module TELEMETRY -Type RESULT -Message "Power data successfully saved to: $csvFile (Size: $fileSize bytes)"
} else {
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "Warning: Expected power data file not found at: $csvFile"
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "SystemMeter may have saved data to a different location or encountered an error."
}

#----------------------------------------------
# 6. Cleanup
#----------------------------------------------
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Cleaning up SystemMeter session metadata..."

# Remove session files from the monitoring folder
Remove-Item $sessionFile -ErrorAction SilentlyContinue
Remove-Item $dirFile -ErrorAction SilentlyContinue
Remove-Item $logFile -ErrorAction SilentlyContinue

# Remove pointer files from both possible locations
if (Test-Path $PointerFileScript) {
    Remove-Item $PointerFileScript -ErrorAction SilentlyContinue
}

if (-not [string]::IsNullOrEmpty($LogDirectory)) {
    $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "power_last_session_dir.txt"
    if (Test-Path $PointerFileCustom) {
        Remove-Item $PointerFileCustom -ErrorAction SilentlyContinue
    }
}

Write-LogEntry -Module TELEMETRY -Type RESULT -Message "SystemMeter power monitoring session stopped and cleanup complete."
exit 0
