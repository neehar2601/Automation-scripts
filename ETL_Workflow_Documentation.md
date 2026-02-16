# ETL Workflow Documentation

## Overview

This document describes the complete ETL (Event Trace Log) processing and push workflow for Kings River test results. The workflow consists of two main components:

1. **ETL Parser** (`ETL_parser.bat`) - Extracts and processes ETL trace logs from test results
2. **ETL Push** (`Push_ETL.bat`) - Uploads ETL logs to the network share via API

---

## Table of Contents

- [Workflow Overview](#workflow-overview)
- [Component 1: ETL Parser](#component-1-etl-parser)
- [Component 2: ETL Push](#component-2-etl-push)
- [Complete Workflow Example](#complete-workflow-example)
- [Troubleshooting](#troubleshooting)
- [Configuration Reference](#configuration-reference)

---

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    ETL Processing Workflow                       │
└─────────────────────────────────────────────────────────────────┘

1. Test Execution → Golden_Results folder
                    └─ GLD1001/
                       GLD1002/
                       └─ *_Tracelog.etl files

2. ETL Parser (ETL_parser.bat)
   ├─ Searches for *_Tracelog.etl files
   ├─ Processes with wpaexporter using profile
   ├─ Generates CSV files
   └─ Organizes in Results\ETL folder
      └─ GLD1001/
         ├─ CSV files
         └─ *_Tracelog.etl (moved)

3. Test Results → KingsResults.zip uploaded to KSR

4. ETL Push (Push_ETL.bat)
   ├─ Receives KingsResults.zip path as parameter
   ├─ Calls ETL API to get network path
   ├─ Mounts network share (if needed)
   └─ Copies ETL folder to network location
      └─ \\gar.corp.intel.com\...\[Platform]\[Config]\AC-Balanced\
         └─ ETL logs and CSV files
```

---

## Component 1: ETL Parser

### Purpose

The ETL Parser (`ETL_parser.bat`) searches for ETL trace log files from test results, processes them using Windows Performance Analyzer (WPA) exporter, and organizes the output CSV files.

### File Location

```
C:\KSR_Package\KSR\Test_Run_KR\ETL_parser.bat
```

### Prerequisites

1. **Windows Performance Analyzer (WPA)** installed
   - `wpaexporter.exe` must be in system PATH
   - Part of Windows Performance Toolkit

2. **WPA Profile File** (`.wpaProfile`)
   - Must exist in one of these locations:
     - `C:\KSR_Package\KSR\Test_Run_KR\*.wpaProfile` (searched first)
     - `%SystemDrive%\*.wpaProfile` (fallback search)

3. **Test Results**
   - Located in: `C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results`
   - Must contain `*_Tracelog.etl` files in test case subfolders

### Configuration

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `SEARCH_FOLDER` | `C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results` | Where to search for ETL files |
| `ETL_OUTPUT_FOLDER` | `C:\KSR_Package\KSR\Test_Run_KR\Results\ETL` | Where to save processed CSV files |
| `PROFILE_PATH` | Auto-detected | Path to `.wpaProfile` file |

### How It Works

#### Step 1: Profile Detection
```batch
# Searches for .wpaProfile file:
1. In C:\KSR_Package\KSR\Test_Run_KR\
2. If not found, searches entire C:\ drive
3. Uses first match found
```

#### Step 2: ETL File Search
```batch
# Recursively searches for files matching: *_Tracelog.etl
# Example structure:
Golden_Results\
├─ GLD1001\
│  └─ Test1_Tracelog.etl
├─ GLD1002\
│  └─ Test2_Tracelog.etl
└─ GLD1015\
   └─ Test3_Tracelog.etl
```

#### Step 3: Processing
For each ETL file found:
1. Extracts test case name from parent folder (e.g., `GLD1001`)
2. Creates output folder: `ETL\GLD1001\`
3. Runs: `wpaexporter -i [etl_file] -profile [profile_path]`
4. Moves original ETL file to output folder
5. CSV files are automatically created by wpaexporter

#### Step 4: Output Organization
```
Results\ETL\
├─ GLD1001\
│  ├─ Test1_Tracelog.etl (moved from source)
│  ├─ Generic_Events.csv
│  ├─ CPU_Usage.csv
│  └─ [other CSV files from profile]
├─ GLD1002\
│  ├─ Test2_Tracelog.etl
│  └─ [CSV files]
└─ GLD1015\
   ├─ Test3_Tracelog.etl
   └─ [CSV files]
```

### Usage

#### Manual Execution
```batch
cd C:\KSR_Package\KSR\Test_Run_KR
ETL_parser.bat
```

#### Automatic Execution
Called automatically by `Push_ETL.bat` if ETL folder is missing.

### Output Summary

```
=================================
Summary:
Total files found: 13
Successfully processed: 13
Errors: 0

All processed files have been organized in: C:\KSR_Package\KSR\Test_Run_KR\Results\ETL
Each test case has its own folder containing the CSV files and original ETL file.
```

### Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| "Search folder not found" | `Golden_Results` folder doesn't exist | Check test execution completed |
| "Profile file not found" | No `.wpaProfile` file found | Copy profile to search locations |
| "ERROR: Failed to process" | `wpaexporter` failed | Check WPA installation and ETL file integrity |

---

## Component 2: ETL Push

### Purpose

The ETL Push (`Push_ETL.bat`) uploads processed ETL logs to a network share location determined by the Kings River API.

### File Location

```
C:\KSR_Package\KSR\Test_Run_KR\Push_ETL.bat
```

### Prerequisites

1. **Network Connectivity**
   - Access to `\\gar.corp.intel.com\ec\proj\my\ccg\Board\kings_etl\File_Server`
   - Corporate network or VPN connection

2. **Credentials**
   - Username: `sys_toolscps`
   - Password: Configured in script

3. **ETL Logs**
   - Processed by `ETL_parser.bat`
   - Located in: `C:\KSR_Package\KSR\Test_Run_KR\Results\ETL`

4. **Test Results ZIP**
   - `KingsResults_[UUID].zip` uploaded to Kings River

### Configuration

| Variable | Value | Description |
|----------|-------|-------------|
| `ETL_FOLDER` | `C:\KSR_Package\KSR\Test_Run_KR\Results\ETL` | Source folder for ETL logs |
| `ETL_API_ENDPOINT` | `https://ksr-dev.intel.com/parser/api/ETLLogPush/ProcessWTLLogs` | API endpoint for path generation |
| `NETWORK_MOUNT` | `\\gar.corp.intel.com\ec\proj\my\ccg\Board\kings_etl\File_Server` | Base network share path |
| `NETWORK_USER` | `sys_toolscps` | Network authentication username |
| `NETWORK_PASS` | `[configured]` | Network authentication password |

### How It Works

#### Step 1: Validate ETL Folder
```batch
# Checks if ETL folder exists
# If not found, calls ETL_parser.bat to generate it
if not exist "C:\...\Results\ETL" (
    call ETL_parser.bat
)
```

#### Step 2: API Call for Path Generation
```batch
# Sends KingsResults.zip to API
curl -X POST \
  -H "Content-Type: multipart/form-data" \
  -F "ResultZip=@KingsResults_[UUID].zip" \
  https://ksr-dev.intel.com/parser/api/ETLLogPush/ProcessWTLLogs

# API Response (example):
file://gar.corp.intel.com/ec/proj/my/ccg/Board/kings_etl/File_Server/WCL/U/Q9XY/WCL-25H2-CONS-PROD-26.05.6.17/AC-Balanced
```

#### Step 3: Path Processing
```batch
# Converts API response to UNC path
file://gar.corp.intel.com/ec/proj/my/ccg/Board/kings_etl/File_Server/WCL/U/Q9XY/...
↓
\\gar.corp.intel.com\ec\proj\my\ccg\Board\kings_etl\File_Server\WCL\U\Q9XY\...

# Extracts relative path
Base: \\gar.corp.intel.com\ec\proj\my\ccg\Board\kings_etl\File_Server
Full: \\gar.corp.intel.com\...\File_Server\WCL\U\Q9XY\WCL-25H2-CONS-PROD-26.05.6.17\AC-Balanced
↓
Relative: WCL\U\Q9XY\WCL-25H2-CONS-PROD-26.05.6.17\AC-Balanced
```

#### Step 4: Network Mount
```batch
# Checks if network path is accessible
dir "\\gar.corp.intel.com\...\File_Server"

# If not accessible, mounts with credentials
net use "\\gar.corp.intel.com\...\File_Server" /user:sys_toolscps [password]
```

#### Step 5: Create Destination Folder
```batch
# Attempts to create nested directory structure
md "\\gar.corp.intel.com\...\File_Server\WCL\U\Q9XY\..."

# Fallback: Uses robocopy /CREATE if md fails
robocopy "base_path" "dest_path" /CREATE
```

#### Step 6: Copy ETL Files
```batch
# Uses robocopy for reliable multi-threaded copying
robocopy "C:\...\Results\ETL" "\\gar.corp.intel.com\...\[dest]" /E /R:3 /W:5 /MT:8 /NFL /NDL /NP /CREATE

# Robocopy flags:
# /E      = Copy subdirectories, including empty ones
# /R:3    = Retry 3 times on failures
# /W:5    = Wait 5 seconds between retries
# /MT:8   = Use 8 threads (multi-threaded)
# /NFL    = No file list (quieter output)
# /NDL    = No directory list (quieter output)
# /NP     = No progress percentage
# /CREATE = Create directory tree and zero-length files only (for folder creation)
```

### Usage

#### From Command Line
```batch
# Called with KingsResults.zip path as parameter
Push_ETL.bat "C:\path\to\KingsResults_61cdfc6a-f61d-4426-b44b-994d545e4f35.zip"
```

#### From PushResult.cmd
```batch
# Automatically called after test results are uploaded
IF NOT EXIST Kings_ZipFileName.txt goto:eof
SET /p kingsZipFile=<Kings_ZipFileName.txt
call Push_ETL.bat "%kingsZipFile%"
```

### Output Files

| File | Description |
|------|-------------|
| `ETL_API_Response.txt` | Raw API response with file path |
| `ETL_SharePath.txt` | Processed share path for reference |

### Success Output

```
========================================
Starting ETL Push Process
========================================

[✓] ETL folder found: C:\KSR_Package\KSR\Test_Run_KR\Results\ETL
[✓] Using zip file: C:\...\KingsResults_61cdfc6a-f61d-4426-b44b-994d545e4f35.zip

Sending zip file to ETL API...

ETL API Response:
file://gar.corp.intel.com/ec/proj/my/ccg/Board/kings_etl/File_Server/WCL/U/Q9XY/WCL-25H2-CONS-PROD-26.05.6.17/AC-Balanced

[✓] Share path received: file://gar.corp.intel.com/.../AC-Balanced
[✓] UNC path: \\gar.corp.intel.com\.../AC-Balanced
[✓] Network mount path: \\gar.corp.intel.com\...\File_Server
[✓] Relative path: WCL\U\Q9XY\WCL-25H2-CONS-PROD-26.05.6.17\AC-Balanced

Checking if network path is accessible...
[✓] Network path is already accessible.

[✓] Destination path: \\gar.corp.intel.com\...\WCL\U\Q9XY\WCL-25H2-CONS-PROD-26.05.6.17\AC-Balanced

Creating destination folder structure...
[✓] Destination folder created successfully.

Copying ETL folder contents to network share...
Source: C:\KSR_Package\KSR\Test_Run_KR\Results\ETL
Destination: \\gar.corp.intel.com\...\AC-Balanced

-------------------------------------------------------------------------------
   ROBOCOPY     ::     Robust File Copy for Windows
-------------------------------------------------------------------------------
  Started : 16 February 2026 11:45:46
  Source : C:\KSR_Package\KSR\Test_Run_KR\Results\ETL\
  Dest : \\gar.corp.intel.com\...\AC-Balanced\
  
  Dirs :         5         5         1         0         0         0
  Files :        16        16         0         0         0         0
  Bytes :   2.425 g   2.425 g         0         0         0         0
  Times :   0:05:18   0:00:46
  
  Speed :   561,23,273 Bytes/sec.
  Speed :   3,211.399 MegaBytes/min.
  Ended : 16 February 2026 11:46:42

[✓] SUCCESS: ETL folder contents copied to network share successfully!
[✓] Location: \\gar.corp.intel.com\...\AC-Balanced
[✓] Robocopy Exit Code: 1

========================================
ETL Push Process Completed
========================================
```

### Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| "ETL folder not found" | ETL_parser.bat not run | Automatically calls ETL_parser.bat |
| "Failed to send zip file to ETL API" | Network/API issue | Check network connectivity and API endpoint |
| "No share path found in API response" | API returned unexpected format | Check ETL_API_Response.txt for details |
| "Failed to mount network path" | Invalid credentials or network issue | Verify credentials and network access |
| "Failed to create destination folder" | Permission denied | Check network share permissions |
| "Failed to copy ETL folder" | Network interruption | Check robocopy exit code (8+) for details |

---

## Complete Workflow Example

### Scenario: Process and Upload ETL Logs for Test Run

#### Step 1: Run Tests
```batch
# Test execution creates ETL files
C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results\
├─ GLD1001\Test1_Tracelog.etl
├─ GLD1002\Test2_Tracelog.etl
└─ GLD1015\Test3_Tracelog.etl
```

#### Step 2: Parse ETL Files (Manual or Automatic)
```batch
cd C:\KSR_Package\KSR\Test_Run_KR
ETL_parser.bat

# Output:
# [1] Found: C:\...\Golden_Results\GLD1001\Test1_Tracelog.etl
# [1] Test Case: GLD1001
# [1] Processing...
# [1] SUCCESS: ...
# [1] Output saved in: C:\...\Results\ETL\GLD1001
```

#### Step 3: Upload Test Results
```batch
# PushResult.cmd uploads KingsResults.zip
# Creates: KingsResults_61cdfc6a-f61d-4426-b44b-994d545e4f35.zip
# Saves path in: Kings_ZipFileName.txt
```

#### Step 4: Push ETL Logs
```batch
# Automatically called by PushResult.cmd
SET /p kingsZipFile=<Kings_ZipFileName.txt
call Push_ETL.bat "%kingsZipFile%"
```

#### Step 5: Verify Upload
```batch
# Check network location:
\\gar.corp.intel.com\ec\proj\my\ccg\Board\kings_etl\File_Server\
└─ WCL\U\Q9XY\WCL-25H2-CONS-PROD-26.05.6.17\AC-Balanced\
   ├─ GLD1001\
   │  ├─ Test1_Tracelog.etl
   │  └─ [CSV files]
   ├─ GLD1002\
   │  ├─ Test2_Tracelog.etl
   │  └─ [CSV files]
   └─ GLD1015\
      ├─ Test3_Tracelog.etl
      └─ [CSV files]
```

---

## Troubleshooting

### Issue: "Profile file not found"

**Symptoms:**
```
Error: Profile file not found: [empty or invalid path]
```

**Solution:**
1. Locate your `.wpaProfile` file
2. Copy to: `C:\KSR_Package\KSR\Test_Run_KR\`
3. Or update `PROFILE_PATH` variable in script

### Issue: "wpaexporter is not recognized"

**Symptoms:**
```
'wpaexporter' is not recognized as an internal or external command
```

**Solution:**
1. Install Windows Performance Toolkit (part of Windows ADK)
2. Add to PATH: `C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\`
3. Or use full path in script

### Issue: Network path not accessible

**Symptoms:**
```
[ERROR] Error: Failed to mount network path
```

**Solution:**
1. Verify VPN/network connection to Intel corporate network
2. Test manual access: `\\gar.corp.intel.com\ec\proj\my\ccg\Board\kings_etl\File_Server`
3. Verify credentials are correct in script
4. Check with IT if account is locked or password expired

### Issue: Robocopy exit code 8 or higher

**Symptoms:**
```
[ERROR] Error: Failed to copy ETL folder. Robocopy error level: 8
```

**Robocopy Exit Codes:**
- 0 = No files copied (no failures)
- 1 = Files copied successfully
- 2 = Extra files/directories found
- 3 = Files copied + extra files
- 4 = Mismatches exist
- 8 = Copy failures occurred
- 16 = Fatal error

**Solution:**
1. Check network stability
2. Verify destination has sufficient space
3. Check permissions on destination folder
4. Review robocopy output for specific file errors

### Issue: API returns error

**Symptoms:**
```
[ERROR] Error: No share path found in ETL API response
```

**Solution:**
1. Check `ETL_API_Response.txt` for error details
2. Verify `KingsResults.zip` was uploaded successfully
3. Check API endpoint is accessible
4. Contact Kings River support if API is down

---

## Configuration Reference

### File Paths (Default Configuration)

| Path Type | Location |
|-----------|----------|
| Test Results | `C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results` |
| ETL Output | `C:\KSR_Package\KSR\Test_Run_KR\Results\ETL` |
| WPA Profile | `C:\KSR_Package\KSR\Test_Run_KR\*.wpaProfile` |
| Zip File | `C:\KSR_Package\KSR\Test_Run_KR\KingsResults_[UUID].zip` |
| Network Share | `\\gar.corp.intel.com\ec\proj\my\ccg\Board\kings_etl\File_Server` |

### Network Configuration

| Setting | Value |
|---------|-------|
| API Endpoint | `https://ksr-dev.intel.com/parser/api/ETLLogPush/ProcessWTLLogs` |
| Network Share | `\\gar.corp.intel.com\ec\proj\my\ccg\Board\kings_etl\File_Server` |
| Service Account | `sys_toolscps` |
| Authentication | NTLM (Windows Integrated) |

### Robocopy Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `/E` | Enabled | Copy subdirectories, including empty |
| `/R` | 3 | Number of retries on failed copies |
| `/W` | 5 | Wait time (seconds) between retries |
| `/MT` | 8 | Multi-threaded copies (8 threads) |
| `/NFL` | Enabled | No file list logging |
| `/NDL` | Enabled | No directory list logging |
| `/NP` | Enabled | No progress indicator |
| `/CREATE` | Enabled | Create directory tree only |

---

## Best Practices

### 1. **Pre-Execution Checklist**
- [ ] VPN connected (if working remotely)
- [ ] WPA installed and in PATH
- [ ] WPA profile file available
- [ ] Network share accessible
- [ ] Sufficient disk space (local and network)

### 2. **Regular Maintenance**
- Monitor ETL folder size (can grow large)
- Clean up old processed ETL files periodically
- Verify network credentials are not expired
- Update API endpoint if Kings River environment changes

### 3. **Error Recovery**
- If ETL_parser fails partway through, it's safe to re-run (processes all files)
- If Push_ETL fails, it's safe to re-run (robocopy handles existing files)
- Keep `ETL_API_Response.txt` and `ETL_SharePath.txt` for debugging

### 4. **Performance Optimization**
- ETL processing time depends on file size and profile complexity
- Network copy speed depends on file size and network bandwidth
- Robocopy `/MT:8` uses 8 threads; increase for better performance on fast networks
- Large ETL files (>1GB) may take several minutes to process

---

## Appendix

### A. Directory Structure

```
C:\KSR_Package\KSR\Test_Run_KR\
├─ ETL_parser.bat          # ETL processing script
├─ Push_ETL.bat            # ETL upload script
├─ PushResult.cmd          # Main result upload script
├─ *.wpaProfile            # WPA profile for ETL processing
├─ Kings_ZipFileName.txt   # Contains path to KingsResults.zip
├─ ETL_API_Response.txt    # API response (generated)
├─ ETL_SharePath.txt       # Network path (generated)
└─ Results\
   ├─ Golden_Results\      # Test output with ETL files
   │  ├─ GLD1001\
   │  │  └─ *_Tracelog.etl
   │  └─ GLD1002\
   │     └─ *_Tracelog.etl
   └─ ETL\                 # Processed ETL output
      ├─ GLD1001\
      │  ├─ *_Tracelog.etl
      │  └─ *.csv
      └─ GLD1002\
         ├─ *_Tracelog.etl
         └─ *.csv
```

### B. Related Scripts

| Script | Purpose |
|--------|---------|
| `PushResult.cmd` | Main script for uploading test results to Kings River |
| `ETL_parser.bat` | Processes ETL files with wpaexporter |
| `Push_ETL.bat` | Uploads ETL logs to network share |
| `ETL_parser2.bat` | Test/development version of Push_ETL.bat |

### C. API Documentation

#### ETL Push API Endpoint

**URL:** `https://ksr-dev.intel.com/parser/api/ETLLogPush/ProcessWTLLogs`

**Method:** POST

**Content-Type:** multipart/form-data

**Parameters:**
- `ResultZip`: The KingsResults ZIP file

**Response:** Plain text file path
```
file://gar.corp.intel.com/ec/proj/my/ccg/Board/kings_etl/File_Server/[Platform]/[SKU]/[System]/[Config]/[Power]
```

**Example:**
```
file://gar.corp.intel.com/ec/proj/my/ccg/Board/kings_etl/File_Server/WCL/U/Q9XY/WCL-25H2-CONS-PROD-26.05.6.17/AC-Balanced
```

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-16 | System | Initial documentation |

---

## Support

For issues or questions:
- **Kings River Platform:** [Kings River Portal](https://kingsriver.intel.com)
- **IT Support:** Contact Intel IT for network/credential issues
- **Script Issues:** Review error messages and troubleshooting section

---

**End of Documentation**
