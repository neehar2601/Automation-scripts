# ----------------------------------------------------------------------------------
# Kings River Benchmark Test Runner - Base Class with Defaults
# All test logic and default parameters in one place
# ----------------------------------------------------------------------------------

class BenchmarkTest {
    # Properties with default values
    [string]$TestType = "Perf"
    [string]$TestID = ""
    [string]$TestName = ""
    [string]$TestDomain = "Golden"
    [string]$TestSubDomain = ""
    [int]$Temperature = 83
    [int]$RecordTime = 0
    [int]$WaitTime = 10
    [int]$Repeats = 1
    [string]$ResultPath = ""
    [string]$TestCMD = ""
    [string]$TestPrestepCMD = ""
    [string]$TestPoststepCMD = ""
    [string]$ScoreRenameBat = "Score_Rename.bat"

    # Constructor - accepts a config hashtable to override defaults
    BenchmarkTest([hashtable]$config) {
        # Override default values with config values if provided
        foreach ($key in $config.Keys) {
            if ($this.PSObject.Properties.Name -contains $key) {
                $this.$key = $config[$key]
            }
        }

        # Auto-generate ResultPath if not provided
        if ([string]::IsNullOrWhiteSpace($this.ResultPath) -and -not [string]::IsNullOrWhiteSpace($this.TestID)) {
            $this.ResultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\$($this.TestID)"
            if (-not (Test-Path $this.ResultPath)) {
                New-Item -ItemType Directory -Path $this.ResultPath | Out-Null
            }
        }
    }

    # Method: PreStep
    [void] PreStep() {
        Write-Host "`n================================================================" -ForegroundColor Cyan
        Write-Host "  PreStep: $($this.TestID)" -ForegroundColor Cyan
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host "  Test Name: $($this.TestName)" -ForegroundColor White
        Write-Host "  Domain: $($this.TestDomain) | SubDomain: $($this.TestSubDomain)" -ForegroundColor White
        Write-Host "  Temperature Limit: $($this.Temperature)°C" -ForegroundColor Gray
        Write-Host "  Wait Time: $($this.WaitTime)s" -ForegroundColor Gray
        Write-Host "  Repeats: $($this.Repeats)" -ForegroundColor Gray
        
        # Execute custom prestep command if defined
        if (-not [string]::IsNullOrWhiteSpace($this.TestPrestepCMD)) {
            Write-Host "  Executing Prestep Command..." -ForegroundColor Yellow
            try {
                Invoke-Expression $this.TestPrestepCMD
                Write-Host "  [OK] Prestep command completed" -ForegroundColor Green
            }
            catch {
                Write-Host "  [ERROR] Prestep command failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        Write-Host "  [OK] PreStep completed" -ForegroundColor Green
    }

    # Method: Test (main test execution)
    [void] Test() {
        Write-Host "`n================================================================" -ForegroundColor Yellow
        Write-Host "  Test Execution: $($this.TestID)" -ForegroundColor Yellow
        Write-Host "================================================================" -ForegroundColor Yellow
        
        if ([string]::IsNullOrWhiteSpace($this.TestCMD)) {
            Write-Host "  [ERROR] TestCMD is not defined!" -ForegroundColor Red
            throw "TestCMD is required but not defined in config"
        }

        for ($i = 1; $i -le $this.Repeats; $i++) {
            if ($this.Repeats -gt 1) {
                Write-Host "`n  --- Iteration $i of $($this.Repeats) ---" -ForegroundColor Cyan
            }
            
            # Wait if WaitTime is specified
            if ($this.WaitTime -gt 0 -and $i -eq 1) {
                Write-Host "  Waiting $($this.WaitTime) seconds before test..." -ForegroundColor Gray
                Start-Sleep -Seconds $this.WaitTime
            }
            
            Write-Host "  Executing: $($this.TestCMD)" -ForegroundColor White
            try {
                $output = Invoke-Expression $this.TestCMD 2>&1
                if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
                    throw "Command exited with code $LASTEXITCODE"
                }
                Write-Host "  [OK] Iteration $i completed" -ForegroundColor Green
            }
            catch {
                Write-Host "  [ERROR] Iteration $i failed: $($_.Exception.Message)" -ForegroundColor Red
                throw
            }
        }
        
        Write-Host "  [OK] Test execution completed" -ForegroundColor Green
    }

    # Method: PostStep (post-processing)
    [void] PostStep() {
        Write-Host "`n================================================================" -ForegroundColor Magenta
        Write-Host "  PostStep: $($this.TestID)" -ForegroundColor Magenta
        Write-Host "================================================================" -ForegroundColor Magenta
        Write-Host "  Result Path: $($this.ResultPath)" -ForegroundColor White
        
        # Call Score_Rename.bat if it exists
        $scoreRenamePath = "C:\KSR_Package\KSR\Test_Run_KR\Score_Rename.bat"
        if (-not [string]::IsNullOrWhiteSpace($this.TestPoststepCMD)) {
            Write-Host "  Executing Poststep Command..." -ForegroundColor Yellow
            try {
                Invoke-Expression $this.TestPoststepCMD
                Write-Host "  [OK] Poststep command completed" -ForegroundColor Green
            }
            catch {
                Write-Host "  [ERROR] Poststep command failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        if (Test-Path $scoreRenamePath) {
            Write-Host "  Calling Score_Rename.bat..." -ForegroundColor Yellow
            try {
                & cmd.exe /c "call `"$scoreRenamePath`" `"$($this.ResultPath)`""
                Write-Host "  [OK] Score_Rename.bat completed" -ForegroundColor Green
            }
            catch {
                Write-Host "  [ERROR] Score_Rename.bat failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "  [INFO] Score_Rename.bat not found at: $scoreRenamePath" -ForegroundColor Yellow
        }
        
        Write-Host "  [OK] Results saved to: $($this.ResultPath)" -ForegroundColor Green
        Write-Host "  [OK] PostStep completed" -ForegroundColor Green
    }

    # Method: Run - Execute full test lifecycle
    [hashtable] Run() {
        $startTime = Get-Date
        $status = "Success"
        $errorMessage = ""

        Write-Host "`n================================================================" -ForegroundColor Magenta
        Write-Host "  Starting Test: $($this.TestID) - $($this.TestName)" -ForegroundColor Magenta
        Write-Host "================================================================" -ForegroundColor Magenta

        try {
            $this.PreStep()
            $this.Test()
            $this.PostStep()
        }
        catch {
            $status = "Failed"
            $errorMessage = $_.Exception.Message
            Write-Host "`n[ERROR] Test failed: $errorMessage" -ForegroundColor Red
        }

        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds

        Write-Host "`n================================================================" -ForegroundColor Magenta
        Write-Host "  Test Completed: $($this.TestID)" -ForegroundColor Magenta
        Write-Host "  Status: $status | Duration: $([math]::Round($duration, 2))s" -ForegroundColor Magenta
        Write-Host "================================================================`n" -ForegroundColor Magenta

        return @{
            TestID = $this.TestID
            TestName = $this.TestName
            Status = $status
            Duration = $duration
            StartTime = $startTime
            EndTime = $endTime
            ResultPath = $this.ResultPath
            ErrorMessage = $errorMessage
        }
    }

    # Method: Display configuration
    [void] DisplayConfig() {
        Write-Host "`n================================================================" -ForegroundColor Cyan
        Write-Host "  Test Configuration: $($this.TestID)" -ForegroundColor Cyan
        Write-Host "================================================================" -ForegroundColor Cyan
        
        $this.PSObject.Properties | Where-Object { $_.MemberType -eq 'Property' } | ForEach-Object {
            $value = if ([string]::IsNullOrWhiteSpace($_.Value)) { "(not set)" } else { $_.Value }
            Write-Host "  $($_.Name.PadRight(20)): $value" -ForegroundColor White
        }
        Write-Host "================================================================`n" -ForegroundColor Cyan
    }
}
