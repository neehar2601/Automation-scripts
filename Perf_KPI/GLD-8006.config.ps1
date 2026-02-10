# ----------------------------------------------------------------------------------
# Test Config: GLD-8006
# Test Name: AIDA64 Memory Latency ns
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters (no defaults in base class)
    TestID = "GLD8006"
    TestName = "AIDA64 Memory Latency ns"
    TestSubDomain = "Memory"
    TestCMD = {
        Start-Process -FilePath "C:\KSR_Package\tools\installers\AIDA64\aida64.exe" `
            -ArgumentList '/SELBENCH', 'ML', "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD8006\GLD8006_KingsScore_Benchmark_MemoryLatency_raw.xml" `
            -NoNewWindow -Wait
    }
    
    # Optional overrides (uncomment to override defaults)
    Temperature = 60        # Override default 83
    WaitTime = 30           # Override default 10
    # Repeats = 1           # Default is 1
    # TestDomain = "Golden" # Default is "Golden"
}
