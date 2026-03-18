# Quick Setup Script for OORJA Daily Parser Scheduled Task
# Run this script in PowerShell to automatically create the scheduled task

Write-Host ""
Write-Host "="*80 -ForegroundColor Cyan
Write-Host "OORJA DAILY PARSER - SCHEDULED TASK SETUP" -ForegroundColor Green
Write-Host "="*80 -ForegroundColor Cyan
Write-Host ""

# Get current directory (parser folder)
$parserDir = Get-Location
Write-Host "Parser Directory: $parserDir" -ForegroundColor White

# Get Python path
$pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $pythonPath) {
    Write-Host "❌ ERROR: Python not found in PATH" -ForegroundColor Red
    Write-Host "   Please install Python or add it to your PATH" -ForegroundColor Yellow
    exit 1
}
Write-Host "Python Path: $pythonPath" -ForegroundColor White

# Prompt for email address
Write-Host ""
Write-Host "Default email: ksr-ptl-execution@intel.com" -ForegroundColor Gray
$emailInput = Read-Host "Enter email address for notifications (press Enter for default)"
if (-not $emailInput) {
    $email = "ksr-ptl-execution@intel.com"
    Write-Host "Using default: $email" -ForegroundColor Yellow
} else {
    $email = $emailInput
}

# Prompt for schedule time
Write-Host ""
Write-Host "Enter the time to run daily (24-hour format, e.g., 09:00)" -ForegroundColor Cyan
$timeInput = Read-Host "Time (default: 09:00)"
if (-not $timeInput) {
    $timeInput = "09:00"
}

try {
    $scheduleTime = [DateTime]::ParseExact($timeInput, "HH:mm", $null)
} catch {
    Write-Host "❌ ERROR: Invalid time format. Use HH:mm (e.g., 09:00)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Creating scheduled task with the following settings:" -ForegroundColor Cyan
Write-Host "  Task Name: OORJA Daily Parser" -ForegroundColor White
Write-Host "  Schedule: Daily at $($scheduleTime.ToString('hh:mm tt'))" -ForegroundColor White
Write-Host "  Email: $email" -ForegroundColor White
Write-Host "  Command: python daily_monitor.py --email $email --force-download" -ForegroundColor White
Write-Host "  Directory: $parserDir" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Proceed with task creation? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "❌ Setup cancelled by user" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Creating task..." -ForegroundColor Yellow

try {
    # Create action (with --force-download flag)
    $action = New-ScheduledTaskAction `
        -Execute $pythonPath `
        -Argument "daily_monitor.py --email $email --force-download" `
        -WorkingDirectory $parserDir.Path

    # Create trigger (daily at specified time)
    $trigger = New-ScheduledTaskTrigger -Daily -At $scheduleTime

    # Create settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -WakeToRun `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Hours 2)

    # Create principal (run as current user with highest privileges)
    $principal = New-ScheduledTaskPrincipal `
        -UserId "$env:USERDOMAIN\$env:USERNAME" `
        -LogonType S4U `
        -RunLevel Highest

    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName "OORJA Daily Parser" -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host ""
        Write-Host "⚠️  Task 'OORJA Daily Parser' already exists" -ForegroundColor Yellow
        $overwrite = Read-Host "Do you want to overwrite it? (Y/N)"
        if ($overwrite -ne "Y" -and $overwrite -ne "y") {
            Write-Host "❌ Setup cancelled" -ForegroundColor Yellow
            exit 0
        }
        Unregister-ScheduledTask -TaskName "OORJA Daily Parser" -Confirm:$false
    }

    # Register the task
    Register-ScheduledTask `
        -TaskName "OORJA Daily Parser" `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "Automated daily monitoring of OORJA documentation with intelligent change detection and email notifications" `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "="*80 -ForegroundColor Green
    Write-Host "✅ SCHEDULED TASK CREATED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "="*80 -ForegroundColor Green
    Write-Host ""
    Write-Host "Task Details:" -ForegroundColor Cyan
    Write-Host "  Name: OORJA Daily Parser" -ForegroundColor White
    Write-Host "  Schedule: Daily at $($scheduleTime.ToString('hh:mm tt'))" -ForegroundColor White
    Write-Host "  Email: $email" -ForegroundColor White
    Write-Host "  Next Run: $(Get-ScheduledTask -TaskName 'OORJA Daily Parser' | Get-ScheduledTaskInfo | Select-Object -ExpandProperty NextRunTime)" -ForegroundColor White
    Write-Host ""
    Write-Host "What happens next:" -ForegroundColor Cyan
    Write-Host "  1. Task will run automatically at $($scheduleTime.ToString('hh:mm tt')) every day" -ForegroundColor White
    Write-Host "  2. It will download pages fresh each time (--force-download)" -ForegroundColor White
    Write-Host "  3. It will compare with baseline and filter HTML noise" -ForegroundColor White
    Write-Host "  4. If meaningful changes are detected, email sent to: $email" -ForegroundColor White
    Write-Host "  5. Reports will be saved in: $parserDir\reports\" -ForegroundColor White
    Write-Host ""
    Write-Host "Testing the task:" -ForegroundColor Cyan
    Write-Host "  To run the task immediately (don't wait for schedule):" -ForegroundColor White
    Write-Host "  Start-ScheduledTask -TaskName 'OORJA Daily Parser'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Or use this command:" -ForegroundColor White
    Write-Host "  schtasks /run /tn 'OORJA Daily Parser'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Monitoring the task:" -ForegroundColor Cyan
    Write-Host "  Get-ScheduledTask -TaskName 'OORJA Daily Parser' | Get-ScheduledTaskInfo" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "View in Task Scheduler:" -ForegroundColor Cyan
    Write-Host "  Press Windows + R, type: taskschd.msc, press Enter" -ForegroundColor Yellow
    Write-Host "  Find: OORJA Daily Parser" -ForegroundColor Yellow
    Write-Host ""
    
    # Ask if user wants to test now
    Write-Host "Would you like to test the task now? (Y/N)" -ForegroundColor Cyan
    $testNow = Read-Host
    if ($testNow -eq "Y" -or $testNow -eq "y") {
        Write-Host ""
        Write-Host "Running task..." -ForegroundColor Yellow
        Start-ScheduledTask -TaskName "OORJA Daily Parser"
        Write-Host "✅ Task started! Check Task Scheduler for status." -ForegroundColor Green
        Write-Host "   This may take 20-30 minutes to complete." -ForegroundColor White
        Write-Host ""
        Write-Host "To monitor progress:" -ForegroundColor Cyan
        Write-Host "  Get-ScheduledTask -TaskName 'OORJA Daily Parser' | Get-ScheduledTaskInfo" -ForegroundColor Yellow
    }

} catch {
    Write-Host ""
    Write-Host "❌ ERROR: Failed to create scheduled task" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Cyan
    Write-Host "  1. Run PowerShell as Administrator" -ForegroundColor White
    Write-Host "  2. Verify Python is in PATH" -ForegroundColor White
    Write-Host "  3. Check parser directory path" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "Setup complete! Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
