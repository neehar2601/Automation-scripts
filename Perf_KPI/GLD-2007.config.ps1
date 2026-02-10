# ----------------------------------------------------------------------------------
# Test Config: GLD-2007
# Test Name: Procyon AI Computer Vision (NPU) Float16
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters (no defaults in base class)
    TestID = "GLD2007"
    TestName = "Procyon AI Computer Vision (NPU) Float16"
    TestSubDomain = "NPU"
    TestCMD = "ProcyonCmd.exe -d `"C:\KSR_Package\KSR\Test_Run_KR\GLD\Script\ai_computer_vision_openvino_GLD2007.def`" --select-openvino-device NPU --export=C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD2007\GLD2007_KingsScore_ClientAI_NPU_FP16_Procyon_AIInception.xml"
    
    # Optional overrides (uncomment to override defaults)
    Temperature = 50        # Override default 83
    # WaitTime = 10          # Default is 10
    # Repeats = 1            # Default is 1
    # TestDomain = "Golden"  # Default is "Golden"
}
