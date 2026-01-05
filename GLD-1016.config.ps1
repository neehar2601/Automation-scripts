# ----------------------------------------------------------------------------------
# Test Config: GLD-1016
# Test Name: CineBench R24 Single Core
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters (no defaults in base class)
    TestID = "GLD1016"
    TestName = "CineBench R24 Single Core"
    TestSubDomain = "CPU"
    TestCMD = {
        Start-Process -FilePath "C:\KSR_Package\tools\installers\CinebenchR24\Cinebench.exe" `
            -ArgumentList 'g_CinebenchCpu1Test=true' `
            -RedirectStandardOutput "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1016\GLD1016_KingsScore_Benchmark_CinebenchR24_singlecopy.txt" `
            -RedirectStandardError "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1016\GLD1016_KingsScore_Benchmark_CinebenchR24_singlecopy_Error.txt" `
            -NoNewWindow -Wait
    }
    
    # Optional overrides (uncomment to override defaults)
    Temperature = 60        # Override default 83
    WaitTime = 30           # Override default 10
    # Repeats = 1           # Default is 1
    # TestDomain = "Golden" # Default is "Golden"
}
