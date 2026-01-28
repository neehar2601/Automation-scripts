@echo off
REM Start-Modular-Server.bat
REM Quick launcher for NiDaq Modular Server

echo ========================================
echo NiDaq Server - Modular Version
echo ========================================
echo.

REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo WARNING: Not running as Administrator
    echo PsExec may not work without admin privileges
    echo.
    echo Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [OK] Running with Administrator privileges
echo.

REM Check if NiDaqServer-Modular.ps1 exists
if not exist "%~dp0NiDaqServer-Modular.ps1" (
    echo ERROR: NiDaqServer-Modular.ps1 not found!
    echo Expected location: %~dp0NiDaqServer-Modular.ps1
    echo.
    pause
    exit /b 1
)

echo [OK] NiDaqServer-Modular.ps1 found
echo.

REM Check if Modules directory exists
if not exist "%~dp0Modules" (
    echo ERROR: Modules directory not found!
    echo Expected location: %~dp0Modules\
    echo.
    echo Please create Modules\ directory with:
    echo   - LoggingModule.psm1
    echo   - ConfigurationModule.psm1
    echo   - TCPServerModule.psm1
    echo.
    pause
    exit /b 1
)

echo [OK] Modules directory found
echo.

REM Check if Classes directory exists
if not exist "%~dp0Classes" (
    echo ERROR: Classes directory not found!
    echo Expected location: %~dp0Classes\
    echo.
    echo Please create Classes\ directory with:
    echo   - PACSController.ps1
    echo   - RemoteExecutor.ps1
    echo   - CommandHandler.ps1
    echo.
    pause
    exit /b 1
)

echo [OK] Classes directory found
echo.

REM Check if ServerConfig.json exists
if not exist "%~dp0ServerConfig.json" (
    echo WARNING: ServerConfig.json not found
    echo A default configuration will be created
    echo.
    echo IMPORTANT: Make sure to add "BufferSize": 4096 to the config!
    echo.
)

REM Check for BufferSize in config (PowerShell check)
echo Checking ServerConfig.json for BufferSize...
powershell -Command "$config = Get-Content '%~dp0ServerConfig.json' -ErrorAction SilentlyContinue | ConvertFrom-Json; if ($config.Server.BufferSize) { Write-Host '  [OK] BufferSize found: ' $config.Server.BufferSize -ForegroundColor Green } else { Write-Host '  [WARNING] BufferSize not found in config!' -ForegroundColor Yellow; Write-Host '  Please add: \"BufferSize\": 4096 to Server section' -ForegroundColor Yellow }"
echo.

REM Start the modular server
echo Starting NiDaq Modular Server...
echo Press Ctrl+C to stop the server
echo.
echo ========================================
echo.

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0NiDaqServer-Modular.ps1"

echo.
echo ========================================
echo Server stopped
echo ========================================
pause
