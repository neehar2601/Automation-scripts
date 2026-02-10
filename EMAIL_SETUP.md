# Email Configuration Guide

## Two Options for Sending Emails

### Option 1: Unauthenticated SMTP (Default)
**Server:** `smtp.intel.com:25`  
**Authentication:** Not required  
**Use case:** When on Intel network/VPN  

✅ **Already configured** - No setup needed!

---

### Option 2: Authenticated SMTP (Recommended)
**Server:** `Smtpauth.intel.com:587`  
**Authentication:** Required  
**Use case:** More reliable, works from anywhere  

This matches your .NET SmtpClient code exactly.

---

## Setup Authenticated Email

### Step 1: Set Environment Variables

You need to set two environment variables with your Intel email credentials:

#### Temporary (Current Session Only):

**PowerShell:**
```powershell
$env:MailUserName = "your.email@intel.com"
$env:MailPassword = "your_password"
```

**Command Prompt:**
```cmd
set MailUserName=your.email@intel.com
set MailPassword=your_password
```

#### Permanent (Recommended):

**Via PowerShell:**
```powershell
# Set for current user permanently
[System.Environment]::SetEnvironmentVariable('MailUserName', 'your.email@intel.com', 'User')
[System.Environment]::SetEnvironmentVariable('MailPassword', 'your_password', 'User')

# Verify they're set
[System.Environment]::GetEnvironmentVariable('MailUserName', 'User')
[System.Environment]::GetEnvironmentVariable('MailPassword', 'User')
```

**Via GUI (Windows):**
1. Press `Win + R`, type `sysdm.cpl`, press Enter
2. Go to **Advanced** tab → **Environment Variables**
3. Under **User variables**, click **New**
4. Add:
   - Variable: `MailUserName`
   - Value: `your.email@intel.com`
5. Click **New** again
6. Add:
   - Variable: `MailPassword`
   - Value: `your_password`
7. Click **OK** to save

**⚠️ Important:** After setting permanent variables, **restart your terminal/VS Code** for changes to take effect.

---

### Step 2: Enable Authenticated SMTP in daily_monitor.py

Open `daily_monitor.py` and modify the email configuration section:

**Change from:**
```python
# Email configuration
SMTP_SERVER = "smtp.intel.com"
SMTP_PORT = 25
USE_AUTH = False
```

**To:**
```python
# Email configuration
SMTP_SERVER = "Smtpauth.intel.com"
SMTP_PORT = 587
USE_AUTH = True
```

---

### Step 3: Test Email Sending

#### Test with standalone script:
```powershell
# Test email sending
python send_email_intel.py --to your.email@intel.com --subject "Test Email" --body "This is a test from Python"
```

#### Test with monitoring system:
```powershell
# Generate a test report and send email
python daily_monitor.py --email your.email@intel.com --no-update
```

---

## Verification

Check if environment variables are set:

```powershell
# PowerShell
echo $env:MailUserName
echo $env:MailPassword

# Command Prompt
echo %MailUserName%
echo %MailPassword%
```

You should see your email and password (password will be displayed - this is for testing only).

---

## Troubleshooting

### Error: "Authentication required but credentials not found"

**Solution:** Environment variables not set or not loaded.
```powershell
# Set them temporarily
$env:MailUserName = "your.email@intel.com"
$env:MailPassword = "your_password"

# Or restart terminal after setting permanent variables
```

---

### Error: "Authentication Failed"

**Possible causes:**
1. **Incorrect username or password**
   - Verify credentials: `echo $env:MailUserName`
   
2. **2FA enabled on your account**
   - Use an app-specific password instead of your regular password
   - Generate one from Intel's password portal
   
3. **Account locked**
   - Try logging into webmail to verify account is active

---

### Error: "SMTP Error: Connection refused"

**Possible causes:**
1. **Not connected to Intel network/VPN**
   - Connect to Intel VPN and try again
   
2. **Firewall blocking port 587**
   - Check firewall settings
   - Try from a different network
   
3. **Server unreachable**
   - Verify: `Test-NetConnection Smtpauth.intel.com -Port 587`

---

### Error: "SMTP Error: Timeout"

**Solution:** Increase timeout or check network connection
```python
# In daily_monitor.py, increase timeout:
with smtplib.SMTP(SMTP_SERVER, SMTP_PORT, timeout=60) as server:  # was 30
```

---

## Comparison: .NET vs Python

Your .NET code translates to Python like this:

| .NET Code | Python Equivalent |
|-----------|-------------------|
| `SmtpClient smtp = new SmtpClient()` | `with smtplib.SMTP(...) as smtp:` |
| `smtp.Host = "Smtpauth.intel.com"` | `SMTP_HOST = "Smtpauth.intel.com"` |
| `smtp.Port = 587` | `SMTP_PORT = 587` |
| `smtp.EnableSsl = true` | `smtp.starttls()` |
| `smtp.UseDefaultCredentials = false` | Authentication explicit |
| `smtp.Credentials = new NetworkCredential(...)` | `smtp.login(username, password)` |
| `Environment.GetEnvironmentVariable("MailUserName")` | `os.environ.get("MailUserName")` |
| `smtp.Send(mm)` | `smtp.send_message(msg)` |
| `Thread.Sleep(1000)` | `time.sleep(1)` |
| `smtp.Dispose()` | Automatic with `with` statement |

---

## Security Best Practices

### ✅ DO:
- Store credentials in environment variables (not in code)
- Use user-level environment variables (not system-level)
- Consider using Windows Credential Manager for password storage
- Use app-specific passwords if 2FA is enabled

### ❌ DON'T:
- Hard-code passwords in scripts
- Commit credentials to version control
- Share your password/credentials

---

## Quick Setup Script

Run this to set everything up at once:

```powershell
# Set environment variables (replace with your credentials)
$env:MailUserName = "your.email@intel.com"
$env:MailPassword = "your_password"

# Test standalone email script
python send_email_intel.py --to your.email@intel.com --subject "Test" --body "Hello from Python"

# If that works, test with monitoring system
python daily_monitor.py --email your.email@intel.com --no-update
```

---

## Files Created

1. **`send_email_intel.py`** - Standalone email sender (Python equivalent of your .NET code)
2. **`daily_monitor.py`** - Updated with authenticated SMTP support
3. **`EMAIL_SETUP.md`** - This guide

---

## Daily Usage

Once configured, simply run:

```powershell
# Daily monitoring with email
python daily_monitor.py --email your.email@intel.com
```

The script will automatically use your stored credentials to send emails! 📧
