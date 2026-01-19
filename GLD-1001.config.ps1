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
    RecordTime = 180          # 3 minutes recording
    WaitTime = 900            # 15 minutes wait before test
    Repeats = 1
    
    # Result Path
    ResultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1001"
    
    # PreStep: Check internet connectivity (GLD1001_pre.exe)
    TestPrestepCMD = 'Start-Process -FilePath "C:\KSR_Package\KSR\Test_Run_KR\GLD\script\GLD1001_pre.exe" -NoNewWindow -Wait'
    
    # TestCMD: Wait for 15 minutes (900 seconds) in idle state
    # Equivalent to: waitfor BusyIDLE /t 900
    TestCMD = 'Start-Sleep -Seconds 900'
    
    # PostStep: Kill remaining processes (postkill.bat)
    TestPoststepCMD = 'Start-Process -FilePath "C:\KSR_Package\KSR\Test_Run_KR\postkill.bat" -NoNewWindow -Wait'
}
