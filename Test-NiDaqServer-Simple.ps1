# Test-NiDaqServer-Simple.ps1
# Simple validation test for NiDaq Server

param(
    [string]$ServerHost = "localhost",
    [int]$ServerPort = 55555
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "NiDaq Server Test Suite v2.0" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$testsPassed = 0
$testsFailed = 0

# Test Helper Function
function Test-ServerCommand {
    param(
        [int]$Command,
        [string]$Payload = ""
    )
    
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect($ServerHost, $ServerPort)
        $client.ReceiveTimeout = 10000
        $stream = $client.GetStream()
        
        # Build message
        if ($Payload -ne "") {
            $message = "$Command" + "|" + "$Payload"
        } else {
            $message = "$Command"
        }
        
        $messageBytes = [System.Text.Encoding]::UTF8.GetBytes($message)
        $stream.Write($messageBytes, 0, $messageBytes.Length)
        $stream.Flush()
        
        # Receive response
        $buffer = New-Object byte[] 1024
        $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
        $response = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead).Trim()
        
        $stream.Close()
        $client.Close()
        
        return @{
            Success = $true
            Response = $response
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    if ($Passed) {
        $status = "PASS"
        $color = "Green"
        $script:testsPassed++
    } else {
        $status = "FAIL"
        $color = "Red"
        $script:testsFailed++
    }
    
    Write-Host "  [$status] $TestName" -ForegroundColor $color
    if ($Details) {
        Write-Host "         $Details" -ForegroundColor Gray
    }
}

# ============================================================================
# Test Cases
# ============================================================================

Write-Host "Test 1: Server Connectivity" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
$result = Test-ServerCommand -Command 101
Write-TestResult -TestName "Connect to server" -Passed $result.Success -Details $result.Response
Write-Host ""

Write-Host "Test 2: Status Commands" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
$result = Test-ServerCommand -Command 101
Write-TestResult -TestName "Command 101 - Get Status" -Passed $result.Success -Details $result.Response

$result = Test-ServerCommand -Command 102 -Payload "TestID"
Write-TestResult -TestName "Command 102 - Execute Test" -Passed $result.Success -Details $result.Response
Write-Host ""

Write-Host "Test 3: Configuration File" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
$configPath = ".\ServerConfig.json"
if (Test-Path $configPath) {
    Write-TestResult -TestName "ServerConfig.json exists" -Passed $true
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-TestResult -TestName "Config file is valid JSON" -Passed $true
    }
    catch {
        Write-TestResult -TestName "Config file is valid JSON" -Passed $false -Details $_.Exception.Message
    }
} else {
    Write-TestResult -TestName "ServerConfig.json exists" -Passed $false
}
Write-Host ""

Write-Host "Test 4: Server Files" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
Write-TestResult -TestName "NiDaqServer.ps1 exists" -Passed (Test-Path ".\NiDaqServer.ps1")
Write-TestResult -TestName "NiDaqClient.ps1 exists" -Passed (Test-Path ".\NiDaqClient.ps1")
Write-TestResult -TestName "README.md exists" -Passed (Test-Path ".\README.md")
Write-Host ""

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$total = $testsPassed + $testsFailed
Write-Host "Total Tests: $total" -ForegroundColor White
Write-Host "Passed: $testsPassed" -ForegroundColor Green
Write-Host "Failed: $testsFailed" -ForegroundColor Red

if ($testsFailed -eq 0) {
    Write-Host "`nAll tests passed!" -ForegroundColor Green
} else {
    $passRate = [math]::Round(($testsPassed / $total) * 100, 1)
    Write-Host "`nPass Rate: $passRate%" -ForegroundColor Yellow
}

Write-Host "`nNote: Some tests may fail if the server is not running." -ForegroundColor Gray
Write-Host "Start the server with: .\Start-NiDaqServer.bat`n" -ForegroundColor Gray
