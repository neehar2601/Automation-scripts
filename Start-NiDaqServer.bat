# Start-NiDaqServer.bat
# Quick launcher for NiDaq Server

@echo off
echo ========================================
echo    NiDaq Server v2.0 - Launcher
echo ========================================
echo.

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell detected' -ForegroundColor Green"
if %errorlevel% neq 0 (
    echo ERROR: PowerShell not found!
    pause
    exit /b 1
)

REM Check if running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script must run as Administrator!
    echo Please right-click and select "Run as Administrator"
    pause
    exit /b 1
)

echo Starting NiDaq Server...
echo.

REM Start server with default config
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0NiDaqServer.ps1"

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Server failed to start!
    pause
    exit /b 1
)

pause
