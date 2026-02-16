@echo off
setlocal enabledelayedexpansion

:: ----------------------------------------------------------------------------------
:: ETL Push Section - Push ETL logs to share path
:: ----------------------------------------------------------------------------------
echo.
echo ========================================
echo Starting ETL Push Process
echo ========================================
echo.

:: Set the ETL folder path
set "ETL_FOLDER=C:\KSR_Package\KSR\Test_Run_KR\Results\ETL"
set "kingsZipFile=%~1"

:: Check if ETL folder exists
if not exist "%ETL_FOLDER%" (
    echo WARNING: ETL folder not found: %ETL_FOLDER%
    @REM echo Skipping ETL push process.
    :: Call ETL_parser.bat if ETL folder is missing
    if exist "%CD%\ETL_parser.bat" (
        echo Calling ETL_parser.bat to generate ETL logs...
        call "%CD%\ETL_parser.bat"
    ) else (
        echo ERROR: ETL_parser.bat not found in current directory. Skipping ETL log generation.
    )
    goto:eof
)

echo [✓] ETL folder found: %ETL_FOLDER%
echo [✓] Using zip file: %kingsZipFile%
echo.

:: Clean up previous ETL API response files
if exist ETL_API_Response.txt del ETL_API_Response.txt
if exist ETL_SharePath.txt del ETL_SharePath.txt

echo ----------------------------------------
echo Sending zip file to ETL API...
echo ----------------------------------------

:: Send the same zip file to the ETL API endpoint
set "ETL_API_ENDPOINT=https://ksr-dev.intel.com/parser/api/ETLLogPush/ProcessWTLLogs"

curl -X POST -H "Content-Type: multipart/form-data" -F "ResultZip=@%kingsZipFile%;type=application/x-zip-compressed" %ETL_API_ENDPOINT% -k > ETL_API_Response.txt 2>&1

:: Check if API call was successful
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to send zip file to ETL API.
    echo Skipping ETL copy process.
    goto:eof
)

:: Display API response
echo.
echo API Response:
type ETL_API_Response.txt
echo.

:: ----------------------------------------------------------------------------------
:: Extract and process the share path from API response
:: ----------------------------------------------------------------------------------
:: Looking for pattern like: file://gar.corp.intel.com/ec/proj/my/ccg/Board/kings_etl/...
set "SHARE_PATH="
for /f "tokens=*" %%a in ('findstr /i "file://" ETL_API_Response.txt') do (
    set "SHARE_PATH=%%a"
)

:: Process the share path if found
if defined SHARE_PATH (
    :: Define the network mount path and credentials first
    set "NETWORK_MOUNT=\\gar.corp.intel.com\ec\proj\my\ccg\Board\kings_etl\File_Server"
    set "NETWORK_USER=sys_toolscps"
    set "NETWORK_PASS=9Iq5oXhSfV1Ii2x!32412"
    
    :: Remove leading/trailing spaces and quotes
    for /f "tokens=*" %%b in ("!SHARE_PATH!") do set "SHARE_PATH=%%b"
    set "SHARE_PATH=!SHARE_PATH:"=!"
    
    :: Convert file:// to UNC path (\\server\share)
    set "UNC_PATH=!SHARE_PATH:file://=\\!"
    set "UNC_PATH=!UNC_PATH:/=\!"
    
    :: Save the share path for reference
    echo !SHARE_PATH! > ETL_SharePath.txt 2>nul
    
    :: Extract the relative path from the full UNC path
    set "TEMP_MOUNT=!NETWORK_MOUNT!\"
    call set "RELATIVE_PATH=%%UNC_PATH:!TEMP_MOUNT!=%%"
    
    echo ----------------------------------------
    echo Path Configuration
    echo ----------------------------------------
    echo Network Mount : !NETWORK_MOUNT!
    echo Relative Path : !RELATIVE_PATH!
    echo Destination   : !NETWORK_MOUNT!\!RELATIVE_PATH!
    echo.
    
    :: ----------------------------------------------------------------------------------
    :: Step 1: Check if network path is accessible, if not mount it
    :: ----------------------------------------------------------------------------------
    echo ----------------------------------------
    echo Checking Network Access...
    echo ----------------------------------------
    dir "!NETWORK_MOUNT!" >nul 2>&1
    if !errorlevel! neq 0 (
        echo [!] Network path not mounted. Attempting to mount...
        net use "!NETWORK_MOUNT!" /user:!NETWORK_USER! !NETWORK_PASS! >nul 2>&1
        if !errorlevel! neq 0 (
            echo.
            echo ERROR: Failed to mount network path
            echo Path: !NETWORK_MOUNT!
            echo Please check credentials and network connectivity.
            goto:eof
        ) else (
            echo [✓] Network path mounted successfully
        )
    ) else (
        echo [✓] Network path is already accessible
    )
    echo.
    
    :: ----------------------------------------------------------------------------------
    :: Step 2: Generate the full destination path
    :: ----------------------------------------------------------------------------------
    set "DEST_PATH=!NETWORK_MOUNT!\!RELATIVE_PATH!"
    
    :: ----------------------------------------------------------------------------------
    :: Step 3: Create the destination folder if it doesn't exist
    :: ----------------------------------------------------------------------------------
    echo ----------------------------------------
    echo Creating Destination Folder...
    echo ----------------------------------------
    if not exist "!DEST_PATH!" (
        :: Use md command instead of mkdir for better network path support
        md "!DEST_PATH!" 2>nul
        if !errorlevel! neq 0 (
            echo [!] Primary method failed. Trying alternate method...
            :: Create folder by copying an empty directory structure
            robocopy "!NETWORK_MOUNT!" "!DEST_PATH!" /CREATE /R:1 /W:1 >nul 2>&1
            if exist "!DEST_PATH!" (
                echo [✓] Destination folder created successfully
            ) else (
                echo.
                echo ERROR: Failed to create destination folder
                echo Path: !DEST_PATH!
                echo Please check permissions and network connectivity.
                goto:eof
            )
        ) else (
            echo [✓] Destination folder created successfully
        )
    ) else (
        echo [✓] Destination folder already exists
    )
    echo.
    
    :: ----------------------------------------------------------------------------------
    :: Step 4: Copy the ETL folder contents to the destination path
    :: ----------------------------------------------------------------------------------
    echo ----------------------------------------
    echo Copying ETL Files...
    echo ----------------------------------------
    echo Source      : %ETL_FOLDER%
    echo Destination : !DEST_PATH!
    echo.
    
    :: Use robocopy for better handling of large folders
    robocopy "%ETL_FOLDER%" "!DEST_PATH!" /E /R:3 /W:5 /MT:8 /NFL /NDL /NP /CREATE
    
    set "ROBOCOPY_EXIT=!errorlevel!"
    
    :: Robocopy exit codes: 0-7 are success, 8+ are errors
    if !ROBOCOPY_EXIT! lss 8 (
        echo.
        echo ========================================
        echo [✓] SUCCESS: ETL files copied successfully!
        echo ========================================
        echo Location: !DEST_PATH!
        echo Robocopy Exit Code: !ROBOCOPY_EXIT!
        echo.
    ) else (
        echo.
        echo ========================================
        echo ERROR: Failed to copy ETL files
        echo ========================================
        echo Robocopy Exit Code: !ROBOCOPY_EXIT!
        echo Check network connectivity and permissions.
        echo.
    )
) else (
    echo.
    echo ERROR: No share path found in API response
    echo Please check the API response in ETL_API_Response.txt
    echo.
)

echo ========================================
echo ETL Push Process Completed
echo ========================================
