#==============================================================================
# Script Name:       stop_emon.ps1
# Description:       Stop EMON EDP data collection and timestamp output
# Original Author:   Sriram Ranganathan
# Modified by:       Sriram Ranganathan
# Date:              November 7, 2024
# Version:           1.0
#==============================================================================

<#
.SYNOPSIS
  Stops Intel EMON (Event Monitor) EDP data collection

.DESCRIPTION
  Terminates the EMON data collection process initiated by start_emon.ps1 and
  properly timestamps the output data files. Ensures clean shutdown of CPU
  performance monitoring and data integrity for analysis.

.PARAMETER LogDirectory
  The directory where the EMON data file is being saved

.PARAMETER FileName
  The base name for the EMON data file

.EXAMPLE
  .\stop_emon.ps1
  Stops EMON data collection with default settings

.EXAMPLE
  .\stop_emon.ps1 -LogDirectory "C:\Logs" -FileName "CPUMetrics"
  Stops EMON with matching directory and filename from start command

.NOTES
  This script should be paired with start_emon.ps1 to complete the CPU monitoring process
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
# This script stops the active EMON tracing session.
# 
# 1. Default Usage (No parameters - Recommended):
#    - Reads the 'emon_last_session_dir.txt' pointer file to find the active trace folder.
#    - Example: 
#    .\stop_emon.ps1
#
# 2. Explicitly specify the trace folder:
#    - Looks for session metadata inside the specified EMON trace directory.
#    - Example: 
#    .\stop_emon.ps1 -LogDirectory "C:\EMON_Data\EMON_Trace_20251104_102000"
#
# 3. Explicitly specify the output file path:
#    - Stops the trace, and renames the output file to the specified path/name, 
#      e.g., "D:\Final\FinishedEmon.dat".
#    - Example: 
#    .\stop_emon.ps1 -FileName "C:\Final\EmonRun_A.dat"
#
#----------------------------------------------

#---------------------------------------------------------------------------------------------------------
# Function: Write-Log (Injected Helper)
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
# 1. Resolve session metadata file locations
#----------------------------------------------
$metadataBaseDir = $null
$PointerFileScript = Join-Path -Path $PSScriptRoot -ChildPath "emon_last_session_dir.txt"

if ([string]::IsNullOrEmpty($LogDirectory)) {
    # Default path: read pointer file from script root
    if (Test-Path $PointerFileScript) {
        $metadataBaseDir = (Get-Content $PointerFileScript -Raw).Trim()
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "Using pointer file to locate session metadata: $metadataBaseDir"
    }
} else {
    # LogDirectory provided: check for pointer file in LogDirectory first, then script root
    $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "emon_last_session_dir.txt"
    
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

# 1b. Validate/Locate the actual trace folder
$traceFolder = $null
$sessionFile = $null

if ([string]::IsNullOrEmpty($metadataBaseDir) -or !(Test-Path $metadataBaseDir)) {
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "No active EMON session info or LogDirectory found. Run start_emon.ps1 first."
    # Set PointerFile to null to avoid error on cleanup if it wasn't used/found
    $PointerFile = $null 
    exit
}
elseif (Test-Path (Join-Path $metadataBaseDir "emon_current_session.txt")) {
    # Case 1: Metadata is found directly in the path (i.e., user provided the full trace folder path)
    $traceFolder = $metadataBaseDir
}
else {
    # Case 2: Metadata not found, search for a single trace subdirectory (i.e., user provided the base directory)
    $emonTraceFolders = Get-ChildItem -Path $metadataBaseDir -Filter "EMON_Trace_*" -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($emonTraceFolders.Count -gt 0) {
        $traceFolder = $emonTraceFolders[0].FullName
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "Found latest trace folder in provided directory: $(Split-Path -Leaf $traceFolder)"
    }
}

if ([string]::IsNullOrEmpty($traceFolder) -or !(Test-Path (Join-Path $traceFolder "emon_current_session.txt"))) {
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "No active EMON session info found in '$metadataBaseDir' or its subfolders. Run start_emon.ps1 first."
    exit
}

# Metadata file paths are now confirmed to be inside $traceFolder
$sessionFile = Join-Path $traceFolder "emon_current_session.txt"
$dirFile     = Join-Path $traceFolder "emon_current_outputdir.txt"
$pidFile     = Join-Path $traceFolder "emon_current_pid.txt"
$requestedNameFile = Join-Path $traceFolder "emon_requested_filename.txt"


#----------------------------------------------
# 2. Read session information
#----------------------------------------------
$SessionName = (Get-Content $sessionFile -Raw).Trim()
$OutputDir   = (Get-Content $dirFile -Raw).Trim() # This should match $traceFolder

Write-LogEntry -Module TELEMETRY -Type INFO -Message "Attempting to stop EMON session: $SessionName"
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Trace data location: $OutputDir"

#----------------------------------------------
# 3. Try PID-based stop first
#----------------------------------------------
$stoppedByPid = $false
if (Test-Path $pidFile) {
    $emonPid = (Get-Content $pidFile -Raw).Trim()
    if ($emonPid) {
        try {
            $proc = Get-Process -Id $emonPid -ErrorAction Stop
            Write-LogEntry -Module TELEMETRY -Type INFO -Message "Found EMON process with PID $emonPid. Stopping..."
            Stop-Process -Id $emonPid -Force
            $stoppedByPid = $true
        } catch {
            Write-LogEntry -Module TELEMETRY -Type WARNING -Message "Could not stop EMON by PID ($emonPid). It may have exited already."
        }
    }
}

#----------------------------------------------
# 4. Fallback: issue 'emon -stop'
#----------------------------------------------
if (-not $stoppedByPid) {
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "Fallback: Attempting EMON stop via 'emon -stop' command..."
    try {
        Push-Location $OutputDir
        emon -stop *>&1 | Out-Null
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "'emon -stop' fallback command succeeded."
    }
    catch {
        Write-LogEntry -Module TELEMETRY -Type ERROR -Message "'emon -stop' fallback failed. Details: $($_.Exception.Message)"
    }
    finally {
        Pop-Location
    }
}

#----------------------------------------------
# 5. Wait for output file and rename it
#----------------------------------------------
$maxWaitSeconds = 30
$waitTime = 0
$fileRenamed = $false
$originalFile = Join-Path $OutputDir "Emon_Output.dat"

# Determine final rename path
if (-not [string]::IsNullOrEmpty($FileName)) {
    # Use explicit filename provided by user parameter, ensure it has .dat extension and is in correct directory
    $fileNameWithExt = if ($FileName.EndsWith(".dat")) { $FileName } else { "$FileName.dat" }
    if (-not [string]::IsNullOrEmpty($LogDirectory)) {
        $renamedFile = Join-Path $LogDirectory $fileNameWithExt
    } else {
        $renamedFile = Join-Path $OutputDir $fileNameWithExt
    }
}
elseif (Test-Path $requestedNameFile) {
    # Use the name requested during start, and place it in the OutputDir
    $requestedName = (Get-Content $requestedNameFile -Raw).Trim()
    $renamedFile = Join-Path $OutputDir $requestedName
}
else {
    # Default: timestamped name inside the OutputDir
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $renamedFile = Join-Path $OutputDir "Emon_Output_$timestamp.dat"
}

if (Test-Path $originalFile) {
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Waiting for EMON to release Emon_Output.dat (max $maxWaitSeconds sec)..."

    do {
        try {
            # Note: We must rename to the final desired name. Split-Path -Leaf handles renaming within the current directory.
            Rename-Item -Path $originalFile -NewName (Split-Path -Leaf $renamedFile) -Force -ErrorAction Stop
            $fileRenamed = $true
            break
        } catch {
            $waitTime += 0.5
            if ($waitTime -ge $maxWaitSeconds) {
                Write-Log -Level ERROR -Module EMON -Message "Timeout reached; could not rename Emon_Output.dat. It may still be locked."
                break
            }
            Start-Sleep -Milliseconds 500
        }
    } while (-not $fileRenamed)

    if ($fileRenamed) {
        Write-LogEntry -Module TELEMETRY -Type RESULT -Message "EMON data output file archived to: $(Split-Path -Leaf $renamedFile)"
    }
} else {
    Write-LogEntry -Module TELEMETRY -Type WARNING -Message "Emon_Output.dat not found in $OutputDir. Skipping rename/archive."
}

#----------------------------------------------
# 6. Clean up metadata files
#----------------------------------------------
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Cleaning up EMON session metadata..."
Remove-Item $sessionFile -ErrorAction SilentlyContinue
Remove-Item $dirFile     -ErrorAction SilentlyContinue
Remove-Item $pidFile     -ErrorAction SilentlyContinue
Remove-Item $requestedNameFile -ErrorAction SilentlyContinue

# Remove pointer files from both possible locations
if (Test-Path $PointerFileScript) {
    Remove-Item $PointerFileScript -ErrorAction SilentlyContinue
}

if (-not [string]::IsNullOrEmpty($LogDirectory)) {
    $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "emon_last_session_dir.txt"
    if (Test-Path $PointerFileCustom) {
        Remove-Item $PointerFileCustom -ErrorAction SilentlyContinue
    }
}

Write-LogEntry -Module TELEMETRY -Type RESULT -Message "EMON data collection stopped successfully. Final data folder: $OutputDir"
exit 0