@echo off
:: ----------------------------------------------------------------------------------
:: ETL Push Results Script
:: Script Name         : Push ETL logs to share path via API
:: Created by          : Neehara Govinda N
:: Created date        : 02-13-2026
:: Version             : V1.0
:: ----------------------------------------------------------------------------------

setlocal enabledelayedexpansion

echo ========================================
echo ETL Push Results Script
echo ========================================
echo.

:: Set the ETL folder path
set "ETL_FOLDER=C:\KSR_Package\KSR\Test_Run_KR\Results\ETL"

:: Set the zip file path (modify this to your actual zip file location)
set "ZIP_FILE=%CD%\KingsResults_61cdfc6a-f61d-4426-b44b-994d545e4f35.zip"

:: Check if ETL folder exists
if not exist "%ETL_FOLDER%" (
    echo [101m Error: ETL folder not found: %ETL_FOLDER%[0m
    pause
    exit /b 1
)

:: Check if zip file exists
if not exist "%ZIP_FILE%" (
    echo [101m Error: Zip file not found: %ZIP_FILE%[0m
    echo Please specify the correct path to your zip file.
    pause
    exit /b 1
)

echo [102m ETL folder found: %ETL_FOLDER%[0m
echo [102m Zip file found: %ZIP_FILE%[0m
echo.

:: Clean up previous response files
if exist ETL_API_Response.txt del ETL_API_Response.txt
if exist ETL_SharePath.txt del ETL_SharePath.txt

echo Sending zip file to API...
echo.

:: Send the zip file to the API endpoint
:: Replace YOUR_API_ENDPOINT with your actual API URL
set "API_ENDPOINT=https://ksr-dev.intel.com/parser/api/ETLLogPush/ProcessWTLLogs"

curl -X POST -H "Content-Type: multipart/form-data" -F "ResultZip=@%ZIP_FILE%;type=application/x-zip-compressed" %API_ENDPOINT% -k > ETL_API_Response.txt

:: Check if API call was successful
if %errorlevel% neq 0 (
    echo [101m Error: Failed to send zip file to API.[0m
    pause
    exit /b 1
)

:: Display API response
echo API Response:
type ETL_API_Response.txt
echo.

:: Extract the share path from the API response
:: Looking for pattern like: file://gar.corp.intel.com/ec/proj/my/ccg/Board/kings_etl/...
for /f "tokens=*" %%a in ('findstr /i "file://" ETL_API_Response.txt') do (
    set "SHARE_PATH=%%a"
)

:: If the share path contains quotes or extra text, try to extract just the path
if defined SHARE_PATH (
    :: Remove leading/trailing spaces and quotes
    for /f "tokens=*" %%b in ("!SHARE_PATH!") do set "SHARE_PATH=%%b"
    set "SHARE_PATH=!SHARE_PATH:"=!"
    
    :: Extract just the file:// path if there's other text
    for /f "tokens=*" %%c in ("!SHARE_PATH!") do (
        echo %%c | findstr /i "file://" >nul
        if !errorlevel! equ 0 (
            :: Convert file:// to UNC path (\\server\share)
            set "UNC_PATH=!SHARE_PATH:file://=\\!"
            set "UNC_PATH=!UNC_PATH:/=\!"
            
            echo [102m Share path received: !SHARE_PATH![0m
            echo [102m UNC path: !UNC_PATH![0m
            echo.
            
            :: Save the share path for reference
            echo !SHARE_PATH! > ETL_SharePath.txt
            
            :: Check if the share path is accessible
            echo Checking share path accessibility...
            if exist "!UNC_PATH!" (
                echo [102m Share path is accessible.[0m
                echo.
                
                :: Copy the ETL folder to the share path
                echo Copying ETL folder to share path...
                echo Source: %ETL_FOLDER%
                echo Destination: !UNC_PATH!
                echo.
                
                :: Use robocopy for better handling of large folders
                robocopy "%ETL_FOLDER%" "!UNC_PATH!" /E /R:3 /W:5 /MT:8 /NFL /NDL /NP
                
                if !errorlevel! lss 8 (
                    echo.
                    echo [102m SUCCESS: ETL folder copied to share path successfully![0m
                    echo [102m Location: !UNC_PATH![0m
                    echo.
                ) else (
                    echo.
                    echo [101m Error: Failed to copy ETL folder. Robocopy error level: !errorlevel![0m
                    echo.
                )
            ) else (
                echo [101m Error: Share path is not accessible: !UNC_PATH![0m
                echo Please check network connectivity and permissions.
                echo.
            )
        )
    )
) else (
    echo [101m Error: No share path found in API response.[0m
    echo Please check the API response in ETL_API_Response.txt
    echo.
)

echo ========================================
echo Script completed.
echo ========================================
pause
