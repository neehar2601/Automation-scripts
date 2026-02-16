# ==================================================================================
# Script Name: Extract_Test_Results.ps1
# Description: Extracts test scores and power data from Golden Results JSON files
# Created: February 13, 2026
# Version: 1.0
# ==================================================================================

param(
    [string]$InputFolder = ".\Golden_Results",
    [string]$OutputCSV = ".\Complete_Test_Results.csv",
    [string]$OutputReport = ".\Test_Results_Report.md",
    [switch]$IncludePowerData = $true,
    [switch]$VerboseOutput = $false
)

# Initialize results array
$results = @()
$errorCount = 0
$successCount = 0

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST RESULTS EXTRACTION SCRIPT" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if input folder exists
if (-not (Test-Path $InputFolder)) {
    Write-Host "ERROR: Input folder not found: $InputFolder" -ForegroundColor Red
    exit 1
}

Write-Host "Input Folder: $InputFolder" -ForegroundColor Yellow
Write-Host "Output CSV: $OutputCSV" -ForegroundColor Yellow
Write-Host "Output Report: $OutputReport" -ForegroundColor Yellow
Write-Host ""

# Get all JSON files
$jsonFiles = Get-ChildItem "$InputFolder\*.JSON" -File

if ($jsonFiles.Count -eq 0) {
    Write-Host "ERROR: No JSON files found in $InputFolder" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($jsonFiles.Count) JSON files to process..." -ForegroundColor Green
Write-Host ""

# Process each JSON file
foreach ($file in $jsonFiles) {
    try {
        if ($VerboseOutput) {
            Write-Host "Processing: $($file.Name)..." -ForegroundColor Gray
        }
        
        # Read and parse JSON
        $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
        
        # Extract basic info
        $testID = $json.KPIId
        $computerName = $json.ComputerName
        
        # Extract all score fields (keep N/A if not present)
        $score = if ($json.Score -and $json.Score -ne "") { $json.Score } else { "N/A" }
        $scoreEMon = if ($json.ScoreEMon -and $json.ScoreEMon -ne "") { $json.ScoreEMon } else { "N/A" }
        $scoreSoCWatch = if ($json.ScoreSoCWatch -and $json.ScoreSoCWatch -ne "") { $json.ScoreSoCWatch } else { "N/A" }
        $scoreTypePerf = if ($json.ScoreTypePerf -and $json.ScoreTypePerf -ne "") { $json.ScoreTypePerf } else { "N/A" }
        $scoreWLC = if ($json.ScoreWLC -and $json.ScoreWLC -ne "") { $json.ScoreWLC } else { "N/A" }
        $scoreEMon_EDP = if ($json.ScoreEMon_EDP -and $json.ScoreEMon_EDP -ne "") { $json.ScoreEMon_EDP } else { "N/A" }
        
        # Create base result object
        $resultObj = [PSCustomObject]@{
            TestID = $testID
            ComputerName = $computerName
            Score = $score
            ScoreEMon = $scoreEMon
            ScoreSoCWatch = $scoreSoCWatch
            ScoreTypePerf = $scoreTypePerf
            ScoreWLC = $scoreWLC
            ScoreEMon_EDP = $scoreEMon_EDP
        }
        
        # Add power data if requested
        if ($IncludePowerData) {
            # Extract P_SOC data
            $psoc = $json.NiDaqResult_TypePerf | Where-Object { $_.Name -eq "P_SOC" }
            $resultObj | Add-Member -NotePropertyName "P_SOC_Peak_W" -NotePropertyValue $(
                if ($psoc) { [math]::Round([double]$psoc.Peak, 2) } else { "N/A" }
            )
            $resultObj | Add-Member -NotePropertyName "P_SOC_Average_W" -NotePropertyValue $(
                if ($psoc) { [math]::Round([double]$psoc.Average, 2) } else { "N/A" }
            )
            $resultObj | Add-Member -NotePropertyName "P_SOC_PeakTime_Sec" -NotePropertyValue $(
                if ($psoc) { $psoc.PeakTime } else { "N/A" }
            )
            
            # Extract P_CPU data
            $pcpu = $json.NiDaqResult_TypePerf | Where-Object { $_.Name -eq "P_CPU" }
            $resultObj | Add-Member -NotePropertyName "P_CPU_Peak_W" -NotePropertyValue $(
                if ($pcpu) { [math]::Round([double]$pcpu.Peak, 2) } else { "N/A" }
            )
            $resultObj | Add-Member -NotePropertyName "P_CPU_Average_W" -NotePropertyValue $(
                if ($pcpu) { [math]::Round([double]$pcpu.Average, 2) } else { "N/A" }
            )
        }
        
        # Add to results
        $results += $resultObj
        $successCount++
        
    } catch {
        Write-Host "ERROR processing $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "Processing Complete!" -ForegroundColor Green
Write-Host "  Success: $successCount files" -ForegroundColor Green
Write-Host "  Errors: $errorCount files" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

# Export to CSV
try {
    $results | Export-Csv -Path $OutputCSV -NoTypeInformation -Force
    Write-Host "CSV file saved: $OutputCSV" -ForegroundColor Green
} catch {
    Write-Host "ERROR saving CSV: $($_.Exception.Message)" -ForegroundColor Red
}

# Generate Markdown Report
try {
    $reportContent = @"
# Test Results Report
**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Source Folder:** $InputFolder  
**Total Tests:** $($results.Count)

---

## Summary Statistics

### Score Availability
"@

    # Calculate score availability
    $scoreAvail = $results | Where-Object { $_.Score -ne "N/A" } | Measure-Object
    $scoreEMonAvail = $results | Where-Object { $_.ScoreEMon -ne "N/A" } | Measure-Object
    $scoreSoCWatchAvail = $results | Where-Object { $_.ScoreSoCWatch -ne "N/A" } | Measure-Object
    $scoreTypePerfAvail = $results | Where-Object { $_.ScoreTypePerf -ne "N/A" } | Measure-Object
    $scoreWLCAvail = $results | Where-Object { $_.ScoreWLC -ne "N/A" } | Measure-Object
    
    $reportContent += @"

| Score Type | Available | Not Available |
|------------|-----------|---------------|
| **Score** | $($scoreAvail.Count) | $($results.Count - $scoreAvail.Count) |
| **ScoreEMon** | $($scoreEMonAvail.Count) | $($results.Count - $scoreEMonAvail.Count) |
| **ScoreSoCWatch** | $($scoreSoCWatchAvail.Count) | $($results.Count - $scoreSoCWatchAvail.Count) |
| **ScoreTypePerf** | $($scoreTypePerfAvail.Count) | $($results.Count - $scoreTypePerfAvail.Count) |
| **ScoreWLC** | $($scoreWLCAvail.Count) | $($results.Count - $scoreWLCAvail.Count) |

---

## Complete Test Results

### All Tests with Scores

| Test ID | Score | ScoreEMon | ScoreSoCWatch | ScoreTypePerf | ScoreWLC |
|---------|-------|-----------|---------------|---------------|----------|
"@

    foreach ($result in $results) {
        $reportContent += "| $($result.TestID) | $($result.Score) | $($result.ScoreEMon) | $($result.ScoreSoCWatch) | $($result.ScoreTypePerf) | $($result.ScoreWLC) |`n"
    }

    if ($IncludePowerData) {
        $reportContent += @"

---

## Power Consumption Data

### SOC and CPU Power for Each Test

| Test ID | SOC Peak (W) | SOC Avg (W) | CPU Peak (W) | CPU Avg (W) | Peak Time (sec) |
|---------|--------------|-------------|--------------|-------------|-----------------|
"@

        foreach ($result in $results) {
            $reportContent += "| $($result.TestID) | $($result.P_SOC_Peak_W) | $($result.P_SOC_Average_W) | $($result.P_CPU_Peak_W) | $($result.P_CPU_Average_W) | $($result.P_SOC_PeakTime_Sec) |`n"
        }
        
        # Add power statistics if available
        $socAvgValues = $results | Where-Object { $_.P_SOC_Average_W -ne "N/A" } | ForEach-Object { [double]$_.P_SOC_Average_W }
        $socPeakValues = $results | Where-Object { $_.P_SOC_Peak_W -ne "N/A" } | ForEach-Object { [double]$_.P_SOC_Peak_W }
        
        if ($socAvgValues.Count -gt 0) {
            $socAvgStats = $socAvgValues | Measure-Object -Average -Minimum -Maximum
            $socPeakStats = $socPeakValues | Measure-Object -Average -Minimum -Maximum
            
            $reportContent += @"

### Power Statistics

**SOC Average Power:**
- Minimum: $([math]::Round($socAvgStats.Minimum, 2)) W
- Maximum: $([math]::Round($socAvgStats.Maximum, 2)) W
- Mean: $([math]::Round($socAvgStats.Average, 2)) W

**SOC Peak Power:**
- Minimum: $([math]::Round($socPeakStats.Minimum, 2)) W
- Maximum: $([math]::Round($socPeakStats.Maximum, 2)) W
- Mean: $([math]::Round($socPeakStats.Average, 2)) W
"@
        }
    }

    $reportContent += @"

---

## Test Categories

### Category Breakdown

"@

    # Group by test category
    $gld1Tests = $results | Where-Object { $_.TestID -like "GLD1*" }
    $gld2Tests = $results | Where-Object { $_.TestID -like "GLD2*" }
    $gld3Tests = $results | Where-Object { $_.TestID -like "GLD3*" }
    $gld4Tests = $results | Where-Object { $_.TestID -like "GLD4*" }
    
    $reportContent += @"
- **GLD1xxx Tests:** $($gld1Tests.Count) (Low Power Category)
- **GLD2xxx Tests:** $($gld2Tests.Count) (Mid Power Category)
- **GLD3xxx Tests:** $($gld3Tests.Count) (High Power Category)
- **GLD4xxx Tests:** $($gld4Tests.Count) (Performance Category)

---

## Data Quality Notes

### Tests with Complete Score Data
"@

    $completeTests = $results | Where-Object { 
        $_.Score -ne "N/A" -or 
        $_.ScoreEMon -ne "N/A" -or 
        $_.ScoreSoCWatch -ne "N/A" -or 
        $_.ScoreTypePerf -ne "N/A" -or 
        $_.ScoreWLC -ne "N/A" 
    }
    
    $reportContent += "`n$($completeTests.Count) out of $($results.Count) tests have at least one score value.`n"
    
    $reportContent += @"

### Tests with Missing Score Data
"@

    $incompleteTests = $results | Where-Object { 
        $_.Score -eq "N/A" -and 
        $_.ScoreEMon -eq "N/A" -and 
        $_.ScoreSoCWatch -eq "N/A" -and 
        $_.ScoreTypePerf -eq "N/A" -and 
        $_.ScoreWLC -eq "N/A" 
    }
    
    if ($incompleteTests.Count -gt 0) {
        $reportContent += "`n"
        foreach ($test in $incompleteTests) {
            $reportContent += "- $($test.TestID)`n"
        }
    } else {
        $reportContent += "`nNone - All tests have at least one score value.`n"
    }

    $reportContent += @"

---

## Files Generated

1. **$OutputCSV** - Raw data in CSV format (can be opened in Excel)
2. **$OutputReport** - This comprehensive report in Markdown format

---

*Report automatically generated by Extract_Test_Results.ps1*
"@

    # Save report
    $reportContent | Out-File -FilePath $OutputReport -Encoding UTF8 -Force
    Write-Host "Report saved: $OutputReport" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR generating report: $($_.Exception.Message)" -ForegroundColor Red
}

# Display summary table
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "EXTRACTED DATA PREVIEW" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($IncludePowerData) {
    $results | Format-Table TestID, ScoreTypePerf, ScoreWLC, P_SOC_Average_W, P_SOC_Peak_W -AutoSize
} else {
    $results | Format-Table TestID, Score, ScoreEMon, ScoreTypePerf, ScoreWLC -AutoSize
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "EXTRACTION COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Return results object for further processing
return $results
