# ----------------------------------------------------------------------------------
# Test Config: GLD-1009
# Test Name: Benchmark - GeekBench_CPU multi benchmark
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters
    TestType = "Perf"
    TestID = "GLD1009"
    TestName = "Benchmark - GeekBench_CPU multi benchmark"
    TestSubDomain = "CPU"
    
    # Override defaults
    Temperature = 50          # Default is 83
    WaitTime = 10             # Default is 10
    
    # Commands
    TestCMD = "geekbench6.exe --multi-core --no-upload --save C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1009\GLD1009_KingsScore_Benchmark_multicore_score.JSON"
    
    # Result path
    ResultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1009"
}