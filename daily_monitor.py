"""
Automated Daily Web Page Monitor and Comparison Script
=======================================================

This script:
1. Downloads all web pages to a "compare" directory
2. Compares with the "baseline" directory
3. Generates a detailed change report
4. Sends the report via email (if changes found)
5. Updates baseline with the new content

Usage:
    python daily_monitor.py --email your.email@intel.com
    python daily_monitor.py --email your.email@intel.com --no-update  # Don't update baseline
"""

import os
import sys
import subprocess
import argparse
import shutil
from pathlib import Path
from datetime import datetime
import difflib
import hashlib

# -------------------- CONFIG --------------------

START_URL = "https://docs.intel.com/documents/OORJA_Repo/index.html"
BASELINE_DIR = Path("baseline")
COMPARE_DIR = Path("compare")
REPORTS_DIR = Path("reports")

# Email configuration - now handled by send_email_intel.py
# Email sent from: ksr_oorja_changes@intel.com
# Uses environment variables: MailUserName, MailPassword

# -------------------- FUNCTIONS --------------------

def run_downloader(output_dir):
    """Run the SSO downloader script to download pages"""
    print(f"\n{'='*80}")
    print(f"DOWNLOADING PAGES TO: {output_dir}")
    print(f"{'='*80}\n")
    
    cmd = [
        sys.executable,  # Current Python interpreter
        "sso_downloader.py",
        "--output", str(output_dir),
        "--url", START_URL
    ]
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print(result.stdout)
        if result.stderr:
            print("Warnings/Errors:", result.stderr)
        return True
    except subprocess.CalledProcessError as e:
        print(f"ERROR: Failed to download pages: {e}")
        print(e.stdout)
        print(e.stderr)
        return False

def get_file_hash(filepath):
    """Calculate MD5 hash of a file"""
    hash_md5 = hashlib.md5()
    try:
        with open(filepath, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()
    except Exception as e:
        return None

def compare_directories(baseline_dir, compare_dir):
    """
    Compare two directories and return changes.
    Returns: (changed_files, new_files, deleted_files, total_changes)
    """
    if not baseline_dir.exists():
        print(f"WARNING: Baseline directory doesn't exist: {baseline_dir}")
        return {}, {}, {}, 0
    
    if not compare_dir.exists():
        print(f"ERROR: Compare directory doesn't exist: {compare_dir}")
        return {}, {}, {}, 0
    
    print(f"\n{'='*80}")
    print("COMPARING DIRECTORIES")
    print(f"{'='*80}\n")
    print(f"Baseline: {baseline_dir}")
    print(f"Compare:  {compare_dir}\n")
    
    changed_files = {}
    new_files = {}
    deleted_files = {}
    
    # Get all HTML files from both directories
    baseline_files = {}
    for file in baseline_dir.rglob("*.html"):
        rel_path = file.relative_to(baseline_dir)
        baseline_files[str(rel_path)] = file
    
    compare_files = {}
    for file in compare_dir.rglob("*.html"):
        rel_path = file.relative_to(compare_dir)
        compare_files[str(rel_path)] = file
    
    print(f"Baseline files: {len(baseline_files)}")
    print(f"Compare files:  {len(compare_files)}")
    print()
    
    # Find changed and new files
    for rel_path, compare_file in compare_files.items():
        if rel_path in baseline_files:
            baseline_file = baseline_files[rel_path]
            
            # Compare file hashes
            baseline_hash = get_file_hash(baseline_file)
            compare_hash = get_file_hash(compare_file)
            
            if baseline_hash != compare_hash:
                # File changed - generate diff
                try:
                    with open(baseline_file, 'r', encoding='utf-8', errors='ignore') as f:
                        baseline_content = f.readlines()
                    with open(compare_file, 'r', encoding='utf-8', errors='ignore') as f:
                        compare_content = f.readlines()
                    
                    diff = list(difflib.unified_diff(
                        baseline_content,
                        compare_content,
                        fromfile=f"baseline/{rel_path}",
                        tofile=f"current/{rel_path}",
                        lineterm=''
                    ))
                    
                    changed_files[rel_path] = {
                        'baseline': baseline_file,
                        'compare': compare_file,
                        'diff': diff
                    }
                    print(f"[CHANGED] {rel_path}")
                except Exception as e:
                    print(f"[ERROR] Could not compare {rel_path}: {e}")
        else:
            # New file
            new_files[rel_path] = compare_file
            print(f"[NEW] {rel_path}")
    
    # Find deleted files
    for rel_path, baseline_file in baseline_files.items():
        if rel_path not in compare_files:
            deleted_files[rel_path] = baseline_file
            print(f"[DELETED] {rel_path}")
    
    total_changes = len(changed_files) + len(new_files) + len(deleted_files)
    
    print()
    print(f"Summary:")
    print(f"  Changed: {len(changed_files)}")
    print(f"  New:     {len(new_files)}")
    print(f"  Deleted: {len(deleted_files)}")
    print(f"  Total:   {total_changes}")
    
    return changed_files, new_files, deleted_files, total_changes

def is_meaningful_change(line):
    """
    Determine if a diff line represents a meaningful content change.
    Returns True if the change is meaningful, False if it's just HTML structure noise.
    """
    if not line.startswith('-') and not line.startswith('+'):
        return False  # Not a change line
    
    # Remove the diff marker
    content = line[1:].strip()
    
    # Ignore empty lines
    if not content:
        return False
    
    # Patterns to IGNORE (HTML structure noise)
    ignore_patterns = [
        # Tracking and analytics scripts
        '<script type="text/javascript" src="/ruxitagentjs',
        'data-dtconfig="rid=RID_',
        'rpid=',
        
        # HTML structure tags
        '<html><head><title>',
        '</head><body>',
        '</body></html>',
        
        # CSS and style tags
        '<style type="text/css">code{white-space: pre;}</style>',
        
        # UI button states and visibility (these are the ones showing in your report!)
        'onclick="pm.subscribe()" style=',  # Subscribe button changes
        'onclick="pm.start_feedback()" style=',  # Feedback button changes
        'id="subscribe_button"',  # Subscribe button
        'id="feedback_button"',  # Feedback button
        'style="display: block;"',  # Display style changes
        'style="display:none"',  # Display style changes
        '<button class="menubutton hastooltip"',  # Menu buttons
        
        # Common HTML boilerplate
        '<span class="fa fa-',  # Font awesome icons
        '<span class="tooltip',  # Tooltip text
    ]
    
    for pattern in ignore_patterns:
        if pattern in content:
            return False
    
    # Additional check: if line only contains HTML tags and whitespace, ignore it
    # Remove HTML tags and check if anything meaningful remains
    import re
    text_only = re.sub(r'<[^>]+>', '', content).strip()
    if not text_only or text_only in ['', '&nbsp;', '&gt;', '&lt;']:
        return False
    
    # If we get here, it's likely a meaningful change
    return True

def extract_text_content(html_line):
    """Extract readable text from HTML line, removing all tags"""
    import re
    # Remove HTML tags
    text = re.sub(r'<[^>]+>', '', html_line)
    # Decode common HTML entities
    text = text.replace('&nbsp;', ' ').replace('&lt;', '<').replace('&gt;', '>').replace('&amp;', '&')
    return text.strip()

def filter_meaningful_changes(diff_lines):
    """
    Filter diff output to extract simple before/after changes.
    Returns list of simple change descriptions and count.
    """
    changes = []
    meaningful_count = 0
    
    i = 0
    while i < len(diff_lines):
        line = diff_lines[i]
        
        # Skip diff headers
        if line.startswith('---') or line.startswith('+++') or line.startswith('@@'):
            i += 1
            continue
        
        # Look for pairs of - and + lines (changes)
        if line.startswith('-') and i + 1 < len(diff_lines) and diff_lines[i + 1].startswith('+'):
            if is_meaningful_change(line) and is_meaningful_change(diff_lines[i + 1]):
                # Extract the actual text content
                before = extract_text_content(line[1:])
                after = extract_text_content(diff_lines[i + 1][1:])
                
                if before and after and before != after:
                    changes.append(f'  "{before}" was changed to "{after}"')
                    meaningful_count += 1
                    i += 2  # Skip both lines
                    continue
        
        # Single additions (no corresponding deletion)
        elif line.startswith('+') and is_meaningful_change(line):
            content = extract_text_content(line[1:])
            if content:
                changes.append(f'  Added: "{content}"')
                meaningful_count += 1
        
        # Single deletions (no corresponding addition)
        elif line.startswith('-') and is_meaningful_change(line):
            content = extract_text_content(line[1:])
            if content:
                changes.append(f'  Removed: "{content}"')
                meaningful_count += 1
        
        i += 1
    
    return changes, meaningful_count

def generate_report(changed_files, new_files, deleted_files):
    """Generate a clean, well-formatted change report that's easy to read
    
    Returns: (report_content, meaningful_change_count)
    """
    timestamp = datetime.now()
    report_lines = []
    
    # First, filter out files with only HTML structure changes
    meaningful_changes = {}
    skipped_files = []
    
    for rel_path, info in changed_files.items():
        simple_changes, meaningful_count = filter_meaningful_changes(info['diff'])
        
        if meaningful_count > 0:
            meaningful_changes[rel_path] = {
                **info,
                'simple_changes': simple_changes,
                'meaningful_count': meaningful_count
            }
        else:
            skipped_files.append(rel_path)
    
    # Calculate total meaningful changes
    meaningful_change_count = len(meaningful_changes) + len(new_files) + len(deleted_files)
    
    # Header with better spacing
    report_lines.append("="*100)
    report_lines.append("WEB PAGE CHANGE DETECTION REPORT".center(100))
    report_lines.append("="*100)
    report_lines.append("")
    report_lines.append(f"Report Generated: {timestamp.strftime('%B %d, %Y at %I:%M %p')}")
    report_lines.append(f"Source URL: {START_URL}")
    report_lines.append("")
    
    # Summary Section with emoji
    report_lines.append("="*100)
    report_lines.append("SUMMARY".center(100))
    report_lines.append("="*100)
    report_lines.append("")
    report_lines.append(f"  📊 Files with Meaningful Changes: {len(meaningful_changes)}")
    report_lines.append(f"  🔇 Files with Only Structure Changes: {len(skipped_files)} (ignored)")
    report_lines.append(f"  ➕ New Files:     {len(new_files)}")
    report_lines.append(f"  ➖ Deleted Files: {len(deleted_files)}")
    report_lines.append(f"  📈 Total Meaningful Changes: {meaningful_change_count}")
    report_lines.append("")
    
    # If no changes, make it clear
    if meaningful_change_count == 0:
        report_lines.append("✅ All content is identical to the baseline.")
        report_lines.append("   Only HTML structure or UI element changes were detected and filtered out.")
        report_lines.append("")
        report_lines.append("="*100)
        report_lines.append("END OF REPORT".center(100))
        report_lines.append("="*100)
        return '\n'.join(report_lines), meaningful_change_count
    
    # Content Changes Section with better formatting
    if meaningful_changes:
        report_lines.append("="*100)
        report_lines.append("CONTENT CHANGES".center(100))
        report_lines.append("="*100)
        report_lines.append("")
        
        for rel_path, info in sorted(meaningful_changes.items()):
            # File heading with bold separator
            report_lines.append("")
            report_lines.append("─"*100)
            report_lines.append(f"📄 FILE: {rel_path}")
            report_lines.append("─"*100)
            report_lines.append("")
            
            # Process each change with better formatting
            for change in info['simple_changes']:
                change = change.strip()
                
                if not change:
                    continue
                
                # Format different types of changes
                if change.startswith('Removed:'):
                    # Removed content
                    content = change.replace('Removed:', '').strip().strip('"')
                    report_lines.append(f"  🔴 REMOVED:")
                    report_lines.append(f"     {content}")
                    report_lines.append("")
                    
                elif change.startswith('Added:'):
                    # Added content
                    content = change.replace('Added:', '').strip().strip('"')
                    report_lines.append(f"  🟢 ADDED:")
                    report_lines.append(f"     {content}")
                    report_lines.append("")
                    
                elif ' was changed to ' in change:
                    # Changed content - split into OLD/NEW
                    parts = change.split(' was changed to ')
                    if len(parts) == 2:
                        old_value = parts[0].strip().strip('"')
                        new_value = parts[1].strip().strip('"')
                        report_lines.append(f"  🔄 CHANGED:")
                        report_lines.append(f"     OLD: {old_value}")
                        report_lines.append(f"     NEW: {new_value}")
                        report_lines.append("")
                else:
                    # Generic change
                    report_lines.append(f"  • {change}")
                    report_lines.append("")
    
    # New files section
    if new_files:
        report_lines.append("")
        report_lines.append("="*100)
        report_lines.append("NEW FILES".center(100))
        report_lines.append("="*100)
        report_lines.append("")
        for rel_path in sorted(new_files.keys()):
            report_lines.append(f"  ➕ {rel_path}")
        report_lines.append("")
    
    # Deleted files section
    if deleted_files:
        report_lines.append("")
        report_lines.append("="*100)
        report_lines.append("DELETED FILES".center(100))
        report_lines.append("="*100)
        report_lines.append("")
        for rel_path in sorted(deleted_files.keys()):
            report_lines.append(f"  ➖ {rel_path}")
        report_lines.append("")
    
    # Footer
    report_lines.append("")
    report_lines.append("="*100)
    report_lines.append("END OF REPORT".center(100))
    report_lines.append("="*100)
    
    return '\n'.join(report_lines), meaningful_change_count

def save_report(report_content, timestamp):
    """Save report to file"""
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    
    report_filename = f"change_report_{timestamp.strftime('%Y%m%d_%H%M%S')}.txt"
    report_path = REPORTS_DIR / report_filename
    
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(report_content)
    
    print(f"\n✅ Report saved to: {report_path}")
    return report_path

def send_email(to_email, subject, body, attachment_path=None):
    """Send email by calling send_email_intel.py script"""
    print(f"\n{'='*80}")
    print("SENDING EMAIL NOTIFICATION")
    print(f"{'='*80}\n")
    
    # Build command to call send_email_intel.py
    cmd = [
        sys.executable,  # Current Python interpreter
        "send_email_intel.py",
        "--to", to_email,
        "--subject", subject,
        "--body", body,
        "--from", "ksr_oorja_changes@intel.com"
    ]
    
    # Add attachment if provided
    if attachment_path and Path(attachment_path).exists():
        cmd.extend(["--attach", str(attachment_path)])
    
    try:
        print(f"Calling send_email_intel.py...")
        print(f"  To: {to_email}")
        print(f"  From: ksr_oorja_changes@intel.com")
        print(f"  Subject: {subject}")
        if attachment_path:
            print(f"  Attachment: {Path(attachment_path).name}")
        print()
        
        # Run the email script
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        # Print output from email script
        if result.stdout:
            print(result.stdout)
        
        if result.returncode == 0:
            print(f"\n✅ Email sent successfully to: {to_email}")
            return True
        else:
            print(f"\n❌ Email script failed with exit code: {result.returncode}")
            if result.stderr:
                print(f"Error: {result.stderr}")
            print(f"Report saved locally at: {attachment_path}")
            return False
            
    except subprocess.TimeoutExpired:
        print(f"\n❌ Email sending timed out after 60 seconds")
        print(f"Report saved locally at: {attachment_path}")
        return False
    except Exception as e:
        print(f"\n❌ Failed to send email: {e}")
        print(f"Report saved locally at: {attachment_path}")
        return False

def update_baseline(compare_dir, baseline_dir):
    """Update baseline using PowerShell (no backup, direct move)
    
    Workflow:
    1. Clear baseline directory
    2. Move contents from compare to baseline  
    3. Clear compare directory (ready for next run)
    """
    import time
    
    print(f"\n{'='*80}")
    print("UPDATING BASELINE")
    print(f"{'='*80}\n")
    
    print("Using PowerShell for reliable file operations (no backup created)...\n")
    
    # PowerShell script to update baseline
    ps_script = f"""
$ErrorActionPreference = "Stop"

try {{
    Write-Host "Step 1: Clearing baseline directory..." -ForegroundColor Yellow
    
    if (Test-Path "{baseline_dir}") {{
        Remove-Item -Path "{baseline_dir}" -Recurse -Force
        Write-Host "  ✓ Baseline cleared" -ForegroundColor Green
    }}
    
    Write-Host "`nStep 2: Moving compare to baseline..." -ForegroundColor Yellow
    
    if (Test-Path "{compare_dir}") {{
        Move-Item -Path "{compare_dir}" -Destination "{baseline_dir}" -Force
        Write-Host "  ✓ Contents moved to baseline" -ForegroundColor Green
    }} else {{
        Write-Host "  ✗ Compare directory not found!" -ForegroundColor Red
        exit 1
    }}
    
    Write-Host "`n✅ Baseline updated successfully!" -ForegroundColor Green
    Write-Host "   - Baseline now contains latest content" -ForegroundColor Cyan
    Write-Host "   - Compare directory cleared (ready for next download)" -ForegroundColor Cyan
    exit 0
    
}} catch {{
    Write-Host "`n❌ Error: $_" -ForegroundColor Red
    exit 1
}}
"""
    
    try:
        # Run PowerShell script
        result = subprocess.run(
            ["powershell.exe", "-NoProfile", "-Command", ps_script],
            capture_output=True,
            text=True,
            timeout=60
        )
        
        # Print output
        if result.stdout:
            print(result.stdout)
        
        if result.returncode == 0:
            return True
        else:
            print(f"\n❌ PowerShell script failed (exit code: {result.returncode})")
            if result.stderr:
                print(f"Error: {result.stderr}")
            
            print(f"\n💡 MANUAL FIX:")
            print(f"   1. Close file explorers and pause OneDrive")
            print(f"   2. Run in PowerShell:")
            print(f"      Remove-Item -Recurse -Force baseline")
            print(f"      Move-Item compare baseline")
            return False
            
    except subprocess.TimeoutExpired:
        print(f"\n❌ Timeout after 60 seconds (files may be locked)")
        return False
        
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(
        description='Automated web page monitoring and comparison',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run daily check and send email
  python daily_monitor.py --email your.email@intel.com
  
  # Run check but don't update baseline
  python daily_monitor.py --email your.email@intel.com --no-update
  
  # Skip email notification
  python daily_monitor.py --no-email
        """
    )
    
    parser.add_argument('--email', '-e',
                       help='Email address to send report to')
    parser.add_argument('--no-update',
                       action='store_true',
                       help='Do not update baseline after comparison')
    parser.add_argument('--no-email',
                       action='store_true',
                       help='Skip email notification')
    parser.add_argument('--force-download',
                       action='store_true',
                       help='Force re-download even if compare directory exists')
    
    args = parser.parse_args()
    
    timestamp = datetime.now()
    
    print("\n" + "="*80)
    print("AUTOMATED WEB PAGE MONITORING SYSTEM")
    print("="*80)
    print(f"\nStarted: {timestamp.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"URL: {START_URL}")
    print(f"Baseline: {BASELINE_DIR}")
    print(f"Compare:  {COMPARE_DIR}")
    
    # Step 1: Download to compare directory
    if args.force_download or not COMPARE_DIR.exists():
        if COMPARE_DIR.exists():
            print(f"\nRemoving old compare directory...")
            shutil.rmtree(COMPARE_DIR)
        
        print(f"\nStep 1: Downloading current pages...")
        if not run_downloader(COMPARE_DIR):
            print("\n❌ Download failed. Exiting.")
            return 1
    else:
        print(f"\nStep 1: Using existing compare directory (use --force-download to re-download)")
    
    # Step 2: Compare with baseline
    print(f"\nStep 2: Comparing with baseline...")
    
    if not BASELINE_DIR.exists():
        print(f"\n⚠️  WARNING: No baseline found!")
        print(f"This appears to be the first run.")
        print(f"Creating initial baseline from downloaded files...")
        shutil.copytree(COMPARE_DIR, BASELINE_DIR)
        print(f"✅ Initial baseline created: {BASELINE_DIR}")
        print(f"\nRun this script again tomorrow to detect changes.")
        return 0
    
    changed_files, new_files, deleted_files, total_changes = compare_directories(
        BASELINE_DIR, COMPARE_DIR
    )
    
    # Step 3: Generate report
    print(f"\nStep 3: Generating report...")
    report_content, meaningful_change_count = generate_report(changed_files, new_files, deleted_files)
    report_path = save_report(report_content, timestamp)
    
    # Print summary to console
    print("\n" + "="*80)
    if meaningful_change_count == 0:
        print("✅ NO MEANINGFUL CHANGES DETECTED")
        print("="*80)
        print(f"\nTotal file changes: {total_changes}")
        print(f"  - Changed: {len(changed_files)} (but only HTML structure/tracking scripts)")
        print(f"  - New: {len(new_files)}")
        print(f"  - Deleted: {len(deleted_files)}")
        print("\n🎯 All content is identical to the baseline.")
    else:
        print(f"⚠️  {meaningful_change_count} MEANINGFUL CHANGES DETECTED")
        print("="*80)
        print(f"\n  Changed: {len([f for f in changed_files if any(filter_meaningful_changes(changed_files[f]['diff'])[0])])}")
        print(f"  New:     {len(new_files)}")
        print(f"  Deleted: {len(deleted_files)}")
        print(f"\n  (Ignored {total_changes - meaningful_change_count} files with only HTML structure changes)")
    
    # Step 4: Send email (if meaningful changes and email requested)
    if not args.no_email and meaningful_change_count > 0:
        if args.email:
            subject = f"Oorja changes {timestamp.strftime('%d/%m/%Y')}"
            
            # Create email body
            body = f"""Web Page Monitoring Report

Meaningful Changes Detected: {meaningful_change_count}
  - Changed Files: {len([f for f in changed_files if any(filter_meaningful_changes(changed_files[f]['diff'])[0])])}
  - New Files: {len(new_files)}
  - Deleted Files: {len(deleted_files)}

(Filtered out {total_changes - meaningful_change_count} files with only HTML structure changes)

Generated: {timestamp.strftime('%Y-%m-%d %H:%M:%S')}
Source: {START_URL}

See attached report for detailed changes.

---
KSR_Automation
"""
            
            send_email(args.email, subject, body, report_path)
        else:
            print("\n⚠️  Changes detected but no email address provided.")
            print("   Use --email option to receive notifications.")
    elif not args.no_email and meaningful_change_count == 0:
        print("\n📧 No email sent (no meaningful changes detected)")
    
    # Step 5: Update baseline
    if not args.no_update:
        print(f"\nStep 5: Updating baseline...")
        if update_baseline(COMPARE_DIR, BASELINE_DIR):
            print("✅ Baseline updated successfully!")
        else:
            print("❌ Failed to update baseline")
            return 1
    else:
        print(f"\nStep 5: Skipped baseline update (--no-update flag)")
    
    print("\n" + "="*80)
    print("MONITORING COMPLETE")
    print("="*80)
    print(f"\nFinished: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Report: {report_path}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
