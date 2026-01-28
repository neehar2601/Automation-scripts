# LoggingModule.psm1
# Logging functionality for NiDaq Server

$Global:LogFile = ".\Logs\NiDaqServer_$(Get-Date -Format 'yyyy-MM-dd').log"

function Write-Log {
    <#
    .SYNOPSIS
        Writes log messages to console and file
    .PARAMETER Message
        The message to log
    .PARAMETER Level
        Log level: INFO, WARNING, ERROR, SUCCESS
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    
    # Console output with colors
    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "DEBUG"   { Write-Host $logEntry -ForegroundColor Gray }
    }
    
    # File output
    try {
        # Ensure Logs directory exists
        $logDir = Split-Path $Global:LogFile -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        $logEntry | Out-File -FilePath $Global:LogFile -Append -Encoding UTF8
    }
    catch {
        Write-Host "Warning: Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Set-LogFile {
    <#
    .SYNOPSIS
        Sets the log file path
    .PARAMETER Path
        Path to the log file
    #>
    param([string]$Path)
    $Global:LogFile = $Path
}

function Get-LogFile {
    <#
    .SYNOPSIS
        Gets the current log file path
    #>
    return $Global:LogFile
}

# Export functions
Export-ModuleMember -Function Write-Log, Set-LogFile, Get-LogFile
