<#
.SYNOPSIS
    Push ETL logs to network share path via Kings River API

.DESCRIPTION
    This script sends a zip file to the ETL API endpoint, retrieves the share path
    from the API response, and copies ETL logs to the network location.
    
    Features:
    - Sends zip file to Kings River ETL API
    - Extracts share path from API response
    - Mounts network drive if needed
    - Creates destination folders automatically
    - Copies ETL logs using robocopy with retry logic

.PARAMETER ZipFile
    Path to the Kings River results zip file to send to the API

.PARAMETER ETLFolder
    The folder containing ETL logs to push
    Default: C:\KSR_Package\KSR\Test_Run_KR\Results\ETL

.PARAMETER CallParserIfMissing
    If ETL folder doesn't exist, call ETL_parser.ps1 to generate it
    Default: $true

.EXAMPLE
    .\Push_ETL.ps1 -ZipFile "C:\Results\KingsResults_xxx.zip"
    Push ETL logs using the specified zip file

.EXAMPLE
    .\Push_ETL.ps1 -ZipFile "results.zip" -ETLFolder "C:\Custom\ETL"
    Push ETL logs from a custom folder location
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ZipFile,
    
    [string]$ETLFolder = "C:\KSR_Package\KSR\Test_Run_KR\Results\ETL",
    
    [bool]$CallParserIfMissing = $true
)

# Configuration
$ETLApiEndpoint = "https://ksr-dev.intel.com/parser/api/ETLLogPush/ProcessWTLLogs"
$NetworkMount = "\\gar.corp.intel.com\ec\proj\my\ccg\Board\kings_etl\File_Server"
$NetworkUser = "sys_toolscps"
$NetworkPass = "9Iq5oXhSfV1Ii2x!32412"
$ETLApiResponseFile = "ETL_API_Response.txt"
$ETLSharePathFile = "ETL_SharePath.txt"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting ETL Push Process" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if ETL folder exists
if (-not (Test-Path $ETLFolder)) {
    Write-Host "[!] WARNING: ETL folder not found: $ETLFolder" -ForegroundColor Yellow
    
    if ($CallParserIfMissing) {
        $parserScript = Join-Path $PSScriptRoot "ETL_parser.ps1"
        if (Test-Path $parserScript) {
            Write-Host "Calling ETL_parser.ps1 to generate ETL logs..." -ForegroundColor Cyan
            & $parserScript
        } else {
            Write-Host "ERROR: ETL_parser.ps1 not found in script directory. Skipping ETL log generation." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Skipping ETL push process." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "[OK] ETL folder found: $ETLFolder" -ForegroundColor Green
Write-Host "[OK] Using zip file: $ZipFile" -ForegroundColor Green
Write-Host ""

# Validate zip file exists
if (-not (Test-Path $ZipFile)) {
    Write-Host "ERROR: Zip file not found: $ZipFile" -ForegroundColor Red
    exit 1
}

# Clean up previous API response files
if (Test-Path $ETLApiResponseFile) {
    Remove-Item $ETLApiResponseFile -Force
}
if (Test-Path $ETLSharePathFile) {
    Remove-Item $ETLSharePathFile -Force
}

Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host "Sending zip file to ETL API..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host ""

# Send the zip file to the ETL API endpoint using curl.exe
try {
    # Build the curl command
    $curlCommand = "curl.exe -X POST -H `"Content-Type: multipart/form-data`" -F `"ResultZip=@$ZipFile;type=application/x-zip-compressed`" $ETLApiEndpoint -k"
    
    Write-Host "Executing: $curlCommand" -ForegroundColor Gray
    Write-Host ""
    
    # Execute curl and capture output
    $apiResponse = Invoke-Expression $curlCommand 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "ERROR: Failed to send zip file to ETL API." -ForegroundColor Red
        Write-Host "Skipping ETL copy process." -ForegroundColor Red
        exit 1
    }
    
    # Save the response to file
    Set-Content -Path $ETLApiResponseFile -Value $apiResponse
    
    Write-Host "[OK] API request completed successfully" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "ERROR: Exception occurred while sending zip file: $_" -ForegroundColor Red
    exit 1
}

# Display API response
if (Test-Path $ETLApiResponseFile) {
    Write-Host ""
    Write-Host "API Response:" -ForegroundColor Cyan
    Get-Content $ETLApiResponseFile | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
    Write-Host ""
} else {
    Write-Host "ERROR: API response file not created" -ForegroundColor Red
    exit 1
}

# Extract share path from API response
$sharePath = $null
$apiResponseContent = Get-Content $ETLApiResponseFile -Raw
if ($apiResponseContent -match 'file://[^\s"]+') {
    $sharePath = $matches[0]
    Write-Host "[OK] Share path extracted from API response" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[ERROR] No share path found in API response" -ForegroundColor Red
    Write-Host "Please check the API response in $ETLApiResponseFile" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# Convert file:// URL to UNC path
$uncPath = $sharePath -replace '^file://', '\\' -replace '/', '\'

# Save the share path for reference
Set-Content -Path $ETLSharePathFile -Value $sharePath

# Extract the relative path from the full UNC path
$relativePath = $uncPath -replace [regex]::Escape("$NetworkMount\"), ''

Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host "Path Configuration" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host "Network Mount : $NetworkMount" -ForegroundColor Gray
Write-Host "Relative Path : $relativePath" -ForegroundColor Gray
Write-Host "Destination   : $NetworkMount\$relativePath" -ForegroundColor Gray
Write-Host ""

# Check if network path is accessible, if not mount it
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host "Checking Network Access..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

if (-not (Test-Path $NetworkMount)) {
    Write-Host "[!] Network path not mounted. Attempting to mount..." -ForegroundColor Yellow
    
    try {
        # Create PSCredential object
        $securePassword = ConvertTo-SecureString $NetworkPass -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($NetworkUser, $securePassword)
        
        # Mount the network drive (use net use as New-PSDrive doesn't persist well)
        $netUseCmd = "net use `"$NetworkMount`" /user:$NetworkUser $NetworkPass"
        $netResult = Invoke-Expression $netUseCmd 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "ERROR: Failed to mount network path" -ForegroundColor Red
            Write-Host "Path: $NetworkMount" -ForegroundColor Red
            Write-Host "Please check credentials and network connectivity." -ForegroundColor Red
            exit 1
        } else {
            Write-Host "[OK] Network path mounted successfully" -ForegroundColor Green
        }
    } catch {
        Write-Host ""
        Write-Host "ERROR: Exception occurred while mounting network path: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[OK] Network path is already accessible" -ForegroundColor Green
}
Write-Host ""

# Generate the full destination path
$destPath = Join-Path $NetworkMount $relativePath

# Create the destination folder if it doesn't exist
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host "Creating Destination Folder..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

if (-not (Test-Path $destPath)) {
    try {
        New-Item -ItemType Directory -Path $destPath -Force | Out-Null
        Write-Host "[OK] Destination folder created successfully" -ForegroundColor Green
    } catch {
        Write-Host "[!] Primary method failed. Trying alternate method..." -ForegroundColor Yellow
        
        # Try using robocopy to create the folder structure
        $robocopyArgs = @(
            "`"$NetworkMount`"",
            "`"$destPath`"",
            "/CREATE",
            "/R:1",
            "/W:1"
        )
        
        $robocopyCmd = "robocopy $($robocopyArgs -join ' ')"
        Invoke-Expression $robocopyCmd | Out-Null
        
        if (Test-Path $destPath) {
            Write-Host "[OK] Destination folder created successfully" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "ERROR: Failed to create destination folder" -ForegroundColor Red
            Write-Host "Path: $destPath" -ForegroundColor Red
            Write-Host "Please check permissions and network connectivity." -ForegroundColor Red
            exit 1
        }
    }
} else {
    Write-Host "[OK] Destination folder already exists" -ForegroundColor Green
}
Write-Host ""

# Copy the ETL folder contents to the destination path
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host "Copying ETL Files..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow
Write-Host "Source      : $ETLFolder" -ForegroundColor Gray
Write-Host "Destination : $destPath" -ForegroundColor Gray
Write-Host ""

# Use robocopy for better handling of large folders
$robocopyArgs = @(
    "`"$ETLFolder`"",
    "`"$destPath`"",
    "/E",           # Copy subdirectories including empty ones
    "/R:3",         # Retry 3 times
    "/W:5",         # Wait 5 seconds between retries
    "/MT:8",        # Multi-threaded (8 threads)
    "/NFL",         # No file list
    "/NDL",         # No directory list
    "/NP",          # No progress
    "/CREATE"       # Create directory structure and zero-length files only
)

$robocopyCmd = "robocopy $($robocopyArgs -join ' ')"
$robocopyOutput = Invoke-Expression $robocopyCmd 2>&1
$robocopyExit = $LASTEXITCODE

# Robocopy exit codes: 0-7 are success, 8+ are errors
if ($robocopyExit -lt 8) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "[OK] SUCCESS: ETL files copied successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Location: $destPath" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "[ERROR] Failed to copy ETL files" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Robocopy Exit Code: $robocopyExit" -ForegroundColor Red
    Write-Host "Check network connectivity and permissions." -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ETL Push Process Completed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
