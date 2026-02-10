# ----------------------------------------------------------------------------------
# Test Configuration
# Central configuration file for test classification
# ----------------------------------------------------------------------------------

# Define Power KPI test IDs
# All tests listed here will look for configs in POWER_KPI folder
# All other test IDs will look in PERF_KPI folder
$PowerKPITests = @(
    'GLD-1001',  # Busy Idle Consumer
    'GLD-1002',  # Power Test 2
    'GLD-1003',  # Power Test 3
    'GLD-1004',  # Power Test 4
    'GLD-1005',  # Power Test 5
    'GLD-1006',  # Power Test 6
    'GLD-1007',  # Power Test 7
    'GLD-6002',  # Power Test 6002
    
    # Support both formats (with and without hyphen)
    'GLD1001',
    'GLD1002',
    'GLD1003',
    'GLD1004',
    'GLD1005',
    'GLD1006',
    'GLD1007',
    'GLD6002'
)

# Return the list
return $PowerKPITests
