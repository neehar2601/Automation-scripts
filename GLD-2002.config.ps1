# ----------------------------------------------------------------------------------
# Test Config: GLD-2002
# Test Name: Procyon AI Computer Vision (CPU) INT8
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters (no defaults in base class)
    TestID = "GLD2002"
    TestName = "Procyon AI Computer Vision (CPU) INT8"
    TestSubDomain = "CPU"
    TestCMD = "ProcyonCmd.exe -d `"C:\KSR_Package\KSR\Test_Run_KR\GLD\Script\ai_computer_vision_openvino_GLD2002.def`" --select-openvino-device CPU --export=C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD2002\GLD2002_KingsScore_ClientAI_CPU_Int8_Procyon_AIInception.xml"
    
    # Optional overrides (uncomment to override defaults)
    Temperature = 50        # Override default 83
    # WaitTime = 10          # Default is 10
    # Repeats = 1            # Default is 1
    # TestDomain = "Golden"  # Default is "Golden"
}
