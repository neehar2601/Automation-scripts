# ----------------------------------------------------------------------------------
# Test Config: GLD-8002
# Test Name: Stream Triad Memory Benchmark
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters (no defaults in base class)
    TestID = "GLD8002"
    TestName = "Stream Triad Memory Benchmark"
    TestSubDomain = "Memory"
    TestCMD = {
        Start-Process -FilePath "C:\KSR_Package\tools\installers\Stream\BabelStreamWW37.exe" `
            -ArgumentList '-n', '1000', '--triad-only' `
            -RedirectStandardOutput "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD8002\GLD8002_KingsScore_Benchmark_Stream_CML_raw.txt" `
            -RedirectStandardError "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD8002\GLD8002_KingsScore_Benchmark_Stream_CML_Error.txt" `
            -NoNewWindow -Wait
    }
    
    # Optional overrides (uncomment to override defaults)
    Temperature = 60        # Override default 83
    WaitTime = 30           # Override default 10
    # Repeats = 1           # Default is 1
    # TestDomain = "Golden" # Default is "Golden"
}
