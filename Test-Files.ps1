# Test-Files.ps1
# Validate NiDaq Server package files

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "NiDaq Server Package Validation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$passed = 0
$failed = 0

function Test-File {
    param([string]$FileName)
    
    if (Test-Path $FileName) {
        Write-Host "  [PASS] $FileName exists" -ForegroundColor Green
        $script:passed++
        return $true
    } else {
        Write-Host "  [FAIL] $FileName not found" -ForegroundColor Red
        $script:failed++
        return $false
    }
}

# Test core files
Write-Host "Core Files:" -ForegroundColor Yellow
Test-File "NiDaqServer.ps1"
Test-File "NiDaqClient.ps1"
Test-File "ServerConfig.json"
Test-File "Start-NiDaqServer.bat"
Write-Host ""

# Test documentation
Write-Host "Documentation:" -ForegroundColor Yellow
Test-File "README.md"
Test-File "ARCHITECTURE.md"
Test-File "QUICK_REFERENCE.md"
Test-File "PACKAGE_SUMMARY.md"
Write-Host ""

# Test PowerShell syntax
Write-Host "Syntax Validation:" -ForegroundColor Yellow
try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content ".\NiDaqServer.ps1" -Raw), [ref]$null)
    Write-Host "  [PASS] NiDaqServer.ps1 syntax is valid" -ForegroundColor Green
    $passed++
} catch {
    Write-Host "  [FAIL] NiDaqServer.ps1 has syntax errors" -ForegroundColor Red
    $failed++
}

try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content ".\NiDaqClient.ps1" -Raw), [ref]$null)
    Write-Host "  [PASS] NiDaqClient.ps1 syntax is valid" -ForegroundColor Green
    $passed++
} catch {
    Write-Host "  [FAIL] NiDaqClient.ps1 has syntax errors" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Test config file
Write-Host "Configuration:" -ForegroundColor Yellow
try {
    $config = Get-Content ".\ServerConfig.json" -Raw | ConvertFrom-Json
    Write-Host "  [PASS] ServerConfig.json is valid JSON" -ForegroundColor Green
    $passed++
    
    # Check required sections
    if ($config.Server) {
        Write-Host "  [PASS] Server section exists" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Server section missing" -ForegroundColor Red
        $failed++
    }
    
    if ($config.Client) {
        Write-Host "  [PASS] Client section exists" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Client section missing" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  [FAIL] ServerConfig.json is invalid: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$total = $passed + $failed
Write-Host "Total: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

if ($failed -eq 0) {
    Write-Host "`nPackage is complete and ready!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "  1. Edit ServerConfig.json with your DUT IP address" -ForegroundColor Gray
    Write-Host "  2. Start server: .\Start-NiDaqServer.bat" -ForegroundColor Gray
    Write-Host "  3. Send command: .\NiDaqClient.ps1 -Command 101`n" -ForegroundColor Gray
} else {
    Write-Host "`nSome files are missing or invalid." -ForegroundColor Red
}
