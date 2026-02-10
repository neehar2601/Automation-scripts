# ----------------------------------------------------------------------------------
# Test Config: GLD-1001
# Test Name: Busy Idle Consumer
# Power KPI test - measures idle power consumption
# ----------------------------------------------------------------------------------

@{
    # Test Identification
    TestID = "GLD-1001"
    TestName = "Busy Idle Consumer"
    TestDomain = "Golden"
    TestSubDomain = "CPU"
    TestType = "Power"
    
    # Test Parameters (from GLD-1001.bat)
    Temperature = 25          # Lower temp for power tests
    RecordTime = 20          # 20 seconds recording
    WaitTime = 20            # 20 seconds wait before test
    Repeats = 1
    
    # Result Path
    ResultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1001"
    
    # PreStep: Run Apps and Chrome setup scripts
    TestPrestepCMD = @'
& "C:\KSR_Package\KSR\Test_Run_KR\Scripts\active_power_kpi\GLD\Script\GLD1001_Apps.ps1"
& "C:\KSR_Package\KSR\Test_Run_KR\Scripts\active_power_kpi\GLD\Script\GLD1001_Chrome.ps1"
'@

    # TestCMD: Wait for 15 minutes (900 seconds) in idle state
    # Equivalent to: waitfor BusyIDLE /t 900
    TestCMD = 'Start-Sleep -Seconds 900'
    
    # PostStep: Kill remaining processes (postkill.bat)
    TestPoststepCMD = 'Write-Host "Killing remaining processes..." -NoNewWindow -Wait'
}