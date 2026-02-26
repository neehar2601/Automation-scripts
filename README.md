# Screen Recorder

A Python-based screen recording utility that supports both continuous and interval recording modes. Perfect for recording meetings, tutorials, monitoring activities, or any screen capture needs.

## Features

- **Two Recording Modes:**
  - 🎥 **Continuous Mode**: Records until stopped, creating a single video file
  - ⏱️ **Interval Mode**: Records segments at regular intervals
    - **Single File Mode** (default): All segments saved in one file
    - **Multiple Files Mode**: Each segment saved as separate file
  
- **Camera Integration:**
  - 📷 **Launch Camera App**: Automatically opens Windows Camera app before recording
  - Auto-maximizes window with taskbar visible
  - Perfect for recording with camera feed visible
  
- **Flexible Control:**
  - Start, stop, and check status from command line
  - Safe stop mechanism that ensures recordings are properly saved
  - Process management with PID file tracking
  
- **Customizable Settings:**
  - Adjustable FPS (frames per second)
  - Custom filenames or auto-generated timestamps
  - Configurable recording duration and intervals
  
- **Real-time Feedback:**
  - Live status updates during recording
  - Frame count and duration tracking
  - File size information after recording

## Requirements

- Python 3.6+
- OpenCV (cv2)
- mss (screen capture)
- numpy

## Installation

1. Clone or download this repository

2. Install required packages:
```bash
pip install opencv-python mss numpy
```

## Usage

### Basic Commands

#### Start Recording (Continuous Mode)
```bash
# Auto-generated filename
python screen_recorder.py start

# Custom filename
python screen_recorder.py start my_recording

# With camera app (launches Windows Camera in full screen)
python screen_recorder.py start meeting --camera

# Custom FPS
python screen_recorder.py start presentation --fps 30
```

#### Start Recording (Interval Mode)
```bash
# Record 30 seconds every 5 minutes (270s wait) - Single file (default)
python screen_recorder.py start work_session --mode interval --duration 30 --interval 300

# Record 30 seconds every 5 minutes - Multiple files
python screen_recorder.py start work_session --mode interval --duration 30 --interval 300 --save-mode multiple

# Record 45 seconds every 2 minutes (75s wait) - Single file
python screen_recorder.py start monitoring --mode interval --duration 45 --interval 120 --fps 15

# Interval mode with camera app
python screen_recorder.py start training --mode interval --duration 60 --interval 300 --camera
```

#### Stop Recording
```bash
python screen_recorder.py stop
```

#### Check Status
```bash
python screen_recorder.py status
```

### Command Reference

```
python screen_recorder.py [command] [filename] [options]

Commands:
  start     Start the screen recorder (default)
  stop      Stop the running recorder
  status    Check if recorder is running

Arguments:
  filename  Base filename for recording (optional, auto-generated if not provided)

Options:
  -m, --mode {continuous,interval}
            Recording mode (default: continuous)
  
  -d, --duration SECONDS
            Duration of each recording segment in seconds (interval mode only)
            (default: 30)
  
  -i, --interval SECONDS
            TOTAL time from start of one recording to start of next (interval mode only)
            Interval = recording time + wait time (default: 60)
  
  -s, --save-mode {single,multiple}
            For interval mode: 'single' saves all segments in one file,
            'multiple' creates separate files per segment (default: single)
  
  -f, --fps FPS
            Frames per second for recording (default: 20)
  
  -c, --camera
            Launch Windows Camera app and automatically maximize it before recording
            Camera window will be maximized (not full screen) with taskbar visible
            Uses PowerShell and Win32 API for automatic window maximization
            Gives you 2 seconds to adjust the window if auto-maximize fails
  
  -h, --help
            Show help message and exit
```

## Recording Modes

### Continuous Mode (Default)

Records continuously until you send a stop signal, creating a **single video file**.

**Use cases:**
- Recording entire meetings or presentations
- Capturing long tutorials
- General screen recording sessions

**Example:**
```bash
python screen_recorder.py start meeting_recording
```

Output: `recordings/meeting_recording_20260220_143025.mp4`

### Interval Mode

Records segments at regular intervals with configurable wait times between recordings.

**Two Save Modes:**

#### Single File Mode (Default)
All segments are saved to **one video file**.

**Use cases:**
- Monitoring activity throughout the day in one file
- Creating time-lapse videos with gaps
- Keeping all recordings organized in single file

**Example:**
```bash
python screen_recorder.py start daily_work --mode interval --duration 30 --interval 300
```

This records 30 seconds, waits 270 seconds (300 - 30 = 270), then repeats.

Output: `recordings/daily_work_20260220_143000.mp4` (one file with all segments)

#### Multiple Files Mode
Each segment is saved as a **separate video file**.

**Use cases:**
- Need to access individual recording segments
- Want to delete/keep specific segments
- Processing segments separately

**Example:**
```bash
python screen_recorder.py start daily_work --mode interval --duration 30 --interval 300 --save-mode multiple
```

Output:
```
recordings/daily_work_seg001_20260220_143000.mp4
recordings/daily_work_seg002_20260220_143500.mp4
recordings/daily_work_seg003_20260220_144000.mp4
...
```

**Understanding Interval:**
- `--interval` is the TOTAL cycle time (recording + waiting)
- Wait time = interval - duration
- Example: `--duration 30 --interval 300` = Record 30s, wait 270s, repeat

## Camera Integration

The `--camera` flag launches the Windows Camera app before recording starts. This is useful for:

**Use Cases:**
- Recording presentations with your camera visible
- Video tutorials showing both screen and presenter
- Remote meetings where camera feed is important
- Recording training sessions with presenter overlay

**How it works:**
1. Launches Windows Camera app using system URI
2. Waits 3 seconds for the camera app to fully load
3. **Automatically attempts to maximize the camera window** using PowerShell and Win32 API
   - Window is maximized (not full screen) - taskbar remains visible
   - Uses `ShowWindow` API with `SW_MAXIMIZE` flag
   - Brings camera window to foreground
4. Gives you 2 additional seconds to adjust if needed
5. Starts recording the entire screen (including camera window)
6. Camera feed is captured as part of the screen recording

**Success Indicators:**
- `[INFO] Camera window maximized (taskbar visible)` - Auto-maximize succeeded
- `[INFO] Camera window not found yet, please manually maximize` - Camera app still loading
- `[INFO] Please manually maximize the camera window` - Auto-maximize unavailable
- `[INFO] Auto-maximize failed` - PowerShell command encountered an error

**Example:**
```bash
# Record meeting with camera
python screen_recorder.py start team_meeting --camera

# Interval recording with camera
python screen_recorder.py start training --mode interval --duration 60 --interval 300 --camera

# High quality recording with camera at 30 FPS
python screen_recorder.py start presentation --camera --fps 30
```

**Tips:**
- **Auto-maximize works in most cases** - camera window automatically fills screen with taskbar visible
- If auto-maximize fails, you have 2 seconds to click the maximize button (□) manually
- Camera window uses standard Windows maximize (taskbar always visible, not full screen)
- You can resize/move the camera window during recording if needed
- The camera app stays open after recording stops (close it manually if desired)
- **Positioning:** Camera app launches in default position, then maximizes automatically
- Works on Windows 10 and Windows 11

**Troubleshooting:**
- If camera doesn't maximize automatically, the window may be loading slowly - manually click maximize (□)
- If you see "Camera window not found", the app may need more time to launch
- Camera app must be installed (comes with Windows 10/11 by default)
- Requires PowerShell for auto-maximize feature

## Output

All recordings are saved in the `recordings/` directory (automatically created if it doesn't exist).

### File Naming

**Continuous Mode:**
- Format: `{filename}_{timestamp}.mp4`
- Example: `meeting_recording_20260220_143025.mp4`

**Interval Mode (Single File):**
- Format: `{filename}_{timestamp}.mp4`
- Example: `daily_work_20260220_143025.mp4`

**Interval Mode (Multiple Files):**
- Format: `{filename}_seg{number}_{timestamp}.mp4`
- Example: `work_session_seg001_20260220_143000.mp4`

### Recording Information

After stopping, you'll see:
- Total duration (HH:MM:SS format)
- Total frames recorded
- File size
- Full path to saved file(s)

## Examples

### Example 1: Quick Recording
```bash
# Start recording with default settings
python screen_recorder.py start

# In another terminal, stop when done
python screen_recorder.py stop
```

### Example 2: High-Quality Meeting Recording
```bash
# Record at 30 FPS for better quality
python screen_recorder.py start client_meeting --fps 30

# Stop from another terminal when meeting ends
python screen_recorder.py stop
```

### Example 3: Work Day Monitoring (Single File)
```bash
# Record 1 minute every 10 minutes - all in one file
python screen_recorder.py start workday_monitor --mode interval --duration 60 --interval 600 --fps 15

# Stop at end of day
python screen_recorder.py stop
```

### Example 4: Hourly Captures (Multiple Files)
```bash
# Record 2 minutes every hour - separate files for each segment
python screen_recorder.py start hourly_capture --mode interval --duration 120 --interval 3600 --save-mode multiple

# Stop when done
python screen_recorder.py stop
```

### Example 5: Recording with Camera (Presentation Mode)
```bash
# Record with camera visible - camera window auto-maximizes
python screen_recorder.py start presentation --camera --fps 30

# Stop when done
python screen_recorder.py stop
```

### Example 6: Interval Recording with Camera
```bash
# Record 60-second clips every 5 minutes with camera
python screen_recorder.py start training_session --mode interval --duration 60 --interval 300 --camera

# Stop when training complete
python screen_recorder.py stop
```

### Example 7: Check If Recording is Active
```bash
python screen_recorder.py status
```

Output:
```
✅ Recorder is RUNNING (PID: 12345)
```
or
```
❌ Recorder is NOT running
```

## Tips

1. **FPS Settings:**
   - 15-20 FPS: Good for general recording, smaller file sizes
   - 25-30 FPS: Smoother video, better for presentations
   - Higher FPS = larger file sizes

2. **Interval Mode:**
   - `--interval` is the TOTAL cycle time (record + wait)
   - Wait time is automatically calculated: `interval - duration`
   - Example: `--duration 30 --interval 300` means record 30s, wait 270s
   - If `duration` > `interval`, recordings will start immediately after previous one finishes
   - **Single file mode** (default): All segments in one file, easier to manage
   - **Multiple files mode**: Separate files per segment, useful for selective processing

3. **Background Recording:**
   - The recorder runs in the current terminal
   - Use a separate terminal to send stop commands
   - Or use Ctrl+C to stop (but using `stop` command is cleaner)

4. **File Sizes:**
   - Approximate: 20 FPS @ 1920x1080 ≈ 10-15 MB per minute
   - Varies based on screen content and compression
   - Interval mode (single file): Only recorded segments count toward file size, not wait time

5. **Camera Integration:**
   - Auto-maximize uses PowerShell and Win32 API
   - Camera window maximizes to fill screen but keeps taskbar visible
   - If auto-maximize doesn't work, manually click the maximize button (□) within 2 seconds
   - Camera positioning is automatic - no need to press F11 or use keyboard shortcuts

## Troubleshooting

### "Recorder is already running" Error
Run the stop command first:
```bash
python screen_recorder.py stop
```

### Stale PID File
If the status command shows a stale PID file, it will automatically clean it up. Then try starting again.

### Import Errors
Make sure all dependencies are installed:
```bash
pip install opencv-python mss numpy
```

### Screen Not Captured
- Ensure you have permissions to capture the screen
- On some systems, you may need to grant screen recording permissions in system settings

### Camera Not Maximizing Automatically
- **Symptom:** Camera window opens but doesn't maximize
- **Solutions:**
  1. Manually click the maximize button (□) within 2 seconds
  2. Check if Windows Camera app is installed (comes with Windows 10/11 by default)
  3. Ensure PowerShell execution is not blocked by security policies
  4. Wait for camera to fully load before the maximize command runs
- **Note:** Recording will still work even if auto-maximize fails - just resize the window manually

### Camera App Timeout
- **Symptom:** "Auto-maximize timed out" message
- **Cause:** PowerShell command took longer than 8 seconds (rare)
- **Solution:** Manually maximize the camera window when recording starts

## Technical Details

- **Video Codec:** MP4V (H.264 compatible)
- **Color Format:** BGR (OpenCV standard)
- **Screen Capture:** MSS library (fast, cross-platform)
- **Process Management:** PID file-based control (`.screen_recorder.pid`)
- **Stop Signal:** File-based signal (`.screen_recorder.stop`)
- **Output Format:** MP4 container
- **Camera Integration:** 
  - Windows Camera app launched via `microsoft.windows.camera:` URI
  - Auto-maximize via PowerShell with Win32 `ShowWindow` API (SW_MAXIMIZE flag)
  - Window state: Maximized (not full screen) - taskbar remains visible
  - Timeout: 8 seconds for PowerShell command execution

## Version History

- **v1.3** (February 26, 2026)
  - Added `--camera` flag to launch Windows Camera app
  - Implemented automatic window maximization with PowerShell/Win32 API
  - Camera window maximizes with taskbar visible (not full screen)
  - Updated timing: 3s camera load + 2s adjustment time
  
- **v1.2** (February 25, 2026)
  - Added interval mode with single/multiple file options
  - JSON configuration file support
  - PowerShell remote control module
  - Continuous recording automation scripts

- **v1.1** (February 20, 2026)
  - Added interval recording mode
  - Improved status reporting
  - File size display

- **v1.0** (Initial Release)
  - Basic continuous recording
  - Start/stop/status commands
  - FPS customization

## License

This project is provided as-is for personal and educational use.

## Contributing

Feel free to submit issues, feature requests, or improvements!

---

**Note:** Screen recording may be subject to privacy laws and regulations. Always ensure you have permission to record screen content, especially in professional or public settings.
