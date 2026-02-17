@echo off
setlocal enabledelayedexpansion

REM Set the folder path where you want to search for ETL files
set "SEARCH_FOLDER=C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results"

REM Set the output ETL folder path
set "ETL_OUTPUT_FOLDER=C:\KSR_Package\KSR\Test_Run_KR\Results\ETL"

REM Set the KPI details JSON file path
set "KPI_JSON_FILE=%~dp0KPI-Details.json"

REM Set the PowerShell helper script path
set "PS_HELPER=%~dp0Get-KPITitle.ps1"

REM Set the profile path
set "PROFILE_PATH=C:\Users\nnellika\OneDrive - Intel Corporation\Documents\ETL\ETL\wprfile.wpaProfile"
REM Set the default profile path
@REM for /f "delims=" %%p in ('dir /s /b "C:\KSR_Package\KSR\Test_Run_KR\*.wpaProfile" 2^>nul') do (
@REM     set "PROFILE_PATH=%%p"
@REM     goto :found_profile_default
@REM )
@REM :found_profile_default

@REM REM If not found in default location, search for the wpaProfile file on the whole disk (first match)
@REM if not exist "%PROFILE_PATH%" (
@REM     set "PROFILE_PATH="
@REM     for /f "delims=" %%p in ('dir /s /b "%SystemDrive%\*.wpaProfile" 2^>nul') do (
@REM         set "PROFILE_PATH=%%p"
@REM         goto :found_profile
@REM     )
@REM     :found_profile
@REM )

REM Check if search folder exists
if not exist "%SEARCH_FOLDER%" (
    echo Error: Search folder not found: %SEARCH_FOLDER%
    pause
    exit /b 1
)

REM Check if profile exists
if not exist "%PROFILE_PATH%" (
    echo Error: Profile file not found: %PROFILE_PATH%
    pause
    exit /b 1
)

REM Check if KPI JSON file exists
if not exist "%KPI_JSON_FILE%" (
    echo Warning: KPI-Details.json not found: %KPI_JSON_FILE%
    echo Will use original ETL filenames without KPI titles.
    set "KPI_JSON_FILE="
)

REM Check if PowerShell helper script exists
if not exist "%PS_HELPER%" (
    echo Warning: Get-KPITitle.ps1 not found: %PS_HELPER%
    echo Will use original ETL filenames without KPI titles.
    set "PS_HELPER="
)

REM Create the ETL output folder if it doesn't exist
if not exist "%ETL_OUTPUT_FOLDER%" (
    mkdir "%ETL_OUTPUT_FOLDER%"
    echo Created ETL output folder: %ETL_OUTPUT_FOLDER%
)

echo Searching for *_Tracelog.etl files in: %SEARCH_FOLDER%
echo Processing files in all subfolders...
echo Output will be organized in: %ETL_OUTPUT_FOLDER%
echo.

set "FILE_COUNT=0"
set "SUCCESS_COUNT=0"
set "ERROR_COUNT=0"

REM Search recursively for all ETL files ending with _Tracelog.etl
for /r "%SEARCH_FOLDER%" %%f in (*_Tracelog.etl) do (
    if exist "%%f" (
        set /a FILE_COUNT+=1
        
        REM Get the filename without path and extension
        set "ETL_NAME=%%~nf"
        
        REM Extract KPI ID from filename (e.g., GLD1003 from GLD1003_Tracelog.etl or GLD1003_busy_idle_Tracelog.etl)
        set "FILENAME=!ETL_NAME!"
        
        REM Remove _Tracelog suffix if present
        set "FILENAME=!FILENAME:_Tracelog=!"
        
        REM Extract just the KPI ID (GLD followed by digits)
        for /f "tokens=1 delims=_" %%k in ("!FILENAME!") do set "KPI_ID=%%k"
        
        REM Get folder name from PowerShell helper script
        REM The script handles both current JSON mode and future filename-based mode
        set "FOLDER_NAME=!KPI_ID!"
        
        if defined KPI_JSON_FILE if defined PS_HELPER (
            REM Call PowerShell to get the folder name
            REM Pass both KPI ID and filename (for future enhancement)
            for /f "delims=" %%t in ('powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -JsonFile "%KPI_JSON_FILE%" -KPIId "!KPI_ID!" -ETLFileName "!FILENAME!" 2^>nul') do (
                set "FOLDER_NAME=%%t"
            )
        )
        
        echo [!FILE_COUNT!] Found: %%f
        echo [!FILE_COUNT!] KPI ID: !KPI_ID!
        echo [!FILE_COUNT!] Folder Name: !FOLDER_NAME!
        echo [!FILE_COUNT!] Processing...
        
        REM Create test case folder in ETL output directory
        set "OUTPUT_DIR=%ETL_OUTPUT_FOLDER%\!FOLDER_NAME!"
        if not exist "!OUTPUT_DIR!" (
            mkdir "!OUTPUT_DIR!"
        )
        
        REM Change to the output directory for wpaexporter
        pushd "!OUTPUT_DIR!"
        
        REM Run wpaexporter - output will be saved in the current directory (OUTPUT_DIR)
        wpaexporter -i "%%f" -profile "%PROFILE_PATH%"
        
        if !errorlevel! equ 0 (
            set /a SUCCESS_COUNT+=1
            
            REM Move the original ETL file to the output directory
            echo [!FILE_COUNT!] Moving ETL file to output directory...
            move "%%f" "!OUTPUT_DIR!\" >nul
            
            echo [!FILE_COUNT!] SUCCESS: %%f
            echo [!FILE_COUNT!] Output saved in: !OUTPUT_DIR!
        ) else (
            set /a ERROR_COUNT+=1
            echo [!FILE_COUNT!] ERROR: Failed to process %%f
        )
        
        REM Return to previous directory
        popd
        echo.
    )
)

echo =================================
echo Summary:
if %FILE_COUNT% equ 0 (
    echo No ETL files ending with _Tracelog.etl found in %SEARCH_FOLDER% and subdirectories.
) else (
    echo Total files found: %FILE_COUNT%
    echo Successfully processed: %SUCCESS_COUNT%
    echo Errors: %ERROR_COUNT%
    echo.
    echo All processed files have been organized in: %ETL_OUTPUT_FOLDER%
    echo Each test case has its own folder containing the CSV files and original ETL file.
)
pause
exit /b
