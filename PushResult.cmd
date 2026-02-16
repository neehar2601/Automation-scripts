@echo off
:: ----------------------------------------------------------------------------------
:: Kings River Push Results 
:: Script Name		      : This script help to generate the parser results as a zip and push to FTP server and update results is copied.
:: Created by		        : Saravanan Rajagopal
:: Modified by		      : Saravanan Rajagopal
:: Last Modified date	  : 12-06-2024
:: Version	            : V1.1
:: ----------------------------------------------------------------------------------

setlocal enabledelayedexpansion

::Collecting BaseBoard SerialNumber
For /F "skip=2 tokens=2 delims=," %%A in ('wmic baseboard get serialnumber /FORMAT:csv') do (set "serialnumber=%%A")

:: Trim spaces from the serial number (if any)
for /f "tokens=* delims= " %%B in ("%serialnumber%") do set "serialnumber=%%B"

:: Check for invalid or missing serial number
if "%serialnumber%"=="" (
    echo Invalid serial number detected. Generating a dummy serial number...
    set "serialnumber=KSRSN%random%%random%"
) else if /i "%serialnumber%"=="Base Board Serial Number" (
    echo Invalid serial number detected. Generating a dummy serial number...
    set "serialnumber=KSRSN%random%%random%"
)

Echo %serialnumber% > %CD%\Results\SerialNumber.txt

IF EXIST %CD%\Results\*_SystemScope.json DEL %CD%\Results\*_SystemScope.json
IF EXIST %CD%\Results\*_SystemInfo.json DEL %CD%\Results\*_SystemInfo.json
IF EXIST %CD%\Results\*_EMonInfo.txt DEL %CD%\Results\*_EMonInfo.txt


::set "pattern=*_emon_*-core.txt"

::for /d /r "%CD%\Results" %%d in (*) do (
::    REM Check if the directory contains the target file
::    dir /b "%%d\%pattern%" >nul 2>&1 && (
::        echo Found in: %%d
::        goto :EMonFound
::    )
::)
:: goto:SystemScope


::Generate EMon Info
IF NOT EXIST "C:\Program Files (x86)\IntelSWTools\sep" (
    echo Emon Installation to get Emon Data
 
    jfrog.exe rt dl "ksr-ba-local/Tools/sep_private_5_56_win_10010457b11497234.zip" "C:\KSR_Package\tools\installers\sep_private_5_56_win_10010457b11497234.zip" --flat=true 
    powershell -Command "Expand-Archive 'C:\KSR_Package\tools\installers\sep_private_5_56_win_10010457b11497234.zip' -DestinationPath 'C:\KSR_Package\tools\installers\sep\'"
    echo "Sep installation started"
    cd "C:\KSR_Package\tools\installers\sep\sep_private_5_56_win_10010457b11497234\"
    call "sep-installer.cmd" -i --accept-license -ni
    echo "Sep Installation done"
    timeout /t 5
    REM Set environment variables in current session instead of opening new cmd
    start cmd /c "C:\Program Files (x86)\IntelSWTools\sep\sep_vars.cmd & echo exit"
    echo "Env set done"
    cd "C:\KSR_Package\KSR\Test_Run_KR"
    EMon -v > "%CD%\Results\%serialnumber%_EMonInfo.txt"
    echo Emon file Generated.
) else (
    cd /d "C:\KSR_Package\KSR\Test_Run_KR"
    EMon -v>"%CD%\Results\%serialnumber%_EMonInfo.txt"
    echo Emon file Generated.
)


:SystemScope
:: Generate SystemScope and SystemInfo Results
Echo Generate SystemScope, SystemInfo Results and EMon Info
::Generate System Scope
"C:\Program Files\Intel Corporation\Intel(R) System Scope Tool\SystemScopeCmdLine.exe" -log %CD%\Results\%serialnumber%_SystemScope.json -bkcmetainfo -firmwareversion -gfxinfo -osinfo -processorinfo -storage -memory -systemsummaryinfo -driverlist
::Generate System Info
"SpeedSysInfo\SpeedSysInfo.exe" -o %CD%\Results\%serialnumber%_SystemInfo.json


if not exist %CD%\Results\%serialnumber%_SystemInfo.json (
	echo [102m The file %serialnumber%_SystemInfo.json does not exist.[0m
	goto:eof
) else (
    echo The file %serialnumber%_SystemInfo.json exists.
)

if not exist %CD%\Results\%serialnumber%_SystemScope.json (
	echo [102m The file %serialnumber%_SystemScope.json does not exist.[0m 
	goto:eof
) else (
    echo The file %serialnumber%_SystemScope.json exists.
)




IF EXIST KingsResults*.zip DEL KingsResults*.zip
IF EXIST Kings_ZipFileName.txt DEL Kings_ZipFileName.txt
IF EXIST KingsWorkload.json DEL KingsWorkload.json

curl --silent -X POST -H "Content-Type: application/json"^
		https://kingsriver.intel.com/api/KPI/GetWorkload -k> KingsWorkload.json
     >nul find "workloadName" KingsWorkload.json && (
		echo [102m Kings Workload Downloaded successfully.[0m
     ) || (
		echo [101m Error: Unable To Download Workload.[0m
		goto:eof
     )
	 

KingsParser.exe

netsh advfirewall set allprofile state off

IF NOT EXIST Kings_ZipFileName.txt goto:eof
SET /p kingsZipFile=<Kings_ZipFileName.txt
curl -X POST -H "Content-Type: multipart/form-data" -F "RunNumber=1" -F "ResultZip=@%kingsZipFile%;type=application/x-zip-compressed" https://kingsriver.intel.com/parser/api/Parser/ProcessData -k> ParserDetails.txt
     >nul find "Results Uploaded Successfully" ParserDetails.txt && (
	 echo.
	 echo.
	 echo.
		echo [102m The Result File Pushed to KSR successfully.[0m
		echo.
		echo.
		echo.
     ) || (
		echo [101m Error: Unable To Send File.[0m
		goto:eof
     )

:: ----------------------------------------------------------------------------------
:: ETL Push Section - Push ETL logs to share path
:: ----------------------------------------------------------------------------------
echo.
echo ========================================
echo Starting ETL Push Process
echo ========================================
echo.

:: Set the ETL folder path
set "ETL_FOLDER=%CD%\Results\ETL"



:: Check if ETL folder exists
if not exist "%ETL_FOLDER%" (
    echo [101m Warning: ETL folder not found: %ETL_FOLDER%[0m
    echo Skipping ETL push process.
    @REM :: Call ETL_parser.bat if ETL folder is missing
    @REM if exist "%CD%\ETL_parser.bat" (
    @REM     echo Calling ETL_parser.bat to generate ETL logs...
    @REM     call "%CD%\ETL_parser.bat"
    @REM ) else (
    @REM     echo [101m ETL_parser.bat not found in current directory. Skipping ETL log generation.[0m
    @REM )
    @REM goto:eof
)

echo [102m ETL folder found: %ETL_FOLDER%[0m
echo [102m Using zip file: %kingsZipFile%[0m
echo.

:: Clean up previous ETL API response files
if exist ETL_API_Response.txt del ETL_API_Response.txt
if exist ETL_SharePath.txt del ETL_SharePath.txt

echo Sending zip file to ETL API...
echo.

:: Send the same zip file to the ETL API endpoint
:: Replace with your actual ETL API endpoint
set "ETL_API_ENDPOINT=https://ksr-dev.intel.com/parser/api/ETLLogPush/ProcessWTLLogs"

curl -X POST -H "Content-Type: multipart/form-data" -F "ResultZip=@%kingsZipFile%;type=application/x-zip-compressed" %ETL_API_ENDPOINT% -k > ETL_API_Response.txt

:: Check if API call was successful
if %errorlevel% neq 0 (
    echo [101m Error: Failed to send zip file to ETL API.[0m
    echo Skipping ETL copy process.
    goto:eof
)

:: Display API response
echo ETL API Response:
type ETL_API_Response.txt
echo.

:: Extract the share path from the API response
:: Looking for pattern like: file://gar.corp.intel.com/ec/proj/my/ccg/Board/kings_etl/...
set "SHARE_PATH="
for /f "tokens=*" %%a in ('findstr /i "file://" ETL_API_Response.txt') do (
    set "SHARE_PATH=%%a"
)

:: If the share path contains quotes or extra text, try to extract just the path
if defined SHARE_PATH (
    :: Remove leading/trailing spaces and quotes
    for /f "tokens=*" %%b in ("!SHARE_PATH!") do set "SHARE_PATH=%%b"
    set "SHARE_PATH=!SHARE_PATH:"=!"
    
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
) else (
    echo [101m Error: No share path found in ETL API response.[0m
    echo Please check the API response in ETL_API_Response.txt
    echo.
)

echo ========================================
echo ETL Push Process Completed
echo ========================================
