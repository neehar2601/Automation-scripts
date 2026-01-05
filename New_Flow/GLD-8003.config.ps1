# ----------------------------------------------------------------------------------
# Test Config: GLD-8003
# Test Name: AIDA64 Memory Read GB/s
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters (no defaults in base class)
    TestID = "GLD8003"
    TestName = "AIDA64 Memory Read GB/s"
    TestSubDomain = "Memory"
    TestCMD = {
        Start-Process -FilePath "C:\KSR_Package\tools\installers\AIDA64\aida64.exe" `
            -ArgumentList '/SELBENCH', 'MR', "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD8003\GLD8003_KingsScore_Benchmark_MemoryRead_raw.xml" `
            -NoNewWindow -Wait
    }
    
    # Optional overrides (uncomment to override defaults)
    Temperature = 60        # Override default 83
    WaitTime = 30           # Override default 10
    # Repeats = 1           # Default is 1
    # TestDomain = "Golden" # Default is "Golden"
}
