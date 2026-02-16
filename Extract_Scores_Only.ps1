# ==================================================================================
# Script Name: Extract_Scores_Only.ps1
# Description: Extracts only test scores from Golden Results JSON files
# Created: February 13, 2026
# Version: 1.0
# ==================================================================================

param(
    [string]$InputFolder = ".\Golden_Results",
    [string]$OutputCSV = ".\Test_Scores.csv",
    [string]$OutputReport = ".\Test_Scores_Report.md",
    [switch]$VerboseOutput = $false
)

# Initialize results array
$results = @()
$errorCount = 0
$successCount = 0

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST SCORES EXTRACTION SCRIPT" -ForegroundColor Cyan
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
        
        # Create result object with scores only
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
# Test Scores Report
**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Source Folder:** $InputFolder  
**Total Tests:** $($results.Count)  
**Computer:** $($results[0].ComputerName)

---

## Executive Summary

### Score Availability

"@

    # Calculate score availability
    $scoreAvail = ($results | Where-Object { $_.Score -ne "N/A" }).Count
    $scoreEMonAvail = ($results | Where-Object { $_.ScoreEMon -ne "N/A" }).Count
    $scoreSoCWatchAvail = ($results | Where-Object { $_.ScoreSoCWatch -ne "N/A" }).Count
    $scoreTypePerfAvail = ($results | Where-Object { $_.ScoreTypePerf -ne "N/A" }).Count
    $scoreWLCAvail = ($results | Where-Object { $_.ScoreWLC -ne "N/A" }).Count
    $scoreEMonEDPAvail = ($results | Where-Object { $_.ScoreEMon_EDP -ne "N/A" }).Count
    
    $reportContent += @"

| Score Type | Available | Not Available | Percentage |
|------------|-----------|---------------|------------|
| **Score** | $scoreAvail | $($results.Count - $scoreAvail) | $([math]::Round($scoreAvail / $results.Count * 100, 1))% |
| **ScoreEMon** | $scoreEMonAvail | $($results.Count - $scoreEMonAvail) | $([math]::Round($scoreEMonAvail / $results.Count * 100, 1))% |
| **ScoreSoCWatch** | $scoreSoCWatchAvail | $($results.Count - $scoreSoCWatchAvail) | $([math]::Round($scoreSoCWatchAvail / $results.Count * 100, 1))% |
| **ScoreTypePerf** | $scoreTypePerfAvail | $($results.Count - $scoreTypePerfAvail) | $([math]::Round($scoreTypePerfAvail / $results.Count * 100, 1))% |
| **ScoreWLC** | $scoreWLCAvail | $($results.Count - $scoreWLCAvail) | $([math]::Round($scoreWLCAvail / $results.Count * 100, 1))% |
| **ScoreEMon_EDP** | $scoreEMonEDPAvail | $($results.Count - $scoreEMonEDPAvail) | $([math]::Round($scoreEMonEDPAvail / $results.Count * 100, 1))% |

---

## Complete Test Scores

### All Tests

| Test ID | Score | ScoreEMon | ScoreSoCWatch | ScoreTypePerf | ScoreWLC | ScoreEMon_EDP |
|---------|-------|-----------|---------------|---------------|----------|---------------|
"@

    foreach ($result in $results) {
        $reportContent += "| $($result.TestID) | $($result.Score) | $($result.ScoreEMon) | $($result.ScoreSoCWatch) | $($result.ScoreTypePerf) | $($result.ScoreWLC) | $($result.ScoreEMon_EDP) |`n"
    }

    $reportContent += @"

---

## Score Analysis by Category

"@

    # Group by test category
    $gld1Tests = $results | Where-Object { $_.TestID -like "GLD1*" }
    $gld2Tests = $results | Where-Object { $_.TestID -like "GLD2*" }
    $gld3Tests = $results | Where-Object { $_.TestID -like "GLD3*" }
    $gld4Tests = $results | Where-Object { $_.TestID -like "GLD4*" }
    
    # GLD1xxx Analysis
    if ($gld1Tests.Count -gt 0) {
        $reportContent += @"

### GLD1xxx Tests (Low Power Category)
**Test Count:** $($gld1Tests.Count)

| Test ID | ScoreTypePerf | ScoreWLC |
|---------|---------------|----------|
"@
        foreach ($test in $gld1Tests) {
            $reportContent += "| $($test.TestID) | $($test.ScoreTypePerf) | $($test.ScoreWLC) |`n"
        }
        
        # Calculate statistics for available scores
        $gld1TypePerf = $gld1Tests | Where-Object { $_.ScoreTypePerf -ne "N/A" } | ForEach-Object { [double]$_.ScoreTypePerf }
        $gld1WLC = $gld1Tests | Where-Object { $_.ScoreWLC -ne "N/A" } | ForEach-Object { [double]$_.ScoreWLC }
        
        if ($gld1TypePerf.Count -gt 0) {
            $typePerfStats = $gld1TypePerf | Measure-Object -Average -Minimum -Maximum
            $reportContent += @"

**ScoreTypePerf Statistics:**
- Count: $($gld1TypePerf.Count)
- Minimum: $([math]::Round($typePerfStats.Minimum, 2))
- Maximum: $([math]::Round($typePerfStats.Maximum, 2))
- Average: $([math]::Round($typePerfStats.Average, 2))

"@
        }
        
        if ($gld1WLC.Count -gt 0) {
            $wlcStats = $gld1WLC | Measure-Object -Average -Minimum -Maximum
            $reportContent += @"
**ScoreWLC Statistics:**
- Count: $($gld1WLC.Count)
- Minimum: $([math]::Round($wlcStats.Minimum, 2))
- Maximum: $([math]::Round($wlcStats.Maximum, 2))
- Average: $([math]::Round($wlcStats.Average, 2))

"@
        }
    }

    # GLD2xxx Analysis
    if ($gld2Tests.Count -gt 0) {
        $reportContent += @"

### GLD2xxx Tests (Mid Power Category)
**Test Count:** $($gld2Tests.Count)

| Test ID | ScoreTypePerf | ScoreWLC |
|---------|---------------|----------|
"@
        foreach ($test in $gld2Tests) {
            $reportContent += "| $($test.TestID) | $($test.ScoreTypePerf) | $($test.ScoreWLC) |`n"
        }
    }

    # GLD3xxx Analysis
    if ($gld3Tests.Count -gt 0) {
        $reportContent += @"

### GLD3xxx Tests (High Power Category)
**Test Count:** $($gld3Tests.Count)

| Test ID | ScoreTypePerf | ScoreWLC |
|---------|---------------|----------|
"@
        foreach ($test in $gld3Tests) {
            $reportContent += "| $($test.TestID) | $($test.ScoreTypePerf) | $($test.ScoreWLC) |`n"
        }
    }

    # GLD4xxx Analysis
    if ($gld4Tests.Count -gt 0) {
        $reportContent += @"

### GLD4xxx Tests (Performance Category)
**Test Count:** $($gld4Tests.Count)

| Test ID | ScoreTypePerf | ScoreWLC |
|---------|---------------|----------|
"@
        foreach ($test in $gld4Tests) {
            $reportContent += "| $($test.TestID) | $($test.ScoreTypePerf) | $($test.ScoreWLC) |`n"
        }
    }

    $reportContent += @"

---

## Key Findings

### Highest Scores

"@

    # Find highest scores for each type
    $highestTypePerf = $results | Where-Object { $_.ScoreTypePerf -ne "N/A" } | Sort-Object { [double]$_.ScoreTypePerf } -Descending | Select-Object -First 1
    $highestWLC = $results | Where-Object { $_.ScoreWLC -ne "N/A" } | Sort-Object { [double]$_.ScoreWLC } -Descending | Select-Object -First 1
    
    if ($highestTypePerf) {
        $reportContent += "- **Best ScoreTypePerf:** $($highestTypePerf.TestID) with score $($highestTypePerf.ScoreTypePerf)`n"
    }
    if ($highestWLC) {
        $reportContent += "- **Best ScoreWLC:** $($highestWLC.TestID) with score $($highestWLC.ScoreWLC)`n"
    }

    $reportContent += @"

### Lowest Scores

"@

    # Find lowest scores
    $lowestTypePerf = $results | Where-Object { $_.ScoreTypePerf -ne "N/A" } | Sort-Object { [double]$_.ScoreTypePerf } | Select-Object -First 1
    $lowestWLC = $results | Where-Object { $_.ScoreWLC -ne "N/A" } | Sort-Object { [double]$_.ScoreWLC } | Select-Object -First 1
    
    if ($lowestTypePerf) {
        $reportContent += "- **Lowest ScoreTypePerf:** $($lowestTypePerf.TestID) with score $($lowestTypePerf.ScoreTypePerf)`n"
    }
    if ($lowestWLC) {
        $reportContent += "- **Lowest ScoreWLC:** $($lowestWLC.TestID) with score $($lowestWLC.ScoreWLC)`n"
    }

    $reportContent += @"

---

## Data Quality

### Tests with Complete Score Data

"@

    $testsWithScores = $results | Where-Object { 
        $_.Score -ne "N/A" -or 
        $_.ScoreEMon -ne "N/A" -or 
        $_.ScoreSoCWatch -ne "N/A" -or 
        $_.ScoreTypePerf -ne "N/A" -or 
        $_.ScoreWLC -ne "N/A" -or
        $_.ScoreEMon_EDP -ne "N/A"
    }
    
    $reportContent += "$($testsWithScores.Count) out of $($results.Count) tests have at least one score value.`n"
    
    $reportContent += @"

### Tests with No Score Data

"@

    $testsWithoutScores = $results | Where-Object { 
        $_.Score -eq "N/A" -and 
        $_.ScoreEMon -eq "N/A" -and 
        $_.ScoreSoCWatch -eq "N/A" -and 
        $_.ScoreTypePerf -eq "N/A" -and 
        $_.ScoreWLC -eq "N/A" -and
        $_.ScoreEMon_EDP -eq "N/A"
    }
    
    if ($testsWithoutScores.Count -gt 0) {
        $reportContent += "`nThe following tests have no score data:`n"
        foreach ($test in $testsWithoutScores) {
            $reportContent += "- $($test.TestID)`n"
        }
    } else {
        $reportContent += "`nAll tests have at least one score value.`n"
    }

    $reportContent += @"

---

## Score Type Definitions

| Score Type | Description |
|------------|-------------|
| **Score** | Overall test score |
| **ScoreEMon** | Energy Monitor performance score |
| **ScoreSoCWatch** | SoC Watch monitoring score |
| **ScoreTypePerf** | Type Performance benchmark score |
| **ScoreWLC** | Workload Cycle benchmark score |
| **ScoreEMon_EDP** | Energy Monitor EDP (Energy Delay Product) score |

---

## Files Generated

1. **$OutputCSV** - Raw score data in CSV format (Excel compatible)
2. **$OutputReport** - This comprehensive score analysis report

---

## Notes

- "N/A" indicates score data was not available or not collected for that test
- All score fields are preserved regardless of availability
- Higher scores generally indicate better performance

---

*Report automatically generated by Extract_Scores_Only.ps1*  
*Last Updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

    # Save report
    $reportContent | Out-File -FilePath $OutputReport -Encoding UTF8 -Force
    Write-Host "Report saved: $OutputReport" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR generating report: $($_.Exception.Message)" -ForegroundColor Red
}

# Display summary table
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "EXTRACTED SCORES PREVIEW" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$results | Format-Table TestID, Score, ScoreEMon, ScoreSoCWatch, ScoreTypePerf, ScoreWLC, ScoreEMon_EDP -AutoSize

Write-Host ""

# Return results object for further processing (suppress output with Out-Null if not captured)
# Uncomment the next line if you want to use the results in another script
# return $results
