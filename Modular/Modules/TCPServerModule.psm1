# TCPServerModule.psm1
# TCP server functionality

function Start-TCPServer {
    <#
    .SYNOPSIS
        Starts the TCP server to listen for client connections
    .PARAMETER Config
        Server configuration object
    .PARAMETER Handler
        Command handler object
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$Config,
        
        [Parameter(Mandatory=$true)]
        [object]$Handler
    )
    
    Write-Log "========================================" -Level "INFO"
    Write-Log "NiDaq Server v2.0 - PowerShell Edition" -Level "INFO"
    Write-Log "========================================" -Level "INFO"
    Write-Log "Server Host: $($Config.Server.Host)" -Level "INFO"
    Write-Log "Server Port: $($Config.Server.Port)" -Level "INFO"
    Write-Log "Client IP: $($Config.Client.DefaultIP)" -Level "INFO"
    Write-Log "PACS Enabled: $($Config.PACS.Enabled)" -Level "INFO"
    Write-Log "========================================" -Level "INFO"
    
    # Create TCP listener
    $endpoint = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Parse($Config.Server.Host), $Config.Server.Port)
    $listener = [System.Net.Sockets.TcpListener]::new($endpoint)
    
    try {
        $listener.Start()
        Write-Log "Server listening on $($Config.Server.Host):$($Config.Server.Port)" -Level "SUCCESS"
        Write-Log "Press Ctrl+C to stop the server" -Level "INFO"
        
        $Global:ServerRunning = $true
        $clientCount = 0
        
        while ($Global:ServerRunning) {
            # Check if a client is pending (non-blocking with timeout)
            if ($listener.Pending()) {
                $clientCount++
                $client = $listener.AcceptTcpClient()
                $clientEndpoint = $client.Client.RemoteEndPoint
                Write-Log "Client #$clientCount connected: $clientEndpoint" -Level "INFO"
                
                try {
                    $stream = $client.GetStream()
                    $stream.ReadTimeout = $Config.Server.ReceiveTimeout * 1000
                    
                    # Read command
                    $bufferSize = $Config.Server.BufferSize
                    $buffer = New-Object byte[] $bufferSize
                    $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
                    
                    if ($bytesRead -gt 0) {
                        $message = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead).Trim()
                        Write-Log "Received: $message" -Level "INFO"
                        
                        # Parse command (format: "CODE|PAYLOAD")
                        $parts = $message -split '\|', 2
                        $command = $parts[0].Trim()
                        $payload = if ($parts.Length -gt 1) { $parts[1] } else { "" }
                        
                        try {
                            # Handle command
                            $response = $Handler.HandleCommand($command, $payload, $stream)
                            
                            # Send response
                            if ($response) {
                                $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($response)
                                $stream.Write($responseBytes, 0, $responseBytes.Length)
                                $stream.Flush()
                                
                                Write-Log "Response sent: $response" -Level "SUCCESS"
                            }
                            else {
                                Write-Log "Empty response from handler" -Level "WARNING"
                            }
                        }
                        catch {
                            Write-Log "Error in command handler: $($_.Exception.Message)" -Level "ERROR"
                            $errorResponse = "ERROR|$($_.Exception.Message)"
                            $errorBytes = [System.Text.Encoding]::UTF8.GetBytes($errorResponse)
                            $stream.Write($errorBytes, 0, $errorBytes.Length)
                            $stream.Flush()
                        }
                    }
                    else {
                        Write-Log "No data received from client" -Level "WARNING"
                    }
                }
                catch {
                    Write-Log "Error handling client: $($_.Exception.Message)" -Level "ERROR"
                    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level "DEBUG"
                }
                finally {
                    if ($stream) { 
                        try { $stream.Close() } catch { }
                    }
                    if ($client) { 
                        try { $client.Close() } catch { }
                    }
                    Write-Log "Client #$clientCount disconnected: $clientEndpoint" -Level "INFO"
                }
            }
            
            # Small delay to prevent CPU spinning
            Start-Sleep -Milliseconds 100
        }
    }
    catch {
        Write-Log "Server error: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
    finally {
        if ($listener) {
            $listener.Stop()
            Write-Log "Server stopped" -Level "INFO"
        }
    }
}

function Stop-TCPServer {
    <#
    .SYNOPSIS
        Stops the TCP server
    #>
    Write-Log "Stopping TCP server..." -Level "WARNING"
    $Global:ServerRunning = $false
}

# Export functions
Export-ModuleMember -Function Start-TCPServer, Stop-TCPServer
