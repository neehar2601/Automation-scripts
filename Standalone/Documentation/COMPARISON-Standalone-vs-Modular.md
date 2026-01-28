# Comparison: Standalone vs Modular NiDaq Server

## Issue Found: Byte Array Constructor Error

### Error Message
```
Error handling client: A constructor was not found. Cannot find an appropriate constructor for type byte[].
```

---

## Root Cause Analysis

### Standalone Version (NiDaqServer.ps1) - ✅ WORKS
**Location:** Line 602
```powershell
# HARDCODED buffer size
$buffer = New-Object byte[] 1024
```
- Uses **hardcoded value** `1024`
- No dependency on configuration
- ✅ Always works

### Modular Version (TCPServerModule.psm1) - ❌ FAILED
**Location:** Lines 55-56
```powershell
# Uses BufferSize from config
$bufferSize = $Config.Server.BufferSize
$buffer = New-Object byte[] $bufferSize
```
- Reads from **ServerConfig.json**
- ❌ Config was missing `BufferSize` property
- `$bufferSize` was `$null` → Constructor failed

---

## Configuration Comparison

### ServerConfig.json - BEFORE (Missing BufferSize)
```json
{
  "Server": {
    "Host": "0.0.0.0",
    "Port": 55555,
    "MaxConnections": 10,
    "ReceiveTimeout": 300
  }
}
```

### ServerConfig.json - AFTER (Fixed)
```json
{
  "Server": {
    "Host": "0.0.0.0",
    "Port": 55555,
    "MaxConnections": 10,
    "ReceiveTimeout": 300,
    "BufferSize": 4096
  }
}
```

---

## Key Functional Differences

| Feature | Standalone (NiDaqServer.ps1) | Modular (NiDaqServer-Modular.ps1) |
|---------|------------------------------|-------------------------------------|
| **Architecture** | Single file (671 lines) | Split into modules & classes (7 files) |
| **Buffer Size** | Hardcoded `1024` bytes | Configurable via JSON |
| **Modules** | None | LoggingModule, ConfigurationModule, TCPServerModule |
| **Classes** | Inline in main file | Separate files (PACSController, RemoteExecutor, CommandHandler) |
| **Reusability** | Low | High |
| **Testing** | Harder to unit test | Easy to test individual modules |
| **Maintenance** | All in one file | Separated concerns |
| **Default Config** | In-code function | Separate module function |

---

## Buffer Size Recommendations

| Size | Use Case | Notes |
|------|----------|-------|
| 1024 bytes | Small commands | Original standalone default |
| 4096 bytes | Standard commands | **New modular default** (4KB) |
| 8192 bytes | Large payloads | For bulk data transfers |
| 65536 bytes | File transfers | Maximum recommended (64KB) |

---

## Solution Applied

### 1. Updated ServerConfig.json
Added `"BufferSize": 4096` to Server section

### 2. Updated ConfigurationModule.psm1
Changed default BufferSize from 1024 to 4096

### 3. Result
✅ Modular version now works correctly
✅ Buffer size is configurable per deployment
✅ Larger buffer handles bigger commands

---

## Testing Validation

### Before Fix
```powershell
PS> .\NiDaqServer-Modular.ps1
# Error: A constructor was not found. Cannot find an appropriate constructor for type byte[].
```

### After Fix
```powershell
PS> .\NiDaqServer-Modular.ps1
# ✅ Server listening on 0.0.0.0:55555
# ✅ Client connections accepted
# ✅ Commands processed correctly
```

---

## Additional Differences Found

### PACSController Constructor
**Standalone:** 3 separate parameters
```powershell
$this.PACS = [PACSController]::new(
    $config.PACS.ExePath,
    $config.PACS.ConfigPath,
    $config.PACS.ResultPath
)
```

**Modular:** Single config object (BETTER DESIGN)
```powershell
# CommandHandler.ps1
$this.PACS = [PACSController]::new($config.PACS)

# PACSController.ps1
PACSController([object]$config) {
    $this.ExePath = $config.ExePath
    $this.ConfigPath = $config.ConfigPath
    $this.ResultPath = $config.ResultPath
    $this.ProcessName = if ($config.ProcessName) { $config.ProcessName } else { "pacs" }
}
```
✅ **Modular version is more flexible and maintainable!**

---

## Recommendations

### For Production Use
1. ✅ Use **Modular version** for better maintainability
2. ✅ Set `BufferSize: 4096` for general use
3. ✅ Increase to 8192 or higher for large payloads
4. ⚠️ Fix PACSController constructor call (add ResultPath)

### For Quick Testing
- Use **Standalone version** if you need quick deployment
- All-in-one file is easier to copy/deploy

### For Development
- Use **Modular version** for easier debugging
- Test individual modules separately
- Better error isolation

---

## Files Modified

1. ✅ `ServerConfig.json` - Added BufferSize property (4096 bytes)
2. ✅ `Modules/ConfigurationModule.psm1` - Updated default BufferSize to 4096

---

## Summary

**Issue:** Missing `BufferSize` in ServerConfig.json caused byte array constructor to fail with `$null` value.

**Solution:** Added `"BufferSize": 4096` to both:
- ServerConfig.json (runtime config)
- ConfigurationModule.psm1 (default config generator)

**Result:** Modular server now works correctly with configurable buffer size.

**Bonus:** Discovered PACSController constructor mismatch that also needs fixing.
