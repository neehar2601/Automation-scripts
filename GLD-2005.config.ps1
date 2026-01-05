# ----------------------------------------------------------------------------------
# Test Config: GLD-2005
# Test Name: Procyon AI Computer Vision (NPU) INT8
# Only override values that differ from defaults
# ----------------------------------------------------------------------------------

@{
    # Required parameters (no defaults in base class)
    TestID = "GLD2005"
    TestName = "Procyon AI Computer Vision (NPU) INT8"
    TestSubDomain = "NPU"
    TestCMD = "ProcyonCmd.exe -d `"C:\KSR_Package\KSR\Test_Run_KR\GLD\Script\ai_computer_vision_openvino_GLD2005.def`" --select-openvino-device NPU --export=C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\GLD2005\GLD2005_KingsScore_ClientAI_NPU_Int8_Procyon_AIInception.xml"
    
    # Optional overrides (uncomment to override defaults)
    Temperature = 50        # Override default 83
    # WaitTime = 10          # Default is 10
    # Repeats = 1            # Default is 1
    # TestDomain = "Golden"  # Default is "Golden"
}
