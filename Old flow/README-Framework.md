# GLD Test Framework - OOP Config-Driven Architecture

## 🏗️ Architecture Overview

This framework uses **Object-Oriented Programming** with **config-driven defaults** for maximum maintainability and flexibility.

### File Structure

```
GLD/
├── TestRunner.ps1           # Base class with all methods and default values
├── GLD-1015.config.ps1      # Config: Only overrides for GLD-1015
├── GLD-1015-New.ps1         # Wrapper: Loads runner + config, executes test
├── GLD-1014.config.ps1      # Config: Only overrides for GLD-1014
└── GLD-1014-New.ps1         # Wrapper: Loads runner + config, executes test
```

---

## 📋 How It Works

### 1️⃣ TestRunner.ps1 (Base Class)
- Defines `BenchmarkTest` class with **all methods** and **default values**
- Constructor accepts config hashtable and overrides defaults
- Contains: `TestPrestep()`, `Test()`, `TestPoststep()`, `Run()`

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

### 2️⃣ Config Files (GLD-XXXX.config.ps1)
- **Only** define values that differ from defaults
- Returns a hashtable
- Minimal ~10-15 lines per test

**Example:**
```powershell
@{
    TestID = "GLD1015"
    TestName = "3DMark Wildlife extreme unlimited"
    TestSubDomain = "GFX-DX12"
    TestCMD = "3DMarkCmd.exe ..."
    # Temperature = 85  # Uncomment to override default (83)
}
```

### 3️⃣ Wrapper Scripts (GLD-XXXX-New.ps1)
- Loads TestRunner.ps1
- Loads config file
- Creates test instance
- Executes test
- **Only ~20 lines each**

---

## ✅ Benefits

| Feature | Benefit |
|---------|---------|
| **Single Source of Truth** | All logic in `TestRunner.ps1` |
| **Default Values** | Define once, inherit everywhere |
| **Override Only What's Needed** | Configs are minimal and clean |
| **Easy Maintenance** | Fix bugs once, all tests benefit |
| **Consistent Behavior** | Every test uses same methods |
| **Simple to Add Tests** | Copy config, change 4-5 values, done! |

---

## 🎯 Usage

### Run a test:
```powershell
.\GLD-1015-New.ps1
```

### Override defaults at runtime:
```powershell
# In config file, uncomment and change:
# Temperature = 90
# Repeats = 3
```

### Display config before running:
```powershell
# In wrapper script, uncomment:
# $test.DisplayConfig()
```

---

## 🆕 Adding a New Test

### Step 1: Create config file (GLD-XXXX.config.ps1)
```powershell
@{
    TestID = "GLD2001"
    TestName = "AI Computer Vision"
    TestSubDomain = "AI-CV"
    TestCMD = "python benchmark.py ..."
}
```

### Step 2: Create wrapper (GLD-XXXX.ps1)
```powershell
. "$PSScriptRoot\TestRunner.ps1"
$config = . "$PSScriptRoot\GLD-XXXX.config.ps1"
$test = [BenchmarkTest]::new($config)
$result = $test.Run()
exit ($result.Status -eq "Success" ? 0 : 1)
```

**That's it! No method duplication, inherits all default behavior.**

---

## 📊 Comparison

### Old Approach (Methods in Each File)
```
GLD-1015.ps1    → 500 lines (class + methods)
GLD-1014.ps1    → 500 lines (class + methods)
GLD-2001.ps1    → 500 lines (class + methods)
Total: 1500 lines
Bug fix: Edit 3 files
```

### New Approach (Config-Driven + OOP)
```
TestRunner.ps1      → 170 lines (base class, once)
GLD-1015.config.ps1 → 10 lines (data only)
GLD-1015-New.ps1    → 20 lines (wrapper)
GLD-1014.config.ps1 → 10 lines (data only)
GLD-1014-New.ps1    → 20 lines (wrapper)
Total: 230 lines
Bug fix: Edit 1 file (TestRunner.ps1)
```

**87% less code, infinitely easier to maintain!**

---

## 🔧 Advanced Features

### Custom Prestep Commands
```powershell
@{
    TestID = "GLD1015"
    TestPrestep = "Write-Host 'Custom setup'; Start-Service MyService"
    # ...
}
```

### Override Score Rename Path
```powershell
@{
    TestID = "GLD1015"
    ScoreRenameBat = "C:\Custom\Path\Score_Rename.bat"
    # ...
}
```

### Custom Result Path
```powershell
@{
    TestID = "GLD1015"
    ResultPath = "D:\CustomResults\GLD1015"
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

1. Test the new architecture with GLD-1015-New.ps1
2. Convert remaining tests to config files
3. Add orchestrator to run multiple tests
4. Add advanced features (logging, error handling, etc.)

---

**Questions? The framework is self-documenting - read TestRunner.ps1 for implementation details!**
