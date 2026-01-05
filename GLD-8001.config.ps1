# ----------------------------------------------------------------------------------
# Test Config: GLD-8001
# Test Name: Babel Stream Memory Benchmark
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters (no defaults in base class)
    TestID = "GLD8001"
    TestName = "Babel Stream Memory Benchmark"
    TestSubDomain = "Memory"
    TestCMD = {
        Start-Process -FilePath "C:\KSR_Package\tools\installers\Stream\BabelStreamWW37.exe" `
            -ArgumentList '--float' `
            -RedirectStandardOutput "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD8001\GLD8001_KingsScore_Benchmark_BabelStream_raw.txt" `
            -RedirectStandardError "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD8001\GLD8001_KingsScore_Benchmark_BabelStream_Error.txt" `
            -NoNewWindow -Wait
    }
    
    # Optional overrides (uncomment to override defaults)
    Temperature = 60        # Override default 83
    WaitTime = 30           # Override default 10
    # Repeats = 1           # Default is 1
    # TestDomain = "Golden" # Default is "Golden"
}
