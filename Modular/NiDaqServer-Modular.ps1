# NiDaqServer-Modular.ps1
# Version: 2.0 - Modular Edition
# Description: Modular TCP server for remote test orchestration
# Integrates with existing RunTest.ps1 framework

#Requires -Version 5.1

<#
.SYNOPSIS
    NiDaq Server - Modular PowerShell Edition
.DESCRIPTION
    TCP server for remote test orchestration with modular architecture
.PARAMETER ConfigFile
    Path to the configuration file
.PARAMETER Port
    Server port (overrides config file)
.PARAMETER ServerHost
    Server host address (overrides config file)
.EXAMPLE
    .\NiDaqServer-Modular.ps1
.EXAMPLE
    .\NiDaqServer-Modular.ps1 -Port 5000 -ServerHost "192.168.1.50"
#>

param(
    [string]$ConfigFile = ".\ServerConfig.json",
    [int]$Port = 0,
    [string]$ServerHost = ""
)

# Set error handling
$ErrorActionPreference = "Stop"
$Global:ServerRunning = $true

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# ============================================================================
# Import Modules
# ============================================================================

Write-Host "Loading NiDaq Server modules..." -ForegroundColor Cyan

# Import Logging Module
Import-Module "$ScriptDir\Modules\LoggingModule.psm1" -Force -ErrorAction Stop -DisableNameChecking
Write-Host "  [OK] LoggingModule loaded" -ForegroundColor Green

# Import Configuration Module
Import-Module "$ScriptDir\Modules\ConfigurationModule.psm1" -Force -ErrorAction Stop -DisableNameChecking
Write-Host "  [OK] ConfigurationModule loaded" -ForegroundColor Green

# Import TCP Server Module
Import-Module "$ScriptDir\Modules\TCPServerModule.psm1" -Force -ErrorAction Stop -DisableNameChecking
Write-Host "  [OK] TCPServerModule loaded" -ForegroundColor Green

# Load Classes
. "$ScriptDir\Classes\PACSController.ps1"
Write-Host "  [OK] PACSController class loaded" -ForegroundColor Green

. "$ScriptDir\Classes\RemoteExecutor.ps1"
Write-Host "  [OK] RemoteExecutor class loaded" -ForegroundColor Green

. "$ScriptDir\Classes\CommandHandler.ps1"
Write-Host "  [OK] CommandHandler class loaded" -ForegroundColor Green

Write-Host ""

# Verify critical functions are available
if (-not (Get-Command Start-TCPServer -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Start-TCPServer function not found after module import!" -ForegroundColor Red
    Write-Host "Available commands from TCPServerModule:" -ForegroundColor Yellow
    Get-Command -Module TCPServerModule | Format-Table -AutoSize
    exit 1
}

# ============================================================================
# Main Entry Point
# ============================================================================

try {
    Write-Log "NiDaq Server v2.0 - Modular Edition" -Level "INFO"
    Write-Log "Starting server initialization..." -Level "INFO"
    
    # Load configuration
    Write-Log "Loading configuration from $ConfigFile" -Level "INFO"
    $config = Load-ServerConfig -ConfigPath $ConfigFile
    
    # Validate configuration
    if (-not (Test-ServerConfig -Config $config)) {
        throw "Configuration validation failed"
    }
    Write-Log "Configuration validated successfully" -Level "SUCCESS"
    
    # Override with command-line parameters
    if ($Port -gt 0) {
        $config.Server.Port = $Port
        Write-Log "Port overridden via command line: $Port" -Level "INFO"
    }
    if ($ServerHost -ne "") {
        $config.Server.Host = $ServerHost
        Write-Log "Host overridden via command line: $ServerHost" -Level "INFO"
    }
    
    # Set log file path
    $logPath = Join-Path $ScriptDir "Logs\NiDaqServer_$(Get-Date -Format 'yyyy-MM-dd').log"
    Set-LogFile -Path $logPath
    Write-Log "Log file: $logPath" -Level "INFO"
    
    # Initialize command handler
    Write-Log "Initializing command handler..." -Level "INFO"
    $handler = [CommandHandler]::new($config)
    Write-Log "Command handler initialized successfully" -Level "SUCCESS"
    
    # Start TCP server
    Write-Log "Starting TCP server..." -Level "INFO"
    Start-TCPServer -Config $config -Handler $handler
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)" -Level "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR"
    exit 1
}
finally {
    Write-Log "NiDaq Server shutting down..." -Level "INFO"
    Write-Log "Server stopped at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level "INFO"
}
