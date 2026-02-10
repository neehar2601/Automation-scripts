# ----------------------------------------------------------------------------------
# Test Config: GLD-2001
# Test Name: Procyon Office Productivity
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters (no defaults in base class)
    TestID = "GLD2001"
    TestName = "Procyon Office Productivity"
    TestSubDomain = "CPU"
    TestCMD = "ProcyonCmd.exe -d office_productivity.def --export=C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD2001\GLD2001_KingsScore_Benchmark_OfficeProductivityScore.xml"
    
    # Optional overrides (uncomment to override defaults)
    Temperature = 50        # Override default 83
    # WaitTime = 10          # Default is 10
    # Repeats = 1            # Default is 1
    # TestDomain = "Golden"  # Default is "Golden"
}
