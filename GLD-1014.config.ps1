# ----------------------------------------------------------------------------------
# Test Config: GLD-1014
# Test Name: 3DMark TimeSpy
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters
    TestID = "GLD1014"
    TestName = "3DMark TimeSpy"
    TestSubDomain = "GFX-DX12"
    TestCMD = "3DMarkCmd.exe --definition=timespy.3dmdef --export=C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1014\GLD1014_KingsScore_Benchmark_TimeSpyPerformanceGraphicsScore.xml"
    
    # Optional overrides
    # Temperature = 85
    # WaitTime = 15
    # Repeats = 2
}
