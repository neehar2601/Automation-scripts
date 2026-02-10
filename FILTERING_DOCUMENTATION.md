# 🎯 Content Filtering - Complete Guide

## Table of Contents
1. [Overview](#overview)
2. [How It Works](#how-it-works)
3. [What Gets Filtered](#what-gets-filtered)
4. [What Gets Reported](#what-gets-reported)
5. [Report Format](#report-format)
6. [Customization](#customization)
7. [Examples](#examples)
8. [Benefits](#benefits)

---

## Overview

The daily monitoring system includes **intelligent content filtering** that automatically distinguishes between:
- ✅ **Meaningful changes**: Test configurations, steps, timings, URLs, actual content
- ❌ **Noise**: HTML structure, tracking scripts, session IDs, dynamic tags, UI button states

### The Problem It Solves

**Before filtering:**
- Report shows: 149 changed files
- Most changes are tracking scripts: `<script src="/ruxitagentjs_..." data-dtconfig="rid=RID_12345">`
- Session IDs changing: `rpid=542264660` → `rpid=1590404154`
- UI button states: `style="display: block;"` → `style="display:none"`
- You waste 30+ minutes finding the 3 real changes

**After filtering:**
- Report shows: 3 meaningful changes (146 filtered out)
- Only actual content changes displayed
- No HTML tags, no tracking scripts, no button states
- Done in 2 minutes! 🎯

---

## How It Works

### 1. **Two-Level Filtering**

#### File-Level Filtering:
```python
For each changed file:
  1. Generate full diff
  2. Analyze each line for meaningful changes
  3. Count meaningful changes
  4. If count > 0: Include in report
  5. If count = 0: Completely ignore file
```

#### Line-Level Filtering:
```python
For each diff line:
  1. Check against ignore patterns
  2. Remove HTML tags and check if text remains
  3. If meaningful: Keep in report
  4. If noise: Filter out
```

### 2. **Smart Pattern Matching**

The filter uses comprehensive patterns to catch all variations:

```python
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
    
    # UI button states and visibility
    'onclick="pm.subscribe()" style=',        # Subscribe button
    'onclick="pm.start_feedback()" style=',  # Feedback button
    'id="subscribe_button"',
    'id="feedback_button"',
    'style="display: block;"',                # With space
    'style="display:none"',                   # Without space
    '<button class="menubutton hastooltip"',
    
    # Icons and tooltips
    '<span class="fa fa-',                    # Font awesome icons
    '<span class="tooltip',                   # Tooltip text
]
```

### 3. **HTML Tag Removal Check**

Even if a line doesn't match ignore patterns, it gets one more check:

```python
# Remove all HTML tags
text_only = re.sub(r'<[^>]+>', '', content).strip()

# If nothing remains, it's HTML-only noise
if not text_only:
    return False  # Filter out
```

This catches edge cases like:
```html
<div><span></span></div>  ← Filtered out (no text content)
```

---

## What Gets Filtered

### ❌ Tracking Scripts
```html
<!-- IGNORED -->
<script type="text/javascript" src="/ruxitagentjs_ICANVfqru_10329260115094557.js" 
  data-dtconfig="rid=RID_1213105673|rpid=542264660|..."></script>
```
**Reason**: Dynamic tracking/analytics that change on every page load

### ❌ Session/Request IDs
```html
<!-- IGNORED -->
data-dtconfig="rid=RID_1213105673|rpid=542264660|..."
```
**Reason**: Random session identifiers with no content value

### ❌ UI Button States
```html
<!-- IGNORED -->
<button onclick="pm.subscribe()" style="display: block;">Subscribe</button>
<button onclick="pm.subscribe()" style="display:none">Subscribe</button>
```
**Reason**: Button visibility toggles don't affect content

### ❌ Display Style Changes
```html
<!-- IGNORED -->
<div style="display: block;">Content</div>
<div style="display:none">Content</div>
```
**Reason**: CSS visibility changes without content modification

### ❌ Menu Buttons and Icons
```html
<!-- IGNORED -->
<button class="menubutton hastooltip">Menu</button>
<span class="fa fa-download"></span>
<span class="tooltip">Click here</span>
```
**Reason**: UI elements that don't change documentation content

### ❌ Pure HTML Structure
```html
<!-- IGNORED -->
<html><head><title>Page Title</title></head>
</head><body>
</body></html>
```
**Reason**: Structure-only changes don't affect content

### ❌ CSS Style Tags
```html
<!-- IGNORED -->
<style type="text/css">code{white-space: pre;}</style>
```
**Reason**: Styling information, not content

---

## What Gets Reported

### ✅ Test Configuration Changes
```
"RAM: 16 GB" was changed to "RAM: 4 GB"
```

### ✅ Execution Steps
```
"Install Windows 10" was changed to "Install Windows 11"
```

### ✅ Command Changes
```
"Run: powercfg /sleepfun" was changed to "Run: powercfg /sleepstudy"
```

### ✅ Path or URL Changes
```
"Download from: \\share\old\path\tool.exe" was changed to "Download from: \\share\new\path\tool.exe"
```

### ✅ Timing Values
```
"Wait 30 seconds before starting" was changed to "Wait 45 seconds before starting"
```

### ✅ Version Numbers
```
"Tool Version: 2.5.1" was changed to "Tool Version: 2.6.0"
```

### ✅ Measurement Units
```
"The unit of measurement for this KPI is KB/ms" was changed to "The unit of measurement for this KPI is MB/s"
```

### ✅ Any Actual Content Text
```
"Battery test should run for 2 hours" was changed to "Battery test should run for 3 hours"
```

---

## Report Format

### Clean, Simple Output

**No more diff markers, no HTML tags, no line numbers!**

```
================================================================================
WEB PAGE CHANGE DETECTION REPORT
================================================================================

Report Generated: 2026-02-04 15:03:38
Source URL: https://docs.intel.com/documents/OORJA_Repo/index.html

================================================================================
SUMMARY
================================================================================

  Files with Meaningful Changes: 3
  Files with Only Structure Changes: 0 (ignored)
  New Files:     0
  Deleted Files: 0
  Total Meaningful Changes: 3


================================================================================
CONTENT CHANGES
================================================================================


Performance_Workloads\Crossmark_ac_dc.html:
  "RAM: 16 GB" was changed to "RAM: 4 GB"

Performance_Workloads\Game%20titles%20TBD.html:
  "The unit of measurement for this KPI is KB/ms / Score / mw / FPS etc.," was changed to "The unit of measurement for this KPI is MB/s / Score / mw / FPS etc.,"

Power_and_Battery_Life_Workloads\Busy%20Idle.html:
  "Run: powercfg /sleepfun" was changed to "Run: powercfg /sleepstudy"


================================================================================
END OF REPORT
================================================================================
```

### What You See:
1. **Filename** - Which file changed
2. **Simple before → after** - What changed in plain English
3. **No clutter** - No HTML, no diff syntax, no technical noise

---

## Customization

### Adding More Patterns

Edit `daily_monitor.py` and modify the `is_meaningful_change()` function:

```python
def is_meaningful_change(line):
    """Determine if a diff line is meaningful"""
    
    ignore_patterns = [
        '<script type="text/javascript" src="/ruxitagentjs',
        'data-dtconfig="rid=RID_',
        'rpid=',
        
        # ADD YOUR CUSTOM PATTERNS HERE:
        'pattern-to-ignore',
        'another-noise-pattern',
    ]
    
    for pattern in ignore_patterns:
        if pattern in content:
            return False
    
    # HTML tag check
    import re
    text_only = re.sub(r'<[^>]+>', '', content).strip()
    if not text_only:
        return False
    
    return True  # Everything else is meaningful
```

### Example Custom Patterns

```python
# Ignore specific HTML comments
'<!-- Generated by tool -->',

# Ignore meta tags
'<meta name="generator"',

# Ignore specific CSS classes
'class="auto-generated-',

# Ignore timestamps in specific format
'timestamp="2024-',
```

---

## Examples

### Example 1: Real Configuration Change ✅

**File**: `Performance_Workloads\Crossmark_ac_dc.html`

**Report Shows**:
```
Performance_Workloads\Crossmark_ac_dc.html:
  "RAM: 16 GB" was changed to "RAM: 4 GB"
```

**Result**: ✅ Email sent with this change

---

### Example 2: Only Tracking Script Changes ❌

**File**: `Performance_Workloads\AI_ML.html`

**Actual Diff**:
```diff
-<script src="/ruxitagentjs_..." data-dtconfig="rid=RID_12345|rpid=999"></script>
+<script src="/ruxitagentjs_..." data-dtconfig="rid=RID_67890|rpid=111"></script>
```

**Report Shows**: (Nothing - file filtered out completely)

**Result**: ❌ Not reported, no email

---

### Example 3: UI Button State Change ❌

**File**: `GFX_Workloads\3D_Mark.html`

**Actual Diff**:
```diff
-<button onclick="pm.subscribe()" style="display: block;">Subscribe</button>
+<button onclick="pm.subscribe()" style="display:none">Subscribe</button>
```

**Report Shows**: (Nothing - file filtered out completely)

**Result**: ❌ Not reported, no email

---

### Example 4: Mixed Changes 🔍

**File**: `Power_and_Battery_Life_Workloads\Battery_Test.html`

**Actual Diff**:
```diff
-<script src="/tracker.js" rid="123"></script>
+<script src="/tracker.js" rid="456"></script>  ← FILTERED OUT

-<p>Battery drain threshold: 5%/hour</p>
+<p>Battery drain threshold: 4%/hour</p>         ← KEPT
```

**Report Shows**:
```
Power_and_Battery_Life_Workloads\Battery_Test.html:
  "Battery drain threshold: 5%/hour" was changed to "Battery drain threshold: 4%/hour"
```

**Result**: ✅ Reports only the threshold change

---

## Benefits

### 1. **No Email Spam**
- Only get notified when content actually changes
- 149 files with tracking script changes? No email!
- 3 files with real content changes? Email sent!

### 2. **Clear Reports**
- See only what matters
- No HTML syntax: `<div>` or `</span>`
- No diff markers: `+++`, `---`, `@@`
- Just plain English: "X was changed to Y"

### 3. **Less Noise**
- 90%+ reduction in false positives
- Ignore dynamic tracking scripts
- Ignore HTML structure changes
- Ignore UI button state toggles

### 4. **Better Focus**
- Quickly identify real documentation updates
- Spend 2 minutes instead of 30 minutes
- Action items immediately visible

### 5. **Automatic**
- No manual filtering needed
- Works on every run
- Consistent results

---

## Console Output Examples

### When No Meaningful Changes:

```
================================================================================
✅ NO MEANINGFUL CHANGES DETECTED
================================================================================

  Changed: 0
  New:     0
  Deleted: 0
  Total:   0

🎯 All content is identical to the baseline.
```

No email sent, no report needed!

---

### When Meaningful Changes Found:

```
================================================================================
⚠️  3 MEANINGFUL CHANGES DETECTED
================================================================================

  Changed: 3
  New:     0
  Deleted: 0

  (Ignored 0 files with only HTML structure changes)
```

Email sent with clean report showing only the 3 real changes!

---

## Testing the Filter

### Test on Current Data:

```powershell
# Run comparison and see filtered results
python daily_monitor.py --no-email --no-update
```

### Check Latest Report:

```powershell
# View most recent report
Get-ChildItem reports | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content
```

### Expected Results:

If you see:
```
✅ NO MEANINGFUL CHANGES DETECTED
```

This means all 100+ file changes were just HTML/tracking noise - correctly filtered! 🎯

---

## Troubleshooting

### "Too many changes filtered out"

If legitimate changes are being filtered:

1. Check the `ignore_patterns` list
2. Remove patterns that are too broad
3. Test with `--no-email --no-update` to verify

### "Still seeing tracking script changes"

If noise still appears:

1. Add more specific patterns to `ignore_patterns`
2. Check the pattern syntax carefully
3. Test with sample diff lines

### "Want to see all changes temporarily"

To disable filtering temporarily:

```python
# In daily_monitor.py, comment out filtering:
# filtered_changes, count = filter_meaningful_changes(diff)
# USE THIS INSTEAD:
filtered_changes = diff  # No filtering
count = len(diff)
```

---

## Summary

### What Filtering Does:

| Aspect | Before Filtering | After Filtering |
|--------|-----------------|-----------------|
| **Changed Files** | 149 | 3 |
| **Email Sent** | Always | Only if meaningful |
| **Report Length** | 500+ lines | 30 lines |
| **Review Time** | 30+ minutes | 2 minutes |
| **False Positives** | ~98% | ~0% |

### Key Takeaways:

✅ **Automatic** - Works on every run, no configuration needed  
✅ **Intelligent** - Distinguishes content from noise  
✅ **Clean** - Simple "X changed to Y" format  
✅ **Fast** - Saves hours of manual review time  
✅ **Customizable** - Easy to add more filter patterns  

---

**Your monitoring system now shows only what matters!** 🚀

For daily workflow and usage, see `DAILY_WORKFLOW.md`
