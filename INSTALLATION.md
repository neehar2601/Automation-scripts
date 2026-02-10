# Installation Guide

## Prerequisites

- Python 3.10 or higher
- Windows 10/11
- Microsoft Edge browser (or Chrome)

## Quick Setup

### 1. Install Python Dependencies

```powershell
# Navigate to project directory
cd "C:\Users\nnellika\OneDrive - Intel Corporation\Documents\parser"

# Install all required packages
pip install -r requirements.txt
```

### 2. Install Playwright Browsers

After installing the Python packages, you need to install the browser binaries:

```powershell
# Install Microsoft Edge browser for Playwright
playwright install msedge

# OR install Chrome
playwright install chrome

# OR install all browsers
playwright install
```

## Dependencies Explained

### Required Packages:

1. **playwright>=1.40.0**
   - Browser automation for SSO-protected downloads
   - Handles authentication via existing browser profile
   - Downloads rendered HTML content

2. **beautifulsoup4>=4.12.0**
   - HTML parsing and manipulation
   - Extracts links from downloaded pages
   - Used by sso_downloader.py

3. **requests>=2.31.0**
   - HTTP library for API calls
   - Used for downloading binary files
   - Backup download method

### Built-in Modules (No Installation Needed):

- `smtplib` - Email sending
- `pathlib` - File path handling
- `difflib` - File comparison
- `hashlib` - MD5 file hashing
- `subprocess` - Running external commands
- `argparse` - Command-line argument parsing
- `datetime` - Timestamps
- `re` - Regular expressions
- `shutil` - File operations

## Verification

Check that everything is installed correctly:

```powershell
# Check Python version
python --version

# Check installed packages
pip list | Select-String "playwright|beautifulsoup4|requests"

# Check Playwright browsers
playwright --version
```

Expected output:
```
Python 3.10+ or higher
playwright       1.40.0+
beautifulsoup4   4.12.0+
requests         2.31.0+
```

## Troubleshooting

### Issue: "playwright: command not found"

**Solution:**
```powershell
# Reinstall playwright
pip uninstall playwright
pip install playwright
playwright install msedge
```

### Issue: "No module named 'playwright'"

**Solution:**
```powershell
# Make sure you're using the correct Python environment
python -m pip install playwright
python -m playwright install msedge
```

### Issue: Browser won't launch

**Solution:**
```powershell
# Install browsers with dependencies
playwright install --with-deps msedge
```

### Issue: "Permission denied" during installation

**Solution:**
```powershell
# Run PowerShell as Administrator, then:
pip install -r requirements.txt
playwright install msedge
```

## First Run Setup

After installation, test the downloader:

```powershell
# Test download (saves to web_pages/ folder)
python sso_downloader.py

# If you need to login, the browser will open
# Log in via SSO, then the download will start
```

## Daily Usage

Once installed, you only need:

```powershell
# Daily monitoring with email
python daily_monitor.py --email your.email@intel.com

# Daily monitoring without email
python daily_monitor.py --no-email
```

## Updating Dependencies

To update to latest versions:

```powershell
# Update all packages
pip install --upgrade -r requirements.txt

# Update Playwright browsers
playwright install msedge
```

## Complete Installation Script

Run all at once:

```powershell
# Full installation
pip install -r requirements.txt
playwright install msedge

# Verify installation
python -c "import playwright; import bs4; import requests; print('✅ All dependencies installed!')"

# Test the system
python daily_monitor.py --no-email --no-update
```

---

## Quick Commands Reference

```powershell
# Install
pip install -r requirements.txt
playwright install msedge

# Update
pip install --upgrade -r requirements.txt

# Verify
pip list | Select-String "playwright|beautifulsoup4|requests"

# Run
python daily_monitor.py --email your.email@intel.com
```

---

**For daily workflow, see [DAILY_WORKFLOW.md](DAILY_WORKFLOW.md)**
