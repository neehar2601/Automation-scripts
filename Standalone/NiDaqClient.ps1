# NiDaq Client - PowerShell Edition
# Version: 2.0
# Description: Client for communicating with NiDaq Server

param(
    [Parameter(Mandatory=$true)]
    [ValidateRange(101, 113)]
    [int]$Command,
    
    [string]$Payload = "",
    
    [string]$ServerHost = "localhost",
    
    [int]$ServerPort = 55555,
    
    [int]$Timeout = 300
)

$ErrorActionPreference = "Stop"

# ============================================================================
# CLIENT FUNCTIONS
# ============================================================================

function Send-NiDaqCommand {
    param(
        [int]$Command,
        [string]$Payload,
        [string]$ServerHost,
        [int]$ServerPort,
        [int]$Timeout
    )
    
    try {
        Write-Host "[INFO] Connecting to NiDaq Server at ${ServerHost}:${ServerPort}..." -ForegroundColor Cyan
        
        # Create TCP client
        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect($ServerHost, $ServerPort)
        $client.ReceiveTimeout = $Timeout * 1000
        $client.SendTimeout = $Timeout * 1000
        
        $stream = $client.GetStream()
        
        # Build message
        $message = if ($Payload) { "$Command|$Payload" } else { "$Command" }
        Write-Host "[INFO] Sending command: $message" -ForegroundColor Cyan
        
        # Send command
        $messageBytes = [System.Text.Encoding]::UTF8.GetBytes($message)
        $stream.Write($messageBytes, 0, $messageBytes.Length)
        $stream.Flush()
        
        # Receive response
        $buffer = New-Object byte[] 4096
        $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
        $response = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead).Trim()
        
        Write-Host "[SUCCESS] Response: $response" -ForegroundColor Green
        
        # Special handling for file transfer (Code 107)
        if ($Command -eq 107) {
            Receive-Files -Stream $stream
        }
        
        return @{
            Success = $true
            Response = $response
        }
    }
    catch {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
    finally {
        if ($stream) { $stream.Close() }
        if ($client) { $client.Close() }
    }
}

function Receive-Files {
    param([System.Net.Sockets.NetworkStream]$Stream)
    
    try {
        Write-Host "[INFO] Starting file transfer..." -ForegroundColor Cyan
        
        # Create result folder
        $resultFolder = ".\NiDaq_Results"
        if (-not (Test-Path $resultFolder)) {
            New-Item -Path $resultFolder -ItemType Directory | Out-Null
        }
        
        # Read file count
        $buffer = New-Object byte[] 1024
        $bytesRead = $Stream.Read($buffer, 0, $buffer.Length)
        $fileCount = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead).Trim()
        Write-Host "[INFO] Files to receive: $fileCount" -ForegroundColor Cyan
        
        for ($i = 1; $i -le [int]$fileCount; $i++) {
            # Read file size
            $bytesRead = $Stream.Read($buffer, 0, $buffer.Length)
            $fileSize = [int]([System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead).Trim())
            
            # Read file name
            $bytesRead = $Stream.Read($buffer, 0, $buffer.Length)
            $fileName = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead).Trim()
            
            Write-Host "[INFO] Receiving: $fileName ($fileSize bytes)" -ForegroundColor Cyan
            
            # Read file content
            $filePath = Join-Path $resultFolder $fileName
            $fileStream = [System.IO.File]::OpenWrite($filePath)
            
            $totalReceived = 0
            $fileBuffer = New-Object byte[] 8192
            
            while ($totalReceived -lt $fileSize) {
                $remaining = $fileSize - $totalReceived
                $toRead = [Math]::Min($remaining, $fileBuffer.Length)
                $bytesRead = $Stream.Read($fileBuffer, 0, $toRead)
                $fileStream.Write($fileBuffer, 0, $bytesRead)
                $totalReceived += $bytesRead
                
                $percent = [Math]::Round(($totalReceived / $fileSize) * 100)
                Write-Progress -Activity "Receiving $fileName" -Status "$percent% Complete" -PercentComplete $percent
            }
            
            $fileStream.Close()
            Write-Host "[SUCCESS] Saved: $filePath" -ForegroundColor Green
        }
        
        Write-Host "[SUCCESS] All files received successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] File transfer failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-Help {
    $helpText = @"
========================================
   NiDaq Client v2.0 - PowerShell Edition
========================================

USAGE:
    NiDaqClient.ps1 -Command <code> [-Payload <data>] [-ServerHost <ip>] [-ServerPort <port>]

COMMANDS:
    101     Check server status
    102     Execute test
            Payload: TestID|WaitTime|Iterations|SoCWatch
            Example: NiDaqClient.ps1 -Command 102 -Payload "GLD-1015|60|3|true"
    
    103     Start PACS
    104     Get PACS status
    105     Start PACS recording
            Payload: Duration|TestID
            Example: NiDaqClient.ps1 -Command 105 -Payload "300|GLD-1015"
    
    106     Stop PACS
    107     Transfer results (socket)
    108     Mark test complete
            Payload: TestID
    
    109     Set temperature
            Payload: Temperature (e.g., "25")
    
    110     Get current temperature
    111     Copy results (network share)
    112     Execute custom command
            Payload: Command to execute
    
    113     Network share results transfer

EXAMPLES:
    # Check server status
    .\NiDaqClient.ps1 -Command 101
    
    # Execute test GLD-1015 with 60s wait, 3 iterations, SoCWatch enabled
    .\NiDaqClient.ps1 -Command 102 -Payload "GLD-1015|60|3|true"
    
    # Start PACS
    .\NiDaqClient.ps1 -Command 103
    
    # Set temperature to 25°C
    .\NiDaqClient.ps1 -Command 109 -Payload "25"
    
    # Transfer results
    .\NiDaqClient.ps1 -Command 107

OPTIONS:
    -ServerHost    Server IP address (default: 192.168.1.10)
    -ServerPort    Server port (default: 55555)
    -Timeout       Connection timeout in seconds (default: 300)

For more information, visit: https://kingsriver.intel.com
"@
    
    Write-Host $helpText -ForegroundColor Cyan
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

if ($Command -eq 0) {
    Show-Help
    exit 0
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   NiDaq Client v2.0 - PowerShell Edition" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$result = Send-NiDaqCommand -Command $Command -Payload $Payload -ServerHost $ServerHost -ServerPort $ServerPort -Timeout $Timeout

if ($result.Success) {
    exit 0
}
else {
    exit 1
}
