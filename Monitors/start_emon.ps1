#==============================================================================
# Script Name:       start_emon.ps1
# Description:       Start EMON EDP data collection (non-blocking)
# Original Author:   Sriram Ranganathan
# Modified by:       Sriram Ranganathan
# Date:              November 7, 2024
# Version:           1.0
#==============================================================================

<#
.SYNOPSIS
  Starts Intel EMON (Event Monitor) EDP data collection

.DESCRIPTION
  Initiates non-blocking Intel EMON data collection for EDP (Event Data Processing)
  to capture detailed CPU performance metrics, power consumption, and hardware
  performance counters. Part of the RBR telemetry collection framework.

.PARAMETER LogDirectory
  The directory where the EMON data file will be saved

.PARAMETER FileName
  The base name for the EMON data file

.EXAMPLE
  .\start_emon.ps1
  Starts EMON data collection with default settings

.EXAMPLE
  .\start_emon.ps1 -LogDirectory "C:\Logs" -FileName "CPUMetrics"
  Starts EMON with custom directory and filename

.NOTES
  Use stop_emon.ps1 to terminate the data collection process.
  Intel EMON tools must be installed and accessible.
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
# This script starts an EMON tracing session, saving data to an Emon_Output.dat file.
# 
# 1. Default Usage (No parameters):
#    - Creates a folder in the script directory named 'EMON_Trace_[timestamp]'.
#    - Example: 
#    .\start_emon.ps1
#
# 2. Specify only the log directory:
#    - Creates a timestamped trace folder inside the specified directory.
#    - Example: 
#    .\start_emon.ps1 -LogDirectory "C:\EMON_Data"
#
# 3. Specify directory and the desired final output file name:
#    - Creates a timestamped trace folder inside the directory. The -FileName is 
#      used by the stop script to rename the final Emon_Output.dat.
#    - Example: 
#    .\start_emon.ps1 -LogDirectory "C:\EMON_Data" -FileName "MyEmonSession.dat"
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


# 1. Ensure EMON is available
$emonPath = (Get-Command emon -ErrorAction SilentlyContinue).Path

if (-not $emonPath) {
    Write-LogEntry -Module TELEMETRY -Type ERROR -Message "EMON was not found in PATH. Please add EMON to PATH or run from its directory."
    exit 1
}

# 2. Define session name and output location
if ([string]::IsNullOrEmpty($LogDirectory)) {
    # Default: Create timestamped folder in script root when no LogDirectory specified
    $BaseDir = $PSScriptRoot
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $SessionName = "EMON_Trace_$timestamp" 
    $OutputDir = Join-Path -Path $BaseDir -ChildPath $SessionName
} else {
    # When LogDirectory is provided, use it directly (don't create subdirectory)
    $OutputDir = $LogDirectory
    $SessionName = "EMON_Session"  # Simple session name since we're not creating subdirectory
}

if (!(Test-Path $OutputDir)) {
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Creating output directory: $OutputDir"
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-LogEntry -Module TELEMETRY -Type INFO -Message "Starting EMON session: $SessionName"
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Logging data to: $OutputDir"

# 3. Build EMON arguments
$EmonOutputFile = "Emon_Output.dat"

$emonArgs = @(
    '-collect-edp'
    '-f'
    $EmonOutputFile
)

# 4. Start EMON in background (output goes to $OutputDir)
Push-Location $OutputDir

try {
    $proc = Start-Process `
        -FilePath $emonPath `
        -ArgumentList $emonArgs `
        -NoNewWindow `
        -PassThru `
        -ErrorAction Stop
}
catch {
    Write-LogEntry -Module TELEMETRY -Type ERROR -Message "Failed to start EMON process. Details: $($_.Exception.Message)"
    Pop-Location
    exit 1
}
finally {
    Pop-Location
}

# 5. Save session metadata
if ($proc -and $proc.Id) {

    # Primary copies (authoritative) go into the EMON run folder
    $sessionFileRun  = Join-Path $OutputDir "emon_current_session.txt"
    $dirFileRun      = Join-Path $OutputDir "emon_current_outputdir.txt"
    $pidFileRun      = Join-Path $OutputDir "emon_current_pid.txt"
    # Store the requested final file name for the stop script to use
    $requestedNameRun = Join-Path $OutputDir "emon_requested_filename.txt"

    $SessionName | Out-File -FilePath $sessionFileRun -Encoding ascii
    $OutputDir   | Out-File -FilePath $dirFileRun     -Encoding ascii
    $proc.Id     | Out-File -FilePath $pidFileRun     -Encoding ascii
    # Only store the requested file name if it was provided
    if (-not [string]::IsNullOrEmpty($FileName)) {
        $FileName | Out-File -FilePath $requestedNameRun -Encoding ascii
    }
    
    # Create pointer file in the script root so stop_emon.ps1 knows where to look
    $PointerFileScript = Join-Path -Path $PSScriptRoot -ChildPath "emon_last_session_dir.txt"
    $OutputDir | Out-File -FilePath $PointerFileScript -Encoding ascii

    # If LogDirectory was provided, also create pointer file there for consistency
    if (-not [string]::IsNullOrEmpty($LogDirectory)) {
        $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "emon_last_session_dir.txt"
        $OutputDir | Out-File -FilePath $PointerFileCustom -Encoding ascii
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "Session metadata saved to: $OutputDir (pointer files in script root and LogDirectory)"
    } else {
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "Session metadata saved to: $OutputDir"
    }

    Write-LogEntry -Module TELEMETRY -Type RESULT -Message "EMON data collection started successfully (PID: $($proc.Id)). Data will be saved to: $(Join-Path $OutputDir $EmonOutputFile)"
}
else {
    Write-LogEntry -Module TELEMETRY -Type ERROR -Message "EMON process failed to start or PID was not captured. Output directory created: $OutputDir"
    exit 1
}
exit 0