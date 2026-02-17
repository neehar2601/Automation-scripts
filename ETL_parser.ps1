<#
.SYNOPSIS
    Process ETL trace log files and generate CSV reports using Windows Performance Analyzer

.DESCRIPTION
    This script searches for *_Tracelog.etl files, processes them using wpaexporter,
    and organizes the output into descriptive folders based on KPI IDs and titles.
    
    Features:
    - Recursively searches for ETL files
    - Creates organized folder structure with normalized names
    - Uses KPI-Details.json for descriptive folder names
    - Generates CSV reports from ETL files
    - Moves processed ETL files to output folders

.PARAMETER SearchFolder
    The folder path where to search for ETL files
    Default: C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results

.PARAMETER OutputFolder
    The output folder path for processed ETL files and CSV reports
    Default: C:\KSR_Package\KSR\Test_Run_KR\Results\ETL

.PARAMETER ProfilePath
    The path to the WPA profile file (.wpaProfile)
    Default: C:\Users\nnellika\OneDrive - Intel Corporation\Documents\ETL\ETL\wprfile.wpaProfile

.PARAMETER KPIJsonFile
    The path to the KPI-Details.json file for KPI title lookup
    Default: <ScriptDirectory>\KPI-Details.json

.EXAMPLE
    .\ETL_parser.ps1
    Process ETL files using default paths

.EXAMPLE
    .\ETL_parser.ps1 -SearchFolder "C:\Custom\Path" -OutputFolder "C:\Output"
    Process ETL files from custom search path to custom output folder
#>

param(
    [string]$SearchFolder = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results",
    [string]$OutputFolder = "C:\KSR_Package\KSR\Test_Run_KR\Results\ETL",
    [string]$ProfilePath = "C:\Users\nnellika\OneDrive - Intel Corporation\Documents\ETL\ETL\wprfile.wpaProfile",
    [string]$KPIJsonFile = "$PSScriptRoot\KPI-Details.json"
)

# PowerShell helper script path
$PSHelper = "$PSScriptRoot\Get-KPITitle.ps1"

# Initialize counters
$fileCount = 0
$successCount = 0
$errorCount = 0

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ETL Parser - Trace Log Processor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Validate search folder
if (-not (Test-Path $SearchFolder)) {
    Write-Host "Error: Search folder not found: $SearchFolder" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Validate profile file
if (-not (Test-Path $ProfilePath)) {
    Write-Host "Error: Profile file not found: $ProfilePath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if KPI JSON file exists
if (-not (Test-Path $KPIJsonFile)) {
    Write-Host "Warning: KPI-Details.json not found: $KPIJsonFile" -ForegroundColor Yellow
    Write-Host "Will use original ETL filenames without KPI titles." -ForegroundColor Yellow
    $KPIJsonFile = $null
}

# Check if PowerShell helper script exists
if (-not (Test-Path $PSHelper)) {
    Write-Host "Warning: Get-KPITitle.ps1 not found: $PSHelper" -ForegroundColor Yellow
    Write-Host "Will use original ETL filenames without KPI titles." -ForegroundColor Yellow
    $PSHelper = $null
}

# Create output folder if it doesn't exist
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    Write-Host "Created ETL output folder: $OutputFolder" -ForegroundColor Green
}

Write-Host "Searching for *_Tracelog.etl files in: $SearchFolder" -ForegroundColor Cyan
Write-Host "Processing files in all subfolders..." -ForegroundColor Cyan
Write-Host "Output will be organized in: $OutputFolder" -ForegroundColor Cyan
Write-Host ""

# Search recursively for all ETL files ending with _Tracelog.etl
$etlFiles = Get-ChildItem -Path $SearchFolder -Recurse -Filter "*_Tracelog.etl" -ErrorAction SilentlyContinue

if ($etlFiles.Count -eq 0) {
    Write-Host "No ETL files ending with _Tracelog.etl found in $SearchFolder and subdirectories." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 0
}

foreach ($file in $etlFiles) {
    $fileCount++
    
    # Get the filename without extension
    $etlName = $file.BaseName
    
    # Remove _Tracelog suffix if present
    $filename = $etlName -replace '_Tracelog$', ''
    
    # Extract just the KPI ID (GLD followed by digits)
    if ($filename -match '^(GLD\d+)') {
        $kpiId = $matches[1]
    } else {
        Write-Host "[$fileCount] Warning: Could not extract KPI ID from: $($file.Name)" -ForegroundColor Yellow
        continue
    }
    
    # Get folder name from PowerShell helper script
    $folderName = $kpiId.ToLower()
    
    if ($KPIJsonFile -and $PSHelper) {
        try {
            $folderName = & $PSHelper -JsonFile $KPIJsonFile -KPIId $kpiId -ETLFileName $filename
            if ([string]::IsNullOrWhiteSpace($folderName)) {
                $folderName = $kpiId.ToLower()
            }
        } catch {
            Write-Host "[$fileCount] Warning: Error getting folder name from helper script" -ForegroundColor Yellow
            $folderName = $kpiId.ToLower()
        }
    }
    
    # Ensure folder name contains no invalid characters (safety check)
    $folderName = $folderName -replace '[\\/:*?"<>|\[\]]', '_'
    $folderName = $folderName -replace '_+', '_'
    $folderName = $folderName.Trim('_')
    
    Write-Host "[$fileCount] Found: $($file.FullName)" -ForegroundColor White
    Write-Host "[$fileCount] KPI ID: $kpiId" -ForegroundColor Gray
    Write-Host "[$fileCount] Folder Name: $folderName" -ForegroundColor Gray
    Write-Host "[$fileCount] Processing..." -ForegroundColor Cyan
    
    # Create test case folder in ETL output directory
    $outputDir = Join-Path $OutputFolder $folderName
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Save current location
    $currentLocation = Get-Location
    
    try {
        # Change to the output directory for wpaexporter
        Set-Location $outputDir
        
        # Run wpaexporter - output will be saved in the current directory
        $wpaProcess = Start-Process -FilePath "wpaexporter" -ArgumentList "-i `"$($file.FullName)`" -profile `"$ProfilePath`"" -Wait -PassThru -NoNewWindow
        
        if ($wpaProcess.ExitCode -eq 0) {
            $successCount++
            
            # Move the original ETL file to the output directory
            Write-Host "[$fileCount] Moving ETL file to output directory..." -ForegroundColor Gray
            Move-Item -Path $file.FullName -Destination $outputDir -Force -ErrorAction SilentlyContinue
            
            Write-Host "[$fileCount] SUCCESS: $($file.Name)" -ForegroundColor Green
            Write-Host "[$fileCount] Output saved in: $outputDir" -ForegroundColor Green
        } else {
            $errorCount++
            Write-Host "[$fileCount] ERROR: Failed to process $($file.Name)" -ForegroundColor Red
        }
    } catch {
        $errorCount++
        Write-Host "[$fileCount] ERROR: Exception occurred: $_" -ForegroundColor Red
    } finally {
        # Return to previous directory
        Set-Location $currentLocation
    }
    
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total files found: $fileCount" -ForegroundColor White
Write-Host "Successfully processed: $successCount" -ForegroundColor Green
Write-Host "Errors: $errorCount" -ForegroundColor Red
Write-Host ""
Write-Host "All processed files have been organized in: $OutputFolder" -ForegroundColor Cyan
Write-Host "Each test case has its own folder containing the CSV files and original ETL file." -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"
