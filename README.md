# OORJA Web Page Monitoring System - DEPLOYMENT PACKAGE
## Complete Setup and Usage Guide

**Date:** February 6, 2026  
**Version:** 1.0  
**Purpose:** Automated daily monitoring of Intel OORJA documentation with intelligent change detection and email notifications

---

## 📦 PACKAGE CONTENTS

### Core Scripts (Required)
1. **`daily_monitor.py`** - Main automation script
2. **`sso_downloader.py`** - SSO-authenticated web scraper
3. **`send_email_intel.py`** - Intel SMTP email sender
4. **`requirements.txt`** - Python dependencies

### Documentation
5. **`README.md`** - This file (complete setup guide)
6. **`INSTALLATION.md`** - Detailed installation steps
7. **`EMAIL_SETUP.md`** - Email configuration guide
8. **`FILTERING_DOCUMENTATION.md`** - How the intelligent filtering works
9. **`DOCUMENTATION_INDEX.md`** - Documentation overview

---

## 🚀 QUICK START (5 Minutes)

### Step 1: Install Python Dependencies
```powershell
# From the DEPLOYMENT folder
pip install -r requirements.txt

# Install Playwright browser binaries
python -m playwright install chromium
```

### Step 2: Set Up Email Credentials
```powershell
# Set environment variables (use your Intel credentials)
$env:MailUserName = "your.email@intel.com"
$env:MailPassword = "your_password"

# To make them permanent:
[System.Environment]::SetEnvironmentVariable('MailUserName', 'your.email@intel.com', 'User')
[System.Environment]::SetEnvironmentVariable('MailPassword', 'your_password', 'User')
```

### Step 3: Run First Time (Create Baseline)
```powershell
python daily_monitor.py --email your.email@intel.com
```

**First run creates the baseline** - no email sent yet.

### Step 4: Run Daily (Detect Changes)
```powershell
# Run the same command daily
python daily_monitor.py --email your.email@intel.com
```

**Email sent only when meaningful content changes are detected!**

---

## 📧 EMAIL BEHAVIOR

### When Email is Sent
✅ **Email sent when:**
- Meaningful content changes detected (text additions, deletions, modifications)
- New pages added
- Pages deleted

❌ **Email NOT sent when:**
- Only HTML structure changes (tracking scripts, session IDs)
- Only UI button state changes (onclick, style="display:block")
- CSS/style changes
- No changes at all

### Email Details
- **From:** ksr_oorja_changes@intel.com
- **Subject:** "OOrja changes dd/mm/yyyy"
- **Attachment:** Detailed change report
- **Server:** Smtpauth.intel.com:587 (authenticated SMTP)

---

## 📁 DIRECTORY STRUCTURE AFTER FIRST RUN

```
DEPLOYMENT/
├── daily_monitor.py          # Main script
├── sso_downloader.py          # Web scraper
├── send_email_intel.py        # Email sender
├── requirements.txt           # Dependencies
├── README.md                  # This guide
├── *.md                       # Other documentation
│
├── baseline/                  # Reference content (auto-created)
│   └── *.html                 # Downloaded pages
│
├── compare/                   # Current content (auto-created, auto-cleared)
│   └── *.html                 # Latest downloads
│
└── reports/                   # Change reports (auto-created)
    └── change_report_*.txt    # Timestamped reports
```

---

## 🎯 DAILY USAGE

### Standard Daily Run
```powershell
python daily_monitor.py --email your.email@intel.com
```

### Test Run (Don't Update Baseline)
```powershell
python daily_monitor.py --email your.email@intel.com --no-update
```

### Generate Report Only (No Email)
```powershell
python daily_monitor.py --no-email
```

### Force Re-Download
```powershell
python daily_monitor.py --email your.email@intel.com --force-download
```

---

## 🔧 TROUBLESHOOTING

### Email Not Received
1. **Check environment variables:**
   ```powershell
   echo $env:MailUserName
   echo $env:MailPassword
   ```

2. **Test email directly:**
   ```powershell
   python send_email_intel.py --to your.email@intel.com --subject "Test" --body "Test email" --from ksr_oorja_changes@intel.com
   ```

3. **Check network:**
   - Must be on Intel network or VPN
   - Port 587 must not be blocked by firewall

### Download Fails
1. **Install/reinstall Playwright:**
   ```powershell
   python -m playwright install chromium --force
   ```

2. **Check SSO authentication:**
   - Script will open browser for SSO login
   - Complete authentication when prompted

### Permission Denied Errors
```powershell
# Close file explorers, pause OneDrive, then:
Remove-Item -Recurse -Force compare
Remove-Item -Recurse -Force baseline
python daily_monitor.py --email your.email@intel.com
```

---

## 🤖 AUTOMATION (Optional)

### Windows Task Scheduler Setup

1. **Open Task Scheduler** → Create Basic Task
2. **Name:** OORJA Daily Monitor
3. **Trigger:** Daily at 9:00 AM
4. **Action:** Start a program
   - **Program:** `C:\Program Files\Python314\python.exe`
   - **Arguments:** `daily_monitor.py --email your.email@intel.com`
   - **Start in:** `C:\path\to\DEPLOYMENT`
5. **Finish**

### Verify Task
```powershell
# Test the task manually
schtasks /run /tn "OORJA Daily Monitor"

# Check task status
schtasks /query /tn "OORJA Daily Monitor"
```

---

## 🧠 INTELLIGENT FILTERING

The system automatically filters out **149 types** of HTML noise:

### Ignored Changes
- ❌ Tracking scripts (`ruxitagentjs`, `data-dtconfig`)
- ❌ Session IDs and GUIDs
- ❌ UI button states (`onclick`, `style="display:block"`)
- ❌ HTML structure tags (`<html>`, `<head>`, `<body>`)
- ❌ CSS and style changes
- ❌ Empty lines and whitespace

### Detected Changes
- ✅ Text content additions
- ✅ Text content deletions
- ✅ Text content modifications
- ✅ New pages added
- ✅ Pages removed

**Example Report:**
```
CONTENT CHANGES
================================================================================

documentation/getting-started.html:
  "Version 1.0" was changed to "Version 1.1"
  Added: "New feature: Advanced filtering"
  Removed: "Beta notice"
```

---

## 📚 DETAILED DOCUMENTATION

- **`INSTALLATION.md`** - Step-by-step installation guide
- **`EMAIL_SETUP.md`** - Email configuration and troubleshooting
- **`FILTERING_DOCUMENTATION.md`** - How the filtering algorithm works
- **`DOCUMENTATION_INDEX.md`** - Complete documentation index

---

## 🔐 SECURITY NOTES

### Credentials Storage
- Email credentials stored in **environment variables**
- Not stored in code or config files
- Password not visible in process list

### Recommended Practice
```powershell
# Set permanently in User environment (not shown in console)
[System.Environment]::SetEnvironmentVariable('MailUserName', 'your.email@intel.com', 'User')
[System.Environment]::SetEnvironmentVariable('MailPassword', 'your_password', 'User')

# Restart PowerShell to load new environment variables
```

---

## 📊 MONITORING WORKFLOW

```
┌─────────────────────────────────────────────────────────────┐
│ 1. DOWNLOAD       Download all pages to compare/ folder     │
│    (SSO auth)     via Playwright + SSO authentication        │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│ 2. COMPARE        Compare with baseline/ folder             │
│    (Smart filter) Filter out HTML noise, keep content       │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│ 3. REPORT         Generate change report with meaningful    │
│    (Readable)     changes in readable format                │
└────────────────────────────┬────────────────────────────────┘
                             │
                  ┌──────────▼──────────┐
                  │ Meaningful changes? │
                  └──────────┬──────────┘
                       YES   │   NO
            ┌────────────────┴────────────────┐
            │                                 │
┌───────────▼──────────────┐   ┌─────────────▼──────────────┐
│ 4. EMAIL                 │   │ 4. SKIP EMAIL               │
│    Send report with      │   │    No changes detected       │
│    attachment            │   │                             │
└───────────┬──────────────┘   └─────────────┬──────────────┘
            │                                 │
            └────────────────┬────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│ 5. UPDATE         Move compare/ → baseline/                 │
│    (No backup)    Clear compare/ (ready for next run)       │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ SUCCESS CRITERIA

After setup, you should see:

### ✅ First Run (Baseline Creation)
```
================================================================================
AUTOMATED WEB PAGE MONITORING SYSTEM
================================================================================

Step 1: Downloading current pages...
✅ Downloaded 50+ pages

Step 2: Comparing with baseline...
⚠️  WARNING: No baseline found!
✅ Initial baseline created

Run this script again tomorrow to detect changes.
```

### ✅ Subsequent Runs (No Changes)
```
Step 3: Generating report...
================================================================================
✅ NO MEANINGFUL CHANGES DETECTED
================================================================================

Total file changes: 149
  - Changed: 149 (but only HTML structure/tracking scripts)
  - New: 0
  - Deleted: 0

🎯 All content is identical to the baseline.
📧 No email sent (no meaningful changes detected)
```

### ✅ Subsequent Runs (Changes Detected)
```
================================================================================
⚠️  3 MEANINGFUL CHANGES DETECTED
================================================================================

  Changed: 2
  New:     1
  Deleted: 0

  (Ignored 147 files with only HTML structure changes)

✅ Email sent successfully to: your.email@intel.com
✅ Baseline updated successfully!
```

---

## 🆘 SUPPORT

### Common Issues

| Issue | Solution |
|-------|----------|
| Email not sent | Check environment variables, test with `send_email_intel.py` |
| Download fails | Reinstall Playwright: `python -m playwright install chromium` |
| Permission denied | Close file explorers, pause OneDrive |
| No changes detected | System working correctly! Email sent only when content changes |

### Contact
For issues or questions, refer to the detailed documentation files included in this package.

---

## 📝 VERSION HISTORY

**Version 1.0** (February 6, 2026)
- Initial deployment package
- Intelligent HTML filtering (15+ ignore patterns)
- Email integration with Intel SMTP
- Automated baseline management
- Clean, readable change reports

---

**🎉 You're all set! Run the script daily to monitor OORJA documentation changes.**
