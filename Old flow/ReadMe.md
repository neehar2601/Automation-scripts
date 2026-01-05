# GLD Test Framework - OOP Config-Driven Architecture

## 🏗️ Architecture Overview

This framework uses **Object-Oriented Programming** with **config-driven defaults** for maximum maintainability and flexibility.

### File Structure

```
GLD/
├── TestRunner.ps1           # Base class with all methods and default values
├── GLD-1001.ps1             # Test script: Config + wrapper combined
├── GLD-1014.ps1             # Test script: Config + wrapper combined
├── GLD-1015.ps1             # Test script: Config + wrapper combined
└── ... (more test scripts)
```

**Each test = ONE file** (config + wrapper combined)

---

## 📋 How It Works

### 1️⃣ TestRunner.ps1 (Base Class)
- Defines `BenchmarkTest` class with **all methods** and **default values**
- Constructor accepts config hashtable and overrides defaults
- Contains: `PreStep()`, `Test()`, `PostStep()`, `Run()`, `DisplayConfig()`

**Default Values:**
```powershell
TestType = "Perf"
TestDomain = "Golden"
Temperature = 83
WaitTime = 10
Repeats = 1
RecordTime = 0
# ... etc
```

### 2️⃣ Test Scripts (GLD-XXXX.ps1)
- **All-in-one file**: Config hashtable + execution logic
- Loads TestRunner.ps1
- Defines inline config hashtable
- Creates test instance
- Executes test and displays results
- **Only ~50-60 lines per test**

**Example Structure:**
```powershell
# Load test runner
. "$PSScriptRoot\TestRunner.ps1"

# Inline configuration
$config = @{
    TestID = "GLD1015"
    TestName = "3DMark Wildlife extreme unlimited"
    TestSubDomain = "GFX-DX12"
    TestCMD = "3DMarkCmd.exe ..."
    # Temperature = 85  # Uncomment to override default (83)
}

# Create and run test
$test = [BenchmarkTest]::new($config)
$result = $test.Run()

# Display results and exit
# ... result summary display code ...
exit ($result.Status -eq "Success" ? 0 : 1)
```

---

## ✅ Benefits

| Feature | Benefit |
|---------|---------|
| **Single Source of Truth** | All logic in `TestRunner.ps1` |
| **Default Values** | Define once, inherit everywhere |
| **Override Only What's Needed** | Configs are inline, minimal and clean |
| **Easy Maintenance** | Fix bugs once, all tests benefit |
| **Consistent Behavior** | Every test uses same methods |
| **Simple to Add Tests** | Copy one file, change config section, done! |
| **Self-Contained** | Each test is one complete file |
| **No File Dependencies** | Only needs TestRunner.ps1 |

---

## 🎯 Usage

### Run a test:
```powershell
.\GLD-1015.ps1
```

### Override defaults in config section:
```powershell
# Edit the $config hashtable at the top of the file:
$config = @{
    TestID = "GLD1015"
    # ...
    Temperature = 90        # Override default 83
    Repeats = 3            # Override default 1
}
```

### Display config before running:
```powershell
# In the test script, uncomment:
# $test.DisplayConfig()
```

---

## 🆕 Adding a New Test

### Copy and modify an existing test file:
```powershell
# 1. Copy existing test
Copy-Item GLD-1015.ps1 GLD-2001.ps1

# 2. Edit the config section at the top
$config = @{
    TestID = "GLD2001"
    TestName = "AI Computer Vision"
    TestSubDomain = "AI-CV"
    TestCMD = "python benchmark.py ..."
    # Add any parameter overrides
}

# 3. Done! The rest of the file stays the same
```

**That's it! No method duplication, inherits all default behavior from TestRunner.ps1**

---

## 📊 Comparison

### Old Approach (Methods in Each File)
```
GLD-1015.ps1    → 500 lines (class + methods)
GLD-1014.ps1    → 500 lines (class + methods)
GLD-2001.ps1    → 500 lines (class + methods)
Total: 1500 lines
Bug fix: Edit 3 files
Files per test: 1
```

### New Approach (Config-Driven + OOP)
```
TestRunner.ps1  → 170 lines (base class, shared by all)
GLD-1015.ps1    → 60 lines (config + wrapper)
GLD-1014.ps1    → 60 lines (config + wrapper)
GLD-2001.ps1    → 60 lines (config + wrapper)
Total: 350 lines
Bug fix: Edit 1 file (TestRunner.ps1)
Files per test: 1
```

**77% less code, infinitely easier to maintain!**

### Key Improvements:
- ✅ **Same number of files** (1 per test), but much simpler
- ✅ **All test logic in one place** (TestRunner.ps1)
- ✅ **Each test file is self-contained** (config + execution)
- ✅ **Fix once, apply everywhere** (bug fixes in TestRunner.ps1)

---

## 🔧 Advanced Features

### Custom Prestep Commands
```powershell
$config = @{
    TestID = "GLD1015"
    TestPrestepCMD = "& 'C:\Scripts\custom_setup.bat'"
    # ...
}
```

### Custom Poststep Commands
```powershell
$config = @{
    TestID = "GLD1001"
    TestPoststepCMD = "& 'C:\Scripts\cleanup.bat'"
    # ...
}
```

### Override Score Rename Path
```powershell
$config = @{
    TestID = "GLD1015"
    ScoreRenameBat = "C:\Custom\Path\Score_Rename.bat"
    # ...
}
```

### Custom Result Path
```powershell
$config = @{
    TestID = "GLD1015"
    ResultPath = "D:\CustomResults\GLD1015"
    # ...
}
```

### Multiple Test Repeats
```powershell
$config = @{
    TestID = "GLD1015"
    Repeats = 5  # Run test 5 times
    # ...
}
```

---

## 🎓 OOP Concepts Used

✅ **Encapsulation**: All methods in one class
✅ **Inheritance**: Default values inherited by all tests
✅ **Polymorphism**: Config overrides default behavior
✅ **Composition**: Wrapper composes runner + config
✅ **Single Responsibility**: Runner has logic, Config has data

---

## 🚀 Next Steps

1. Test the new architecture with GLD-1015.ps1
2. Convert remaining tests by copying and modifying config section
3. Add orchestrator to run multiple tests
4. Add advanced features (logging, temperature monitoring, etc.)

---

## 📝 Complete Example: GLD-1015.ps1

```powershell
# ----------------------------------------------------------------------------------
# Kings River Benchmark Test Script
# Test Name: 3DMark Wildlife extreme unlimited
# ----------------------------------------------------------------------------------

# Load the test runner (base class with all methods)
. "$PSScriptRoot\TestRunner.ps1"

# Test Configuration (inline)
$config = @{
    TestID = "GLD1015"
    TestName = "3DMark Wildlife extreme unlimited"
    TestSubDomain = "GFX-DX12"
    TestCMD = "3DMarkCmd.exe --definition=wildlife_extreme.3dmdef ..."
    
    # Optional overrides (uncomment to override defaults)
    # Temperature = 90
    # Repeats = 3
}

# Create test instance with config
$test = [BenchmarkTest]::new($config)

# Run the test
$result = $test.Run()

# Display results summary
Write-Host "`n========== Test Summary ==========" -ForegroundColor Cyan
Write-Host "Test ID    : $($result.TestID)" -ForegroundColor White
Write-Host "Status     : $($result.Status)" -ForegroundColor Green
Write-Host "Duration   : $([math]::Round($result.Duration, 2))s" -ForegroundColor White
Write-Host "==================================`n" -ForegroundColor Cyan

# Exit with appropriate code
exit ($result.Status -eq "Success" ? 0 : 1)
```

---

**Questions? The framework is self-documenting - read TestRunner.ps1 for implementation details!**
