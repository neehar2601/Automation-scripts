# ----------------------------------------------------------------------------------
# Test Config: GLD-1015
# Test Name: 3DMark Wildlife extreme unlimited
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters (no defaults in base class)
    TestID = "GLD1015"
    TestName = "3DMark Wildlife extreme unlimited"
    TestSubDomain = "GFX-DX12"
    TestCMD = "3DMarkCmd.exe --definition=wildlife_extreme.3dmdef --export=C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1015\GLD1015_KingsScore_Benchmark_WildLifeExtremeGraphicsScore.xml"
    
    # Optional overrides (uncomment to override defaults)
    # Temperature = 85        # Default is 83
    # WaitTime = 15          # Default is 10
    # Repeats = 3            # Default is 1
    # TestDomain = "Custom"  # Default is "Golden"
}
