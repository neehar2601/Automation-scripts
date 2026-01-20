#==============================================================================
# Script Name:       start_presentmon.ps1
# Description:       Start PresentMon data collection for all processes (non-blocking, quiet)
# Original Author:   Sriram Ranganathan
# Modified by:       Sriram Ranganathan
# Date:              November 7, 2024
# Version:           1.0
#==============================================================================

<#
.SYNOPSIS
  Starts PresentMon GPU performance data collection

.DESCRIPTION
  Initiates non-blocking PresentMon data collection for all processes to capture
  GPU performance metrics including frame rates, present times, and graphics
  performance indicators. Runs in quiet mode for background monitoring.

.PARAMETER LogDirectory
  The directory where the PresentMon CSV file will be saved

.PARAMETER FileName
  The base name for the PresentMon CSV file

.EXAMPLE
  .\start_presentmon.ps1
  Starts PresentMon data collection with default settings

.EXAMPLE
  .\start_presentmon.ps1 -LogDirectory "C:\Logs" -FileName "GPUMetrics"
  Starts PresentMon with custom directory and filename

.NOTES
  Use stop_presentmon.ps1 to terminate the data collection process.
  PresentMon must be installed and accessible in the system PATH.
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
# This script starts a PresentMon tracing session, monitoring all processes.
# 
# 1. Default Usage (No parameters):
#    - Creates a folder in the script directory named 'result_[timestamp]'.
#    - Example: 
#    .\start_presentmon.ps1
#
# 2. Specify only the log directory:
#    - Uses the specified directory as the base for the timestamped trace folder.
#    - Example: 
#    .\start_presentmon.ps1 -LogDirectory "C:\FrameData"
#
# 3. Specify both directory and session name:
#    - Creates the trace folder under the specified directory using the specified 
#      name as the folder name.
#    - Example: 
#    .\start_presentmon.ps1 -LogDirectory "C:\FrameData" -FileName "MyGameFrames"
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
# 1. Define executable and ensure availability
#----------------------------------------------
$PresentMonExeName = "PresentMon-2.3.1-x64.exe"
$PresentMonProcessName = $PresentMonExeName -replace '\.exe$', ''

$presentmonCmd = Get-Command $PresentMonExeName -ErrorAction SilentlyContinue
if (-not $presentmonCmd) {
    Write-LogEntry -Module TELEMETRY -Type ERROR -Message "'$PresentMonExeName' was not found in PATH. Please add PresentMon to PATH."
    exit 1
}
$PresentMonPath = $presentmonCmd.Path

#----------------------------------------------
# 2. Determine output directory
#----------------------------------------------
if ([string]::IsNullOrEmpty($LogDirectory)) {
    # Default: A 'result' folder with a timestamp in the current script's directory.
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $BaseDir = Join-Path -Path $PSScriptRoot -ChildPath "result_$timestamp"
    
    if ([string]::IsNullOrEmpty($FileName)) {
        # Default: timestamped session name.
        $timestamp   = Get-Date -Format "yyyyMMdd_HHmmss"
        $SessionName = "PRESENTMON_Trace_ALL_$timestamp"
    } else {
        # Use the provided FileName.
        $SessionName = $FileName 
    }
    
    $OutputDir = Join-Path -Path $BaseDir -ChildPath $SessionName
} else {
    # Use the provided LogDirectory directly (called from orchestrator)
    $OutputDir = $LogDirectory
    
    if ([string]::IsNullOrEmpty($FileName)) {
        # Default: timestamped session name.
        $timestamp   = Get-Date -Format "yyyyMMdd_HHmmss"
        $SessionName = "PRESENTMON_Trace_ALL_$timestamp"
    } else {
        # Use the provided FileName.
        $SessionName = $FileName 
    }
}

if (!(Test-Path $OutputDir)) {
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Creating output directory: $OutputDir"
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

Write-LogEntry -Module TELEMETRY -Type INFO -Message "Starting PresentMon session: $SessionName"
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Logging data to: $OutputDir"
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Monitoring all running processes using '$PresentMonExeName'."

#----------------------------------------------
# 3. Cleanup existing trace sessions before starting
#----------------------------------------------
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Checking for lingering PresentMon sessions..."
try {
    & $PresentMonPath --terminate_existing_session | Out-Null
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Any existing PresentMon session terminated."
} catch {
    Write-LogEntry -Module TELEMETRY -Type DEBUG -Message "No lingering PresentMon session found or cleanup not needed."
}

#----------------------------------------------
# 4. Launch PresentMon (non-blocking)
#----------------------------------------------
$OutputFile = "PresentMon_Output.csv"

Push-Location $OutputDir
try {
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Starting PresentMon quietly in background..."
    # Start PresentMon in background using Start-Process
    $proc = Start-Process -FilePath $PresentMonPath -ArgumentList "-output_file", $OutputFile, "--no_console_stats" -NoNewWindow -PassThru
    Start-Sleep -Milliseconds 500
}
catch {
    Write-LogEntry -Module TELEMETRY -Type ERROR -Message "Failed to launch PresentMon. Details: $($_.Exception.Message)"
    Pop-Location
    exit 1
}
Pop-Location

#----------------------------------------------
# 5. Save session metadata
#----------------------------------------------
# Primary copies (authoritative) go into the PresentMon run folder
$sessionFileRun = Join-Path $OutputDir "presentmon_current_session.txt"
$dirFileRun     = Join-Path $OutputDir "presentmon_current_outputdir.txt"

$SessionName | Out-File -FilePath $sessionFileRun -Encoding ascii
$OutputDir   | Out-File -FilePath $dirFileRun     -Encoding ascii

# Create pointer file in the script root so stop_presentmon.ps1 knows where to look
$PointerFileScript = Join-Path -Path $PSScriptRoot -ChildPath "presentmon_last_session_dir.txt"
$OutputDir | Out-File -FilePath $PointerFileScript -Encoding ascii

# If LogDirectory was provided, also create pointer file there for consistency
if (-not [string]::IsNullOrEmpty($LogDirectory)) {
    $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "presentmon_last_session_dir.txt"
    $OutputDir | Out-File -FilePath $PointerFileCustom -Encoding ascii
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Session metadata saved to: $OutputDir (pointer files in script root and LogDirectory)"
} else {
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Session metadata saved to: $OutputDir"
}

#----------------------------------------------
# 6. Summary
#----------------------------------------------
Write-LogEntry -Module TELEMETRY -Type RESULT -Message "PRESENTMON data collection started successfully in background. Logs Directory: $OutputDir"
exit 0