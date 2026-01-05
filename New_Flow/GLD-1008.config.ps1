# ----------------------------------------------------------------------------------
# GLD-1008 Wrapper Script
# Test Name: Benchmark - CineBenchR24 Multi
# Loads TestRunner and config, executes the test
# ----------------------------------------------------------------------------------


@{
    # Required parameters
    TestType = "Perf"
    TestID = "GLD1008"
    TestName = "Benchmark - CineBenchR24 Multi"
    TestSubDomain = "CPU"
    
    # Override defaults
    Temperature = 50          # Default is 83
    WaitTime = 30             # Default is 10
    
    # Commands
    TestCMD = {
        Start-Process -FilePath "C:\KSR_Package\tools\installers\CinebenchR24\Cinebench.exe" `
            -ArgumentList 'g_CinebenchCpuXTest=true' `
            -RedirectStandardOutput "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1008\$($config.TestID)_KingsScore_Benchmark_CinebenchR24_Multicopy.txt" `
            -RedirectStandardError "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1008\$($config.TestID)_KingsScore_Benchmark_CinebenchR24_Multicopy_Error.txt" `
            -NoNewWindow -Wait
    }
    
    # Result path (auto-generated based on TestID)
    ResultPath = "C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD1008"
}