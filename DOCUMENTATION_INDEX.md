# 📚 Documentation Index

Quick links to all documentation files for the automated web page monitoring system.

## 🚀 Getting Started

**Start here:**
- **[INSTALLATION.md](INSTALLATION.md)** - Install dependencies and setup
- **[DAILY_WORKFLOW.md](DAILY_WORKFLOW.md)** - Complete daily monitoring workflow and usage

## 📖 Main Documentation

### Core Documentation
- **[INSTALLATION.md](INSTALLATION.md)** - Dependencies and setup guide
- **[FILTERING_DOCUMENTATION.md](FILTERING_DOCUMENTATION.md)** - Complete filtering guide (what gets reported vs filtered out)
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Email and baseline update issues

### Quick Reference
- **[QUICK_COMMANDS.md](QUICK_COMMANDS.md)** - Command reference
- **[QUICK_START.md](QUICK_START.md)** - Quick start guide

### Additional Resources
- **[README.md](README.md)** - Project overview
- **[DAILY_MONITOR_README.md](DAILY_MONITOR_README.md)** - Daily monitor script details
- **[FIXES_APPLIED.md](FIXES_APPLIED.md)** - Summary of enhancements
- **[SOLUTION_SUMMARY.md](SOLUTION_SUMMARY.md)** - Complete solution overview
- **[IMMEDIATE_FIX.md](IMMEDIATE_FIX.md)** - OneDrive file lock solutions

---

## 🎯 Most Important Files

### For Daily Use:
1. **[DAILY_WORKFLOW.md](DAILY_WORKFLOW.md)** - How to run the system daily
2. **[FILTERING_DOCUMENTATION.md](FILTERING_DOCUMENTATION.md)** - What changes get reported

### For Troubleshooting:
1. **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Email/baseline issues
2. **[IMMEDIATE_FIX.md](IMMEDIATE_FIX.md)** - OneDrive lock problems

### For Customization:
1. **[FILTERING_DOCUMENTATION.md](FILTERING_DOCUMENTATION.md)** - Section: "Customization"
2. **[QUICK_COMMANDS.md](QUICK_COMMANDS.md)** - All available commands

---

## 📝 Quick Usage

```powershell
# Daily run with email
python daily_monitor.py --email your.email@intel.com

# Test run without email
python daily_monitor.py --no-email
```

**See [DAILY_WORKFLOW.md](DAILY_WORKFLOW.md) for complete workflow details.**

---

## 🔍 Find What You Need

| I want to... | Read this file |
|-------------|----------------|
| Install the system | [INSTALLATION.md](INSTALLATION.md) |
| Understand the daily workflow | [DAILY_WORKFLOW.md](DAILY_WORKFLOW.md) |
| Learn what gets filtered | [FILTERING_DOCUMENTATION.md](FILTERING_DOCUMENTATION.md) |
| Fix email connection errors | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| Fix baseline update errors | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or [IMMEDIATE_FIX.md](IMMEDIATE_FIX.md) |
| See all commands | [QUICK_COMMANDS.md](QUICK_COMMANDS.md) |
| Customize filtering | [FILTERING_DOCUMENTATION.md](FILTERING_DOCUMENTATION.md) → Customization |
| Quick start guide | [QUICK_START.md](QUICK_START.md) |
| Understand OneDrive issues | [IMMEDIATE_FIX.md](IMMEDIATE_FIX.md) |

---

## 📂 Project Structure

```
parser/
├── daily_monitor.py           # Main monitoring script
├── sso_downloader.py          # SSO download script
├── baseline/                  # Current baseline files
├── compare/                   # (Created during run)
├── reports/                   # All change reports
│   └── change_report_*.txt
├── DAILY_WORKFLOW.md          ⭐ Start here
├── FILTERING_DOCUMENTATION.md ⭐ Filtering guide
├── TROUBLESHOOTING.md
├── QUICK_COMMANDS.md
├── QUICK_START.md
└── [Other documentation files...]
```

---

**Start with [DAILY_WORKFLOW.md](DAILY_WORKFLOW.md) to understand the complete workflow!** 🚀
