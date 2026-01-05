# ----------------------------------------------------------------------------------
# Test Config: GLD-1010
# Test Name: Benchmark - GeekBench_CPU single benchmark
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters
    TestType = "Perf"
    TestID = "GLD1010"
    TestName = "Benchmark - GeekBench_CPU single benchmark"
    TestSubDomain = "CPU"
    
    # Override defaults
    Temperature = 50          # Default is 83
    WaitTime = 10             # Default is 10
    
    # Commands
    TestCMD = "geekbench6.exe --single-core --no-upload --save 'C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1010\GLD1010_KingsScore_Benchmark_singlecore_score.JSON'"
    
    # Result path
    ResultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1010"
}