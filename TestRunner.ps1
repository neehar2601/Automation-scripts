# ----------------------------------------------------------------------------------
# Kings River Benchmark Test Runner - Base Class with Defaults
# All test logic and default parameters in one place
# Monitoring modules are loaded from Monitors/ directory
# ----------------------------------------------------------------------------------

# Load monitoring modules
. "$PSScriptRoot\Monitors\SoCWatch.ps1"
. "$PSScriptRoot\Monitors\PowerMeter.ps1"
. "$PSScriptRoot\Monitors\TypePerf.ps1"
. "$PSScriptRoot\Monitors\PresentMon.ps1"
. "$PSScriptRoot\Monitors\WLC.ps1"
. "$PSScriptRoot\Monitors\EMON.ps1"

class BenchmarkTest {
    # Basic test properties
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

    # Monitoring tool enables
    [bool]$EnableSoCWatch = $false
    [bool]$EnablePowerMeter = $false
    [bool]$EnableTypePerfTP = $false
    [bool]$EnableTypePerfSC = $false
    [bool]$EnablePresentMon = $false
    [bool]$EnableWLC = $false
    [bool]$EnableEMON_P_Core = $false
    [bool]$EnableEMON_E_Core = $false
    [bool]$EnableEMON_P_Core_Cache = $false
    [bool]$EnableEMON_E_Core_Cache = $false
    [bool]$EnableEMON_EDP = $false
    [bool]$EnablePerfMon_PS = $false
    [bool]$EnablePerfMon_UArch = $false
    [bool]$EnablePerfMon_NPU = $false
    [bool]$EnablePowerGadget = $false
    [bool]$EnableThermal = $false
    [bool]$EnableOSPerf = $false
    [bool]$JWorkloadOnly = $false
    
    # Monitoring timing parameters
    [int]$SoCWatchWaitTime = 0
    [int]$SoCWatchRunTime = 0
    [int]$PowerMeterWaitTime = 0
    [int]$PowerMeterRunTime = 0
    [int]$TypePerfWaitTime = 0
    [int]$EMONWaitTime = 0
    [int]$EMONRunTime = 0
    
    # SoCWatch flags
    [string]$SoCWatchFlags = "-f sys -f memss-pstate -f cpu -f gfx -f npu -f power -f temp -f display -f io"
    
    # Tool paths
    # [string]$PowerSliderPath = "C:\KSR_Package\KSR\Test_Run_KR\PowerSlider.exe"
    # [string]$SoCWatchHelperPath = "C:\KSR_Package\KSR\Test_Run_KR\tools\socwatch\64\SoCWatchHelper.exe"

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

        # Determine which monitoring to use and call appropriate module
        # Priority order: SoCWatch > PowerMeter > TypePerf > EMON > PresentMon > WLC > Normal
        if ($this.EnableSoCWatch) {
            Invoke-SoCWatchMonitoring -TestInstance $this
        }
        elseif ($this.EnablePowerMeter) {
            Invoke-PowerMeterMonitoring -TestInstance $this
        }
        elseif ($this.EnableTypePerfTP -or $this.EnableTypePerfSC) {
            Invoke-TypePerfMonitoring -TestInstance $this
        }
        elseif ($this.EnableEMON_P_Core -or $this.EnableEMON_E_Core -or $this.EnableEMON_P_Core_Cache -or $this.EnableEMON_E_Core_Cache -or $this.EnableEMON_EDP) {
            Invoke-EMONMonitoring -TestInstance $this
        }
        elseif ($this.EnablePresentMon) {
            Invoke-PresentMonMonitoring -TestInstance $this
        }
        elseif ($this.EnableWLC) {
            Invoke-WLCMonitoring -TestInstance $this
        }
        else {
            $this.RunNormal()
        }
    }

    # Normal execution (no monitoring)
    [void] RunNormal() {
        Write-Host "  [INFO] Running test without monitoring" -ForegroundColor Cyan
        
        for ($i = 1; $i -le $this.Repeats; $i++) {
            if ($this.Repeats -gt 1) {
                Write-Host "`n  --- Iteration $i of $($this.Repeats) ---" -ForegroundColor Cyan
            }
            
            if ($this.WaitTime -gt 0 -and $i -eq 1) {
                Write-Host "  Waiting $($this.WaitTime) seconds..." -ForegroundColor Gray
                Start-Sleep -Seconds $this.WaitTime
            }
            
            Write-Host "  Executing: " -NoNewline -ForegroundColor White
            try {
                # Check if TestCMD is a ScriptBlock or string
                if ($this.TestCMD -is [scriptblock]) {
                    Write-Host "<ScriptBlock>" -ForegroundColor Gray
                    & $this.TestCMD
                }
                else {
                    Write-Host "$($this.TestCMD)" -ForegroundColor Gray
                    Invoke-Expression $this.TestCMD
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
