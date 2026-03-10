# Camera Recorder

A Python-based camera/webcam recording utility that supports both continuous and interval recording modes. Perfect for recording video calls, creating tutorials, monitoring, or any camera capture needs.

## Features

- **🎥 Camera Recording**: Records from any connected webcam or camera
- **Two Recording Modes:**
  - **Continuous Mode**: Records until stopped, creating a single video file
  - **Interval Mode**: Records segments at regular intervals
  
- **Flexible Control:**
  - Start, stop, and check status from command line
  - Safe stop mechanism
  - Process management with PID file tracking
  
- **Customizable Settings:**
  - Multiple resolution options (480p, 720p, 1080p, native)
  - Adjustable FPS
  - Custom filenames or auto-generated timestamps
  - Multiple camera support
  
- **Real-time Feedback:**
  - Live status updates during recording
  - Frame count and duration tracking
  - File size information

## Requirements

- Python 3.6+
- OpenCV (cv2)
- numpy

## Installation

1. Install required packages:
```bash
pip install opencv-python numpy
```

2. Test your camera:
```bash
python camera_recorder.py list
```

## Usage

### List Available Cameras

```bash
python camera_recorder.py list
```

Output:
```
Detecting available cameras...
============================================================
Camera 0: Available
  Resolution: 1280x720
  FPS: 30

Camera 1: Available
  Resolution: 1920x1080
  FPS: 30

Found 2 camera(s): [0, 1]
============================================================
```

### Basic Commands

#### Start Recording (Continuous Mode)
```bash
# Auto-generated filename, default camera (0)
python camera_recorder.py start

# Custom filename
python camera_recorder.py start my_video

# Use camera 1 instead of default
python camera_recorder.py start --camera 1

# Record in 1080p
python camera_recorder.py start --resolution 1080p

# Custom FPS
python camera_recorder.py start --fps 60
```

#### Start Recording (Interval Mode)
```bash
# Record 30 seconds every minute
python camera_recorder.py start --mode interval --duration 30 --interval 60

# Record 45 seconds every 2 minutes at 15 FPS
python camera_recorder.py start --mode interval --duration 45 --interval 120 --fps 15

# Interval with multiple files
python camera_recorder.py start --mode interval --duration 30 --interval 60 --save-mode multiple
```

#### Stop Recording
```bash
python camera_recorder.py stop
```

#### Check Status
```bash
python camera_recorder.py status
```

### Command Reference

```
python camera_recorder.py [command] [filename] [options]

Commands:
  start     Start the camera recorder (default)
  stop      Stop the running recorder
  status    Check if recorder is running
  list      List available cameras

Arguments:
  filename  Base filename for recording (optional, auto-generated if not provided)

Options:
  -c, --camera INDEX
            Camera device index (default: 0)
  
  -m, --mode {continuous,interval}
            Recording mode (default: continuous)
  
  -d, --duration SECONDS
            Duration of each recording segment in seconds (interval mode only)
            (default: 30)
  
  -i, --interval SECONDS
            Time between recording starts in seconds (interval mode only)
            (default: 60)
  
  -s, --save-mode {single,multiple}
            Save mode for interval recording (default: single)
  
  -f, --fps FPS
            Frames per second (default: 30)
  
  -r, --resolution {480p,720p,1080p,native}
            Video resolution (default: 720p)
  
  -h, --help
            Show help message and exit
```

## Resolution Options

| Resolution | Dimensions | Use Case |
|------------|------------|----------|
| **480p** | 640x480 | Low quality, small file size |
| **720p** | 1280x720 | Good balance (default) |
| **1080p** | 1920x1080 | High quality, large file size |
| **native** | Camera's native | Use camera's default resolution |

## Recording Modes

### Continuous Mode (Default)

Records continuously until you send a stop signal.

**Example:**
```bash
python camera_recorder.py start interview
```

Output: `camera_recordings/interview_20260225_143025.mp4`

### Interval Mode

Records segments at regular intervals.

**Single File Mode (default):**
```bash
python camera_recorder.py start daily_vlog --mode interval --duration 60 --interval 600
```

All segments in one file: `camera_recordings/daily_vlog_20260225_143000.mp4`

**Multiple Files Mode:**
```bash
python camera_recorder.py start monitoring --mode interval --duration 30 --interval 300 --save-mode multiple
```

Separate files:
```
camera_recordings/monitoring_seg001_20260225_143000.mp4
camera_recordings/monitoring_seg002_20260225_143500.mp4
...
```

## Output

All recordings are saved in the `camera_recordings/` directory (automatically created).

### File Naming

**Continuous Mode:**
- Format: `{filename}_{timestamp}.mp4`
- Example: `meeting_20260225_143025.mp4`

**Interval Mode (Single File):**
- Format: `{filename}_{timestamp}.mp4`

**Interval Mode (Multiple Files):**
- Format: `{filename}_seg{number}_{timestamp}.mp4`

## Examples

### Example 1: Quick Video Recording
```bash
# Start recording with default camera
python camera_recorder.py start

# Stop when done (in another terminal)
python camera_recorder.py stop
```

### Example 2: High-Quality Meeting Recording
```bash
# Record at 1080p, 30 FPS
python camera_recorder.py start client_meeting --resolution 1080p --fps 30

# Stop when meeting ends
python camera_recorder.py stop
```

### Example 3: Use External Webcam
```bash
# List cameras first
python camera_recorder.py list

# Use camera 1 (external webcam)
python camera_recorder.py start presentation --camera 1 --resolution 1080p
```

### Example 4: Time-Lapse Recording
```bash
# Record 5 seconds every 5 minutes (for time-lapse effect)
python camera_recorder.py start timelapse --mode interval --duration 5 --interval 300 --fps 15
```

### Example 5: Security Monitoring
```bash
# Record 1 minute every 10 minutes
python camera_recorder.py start security --mode interval --duration 60 --interval 600 --save-mode multiple
```

## Tips

1. **Camera Selection:**
   - Camera 0 is usually the built-in webcam
   - Camera 1+ are external USB cameras
   - Use `list` command to find available cameras

2. **Resolution:**
   - Not all cameras support all resolutions
   - If resolution fails, camera uses its native resolution
   - Use `native` to let camera decide

3. **FPS Settings:**
   - 15-20 FPS: Good for video calls, smaller files
   - 25-30 FPS: Standard video (recommended)
   - 60 FPS: Smooth motion (large files)

4. **File Sizes (at 720p):**
   - 15 FPS: ~5-8 MB per minute
   - 30 FPS: ~10-15 MB per minute
   - 60 FPS: ~20-30 MB per minute

5. **Lighting:**
   - Good lighting improves video quality
   - Avoid backlighting (window behind you)
   - Use front lighting for best results

## Troubleshooting

### "Cannot open camera" Error
```bash
# Check if camera is available
python camera_recorder.py list

# Try different camera index
python camera_recorder.py start --camera 1
```

### Camera Already in Use
- Close other applications using the camera
- Only one application can use the camera at a time

### Poor Video Quality
```bash
# Increase resolution
python camera_recorder.py start --resolution 1080p

# Increase FPS
python camera_recorder.py start --fps 30
```

### Import Errors
Make sure dependencies are installed:
```bash
pip install opencv-python numpy
```

## Comparing with Screen Recorder

| Feature | Screen Recorder | Camera Recorder |
|---------|----------------|-----------------|
| **Source** | Screen capture | Webcam/Camera |
| **Library** | MSS (fast) | OpenCV |
| **Default FPS** | 20 | 30 |
| **Resolution** | Screen size | Camera resolution |
| **Output Dir** | `recordings/` | `camera_recordings/` |
| **Use Case** | Tutorials, demos | Video calls, vlogs |

## Using Both Together

You can run both recorders simultaneously to capture screen + camera:

```bash
# Terminal 1: Record screen
python screen_recorder.py start demo_screen

# Terminal 2: Record camera
python camera_recorder.py start demo_camera

# Stop both
python screen_recorder.py stop
python camera_recorder.py stop
```

Then merge the videos using video editing software!

## Technical Details

- **Video Codec:** MP4V (H.264 compatible)
- **Color Format:** BGR (OpenCV standard)
- **Camera Access:** OpenCV VideoCapture
- **Process Management:** PID file-based control
- **Output Format:** MP4 container

## Privacy Note

⚠️ **Important:** Always inform people when recording with a camera. Camera recording may be subject to privacy laws and regulations. Ensure you have permission to record, especially in meetings or public spaces.

## License

This project is provided as-is for personal and educational use.

---

**Version**: 1.0  
**Last Updated**: February 25, 2026
