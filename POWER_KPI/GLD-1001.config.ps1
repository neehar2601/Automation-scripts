# ----------------------------------------------------------------------------------
# Test Config: GLD-1001
# Test Name: Busy Idle Consumer
# Power KPI test - measures idle power consumption with multiple monitoring cycles
# ----------------------------------------------------------------------------------

return @{
    TestID = 'GLD-1001'
    TestName = 'Busy Idle Consumer'
    TestDomain = 'Golden'
    TestSubDomain = 'Power_KPI'
    
    # Timing Configuration
    WaitTime = 20               # Initial wait AFTER PreStep (system stabilization)
    InterCycleWait = 10         # Wait BETWEEN monitoring cycles
    Repeats = 1                 # Number of monitoring cycles (3 cycles = 3 separate measurements)
    
    # Test Command (idle workload - 60 seconds)
    TestCMD = 'Start-Sleep -Seconds 60'
    
    # PreStep: Launch applications
#     TestPrestepCMD = @'
# & "C:\KSR_Package\KSR\Test_Run_KR\Scripts\active_power_kpi\GLD\Script\GLD1001_Apps.ps1"
# & "C:\KSR_Package\KSR\Test_Run_KR\Scripts\active_power_kpi\GLD\Script\GLD1001_Chrome.ps1"
# '@

    TestPrestepCMD = "Write-Host 'Launching PreStep Applications...'"
    
    # PostStep: Kill applications
    TestPoststepCMD = @'
Get-Process -Name "chrome", "Teams", "Outlook", "Excel" -ErrorAction SilentlyContinue | Stop-Process -Force
'@
    
    # Monitoring Configuration
    EnableSoCWatch = $true
    
    # Result Path
    ResultPath = 'C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD-1001'
}