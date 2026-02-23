# Screen Recorder

A Python-based screen recording utility that supports both continuous and interval recording modes. Perfect for recording meetings, tutorials, monitoring activities, or any screen capture needs.

## Features

- **Two Recording Modes:**
  - 🎥 **Continuous Mode**: Records until stopped, creating a single video file
  - ⏱️ **Interval Mode**: Records segments at regular intervals
    - **Single File Mode** (default): All segments saved in one file
    - **Multiple Files Mode**: Each segment saved as separate file
  
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

### Example 5: Check If Recording is Active
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

## Technical Details

- **Video Codec:** MP4V (H.264 compatible)
- **Color Format:** BGR (OpenCV standard)
- **Screen Capture:** MSS library (fast, cross-platform)
- **Process Management:** PID file-based control
- **Output Format:** MP4 container

## License

This project is provided as-is for personal and educational use.

## Contributing

Feel free to submit issues, feature requests, or improvements!

---

**Note:** Screen recording may be subject to privacy laws and regulations. Always ensure you have permission to record screen content, especially in professional or public settings.
