# ----------------------------------------------------------------------------------
# Test Config: GLD-1003
# Test Name: ADK Browsing
# Power test - Edge browser automation with ADK browsing profile
# ----------------------------------------------------------------------------------

@{
    # Test Identification
    TestID = "GLD-1003"
    TestName = "ADK Browsing"
    TestDomain = "Golden"
    TestSubDomain = "CPU"
    TestType = "Power"
    
    # Test Parameters (from GLD-1003.bat)
    Temperature = 40          # 40°C for power test
    RecordTime = 1020         # 17 minutes recording
    WaitTime = 0              # No wait before test
    Repeats = 1
    
    # Result Path
    ResultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1003"
    
    # PreStep: Change directory to Edge Browsing assessment folder
    TestPrestepCMD = 'Set-Location "C:\data\EdgeBrowsingPowerV2.0.6\Assessment2\amd64"'
    
    # TestCMD: Run Edge automation with ADK browsing profile
    TestCMD = 'EdgeAutomationClient.exe /AxeBinPath C:\Data\EdgeBrowsingPowerV2.0.6\Assessment1\amd64 /BrowsingProfile scenario.browsing_abl.json /Debug /Mode trained'
    
    # PostStep: Return to test directory (optional)
    TestPoststepCMD = 'Set-Location "C:\KSR_Package\KSR\Test_Run_KR"'
}
