# ----------------------------------------------------------------------------------
# Test Config: GLD-1001
# Test Name: Busy Idle Consumer
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters
    TestType = "Power"
    TestID = "GLD1001"
    TestName = "Busy Idle Consumer"
    TestSubDomain = "CPU"
    
    # Override defaults
    Temperature = 25          # Default is 83
    RecordTime = 180          # Default is 0
    WaitTime = 900            # Default is 10
    
    # Commands
    TestPrestepCMD = "& 'C:\KSR_Package\KSR\Test_Run_KR\GLD\script\GLD1001_pre.exe'"
    TestCMD = "& 'C:\KSR_Package\KSR\Test_Run_KR\GLD\script\GLD1001_CMD.bat'"
    TestPoststepCMD = "& 'C:\KSR_Package\KSR\Test_Run_KR\postkill.bat'"
    
    # Result path (auto-generated if not specified)
    ResultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1001"
}