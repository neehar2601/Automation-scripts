#==============================================================================
# Script Name:       start_socwatch.ps1
# Description:       SoCWatch telemetry collection starter
# Original Author:   Sriram Ranganathan
# Modified by:       Sriram Ranganathan
# Date:              November 12, 2025
# Version:           1.0
#==============================================================================

<#
.SYNOPSIS
  Starts SoCWatch monitoring session

.DESCRIPTION
  Initiates a SoCWatch monitoring session to collect comprehensive system-on-chip (SoC)
  telemetry data including CPU, GPU, NPU, memory, power, and various hardware states
  during test execution. Creates result files in the specified directory.

.PARAMETER LogDirectory
  Directory where SoCWatch result files will be stored

.PARAMETER FileName
  Base name for the SoCWatch results folder (without extension)

.EXAMPLE
  .\start_socwatch.ps1 -LogDirectory "C:\TestResults" -FileName "TestSoCWatch"
  
.EXAMPLE
  .\start_socwatch.ps1 -LogDirectory "C:\Logs" -FileName "SoC_Metrics"
#>

param(
    [Parameter(Mandatory=$false)] [string]$LogDirectory,
    [Parameter(Mandatory=$false)] [string]$FileName,
    [Parameter(Mandatory=$false)] [switch]$ShowConsole,   # If supplied, launch socwatch.exe with a visible window
    [Parameter(Mandatory=$false)] [switch]$SocDiag        # If supplied, emit diagnostic JSON file (renamed from -Debug to avoid common parameter conflict)
)

#----------------------------------------------
# HELP AND USAGE EXAMPLES
#----------------------------------------------
# 
# This script starts a SoCWatch monitoring session, saving data to a results directory.
# 
# 1. Default Usage (No parameters):
#    - Creates a folder in the script directory named 'result_[timestamp]'.
#    - Example: 
#    .\start_socwatch.ps1
#
# 2. Specify only the log directory:
#    - Uses the specified directory to create the timestamped results folder inside it.
#    - Example: 
#    .\start_socwatch.ps1 -LogDirectory "C:\SoCWatch_Data\Traces"
#
# 3. Specify both directory and file name:
#    - Creates the results folder under the specified directory using the specified 
#      file name as the folder name.
#    - Example: 
#    .\start_socwatch.ps1 -LogDirectory "C:\SoCWatch_Data" -FileName "MySoCTrace"
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

<#
PATH STRATEGY SIMPLIFICATION
We now treat LogDirectory (when provided) as the sole output directory for SoCWatch.
If LogDirectory is omitted, we fall back to a timestamped folder under the script root.
No additional nested results folder is created; socwatch.exe writes directly into the chosen directory.
FileName influences only the session metadata name, not the path structure.
#>

###############################################
# STATELESS PATH RESOLUTION
# (No metadata or pointer files written; stop script reconstructs path.)
###############################################
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Incoming parameters: LogDirectory='${LogDirectory}', FileName='${FileName}', SocDiag='${SocDiag}'"

if ([string]::IsNullOrEmpty($LogDirectory)) {
    $timestamp    = Get-Date -Format "yyyyMMdd_HHmmss"
    $LogDirectory = Join-Path -Path $PSScriptRoot -ChildPath "result_$timestamp"
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "No LogDirectory provided; using auto path: $LogDirectory"
}

if ([string]::IsNullOrEmpty($FileName)) {
    $BaseTestId = "SoCWatch_" + (Get-Date -Format "yyyyMMdd_HHmmss")
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "No FileName provided; auto test id: $BaseTestId"
} else {
    $BaseTestId = $FileName -replace '_socwatch$',''
}

# Decide final output directory.
# If caller's LogDirectory already targets a test-specific timestamp folder (common orchestrator case),
# DO NOT create an extra nested <testid>_socwatch folder; just write directly there.
# We detect this by checking if the leaf of LogDirectory already contains the base test id.
$logLeaf = Split-Path -Path $LogDirectory -Leaf
$SessionFolderName = if ($BaseTestId -match '_socwatch$') { $BaseTestId } else { "$BaseTestId`_socwatch" }
$SessionName = $SessionFolderName

if ($logLeaf -like "$BaseTestId*" -and $logLeaf -notlike "*$SessionFolderName") {
    # LogDirectory already points to test run folder; use it directly.
    $OutputDir = $LogDirectory
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Using provided LogDirectory as output (no nested session folder)."
} else {
    # Need to create/ensure a dedicated session folder under LogDirectory
    $OutputDir = Join-Path -Path $LogDirectory -ChildPath $SessionFolderName
}
# (Legacy variable removed; using $OutputDir + $socwatchPrefix now)

# 4. Ensure directory exists
if (!(Test-Path $LogDirectory)) {
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Creating log directory: $LogDirectory"
    New-Item -ItemType Directory -Path $LogDirectory | Out-Null
}
if (!(Test-Path $OutputDir)) {
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Creating output directory: $OutputDir"
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
} else {
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Output directory already exists: $OutputDir"
}

Write-LogEntry -Module TELEMETRY -Type INFO -Message "Starting SoCWatch collection: Session='$SessionName' BaseTestId='$BaseTestId'"
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Output directory resolved: $OutputDir"
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Resolved LogDirectory='$LogDirectory' OutputDir='$OutputDir' (Leaf='$logLeaf')"
Write-LogEntry -Module TELEMETRY -Type INFO -Message "NOTE: Using OutputDir as process working directory; -o will be treated as filename prefix."

# 5. Find socwatch.exe (the actual monitoring executable)
$socwatchExe = "socwatch.exe"

# Check if socwatch.exe exists in PATH
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
            Write-LogEntry -Module TELEMETRY -Type INFO -Message "Found socwatch at: $socwatchExe"
            break
        }
    }
    
    # If still not found, check if it's in the script directory
    if (-not (Test-Path $socwatchExe)) {
        $localPath = Join-Path $PSScriptRoot $socwatchExe
        if (Test-Path $localPath) {
            $socwatchExe = $localPath
            Write-LogEntry -Module TELEMETRY -Type INFO -Message "Found socwatch in script directory: $socwatchExe"
        } else {
            Write-LogEntry -Module TELEMETRY -Type ERROR -Message "socwatch.exe not found. Please install Intel SoCWatch or add it to PATH."
            Write-LogEntry -Module TELEMETRY -Type ERROR -Message "Searched locations: PATH, Program Files\Intel\SoCWatch\bin, and script directory"
            exit 1
        }
    }
} else {
    $socwatchExe = $socwatchPath.Source
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "Found socwatch in PATH: $socwatchExe"
}

# 6. Start SoCWatch using a background PowerShell job
Write-LogEntry -Module TELEMETRY -Type INFO -Message "Starting SoCWatch monitoring (background job)..."

# (Directory creation already handled above.)

<#
SoCWatch -o parameter semantics:
    -o <name> sets the base filename/prefix for generated artifacts (etl, csv, etc.)
It does NOT accept a full directory path. Previously we passed a full path which caused
files to appear in the parent/session directory. We now:
    * Set Start-Process -WorkingDirectory to $OutputDir
    * Pass only the session name/prefix to -o
Result: All artifacts land inside $OutputDir.
#>

$socwatchPrefix = $SessionName  # base name for result files
$socwatchArgs   = "-f sys -f cpu -f gfx -o `"$socwatchPrefix`""
Write-LogEntry -Module TELEMETRY -Type INFO -Message "SocWatch arguments: $socwatchArgs"
Write-LogEntry -Module TELEMETRY -Type INFO -Message "SocWatch working directory: $OutputDir"

# PID file for tracking
$pidFile = Join-Path $OutputDir "socwatch.pid"

# Launch socwatch as a DETACHED background process
# This ensures it survives even after the parent script returns
$useVisibleWindow = $ShowConsole.IsPresent

Write-LogEntry -Module TELEMETRY -Type INFO -Message "Launching SoCWatch as detached background process..."

try {
    if ($useVisibleWindow) {
        # Normal window (visible) for debugging/monitoring
        $proc = Start-Process -FilePath $socwatchExe `
            -ArgumentList $socwatchArgs `
            -WorkingDirectory $OutputDir `
            -WindowStyle Normal `
            -PassThru
    } else {
        # Hidden window for non-intrusive monitoring
        $proc = Start-Process -FilePath $socwatchExe `
            -ArgumentList $socwatchArgs `
            -WorkingDirectory $OutputDir `
            -WindowStyle Hidden `
            -PassThru
    }
    
    # Save PID for stop script
    $proc.Id | Out-File -FilePath $pidFile -Encoding ascii -Force
    
    # Give SoCWatch time to initialize
    Start-Sleep -Milliseconds 1000
    
    # Verify process is still running
    if (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue) {
        $winMsg = if ($useVisibleWindow) { 'Window: Visible' } else { 'Window: Hidden' }
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "SoCWatch process started successfully (PID: $($proc.Id)). $winMsg"
        Write-LogEntry -Module TELEMETRY -Type INFO -Message "Process is running independently and will survive parent script termination."
    } else {
        Write-LogEntry -Module TELEMETRY -Type ERROR -Message "SoCWatch process started but immediately terminated. Check socwatch.exe compatibility."
        exit 1
    }
} catch {
    Write-LogEntry -Module TELEMETRY -Type ERROR -Message "Failed to start SoCWatch: $($_.Exception.Message)"
    exit 1
}

$socwatchPid = $proc.Id

Write-LogEntry -Module TELEMETRY -Type RESULT -Message "SoCWatch monitoring session armed. Returning to orchestrator."

if ($SocDiag) {
    @{
        Timestamp    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        LogDirectory = $LogDirectory
        BaseTestId   = $BaseTestId
        SessionName  = $SessionName
        OutputDir    = $OutputDir
        SocwatchExe  = $socwatchExe
        Arguments    = $socwatchArgs
    } | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path -Path $OutputDir -ChildPath "socwatch_param_dump.json") -Encoding utf8 -Force
    Write-LogEntry -Module TELEMETRY -Type INFO -Message "SocDiag param dump written."
}

Write-LogEntry -Module TELEMETRY -Type RESULT -Message "SoCWatch collection started (stateless mode)."
exit 0
