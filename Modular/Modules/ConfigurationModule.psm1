# ConfigurationModule.psm1
# Configuration management for NiDaq Server

function Load-ServerConfig {
    <#
    .SYNOPSIS
        Loads server configuration from JSON file
    .PARAMETER ConfigPath
        Path to the configuration file
    #>
    param([string]$ConfigPath)
    
    try {
        if (-not (Test-Path $ConfigPath)) {
            Write-Log "Config file not found. Creating default configuration..." -Level "WARNING"
            $defaultConfig = Get-DefaultConfig
            Save-ServerConfig -Config $defaultConfig -ConfigPath $ConfigPath
            return $defaultConfig
        }
        
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        Write-Log "Configuration loaded successfully from $ConfigPath" -Level "SUCCESS"
        return $config
    }
    catch {
        Write-Log "Failed to load configuration: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Save-ServerConfig {
    <#
    .SYNOPSIS
        Saves server configuration to JSON file
    .PARAMETER Config
        Configuration object to save
    .PARAMETER ConfigPath
        Path to save the configuration file
    #>
    param(
        [object]$Config,
        [string]$ConfigPath
    )
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Out-File $ConfigPath -Encoding UTF8
        Write-Log "Configuration saved to $ConfigPath" -Level "SUCCESS"
    }
    catch {
        Write-Log "Failed to save configuration: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-DefaultConfig {
    <#
    .SYNOPSIS
        Returns default server configuration
    #>
    return [PSCustomObject]@{
        Server = @{
            Host = "0.0.0.0"
            Port = 55555
            MaxConnections = 10
            ReceiveTimeout = 300
            BufferSize = 4096
        }
        Client = @{
            DefaultIP = "192.168.1.100"
            Username = "Administrator"
            Password = ""
            WorkingPath = "C:\KSR_Package\KSR\Test_Run_KR"
        }
        PACS = @{
            Enabled = $true
            ExePath = "C:\Intel\PACS\pacs.exe"
            ConfigPath = "C:\Test\testconfig.csv"
            ResultPath = "C:\Test\results"
            DelayBeforeRecord = 10
            ProcessName = "pacs"
        }
        Paths = @{
            RunTestScript = "C:\GLD\New_Flow_5\RunTest.ps1"
            TestConfigFolder = "C:\GLD"
            ResultsFolder = "C:\Results"
            TempFolder = "C:\Temp"
            LogFolder = ".\Logs"
        }
        Temperature = @{
            Enabled = $false
            ScriptPath = "C:\Tools\KSRTemp.py"
            PythonPath = "python"
        }
        Features = @{
            BackgroundServiceControl = $true
            RemoteExecution = $true
            FileTransfer = $true
            TemperatureControl = $false
            AutoStartPACS = $false
        }
        Logging = @{
            Level = "INFO"
            MaxLogSizeMB = 100
            RetainDays = 30
        }
    }
}

function Test-ServerConfig {
    <#
    .SYNOPSIS
        Validates server configuration
    .PARAMETER Config
        Configuration object to validate
    #>
    param([object]$Config)
    
    $isValid = $true
    
    # Check required sections
    $requiredSections = @('Server', 'Client', 'PACS', 'Paths', 'Temperature', 'Features')
    foreach ($section in $requiredSections) {
        if (-not $Config.$section) {
            Write-Log "Configuration missing required section: $section" -Level "ERROR"
            $isValid = $false
        }
    }
    
    # Check required server settings
    if ($Config.Server.Port -lt 1 -or $Config.Server.Port -gt 65535) {
        Write-Log "Invalid port number: $($Config.Server.Port)" -Level "ERROR"
        $isValid = $false
    }
    
    return $isValid
}

# Export functions
Export-ModuleMember -Function Load-ServerConfig, Save-ServerConfig, Get-DefaultConfig, Test-ServerConfig
