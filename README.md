# ETL Processing and Results Push Documentation

## Overview
This documentation covers the automated ETL (Event Trace Log) processing and results submission workflow for the Kings River System.

---

## Table of Contents
1. [ETL Parser Script](#etl-parser-script)
2. [Push Results Script](#push-results-script)
3. [Folder Structure](#folder-structure)
4. [API Endpoints](#api-endpoints)
5. [Manual Commands](#manual-commands)
6. [Troubleshooting](#troubleshooting)

---

## ETL Parser Script

### Script Name
`Naming_batch.bat`

### Purpose
Converts Windows Performance Analyzer trace log files (`*_Tracelog.etl`) to CSV format using the Windows Performance Analyzer exporter tool, and organizes them into a structured ETL folder.

### Configuration
```batch
set "SEARCH_FOLDER=C:\KSR_Package\KSR\Test_Run_KR\Results\Golden_Results"
set "ETL_OUTPUT_FOLDER=C:\KSR_Package\KSR\Test_Run_KR\Results\ETL"
set "PROFILE_PATH=C:\Users\nnellika\Downloads\wprfile.wpaProfile"
```

### Input Structure
```
Results/Golden_Results/
    ├── GLD-1001/
    │   └── *_Tracelog.etl
    ├── GLD-1005/
    │   └── *_Tracelog.etl
    ├── GLD6001/
    │   └── *_Tracelog.etl
    ├── GLD6002/
    │    └── *_Tracelog.etl
    ├── GLD1015/
    │   └── *_Tracelog.etl
    └── GLD1016/
        └── *_Tracelog.etl
```

### Output Structure
```
Results/ETL/
├── GLD-1001/
│   ├── *.csv (converted files)
│   └── *_Tracelog.etl (original file)
├── GLD-1005/
│   ├── *.csv
│   └── *_Tracelog.etl
├── GLD6001/
│   ├── *.csv
│   └── *_Tracelog.etl
└── GLD6002/
    ├── *.csv
    └── *_Tracelog.etl
```

### Process Flow
1. **Validation**: Checks if search folder and WPA profile exist
2. **Search**: Recursively finds all `*_Tracelog.etl` files
3. **Create Folders**: Creates test case folders in ETL output directory
4. **Convert**: Runs `wpaexporter` to convert ETL to CSV format
5. **Move Files**: Moves original ETL file to output directory
6. **Report**: Displays summary of processed files

### Usage
```cmd
cd C:\KSR_Package\KSR\Test_Run_KR
Naming_batch.bat
```

### Requirements
- Windows Performance Analyzer (`wpaexporter`) must be installed
- WPA profile file (`.wpaProfile`) must exist
- Sufficient disk space for converted files

---

## Push Results Script

### Script Name
`PushResult.cmd`

### Purpose
Comprehensive script that:
1. Collects system information
2. Generates EMon, SystemScope, and SystemInfo data
3. Creates a zip file with results
4. Pushes results to Kings River API
5. Pushes ETL logs to share path

### Configuration
```batch
set "ETL_FOLDER=%CD%\Results\ETL"
set "ETL_API_ENDPOINT=https://ksr-dev.intel.com/parser/api/ETLLogPush/ProcessWTLLogs"
```

### Process Flow

#### Phase 1: System Information Collection
1. **Serial Number Collection**
   - Retrieves baseboard serial number via WMIC
   - Generates dummy serial if unavailable (format: `KSRSN[random]`)
   - Saves to `Results\SerialNumber.txt`

2. **EMon Installation & Data Generation** (if needed)
   - Downloads SEP tools from JFrog
   - Installs Intel SEP (System Event Profiler)
   - Generates EMon version info

3. **System Data Generation**
   - SystemScope: Hardware/firmware information
   - SystemInfo: Detailed system configuration

#### Phase 2: Results Packaging & Upload
4. **Workload Download**
   - Downloads workload configuration from Kings River API
   - Endpoint: `https://kingsriver.intel.com/api/KPI/GetWorkload`

5. **Zip Creation**
   - `KingsParser.exe` creates zip file
   - Filename saved to `Kings_ZipFileName.txt`

6. **Results Upload**
   - Uploads zip to Kings River Parser API
   - Endpoint: `https://kingsriver.intel.com/parser/api/Parser/ProcessData`
   - Validates "Results Uploaded Successfully" response

#### Phase 3: ETL Push (New Addition)
7. **ETL Folder Check**
   - Verifies `Results\ETL` folder exists
   - Skips gracefully if not found

8. **ETL Zip Upload**
   - Sends same zip file to ETL API
   - Endpoint: `https://ksr-dev.intel.com/parser/api/ETLLogPush/ProcessWTLLogs`
   - Parameter: `ResultZip`

9. **Share Path Extraction**
   - Parses API response for share path
   - Expected format: `file://gar.corp.intel.com/ec/proj/my/ccg/Board/kings_etl/...`
   - Converts to UNC format: `\\gar.corp.intel.com\ec\proj\my\ccg\Board\kings_etl\...`

10. **ETL Folder Copy**
    - Copies entire ETL folder to share path
    - Uses `robocopy` with retry logic
    - Multi-threaded transfer for performance

### Usage
```cmd
cd C:\KSR_Package\KSR\Test_Run_KR
PushResult.cmd
```

### Dependencies
- `curl` (for API calls)
- `wmic` (for serial number)
- `KingsParser.exe` (for zip creation)
- `SystemScopeCmdLine.exe` (for system info)
- `SpeedSysInfo.exe` (for system details)
- `robocopy` (for ETL folder copy)
- Network access to Kings River APIs
- Access to share path (SMB/CIFS)

---

## Folder Structure

### Working Directory
```
C:\KSR_Package\KSR\Test_Run_KR\
├── Results\
│   ├── Golden_Results\        # Input: Raw test results
│   │   ├── Active Power\
│   │   ├── Low Power\
│   │   └── Performance\
│   ├── ETL\                   # Output: Processed ETL files
│   │   ├── GLD-1001\
│   │   ├── GLD-1005\
│   │   └── ...
│   ├── SerialNumber.txt
│   ├── [SerialNumber]_SystemScope.json
│   ├── [SerialNumber]_SystemInfo.json
│   └── [SerialNumber]_EMonInfo.txt
├── KingsResults_[UUID].zip    # Generated zip file
├── Kings_ZipFileName.txt      # Zip filename reference
├── KingsWorkload.json         # Downloaded workload
├── ParserDetails.txt          # Results upload response
├── ETL_API_Response.txt       # ETL API response
└── ETL_SharePath.txt          # Extracted share path
```

---

## API Endpoints

### 1. Workload Download
- **URL**: `https://kingsriver.intel.com/api/KPI/GetWorkload`
- **Method**: POST
- **Headers**: `Content-Type: application/json`
- **Response**: JSON with workload configuration

### 2. Results Upload
- **URL**: `https://kingsriver.intel.com/parser/api/Parser/ProcessData`
- **Method**: POST
- **Headers**: `Content-Type: multipart/form-data`
- **Parameters**:
  - `RunNumber`: Integer (default: 1)
  - `ResultZip`: File (zip archive)
- **Success Response**: Contains "Results Uploaded Successfully"

### 3. ETL Upload
- **URL**: `https://ksr-dev.intel.com/parser/api/ETLLogPush/ProcessWTLLogs`
- **Method**: POST
- **Headers**: `Content-Type: multipart/form-data`
- **Parameters**:
  - `ResultZip`: File (zip archive)
- **Response**: Share path in format `file://server/path/...`

---

## Manual Commands

### ETL Conversion (Manual)
```cmd
cd [directory_with_etl_file]
wpaexporter -i "file_Tracelog.etl" -profile "C:\path\to\wprfile.wpaProfile"
```

### Results Upload (Manual)
```bash
curl.exe -X POST ^
  -H "Content-Type: multipart/form-data" ^
  -F "RunNumber=1" ^
  -F "ResultZip=@KingsResults_[UUID].zip;type=application/x-zip-compressed" ^
  https://kingsriver.intel.com/parser/api/Parser/ProcessData ^
  -k > ParserDetails.txt
```

### ETL Upload (Manual)
```bash
curl.exe -X POST ^
  -H "Content-Type: multipart/form-data" ^
  -F "ResultZip=@KingsResults_[UUID].zip;type=application/x-zip-compressed" ^
  https://ksr-dev.intel.com/parser/api/ETLLogPush/ProcessWTLLogs ^
  -k > ETL_API_Response.txt
```

### View API Response
```cmd
type ETL_API_Response.txt
```

### Copy ETL Folder to Share (Manual)
```cmd
robocopy "C:\KSR_Package\KSR\Test_Run_KR\Results\ETL" ^
  "\\gar.corp.intel.com\ec\proj\my\ccg\Board\kings_etl\File_Server\[path]" ^
  /E /R:3 /W:5 /MT:8
```

---

## Troubleshooting

### ETL Parser Issues

#### Issue: "No ETL files found"
**Solution**: 
- Verify `SEARCH_FOLDER` path is correct
- Check that files end with `_Tracelog.etl`
- Ensure files exist in subdirectories

#### Issue: "Profile not found"
**Solution**:
- Download/locate `.wpaProfile` file
- Update `PROFILE_PATH` in script
- Ensure full path with no spaces (or use quotes)

#### Issue: "wpaexporter not recognized"
**Solution**:
- Install Windows Performance Toolkit
- Add WPT to system PATH
- Or use full path to `wpaexporter.exe`

### Push Results Issues

#### Issue: "Invalid serial number"
**Solution**:
- Script auto-generates dummy serial: `KSRSN[random]`
- This is expected behavior for systems without proper serial

#### Issue: "SystemScope.json does not exist"
**Solution**:
- Install Intel System Scope Tool
- Verify path: `C:\Program Files\Intel Corporation\Intel(R) System Scope Tool\`
- Run SystemScope manually to test

#### Issue: "Unable To Download Workload"
**Solution**:
- Check network connectivity to `kingsriver.intel.com`
- Verify VPN connection if required
- Check firewall settings

#### Issue: "Unable To Send File"
**Solution**:
- Verify `Kings_ZipFileName.txt` exists
- Check zip file exists
- Verify API endpoint is accessible
- Check network/proxy settings

#### Issue: "ETL API returns empty response"
**Solution**:
- Verify API endpoint URL is correct
- Check parameter name (`ResultZip` vs `ETLZip`)
- Test API with curl manually
- Contact API team for endpoint status

#### Issue: "Share path is not accessible"
**Solution**:
- Verify network connection to share server
- Check SMB/CIFS permissions
- Test UNC path in File Explorer: `\\gar.corp.intel.com\...`
- Verify user has write permissions
- Check if share requires authentication

#### Issue: PowerShell curl alias conflict
**Solution**:
- Use `curl.exe` instead of `curl` in PowerShell
- Or run from CMD instead of PowerShell

### Robocopy Error Codes
- **0-7**: Success (0=no files, 1=files copied, 2=extra files, etc.)
- **8+**: Errors (8=some failures, 16=serious error)

---

## Color-Coded Messages

### Script Output Legend
- **[102m** (Green): Success messages
- **[101m** (Red): Error messages
- **[0m**: Reset to default color

---

## Version History

| Version | Date       | Changes                                      |
|---------|------------|----------------------------------------------|
| V1.0    | 02-13-2026 | Initial ETL parser with folder organization  |
| V1.1    | 02-13-2026 | Added ETL push to PushResult script          |

---

## Contact & Support

For issues or questions:
- **Script Owner**: Saravanan Rajagopal
- **Modified By**: GitHub Copilot
- **Kings River System**: https://kingsriver.intel.com

---

## Notes

1. **enabledelayedexpansion**: Required in PushResult.cmd for variable expansion in loops
2. **Firewall**: Script disables firewall (`netsh advfirewall set allprofile state off`)
3. **Background Process**: Script uses `-k` flag with curl to ignore SSL certificate errors
4. **Zip File Format**: Must use `application/x-zip-compressed` content type
5. **Share Path Format**: Converts `file://` to `\\` (UNC path) automatically
6. **Test Case Names**: Extracted from parent folder name (GLD-XXXX, GLDXXXX, etc.)

---

## Best Practices

1. Always run scripts from the correct working directory
2. Verify all dependencies are installed before running
3. Check disk space before processing large ETL files
4. Save backup of results before pushing
5. Verify API responses for errors
6. Test share path accessibility before copying large folders
7. Keep `.wpaProfile` file up to date for accurate conversions

---

*Last Updated: February 13, 2026*
