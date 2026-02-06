#==============================================================================
# Script Name:       start_power.ps1
# Description:       SystemMeter power telemetry collection starter
# Original Author:   Sriram Ranganathan
# Modified by:       Sriram Ranganathan
# Date:              November 12, 2025
# Version:           1.0
#==============================================================================

<#
.SYNOPSIS
  Starts SystemMeter power monitoring session

.DESCRIPTION
  Initiates a SystemMeter power monitoring session to collect system power metrics
  using onboard PAC devices and RAPL data during test execution. Creates CSV files 
  for power analysis and saves them to the specified directory.

.PARAMETER LogDirectory
  Directory where SystemMeter power data files will be stored

.PARAMETER FileName
  Base filename for the power data file (without extension)

.EXAMPLE
  .\start_power.ps1 -LogDirectory "C:\TestResults" -FileName "TestPower"
  
.EXAMPLE
  .\start_power.ps1 -LogDirectory "C:\Logs" -FileName "Power_Metrics"
#>

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
# This script starts a SystemMeter power monitoring session, saving data to a CSV file.
# 
# 1. Default Usage (No parameters):
#    - Creates a folder in the script directory named 'result_[timestamp]'.
#    - Example: 
#    .\start_power.ps1
#
# 2. Specify only the log directory:
#    - Uses the specified directory to create the timestamped power data folder inside it.
#    - Example: 
#    .\start_power.ps1 -LogDirectory "C:\PowerData\Traces"
#
# 3. Specify both directory and file name:
#    - Creates the power data folder under the specified directory using the specified 
#      file name as the folder name.
#    - Example: 
#    .\start_power.ps1 -LogDirectory "C:\PowerData" -FileName "MyPowerTrace"
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

# 1. Define the base directory for the log file
if ([string]::IsNullOrEmpty($LogDirectory)) {
    # If LogDirectory is NOT provided, use the default logic:
    # A 'result' folder with a timestamp in the current script's directory.
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $BaseDir = Join-Path -Path $PSScriptRoot -ChildPath "result_$timestamp"
} else {
    # If LogDirectory IS provided, use it.
    $BaseDir = $LogDirectory
}

# 2. Define the log file name and session name
if ([string]::IsNullOrEmpty($FileName)) {
    # If FileName is NOT provided, use the default: timestamped session name.
    $timestamp   = Get-Date -Format "yyyyMMdd_HHmmss"
    $SessionName = "Power_Trace_$timestamp"
    $LogFileName = "powerMeter_$timestamp.csv"
} else {
    # If FileName IS provided, use it.
    $SessionName = $FileName # Use the file name as the session name
    $timestamp   = Get-Date -Format "yyyyMMdd_HHmmss"
    $LogFileName = "${FileName}_${timestamp}_powerMeter.csv"
}

# 3. Define the final output directory and full log path
$OutputDir = $BaseDir
$LogFilePath = Join-Path -Path $OutputDir -ChildPath $LogFileName

# 4. Create the directory if it doesn't exist
if (!(Test-Path $OutputDir)) {
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Creating output directory: $OutputDir"
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

Write-LogEntry -Module TELEMETRY -Type INFO -Message "Starting SystemMeter power monitoring session: $SessionName"
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Recording power data to: $LogFilePath"
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Temporary files and helper info will be in: $OutputDir"

# 5. Start SystemMeter with power monitoring parameters
SystemMeter -start -d=3 -rapl -pac -n="$LogFilePath"

# 6. Persist info for stop script to the output directory ($OutputDir)
$SessionName | Out-File -FilePath (Join-Path -Path $OutputDir -ChildPath "current_session.txt") -Encoding ascii
$OutputDir   | Out-File -FilePath (Join-Path -Path $OutputDir -ChildPath "current_outputdir.txt") -Encoding ascii
$LogFilePath | Out-File -FilePath (Join-Path -Path $OutputDir -ChildPath "current_logfilepath.txt") -Encoding ascii

# 7. Create pointer file so stop_power.ps1 knows where to look
# If LogDirectory was provided, save pointer in the LogDirectory as well as script root
if ([string]::IsNullOrEmpty($LogDirectory)) {
    # Default: Save pointer in script root only
    $PointerFile = Join-Path -Path $PSScriptRoot -ChildPath "power_last_session_dir.txt"
    $OutputDir | Out-File -FilePath $PointerFile -Encoding ascii
} else {
    # Custom LogDirectory: Save pointer in both locations for compatibility
    $PointerFileScript = Join-Path -Path $PSScriptRoot -ChildPath "power_last_session_dir.txt"
    $PointerFileCustom = Join-Path -Path $LogDirectory -ChildPath "power_last_session_dir.txt"
    
    $OutputDir | Out-File -FilePath $PointerFileScript -Encoding ascii
    $OutputDir | Out-File -FilePath $PointerFileCustom -Encoding ascii
    
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Session metadata saved to: $OutputDir"
}

Write-LogEntry -Module TELEMETRY -Type RESULT -Message "SystemMeter power monitoring session started successfully."
exit 0
