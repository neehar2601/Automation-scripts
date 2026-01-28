# Test-ModularServer.ps1
# Comprehensive test suite for NiDaq Modular Server

param(
    [string]$ServerHost = "localhost",
    [int]$ServerPort = 55555
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "NiDaq Modular Server Test Suite v2.0" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$testsPassed = 0
$testsFailed = 0
$testsSkipped = 0

# ============================================================================
# Test Helper Functions
# ============================================================================

function Test-ServerCommand {
    param(
        [int]$Command,
        [string]$Payload = "",
        [int]$TimeoutMs = 10000
    )
    
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect($ServerHost, $ServerPort)
        $client.ReceiveTimeout = $TimeoutMs
        $stream = $client.GetStream()
        
        # Build message
        if ($Payload -ne "") {
            $message = "$Command|$Payload"
        } else {
            $message = "$Command"
        }
        
        Write-Host "    Sending: $message" -ForegroundColor Gray
        
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
            Command = $Command
            Payload = $Payload
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Command = $Command
            Payload = $Payload
        }
    }
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = "",
        [bool]$Skipped = $false
    )
    
    if ($Skipped) {
        $status = "SKIP"
        $color = "Yellow"
        $script:testsSkipped++
    }
    elseif ($Passed) {
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

function Test-ModuleFile {
    param([string]$ModulePath)
    
    if (-not (Test-Path $ModulePath)) {
        return $false
    }
    
    try {
        $content = Get-Content $ModulePath -Raw
        # Check if it has Export-ModuleMember
        return $content -match "Export-ModuleMember"
    }
    catch {
        return $false
    }
}

function Test-ClassFile {
    param([string]$ClassPath)
    
    if (-not (Test-Path $ClassPath)) {
        return $false
    }
    
    try {
        $content = Get-Content $ClassPath -Raw
        # Check if it has class definition
        return $content -match "class\s+\w+"
    }
    catch {
        return $false
    }
}

# ============================================================================
# Test Cases
# ============================================================================

Write-Host "Test Suite 1: Modular Structure" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

Write-Host "1.1 Directory Structure" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
Write-TestResult -TestName "Modules directory exists" -Passed (Test-Path ".\Modules")
Write-TestResult -TestName "Classes directory exists" -Passed (Test-Path ".\Classes")
Write-TestResult -TestName "Logs directory exists" -Passed (Test-Path ".\Logs")
Write-Host ""

Write-Host "1.2 Module Files" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
$moduleTests = @(
    @{Path = ".\Modules\LoggingModule.psm1"; Name = "LoggingModule.psm1"},
    @{Path = ".\Modules\ConfigurationModule.psm1"; Name = "ConfigurationModule.psm1"},
    @{Path = ".\Modules\TCPServerModule.psm1"; Name = "TCPServerModule.psm1"}
)

foreach ($test in $moduleTests) {
    $exists = Test-Path $test.Path
    $isValid = if ($exists) { Test-ModuleFile -ModulePath $test.Path } else { $false }
    Write-TestResult -TestName "$($test.Name) exists and valid" -Passed $isValid -Details $(if (-not $exists) { "File not found" } elseif (-not $isValid) { "Missing Export-ModuleMember" } else { "OK" })
}
Write-Host ""

Write-Host "1.3 Class Files" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
$classTests = @(
    @{Path = ".\Classes\PACSController.ps1"; Name = "PACSController.ps1"; ClassName = "PACSController"},
    @{Path = ".\Classes\RemoteExecutor.ps1"; Name = "RemoteExecutor.ps1"; ClassName = "RemoteExecutor"},
    @{Path = ".\Classes\CommandHandler.ps1"; Name = "CommandHandler.ps1"; ClassName = "CommandHandler"}
)

foreach ($test in $classTests) {
    $exists = Test-Path $test.Path
    $isValid = if ($exists) { 
        $content = Get-Content $test.Path -Raw
        $content -match "class\s+$($test.ClassName)"
    } else { $false }
    Write-TestResult -TestName "$($test.Name) contains $($test.ClassName) class" -Passed $isValid -Details $(if (-not $exists) { "File not found" } elseif (-not $isValid) { "Class definition not found" } else { "OK" })
}
Write-Host ""

Write-Host "1.4 Main Entry Point" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
Write-TestResult -TestName "NiDaqServer-Modular.ps1 exists" -Passed (Test-Path ".\NiDaqServer-Modular.ps1")
Write-TestResult -TestName "Start-ModularServer.bat exists" -Passed (Test-Path ".\Start-ModularServer.bat")
Write-TestResult -TestName "README-Modular.md exists" -Passed (Test-Path ".\README-Modular.md")
Write-Host ""

Write-Host "`nTest Suite 2: Module Functionality" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

Write-Host "2.1 Logging Module" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
try {
    Import-Module ".\Modules\LoggingModule.psm1" -Force -ErrorAction Stop
    $logFunctions = @("Write-Log", "Set-LogFile", "Get-LogFile")
    $hasAllFunctions = $true
    foreach ($func in $logFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $hasAllFunctions = $false
            break
        }
    }
    Write-TestResult -TestName "LoggingModule exports all functions" -Passed $hasAllFunctions -Details "Write-Log, Set-LogFile, Get-LogFile"
    
    # Test Write-Log
    try {
        Write-Log "Test message" -Level "INFO"
        Write-TestResult -TestName "Write-Log function works" -Passed $true
    }
    catch {
        Write-TestResult -TestName "Write-Log function works" -Passed $false -Details $_.Exception.Message
    }
}
catch {
    Write-TestResult -TestName "LoggingModule can be imported" -Passed $false -Details $_.Exception.Message
}
Write-Host ""

Write-Host "2.2 Configuration Module" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
try {
    Import-Module ".\Modules\ConfigurationModule.psm1" -Force -ErrorAction Stop
    $configFunctions = @("Load-ServerConfig", "Save-ServerConfig", "Get-DefaultConfig", "Test-ServerConfig")
    $hasAllFunctions = $true
    foreach ($func in $configFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $hasAllFunctions = $false
            break
        }
    }
    Write-TestResult -TestName "ConfigurationModule exports all functions" -Passed $hasAllFunctions
    
    # Test Get-DefaultConfig
    try {
        $defaultConfig = Get-DefaultConfig
        $hasRequiredSections = ($defaultConfig.Server -and $defaultConfig.Client -and $defaultConfig.PACS)
        Write-TestResult -TestName "Get-DefaultConfig returns valid config" -Passed $hasRequiredSections
    }
    catch {
        Write-TestResult -TestName "Get-DefaultConfig returns valid config" -Passed $false -Details $_.Exception.Message
    }
}
catch {
    Write-TestResult -TestName "ConfigurationModule can be imported" -Passed $false -Details $_.Exception.Message
}
Write-Host ""

Write-Host "2.3 TCP Server Module" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
try {
    Import-Module ".\Modules\TCPServerModule.psm1" -Force -ErrorAction Stop
    $tcpFunctions = @("Start-TCPServer", "Stop-TCPServer")
    $hasAllFunctions = $true
    foreach ($func in $tcpFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $hasAllFunctions = $false
            break
        }
    }
    Write-TestResult -TestName "TCPServerModule exports all functions" -Passed $hasAllFunctions
}
catch {
    Write-TestResult -TestName "TCPServerModule can be imported" -Passed $false -Details $_.Exception.Message
}
Write-Host ""

Write-Host "`nTest Suite 3: Server Connection Tests" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

Write-Host "3.1 Basic Connectivity" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
$connectionResult = Test-ServerCommand -Command 101
if ($connectionResult.Success) {
    Write-TestResult -TestName "Connect to modular server" -Passed $true -Details $connectionResult.Response
    $serverOnline = $connectionResult.Response -like "*SERVER_ONLINE*"
    Write-TestResult -TestName "Server responds with valid status" -Passed $serverOnline -Details $connectionResult.Response
} else {
    Write-TestResult -TestName "Connect to modular server" -Passed $false -Details $connectionResult.Error
    Write-Host "`n  NOTE: Server must be running for connection tests." -ForegroundColor Yellow
    Write-Host "  Start server with: .\Start-ModularServer.bat`n" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "3.2 Command Protocol Tests" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
if ($connectionResult.Success) {
    # Test Command 101 - Status
    $result = Test-ServerCommand -Command 101
    Write-TestResult -TestName "Command 101 (Status)" -Passed ($result.Success -and $result.Response -like "*SERVER_ONLINE*") -Details $result.Response
    
    # Test Command 104 - PACS Status
    $result = Test-ServerCommand -Command 104
    Write-TestResult -TestName "Command 104 (PACS Status)" -Passed ($result.Success -and ($result.Response -like "*PACS_STATUS*" -or $result.Response -like "*PACS_DISABLED*")) -Details $result.Response
    
    # Test invalid command
    $result = Test-ServerCommand -Command 999
    Write-TestResult -TestName "Invalid command handling" -Passed ($result.Success -and $result.Response -like "*INVALID_COMMAND*") -Details $result.Response
} else {
    Write-TestResult -TestName "Command tests" -Passed $false -Skipped $true -Details "Server not running"
}
Write-Host ""

Write-Host "`nTest Suite 4: Configuration Tests" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

Write-Host "4.1 Configuration File" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
$configPath = ".\ServerConfig.json"
if (Test-Path $configPath) {
    Write-TestResult -TestName "ServerConfig.json exists" -Passed $true
    
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-TestResult -TestName "Config is valid JSON" -Passed $true
        
        # Check required sections
        $requiredSections = @('Server', 'Client', 'PACS', 'Paths', 'Temperature', 'Features')
        $missingSections = @()
        foreach ($section in $requiredSections) {
            if (-not $config.$section) {
                $missingSections += $section
            }
        }
        
        if ($missingSections.Count -eq 0) {
            Write-TestResult -TestName "All required sections present" -Passed $true -Details "Server, Client, PACS, Paths, Temperature, Features"
        } else {
            Write-TestResult -TestName "All required sections present" -Passed $false -Details "Missing: $($missingSections -join ', ')"
        }
        
        # Check Server settings
        if ($config.Server.Port -gt 0 -and $config.Server.Port -lt 65536) {
            Write-TestResult -TestName "Valid port number" -Passed $true -Details "Port: $($config.Server.Port)"
        } else {
            Write-TestResult -TestName "Valid port number" -Passed $false -Details "Invalid port: $($config.Server.Port)"
        }
    }
    catch {
        Write-TestResult -TestName "Config is valid JSON" -Passed $false -Details $_.Exception.Message
    }
} else {
    Write-TestResult -TestName "ServerConfig.json exists" -Passed $false
}
Write-Host ""

Write-Host "`nTest Suite 5: Documentation Tests" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

Write-Host "5.1 Documentation Files" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
$docFiles = @(
    @{Path = ".\README-Modular.md"; Name = "README-Modular.md"; MinLines = 50},
    @{Path = ".\README.md"; Name = "README.md (original)"; MinLines = 30},
    @{Path = ".\ARCHITECTURE.md"; Name = "ARCHITECTURE.md"; MinLines = 50}
)

foreach ($doc in $docFiles) {
    if (Test-Path $doc.Path) {
        $lineCount = (Get-Content $doc.Path).Count
        $hasContent = $lineCount -gt $doc.MinLines
        Write-TestResult -TestName "$($doc.Name) exists with content" -Passed $hasContent -Details "$lineCount lines"
    } else {
        Write-TestResult -TestName "$($doc.Name) exists" -Passed $false
    }
}
Write-Host ""

# ============================================================================
# Summary
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$total = $testsPassed + $testsFailed + $testsSkipped
Write-Host "Total Tests: $total" -ForegroundColor White
Write-Host "Passed: $testsPassed" -ForegroundColor Green
Write-Host "Failed: $testsFailed" -ForegroundColor Red
Write-Host "Skipped: $testsSkipped" -ForegroundColor Yellow

if ($testsFailed -eq 0 -and $testsSkipped -eq 0) {
    Write-Host "`n✓ All tests passed! Modular server is fully functional." -ForegroundColor Green
} elseif ($testsFailed -eq 0) {
    Write-Host "`n✓ All active tests passed! ($testsSkipped skipped)" -ForegroundColor Green
    Write-Host "  Skipped tests require the server to be running." -ForegroundColor Yellow
} else {
    $passRate = [math]::Round(($testsPassed / ($testsPassed + $testsFailed)) * 100, 1)
    Write-Host "`nPass Rate: $passRate% (excluding skipped)" -ForegroundColor Yellow
    Write-Host "Some tests failed. Please review the errors above." -ForegroundColor Red
}

Write-Host "`nQuick Start Commands:" -ForegroundColor Cyan
Write-Host "  Start Server:  .\Start-ModularServer.bat" -ForegroundColor Gray
Write-Host "  Test Server:   .\Test-ModularServer.ps1" -ForegroundColor Gray
Write-Host "  Stop Server:   Press Ctrl+C in server window`n" -ForegroundColor Gray
