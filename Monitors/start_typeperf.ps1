#==============================================================================
# Script Name:       start_typeperf.ps1
# Description:       Start TYPEPERF performance counter data collection (non-blocking)
# Original Author:   Sriram Ranganathan
# Modified by:       Sriram Ranganathan
# Date:              November 7, 2024
# Version:           1.0
#==============================================================================

<#
.SYNOPSIS
  Starts Windows performance counter data collection using typeperf

.DESCRIPTION
  Initiates non-blocking performance counter data collection using the Windows typeperf utility.
  Collects system metrics including CPU, memory, disk, and network performance counters
  as defined in the metrics configuration file.

.PARAMETER LogDirectory
  The directory where the performance counter CSV file will be saved

.PARAMETER FileName
  The base name for the performance counter CSV file

.EXAMPLE
  .\start_typeperf.ps1
  Starts typeperf data collection with default settings

.EXAMPLE
  .\start_typeperf.ps1 -LogDirectory "C:\Logs" -FileName "PerfCounters"
  Starts typeperf with custom directory and filename

.NOTES
  Use stop_typeperf.ps1 to terminate the data collection process
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
# This script starts a TYPEPERF tracing session, collecting metrics defined in 'typeperf_metrics.txt'.
# 
# 1. Default Usage (No parameters):
#    - Creates a folder in the script directory named 'result_[timestamp]'.
#    - Example: 
#    .\start_typeperf.ps1
#
# 2. Specify only the log directory:
#    - Uses the specified directory as the base for the timestamped trace folder.
#    - Example: 
#    .\start_typeperf.ps1 -LogDirectory "C:\PerfLogs"
#
# 3. Specify both directory and session name:
#    - Creates the trace folder under the specified directory using the specified 
#      name as the folder name.
#    - Example: 
#    .\start_typeperf.ps1 -LogDirectory "C:\PerfLogs" -FileName "MyAppMetrics"
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
# 1. Ensure typeperf is available
#----------------------------------------------
$typeperfCmd = Get-Command typeperf -ErrorAction SilentlyContinue
if (-not $typeperfCmd) {
    Write-Log -Level ERROR -Module TYPEPERF -Message "'typeperf' was not found in PATH."
    exit 1
}

#----------------------------------------------
# 2. Build session name and output location
#----------------------------------------------
if ([string]::IsNullOrEmpty($LogDirectory)) {
    # Default: A 'result' folder with a timestamp in the current script's directory.
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $BaseDir = Join-Path -Path $PSScriptRoot -ChildPath "result_$timestamp"
} else {
    # Use the provided LogDirectory.
    $BaseDir = $LogDirectory
}

if ([string]::IsNullOrEmpty($FileName)) {
    # Default: timestamped session name.
    $timestamp   = Get-Date -Format "yyyyMMdd_HHmmss"
    $SessionName = "TYPEPERF_Trace_$timestamp"
} else {
    # Use the provided FileName.
    $SessionName = $FileName 
}

# Final TYPEPERF run directory (this is where we want ALL run artifacts)
# Check if both LogDirectory and FileName are provided (orchestrator mode)
if (-not [string]::IsNullOrEmpty($LogDirectory) -and -not [string]::IsNullOrEmpty($FileName)) {
    # Orchestrator mode: create files directly in LogDirectory
    $OutputDir = $BaseDir
    Write-Log -Level INFO -Module TYPEPERF -Message "Using orchestrator mode: files will be created directly in LogDirectory"
} else {
    # Standalone mode: create subdirectory for all artifacts
    $OutputDir = Join-Path -Path $BaseDir -ChildPath $SessionName
    Write-Log -Level INFO -Module TYPEPERF -Message "Using standalone mode: creating dedicated subdirectory"
}
if (!(Test-Path $OutputDir)) {
    Write-Log -Level INFO -Module TYPEPERF -Message "Creating output directory: $OutputDir"
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

Write-Log -Level INFO -Module TYPEPERF -Message "Starting TYPEPERF session: $SessionName"
Write-Log -Level INFO -Module TYPEPERF -Message "Logging data to: $OutputDir"

#----------------------------------------------
# 3. Prepare input/output files
#----------------------------------------------
$InputFile  = "typeperf_metrics.txt"

# Determine output file name based on mode
if (-not [string]::IsNullOrEmpty($LogDirectory) -and -not [string]::IsNullOrEmpty($FileName)) {
    # Orchestrator mode: use FileName with .csv extension
    $OutputFile = "$SessionName.csv"
} else {
    # Standalone mode: use default name
    $OutputFile = "typeperf_Output.csv"
}

# The input file path should still be relative to the script root ($PSScriptRoot)
$InputPath = Join-Path $PSScriptRoot $InputFile
if (!(Test-Path $InputPath)) {
    Write-Log -Level ERROR -Module TYPEPERF -Message "Required input file '$InputFile' not found in script directory: $PSScriptRoot"
    exit 1
}

$typeperfArgs = @(
    "-cf", "`"$InputPath`"",
    "-o", "`"$OutputFile`""
)

#----------------------------------------------
# 4. Start TYPEPERF in background
#----------------------------------------------
Push-Location $OutputDir
$proc = $null

try {
    $proc = Start-Process `
        -FilePath "typeperf.exe" `
        -ArgumentList $typeperfArgs `
        -NoNewWindow `
        -PassThru `
        -ErrorAction Stop
}
catch {
    Write-Log -Level ERROR -Module TYPEPERF -Message "Failed to start TYPEPERF. Check if metrics file exists and is valid. Details: $($_.Exception.Message)"
    Pop-Location
    exit 1
}
finally {
    Pop-Location
}

#----------------------------------------------
# 5. Save session metadata
#----------------------------------------------
if ($proc -and $proc.Id) {
    # Primary copies (authoritative) go into the TYPEPERF run folder
    $pidFileRun     = Join-Path $OutputDir "typeperf_current_pid.txt"
    $sessionFileRun = Join-Path $OutputDir "typeperf_current_session.txt"
    $dirFileRun     = Join-Path $OutputDir "typeperf_current_outputdir.txt"
    $outputFileRun  = Join-Path $OutputDir "typeperf_current_outputfile.txt"

    $proc.Id     | Out-File -FilePath $pidFileRun     -Encoding ascii
    $SessionName | Out-File -FilePath $sessionFileRun -Encoding ascii
    $OutputDir   | Out-File -FilePath $dirFileRun     -Encoding ascii
    $OutputFile  | Out-File -FilePath $outputFileRun  -Encoding ascii

    # Create pointer file in the script root so stop_typeperf.ps1 knows where to look
    $PointerFileScript = Join-Path -Path $PSScriptRoot -ChildPath "typeperf_last_session_dir.txt"
    $OutputDir | Out-File -FilePath $PointerFileScript -Encoding ascii

    # If LogDirectory was provided, also create pointer file there for consistency
    if (-not [string]::IsNullOrEmpty($LogDirectory)) {
        $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "typeperf_last_session_dir.txt"
        $OutputDir | Out-File -FilePath $PointerFileCustom -Encoding ascii
        Write-Log -Level INFO -Module TYPEPERF -Message "Session metadata saved to: $OutputDir (pointer files in script root and LogDirectory)"
    } else {
        Write-Log -Level INFO -Module TYPEPERF -Message "Session metadata saved to: $OutputDir"
    }

    #----------------------------------------------
    # 6. Summary
    #----------------------------------------------
    Write-Log -Level RESULT -Module TYPEPERF -Message "TYPEPERF data collection started successfully (PID: $($proc.Id)). Data folder: $OutputDir"
    exit 0
}
else {
    Write-Log -Level ERROR -Module TYPEPERF -Message "TYPEPERF process failed to start or PID was not captured. Output directory created: $OutputDir"
    exit 1
}
exit 0