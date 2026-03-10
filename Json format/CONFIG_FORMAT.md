# Screen Recorder Configuration Format

This document describes the JSON configuration format for the Screen Recorder application.

## Overview

The screen recorder uses a JSON configuration file to store all recording settings. This eliminates the need for long command-line arguments and makes it easy to switch between different recording configurations.

## Configuration File Location

- **Default**: `config.json` in the same directory as the script
- **Custom**: Specify a different config file using `-c` or `--config` flag

```bash
python screen_recorder.py start -c my_custom_config.json
```

## JSON Structure

The configuration file is a JSON object with the following properties:

```json
{
  "mode": "continuous",
  "duration": 30,
  "interval": 300,
  "fps": 20,
  "save_mode": "single",
  "output_dir": "recordings"
}
```

## Configuration Parameters

### `mode` (string, required)
**Description**: Recording mode  
**Values**: 
- `"continuous"` - Records continuously until stopped
- `"interval"` - Records in segments at regular intervals

**Example**:
```json
"mode": "continuous"
```

---

### `duration` (integer, optional)
**Description**: Duration of each recording segment in seconds  
**Used in**: Interval mode only  
**Default**: `30`  
**Range**: Must be positive (> 0)  
**Note**: This is the actual recording time per segment

**Example**:
```json
"duration": 30
```

---

### `interval` (integer, optional)
**Description**: Total cycle time from start of one recording to start of the next, in seconds  
**Used in**: Interval mode only  
**Default**: `300`  
**Range**: Must be positive (> 0)  
**Calculation**: `interval = recording duration + wait time`

**Example**:
```json
"interval": 300
```

**Note**: If `duration` is 30 and `interval` is 300, the recorder will:
1. Record for 30 seconds
2. Wait for 270 seconds (300 - 30)
3. Repeat

---

### `fps` (integer, optional)
**Description**: Frames per second for video recording  
**Default**: `20`  
**Range**: Must be positive (> 0)  
**Typical values**:
- `15-20`: Good for general recording, smaller file sizes
- `24-25`: Standard video frame rate
- `30`: Smooth video, better for presentations
- `60`: Very smooth, large file sizes

**Example**:
```json
"fps": 20
```

---

### `save_mode` (string, optional)
**Description**: How to save recordings in interval mode  
**Used in**: Interval mode only  
**Default**: `"single"`  
**Values**:
- `"single"` - All segments saved in one continuous file
- `"multiple"` - Each segment saved as a separate file

**Example**:
```json
"save_mode": "single"
```

---

### `output_dir` (string, optional)
**Description**: Directory where recordings will be saved  
**Default**: `"recordings"`  
**Note**: Directory will be created automatically if it doesn't exist

**Example**:
```json
"output_dir": "recordings"
```

## Configuration Examples

### Example 1: Continuous Recording (Default)

Perfect for recording meetings, presentations, or long sessions.

**File**: `config_continuous.json`
```json
{
  "mode": "continuous",
  "fps": 20,
  "save_mode": "single",
  "output_dir": "recordings"
}
```

**Usage**:
```bash
python screen_recorder.py start -c config_continuous.json
```

**Behavior**:
- Records continuously until you send stop command
- Creates one video file
- 20 FPS recording

---

### Example 2: Interval Recording - Single File

Good for monitoring activities throughout the day with all segments in one file.

**File**: `config_interval_single.json`
```json
{
  "mode": "interval",
  "duration": 30,
  "interval": 300,
  "fps": 20,
  "save_mode": "single",
  "output_dir": "recordings"
}
```

**Usage**:
```bash
python screen_recorder.py start -c config_interval_single.json
```

**Behavior**:
- Records 30 seconds
- Waits 270 seconds (300 - 30 = 270)
- Repeats until stopped
- All segments saved in one file

---

### Example 3: Interval Recording - Multiple Files

Good when you need individual segment files for processing or selective deletion.

**File**: `config_interval_multiple.json`
```json
{
  "mode": "interval",
  "duration": 30,
  "interval": 300,
  "fps": 20,
  "save_mode": "multiple",
  "output_dir": "recordings"
}
```

**Usage**:
```bash
python screen_recorder.py start -c config_interval_multiple.json
```

**Behavior**:
- Records 30 seconds
- Waits 270 seconds
- Repeats until stopped
- Each segment saved as separate file (seg001, seg002, etc.)

---

### Example 4: High-Quality Recording

For important presentations or meetings requiring smooth video.

**File**: `config_high_quality.json`
```json
{
  "mode": "continuous",
  "fps": 30,
  "save_mode": "single",
  "output_dir": "important_recordings"
}
```

**Usage**:
```bash
python screen_recorder.py start -c config_high_quality.json
```

**Behavior**:
- Records continuously at 30 FPS
- Smoother video but larger file size
- Saved in "important_recordings" folder

---

### Example 5: Work Day Monitoring

Record 1 minute every 10 minutes throughout the workday.

**File**: `config_workday.json`
```json
{
  "mode": "interval",
  "duration": 60,
  "interval": 600,
  "fps": 15,
  "save_mode": "single",
  "output_dir": "workday_recordings"
}
```

**Usage**:
```bash
python screen_recorder.py start -c config_workday.json
```

**Behavior**:
- Records 60 seconds (1 minute)
- Waits 540 seconds (9 minutes)
- 15 FPS (smaller file size)
- All recordings in one file per day

---

### Example 6: Hourly Snapshots

Capture 2 minutes every hour for long-term monitoring.

**File**: `config_hourly.json`
```json
{
  "mode": "interval",
  "duration": 120,
  "interval": 3600,
  "fps": 20,
  "save_mode": "multiple",
  "output_dir": "hourly_captures"
}
```

**Usage**:
```bash
python screen_recorder.py start -c config_hourly.json
```

**Behavior**:
- Records 120 seconds (2 minutes)
- Waits 3480 seconds (58 minutes)
- Each hour saved as separate file
- 20 FPS standard quality

## Validation Rules

The screen recorder validates the configuration when starting:

1. **`mode`**: Must be either `"continuous"` or `"interval"`
2. **`fps`**: Must be a positive integer (> 0)
3. **`duration`**: Must be a positive integer when using interval mode
4. **`interval`**: Must be a positive integer when using interval mode
5. **`save_mode`**: Must be either `"single"` or `"multiple"`

### Warning Conditions

If `duration > interval` in interval mode:
- You'll receive a warning
- Recordings will start immediately after the previous one finishes
- No wait time between recordings

## Creating Your Own Configuration

1. **Copy an existing config file**:
   ```bash
   cp config.json my_config.json
   ```

2. **Edit the JSON file** with your preferred settings

3. **Validate JSON syntax** (use a JSON validator or editor)

4. **Test the configuration**:
   ```bash
   python screen_recorder.py start -c my_config.json
   ```

5. **Stop after testing**:
   ```bash
   python screen_recorder.py stop
   ```

## Default Configuration

If no config file is found, the recorder creates a default `config.json`:

```json
{
  "mode": "continuous",
  "duration": 30,
  "interval": 300,
  "fps": 20,
  "save_mode": "single",
  "output_dir": "recordings"
}
```

## Tips and Best Practices

### File Size Considerations

Approximate file sizes (1920x1080 resolution):
- **15 FPS**: ~8-10 MB per minute
- **20 FPS**: ~10-15 MB per minute
- **30 FPS**: ~15-20 MB per minute

### Interval Mode Planning

Calculate your wait time:
```
Wait Time = interval - duration
```

Examples:
- Record 30s every 5 min: `interval=300, duration=30` → wait 270s
- Record 1 min every 10 min: `interval=600, duration=60` → wait 540s
- Record 2 min every hour: `interval=3600, duration=120` → wait 3480s

### Single File vs Multiple Files

**Use Single File when**:
- You want one cohesive recording
- Easier file management
- Creating time-lapse videos
- Monitoring full day activities

**Use Multiple Files when**:
- Need to access individual segments
- Want to delete specific recordings
- Processing segments separately
- Analyzing specific time periods

### Output Directory Organization

Organize recordings by purpose:
```json
"output_dir": "meetings"
"output_dir": "tutorials"
"output_dir": "monitoring/daily"
"output_dir": "presentations"
```

## Troubleshooting

### Config File Not Found
- Check file exists in the same directory as script
- Use absolute path: `python screen_recorder.py start -c "C:/path/to/config.json"`
- Verify filename spelling (case-sensitive on Linux/Mac)

### Invalid JSON Syntax
- Use a JSON validator (jsonlint.com)
- Check for missing commas, quotes, or brackets
- Ensure no trailing commas in JSON objects

### Settings Not Applied
- Verify you're using the correct config file
- Check for typos in parameter names
- Ensure values are in correct format (string vs integer)

## Command Line Reference

```bash
# Start with default config.json
python screen_recorder.py start

# Start with custom filename
python screen_recorder.py start my_recording

# Start with custom config file
python screen_recorder.py start -c my_config.json

# Start with both custom filename and config
python screen_recorder.py start my_recording -c my_config.json

# Stop recording
python screen_recorder.py stop

# Check status
python screen_recorder.py status
```

## Version Compatibility

This configuration format is compatible with:
- Screen Recorder v2.0+
- Python 3.6+
- All operating systems (Windows, macOS, Linux)

---

**Last Updated**: February 23, 2026  
**Format Version**: 2.0
