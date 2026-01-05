# ----------------------------------------------------------------------------------
# Test Config: GLD-2003
# Test Name: Procyon AI Computer Vision (CPU) Float16
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters (no defaults in base class)
    TestID = "GLD2003"
    TestName = "Procyon AI Computer Vision (CPU) Float16"
    TestSubDomain = "CPU"
    TestCMD = "ProcyonCmd.exe -d `"C:\KSR_Package\KSR\Test_Run_KR\GLD\Script\ai_computer_vision_openvino_GLD2003.def`" --select-openvino-device CPU --export=C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD2003\GLD2003_KingsScore_ClientAI_CPU_FP16_Procyon_AIInception.xml"
    
    # Optional overrides (uncomment to override defaults)
    Temperature = 50        # Override default 83
    # WaitTime = 10          # Default is 10
    # Repeats = 1            # Default is 1
    # TestDomain = "Golden"  # Default is "Golden"
}
