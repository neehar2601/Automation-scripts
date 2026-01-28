@echo off
REM Test-Connection.bat
REM Quick test to verify server connectivity

setlocal enabledelayedexpansion

echo ========================================
echo NiDaq Server Connection Test
echo ========================================
echo.

REM Configuration (edit these as needed)
set SERVER_IP=127.0.0.1
set SERVER_PORT=55555

echo Testing connection to: %SERVER_IP%:%SERVER_PORT%
echo.

REM Check if NiDaqClient.ps1 exists
if not exist "%~dp0NiDaqClient.ps1" (
    echo ERROR: NiDaqClient.ps1 not found!
    echo Expected location: %~dp0NiDaqClient.ps1
    echo.
    pause
    exit /b 1
)

echo [1/3] Checking network connectivity...
ping -n 1 %SERVER_IP% >nul 2>&1
if %errorLevel% equ 0 (
    echo    [OK] Ping successful
) else (
    echo    [FAIL] Cannot ping server
    echo.
    pause
    exit /b 1
)

echo.
echo [2/3] Checking TCP port...
powershell -Command "Test-NetConnection -ComputerName %SERVER_IP% -Port %SERVER_PORT% -InformationLevel Quiet" >nul 2>&1
if %errorLevel% equ 0 (
    echo    [OK] Port %SERVER_PORT% is open
) else (
    echo    [FAIL] Port %SERVER_PORT% is not accessible
    echo    Make sure the server is running!
    echo.
    pause
    exit /b 1
)

echo.
echo [3/3] Sending status command (101)...
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0NiDaqClient.ps1" -Command 101

if %errorLevel% equ 0 (
    echo.
    echo ========================================
    echo [SUCCESS] Server is responding!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo [FAIL] Server did not respond properly
    echo ========================================
)

echo.
pause
