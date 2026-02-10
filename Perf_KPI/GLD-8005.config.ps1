# ----------------------------------------------------------------------------------
# Test Config: GLD-8005
# Test Name: AIDA64 Memory Copy GB/s
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters (no defaults in base class)
    TestID = "GLD8005"
    TestName = "AIDA64 Memory Copy GB/s"
    TestSubDomain = "Memory"
    TestCMD = {
        Start-Process -FilePath "C:\KSR_Package\tools\installers\AIDA64\aida64.exe" `
            -ArgumentList '/SELBENCH', 'MC', "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD8005\GLD8005_KingsScore_Benchmark_MemoryCopy_raw.xml" `
            -NoNewWindow -Wait
    }
    
    # Optional overrides (uncomment to override defaults)
    Temperature = 60        # Override default 83
    WaitTime = 30           # Override default 10
    # Repeats = 1           # Default is 1
    # TestDomain = "Golden" # Default is "Golden"
}
