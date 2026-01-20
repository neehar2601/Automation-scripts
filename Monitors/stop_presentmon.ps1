#==============================================================================
# Script Name:       stop_presentmon.ps1
# Description:       Stop the running PresentMon session and terminate the process
# Original Author:   Sriram Ranganathan
# Modified by:       Sriram Ranganathan
# Date:              November 7, 2024
# Version:           1.0
#==============================================================================

<#
.SYNOPSIS
  Stops PresentMon GPU performance data collection

.DESCRIPTION
  Terminates the PresentMon data collection process initiated by start_presentmon.ps1
  and ensures proper cleanup of GPU monitoring processes. Finalizes the CSV output
  with collected GPU performance metrics.

.PARAMETER LogDirectory
  The directory where the PresentMon CSV file is being saved

.PARAMETER FileName
  The base name for the PresentMon CSV file

.EXAMPLE
  .\stop_presentmon.ps1
  Stops PresentMon data collection with default settings

.EXAMPLE
  .\stop_presentmon.ps1 -LogDirectory "C:\Logs" -FileName "GPUMetrics"
  Stops PresentMon with matching directory and filename from start command

.NOTES
  This script should be paired with start_presentmon.ps1 to complete the GPU monitoring process
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$LogDirectory,

    [Parameter(Mandatory=$false)]
    [string]$FileName
)

#---------------------------------------------------------------------------------------------------------
# Function: Write-Log (Helper)
# Purpose: Provides standardized, color-coded logging for Telemetry scripts.
# NOTE: This function should ideally be imported, but is duplicated for standalone execution.
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
# 1. Define executable and session file names
#----------------------------------------------
# 1. Resolve session metadata file locations
#----------------------------------------------
$PresentMonExeName = "PresentMon-2.3.1-x64.exe"
$PresentMonProcessName = $PresentMonExeName -replace '\.exe$', ''

$metadataBaseDir = $null
$PointerFileScript = Join-Path -Path $PSScriptRoot -ChildPath "presentmon_last_session_dir.txt"

if ([string]::IsNullOrEmpty($LogDirectory)) {
    # Default path: read pointer file from script root
    if (Test-Path $PointerFileScript) {
        $metadataBaseDir = (Get-Content $PointerFileScript -Raw).Trim()
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "Using pointer file to locate session metadata: $metadataBaseDir"
    }
} else {
    # LogDirectory provided: check for pointer file in LogDirectory first, then script root
    $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "presentmon_last_session_dir.txt"
    
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

#----------------------------------------------
# 2. Check for required metadata directory
#----------------------------------------------
if ([string]::IsNullOrEmpty($metadataBaseDir) -or !(Test-Path $metadataBaseDir)) {
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "No active PRESENTMON session info or LogDirectory found. Run start_presentmon.ps1 first."
    exit
}

# Use the resolved directory as OutputDir
$OutputDir = $metadataBaseDir

# Get the authoritative session files from the output directory
$sessionFileRun = Join-Path $OutputDir "presentmon_current_session.txt"
$dirFileRun     = Join-Path $OutputDir "presentmon_current_outputdir.txt"

# Determine final output file path
if (-not [string]::IsNullOrEmpty($LogDirectory) -and -not [string]::IsNullOrEmpty($FileName)) {
    # Use provided LogDirectory and FileName parameters
    $OutputFile = Join-Path $LogDirectory "$FileName.csv"
} else {
    # Use default path from the session
    $OutputFile = Join-Path $OutputDir "PresentMon_Output.csv"
}


#----------------------------------------------
# 3. Check for the running PresentMon process
#----------------------------------------------
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Searching for running PresentMon process: '$PresentMonProcessName'..."
$PresentMonProcesses = Get-Process -Name $PresentMonProcessName -ErrorAction SilentlyContinue

if (-not $PresentMonProcesses) {
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "No running PresentMon process found."
    # Even if process isn't found, we'll try to terminate the session just in case it's a lingering ETW trace.
}


#----------------------------------------------
# 4. Terminate the PresentMon session and process
#----------------------------------------------
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Terminating PresentMon session and process..."

$presentmonCmd = Get-Command $PresentMonExeName -ErrorAction SilentlyContinue
if (-not $presentmonCmd) {
    Write-LogEntry -Module TELEMETRY -Type ERROR -Message "'$PresentMonExeName' was not found in PATH. Cannot use it to terminate session."
} else {
    try {
        & $presentmonCmd.Path --terminate_existing_session | Out-Null
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "PresentMon ETW session terminated."
    } catch {
        Write-LogEntry -Module TELEMETRY -Type WARNING -Message "Could not terminate ETW session cleanly. Details: $($_.Exception.Message)"
    }
}

if ($PresentMonProcesses) {
    Stop-Process -InputObject $PresentMonProcesses -Force -ErrorAction SilentlyContinue
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "PresentMon background process killed."
}


#----------------------------------------------
# 5. Final cleanup and summary
#----------------------------------------------
# Remove session metadata files
Remove-Item $sessionFileRun, $dirFileRun -ErrorAction SilentlyContinue

# Remove pointer files from both possible locations
if (Test-Path $PointerFileScript) {
    Remove-Item $PointerFileScript -ErrorAction SilentlyContinue
}

if (-not [string]::IsNullOrEmpty($LogDirectory)) {
    $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "presentmon_last_session_dir.txt"
    if (Test-Path $PointerFileCustom) {
        Remove-Item $PointerFileCustom -ErrorAction SilentlyContinue
    }
}

# Check if we need to move the output file to a custom location
$originalOutputFile = Join-Path $OutputDir "PresentMon_Output.csv"
$finalOutputFile = $OutputFile

# If custom parameters were provided and original file exists, move it
if (-not [string]::IsNullOrEmpty($LogDirectory) -and -not [string]::IsNullOrEmpty($FileName)) {
    if (Test-Path $originalOutputFile) {
        # Ensure the target directory exists
        $targetDir = Split-Path $finalOutputFile -Parent
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        # Move the file to the custom location
        try {
            Move-Item $originalOutputFile $finalOutputFile -Force
            Write-LogEntry -Module TELEMETRY -Type INFO -Message "Moved output file to custom location: $finalOutputFile"
        } catch {
            Write-LogEntry -Module TELEMETRY -Type WARNING -Message "Could not move file to custom location. Error: $($_.Exception.Message)"
            $finalOutputFile = $originalOutputFile  # Fall back to original location
        }
    }
}

Write-LogEntry -Module TELEMETRY -Type INFO -Message "Checking for output file: $finalOutputFile"
if (Test-Path $finalOutputFile) {
    $fileSize = (Get-Item $finalOutputFile).Length / 1MB | ForEach-Object { "{0:N2}" -f $_ }
    Write-LogEntry -Module TELEMETRY -Type RESULT -Message "PRESENTMON data collection stopped. Output file saved to: $finalOutputFile ($fileSize MB)"
} else {
    Write-LogEntry -Module TELEMETRY -Type ERROR -Message "PRESENTMON output file was NOT created or is missing: $finalOutputFile"
}
exit 0