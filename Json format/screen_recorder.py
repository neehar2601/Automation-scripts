import cv2
import numpy as np
from mss import mss
import time
from datetime import datetime
import argparse
import os
import sys
import json

class ScreenRecorder:
    def __init__(self, base_filename, mode='continuous', record_duration=30, interval=60, 
                 fps=20, save_mode='single', output_dir='recordings'):
        """
        Initialize the screen recorder.
        
        Args:
            base_filename: Base name for output files
            mode: 'continuous' or 'interval'
            record_duration: Duration of each recording segment in seconds (for interval mode)
            interval: Time between recording starts in seconds (for interval mode)
            fps: Frames per second for recording
            save_mode: 'single' (one file) or 'multiple' (separate files per segment)
            output_dir: Directory to save recordings
        """
        self.base_filename = base_filename
        self.mode = mode
        self.record_duration = record_duration
        self.interval = interval
        self.fps = fps
        self.save_mode = save_mode
        self.output_dir = output_dir
        self.is_running = False
        self.sct = mss()
        self.out = None
        self.filename = None
        self.frame_count = 0
        self.total_frames = 0
        self.start_time = None
        self.segment_count = 0
        
        # Control files
        self.pid_file = ".screen_recorder.pid"
        self.stop_file = ".screen_recorder.stop"
        
        # Get screen dimensions
        monitor = self.sct.monitors[1]  # Primary monitor
        self.screen_width = monitor["width"]
        self.screen_height = monitor["height"]
        
        # Create output directory if it doesn't exist
        os.makedirs(self.output_dir, exist_ok=True)
        
        print(f"Screen Resolution: {self.screen_width}x{self.screen_height}")
        print(f"Recording Mode: {self.mode.upper()}")
        if self.mode == 'interval':
            print(f"Recording Duration: {self.record_duration} seconds")
            print(f"Interval: {self.interval} seconds")
            print(f"Wait Time Between Recordings: {self.interval - self.record_duration} seconds")
            print(f"Save Mode: {'SINGLE FILE' if self.save_mode == 'single' else 'MULTIPLE FILES'}")
        print(f"FPS: {self.fps}")
    
    def format_duration(self, seconds):
        """Format duration in seconds to HH:MM:SS format."""
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        secs = int(seconds % 60)
        return f"{hours:02d}:{minutes:02d}:{secs:02d}"
    
    def get_file_size(self, filename):
        """Get human-readable file size."""
        if not os.path.exists(filename):
            return "Unknown"
        
        size_bytes = os.path.getsize(filename)
        
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.2f} TB"
    
    def record_continuous(self):
        """Record screen continuously until stop signal - SINGLE FILE."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.filename = os.path.join(self.output_dir, f"{self.base_filename}_{timestamp}.mp4")
        
        # Define the codec and create VideoWriter object
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        self.out = cv2.VideoWriter(self.filename, fourcc, self.fps, 
                                   (self.screen_width, self.screen_height))
        
        print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Recording started: {self.filename}")
        print("Recording in progress... (Use 'stop' command to end)")
        
        self.start_time = time.time()
        self.frame_count = 0
        last_status_time = time.time()
        
        try:
            while self.is_running:
                # Check for stop signal
                if os.path.exists(self.stop_file):
                    print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Stop signal received!")
                    break
                
                # Capture the screen
                img = self.sct.grab(self.sct.monitors[1])
                
                # Convert to numpy array and then to BGR format for OpenCV
                frame = np.array(img)
                frame = cv2.cvtColor(frame, cv2.COLOR_BGRA2BGR)
                
                # Write frame to video
                self.out.write(frame)
                self.frame_count += 1
                
                # Print status every 10 seconds
                current_time = time.time()
                if current_time - last_status_time >= 10:
                    elapsed = current_time - self.start_time
                    duration_str = self.format_duration(elapsed)
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Recording... Duration: {duration_str} | Frames: {self.frame_count}")
                    last_status_time = current_time
                
                # Control frame rate
                time.sleep(1 / self.fps)
                
        except Exception as e:
            print(f"Error during recording: {e}")
        finally:
            if self.out:
                self.out.release()
            
            total_duration = time.time() - self.start_time if self.start_time else 0
            duration_str = self.format_duration(total_duration)
            
            print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Recording stopped")
            print(f"{'='*60}")
            print(f"Recording saved: {self.filename}")
            print(f"Total Duration: {duration_str}")
            print(f"Total Frames: {self.frame_count}")
            print(f"File Size: {self.get_file_size(self.filename)}")
            print(f"{'='*60}")
    
    def record_segment_to_file(self, out, segment_num=None):
        """Record a single segment to the provided video writer."""
        segment_start = time.time()
        frame_count = 0
        target_frames = int(self.record_duration * self.fps)
        
        if segment_num:
            print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Recording segment {segment_num} for {self.record_duration} seconds...")
        
        try:
            while frame_count < target_frames:
                # Check for stop signal
                if os.path.exists(self.stop_file):
                    print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Stop signal received!")
                    self.is_running = False
                    break
                
                # Capture the screen
                img = self.sct.grab(self.sct.monitors[1])
                
                # Convert to numpy array and then to BGR format for OpenCV
                frame = np.array(img)
                frame = cv2.cvtColor(frame, cv2.COLOR_BGRA2BGR)
                
                # Write frame to video
                out.write(frame)
                frame_count += 1
                
                # Control frame rate
                elapsed = time.time() - segment_start
                expected_frames = int(elapsed * self.fps)
                if frame_count < expected_frames:
                    continue  # Skip sleep to catch up
                elif frame_count > expected_frames:
                    time.sleep((frame_count - expected_frames) / self.fps)
                
        except Exception as e:
            print(f"Error during recording: {e}")
        
        actual_duration = time.time() - segment_start
        return frame_count, actual_duration
    
    def record_interval_multiple_files(self):
        """Record in interval mode - separate files for each segment."""
        print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Interval recording started (Multiple Files)")
        print(f"Recording {self.record_duration}s, then waiting {self.interval - self.record_duration}s")
        print("Use 'stop' command to end recording\n")
        
        try:
            while self.is_running:
                # Check for stop signal before starting new recording
                if os.path.exists(self.stop_file):
                    print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Stop signal received!")
                    break
                
                self.segment_count += 1
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = os.path.join(self.output_dir, 
                                       f"{self.base_filename}_seg{self.segment_count:03d}_{timestamp}.mp4")
                
                # Create video writer for this segment
                fourcc = cv2.VideoWriter_fourcc(*'mp4v')
                out = cv2.VideoWriter(filename, fourcc, self.fps, 
                                     (self.screen_width, self.screen_height))
                
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Starting segment {self.segment_count}: {os.path.basename(filename)}")
                
                # Record segment
                frame_count, actual_duration = self.record_segment_to_file(out, self.segment_count)
                
                # Release video writer
                out.release()
                
                file_size = self.get_file_size(filename)
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Segment {self.segment_count} saved: {frame_count} frames | Duration: {actual_duration:.1f}s | Size: {file_size}")
                
                if not self.is_running:
                    break
                
                # Calculate and wait for next recording
                wait_time = self.interval - self.record_duration
                
                if wait_time > 0:
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Waiting {wait_time} seconds until next recording...")
                    
                    # Wait with periodic checks for stop signal
                    wait_start = time.time()
                    while time.time() - wait_start < wait_time and self.is_running:
                        if os.path.exists(self.stop_file):
                            print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Stop signal received!")
                            self.is_running = False
                            break
                        time.sleep(0.5)
                else:
                    print("Note: Starting next recording immediately (interval <= duration)")
                    
        except Exception as e:
            print(f"Error in interval recording: {e}")
        finally:
            print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Interval recording stopped")
            print(f"Total segments recorded: {self.segment_count}")
    
    def record_interval_single_file(self):
        """Record in interval mode - all segments in ONE file."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.filename = os.path.join(self.output_dir, f"{self.base_filename}_{timestamp}.mp4")
        
        # Create video writer that will be reused for all segments
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        self.out = cv2.VideoWriter(self.filename, fourcc, self.fps, 
                                   (self.screen_width, self.screen_height))
        
        print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Interval recording started (Single File)")
        print(f"Output file: {self.filename}")
        print(f"Recording {self.record_duration}s, then waiting {self.interval - self.record_duration}s")
        print("All segments will be saved to the same file")
        print("Use 'stop' command to end recording\n")
        
        self.start_time = time.time()
        
        try:
            while self.is_running:
                # Check for stop signal before starting new recording
                if os.path.exists(self.stop_file):
                    print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Stop signal received!")
                    break
                
                self.segment_count += 1
                
                # Record segment to the same file
                frame_count, actual_duration = self.record_segment_to_file(self.out, self.segment_count)
                self.total_frames += frame_count
                
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Segment {self.segment_count} recorded: {frame_count} frames | Duration: {actual_duration:.1f}s | Total frames: {self.total_frames}")
                
                if not self.is_running:
                    break
                
                # Calculate and wait for next recording
                wait_time = self.interval - self.record_duration
                
                if wait_time > 0:
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Waiting {wait_time} seconds until next recording...")
                    
                    # Wait with periodic checks for stop signal
                    wait_start = time.time()
                    while time.time() - wait_start < wait_time and self.is_running:
                        if os.path.exists(self.stop_file):
                            print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Stop signal received!")
                            self.is_running = False
                            break
                        time.sleep(0.5)
                else:
                    print("Note: Starting next recording immediately (interval <= duration)")
                    
        except Exception as e:
            print(f"Error in interval recording: {e}")
        finally:
            if self.out:
                self.out.release()
            
            total_duration = time.time() - self.start_time if self.start_time else 0
            duration_str = self.format_duration(total_duration)
            
            print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Interval recording stopped")
            print(f"{'='*60}")
            print(f"Recording saved: {self.filename}")
            print(f"Total Segments: {self.segment_count}")
            print(f"Total Frames: {self.total_frames}")
            print(f"Total Duration: {duration_str}")
            print(f"File Size: {self.get_file_size(self.filename)}")
            print(f"{'='*60}")
    
    def create_pid_file(self):
        """Create a PID file to track the running process."""
        with open(self.pid_file, 'w') as f:
            f.write(str(os.getpid()))
    
    def remove_pid_file(self):
        """Remove the PID file."""
        if os.path.exists(self.pid_file):
            os.remove(self.pid_file)
    
    def start(self):
        """Start the recording based on mode."""
        # Check if already running
        if os.path.exists(self.pid_file):
            print("Error: Recorder is already running!")
            print(f"PID file exists: {self.pid_file}")
            print("Use 'stop' command to stop the existing recorder first.")
            return
        
        # Create PID file
        self.create_pid_file()
        
        # Remove any existing stop file
        if os.path.exists(self.stop_file):
            os.remove(self.stop_file)
        
        self.is_running = True
        print(f"\n{'='*60}")
        print(f"Screen Recorder Started")
        print(f"{'='*60}")
        print(f"Output Directory: {os.path.abspath(self.output_dir)}")
        print(f"Base Filename: {self.base_filename}")
        print(f"Process ID: {os.getpid()}")
        print(f"\nTo stop recording, run:")
        print(f"  python {sys.argv[0]} stop")
        print(f"{'='*60}")
        
        try:
            if self.mode == 'continuous':
                self.record_continuous()
            else:  # interval mode
                if self.save_mode == 'single':
                    self.record_interval_single_file()
                else:
                    self.record_interval_multiple_files()
                
        except KeyboardInterrupt:
            print(f"\n\n{'='*60}")
            print("Recording stopped by user (Ctrl+C)")
            print(f"{'='*60}")
        finally:
            self.stop()
    
    def stop(self):
        """Stop the recording."""
        self.is_running = False
        self.remove_pid_file()
        
        # Remove stop file if it exists
        if os.path.exists(self.stop_file):
            os.remove(self.stop_file)
        
        print(f"\nAll recordings saved in: {os.path.abspath(self.output_dir)}")


def stop_recorder():
    """Send stop signal to running recorder."""
    pid_file = ".screen_recorder.pid"
    stop_file = ".screen_recorder.stop"
    
    if not os.path.exists(pid_file):
        print("❌ Error: No recorder is currently running.")
        print(f"PID file not found: {pid_file}")
        return
    
    # Read PID
    with open(pid_file, 'r') as f:
        pid = int(f.read().strip())
    
    print(f"📡 Sending stop signal to recorder (PID: {pid})...")
    
    # Create stop file
    with open(stop_file, 'w') as f:
        f.write(str(datetime.now()))
    
    print("✅ Stop signal sent successfully!")
    print("The recorder will stop and save the recording file(s).")


def check_status():
    """Check if recorder is running."""
    pid_file = ".screen_recorder.pid"
    
    if os.path.exists(pid_file):
        with open(pid_file, 'r') as f:
            pid = int(f.read().strip())
        
        # Check if process is actually running
        try:
            os.kill(pid, 0)
            print(f"✅ Recorder is RUNNING (PID: {pid})")
            return True
        except OSError:
            print(f"❌ Recorder is NOT running (stale PID file found)")
            print(f"   Cleaning up stale PID file...")
            os.remove(pid_file)
            return False
    else:
        print("❌ Recorder is NOT running")
        return False


def load_config(config_file='config.json'):
    """Load configuration from JSON file."""
    default_config = {
        "mode": "continuous",
        "duration": 30,
        "interval": 300,
        "fps": 20,
        "save_mode": "single",
        "output_dir": "recordings"
    }
    
    if os.path.exists(config_file):
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
                print(f"✅ Loaded configuration from {config_file}")
                return config
        except Exception as e:
            print(f"⚠️  Warning: Could not load {config_file}: {e}")
            print(f"   Using default configuration")
            return default_config
    else:
        print(f"ℹ️  Config file '{config_file}' not found. Using default configuration.")
        # Create default config file
        try:
            with open(config_file, 'w') as f:
                json.dump(default_config, f, indent=2)
            print(f"✅ Created default config file: {config_file}")
        except Exception as e:
            print(f"⚠️  Could not create config file: {e}")
        return default_config


def main():
    parser = argparse.ArgumentParser(
        description='Screen Recorder - Record screen continuously or at intervals',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Commands:
  start [filename]  Start the screen recorder with optional filename
  stop              Stop the running recorder
  status            Check if recorder is running

Configuration:
  All recording settings are read from 'config.json' file.
  Edit config.json to change recording parameters.

config.json parameters:
  - mode: "continuous" or "interval"
  - duration: Recording duration per segment (seconds) for interval mode
  - interval: Total cycle time (record + wait) in seconds for interval mode
  - fps: Frames per second
  - save_mode: "single" or "multiple" (for interval mode)
  - output_dir: Directory to save recordings

Examples:
  # Start recording with auto-generated filename
  python screen_recorder.py start
  
  # Start recording with custom filename
  python screen_recorder.py start meeting_recording
  
  # Stop recording
  python screen_recorder.py stop
  
  # Check status
  python screen_recorder.py status

To change recording settings, edit config.json:
  {
    "mode": "interval",
    "duration": 30,
    "interval": 300,
    "fps": 20,
    "save_mode": "single",
    "output_dir": "recordings"
  }
        """
    )
    
    parser.add_argument('command',
                       nargs='?',
                       default='start',
                       choices=['start', 'stop', 'status'],
                       help='Command to execute (default: start)')
    
    parser.add_argument('filename',
                       nargs='?',
                       type=str,
                       default=None,
                       help='Base filename for recording (default: auto-generated)')
    
    parser.add_argument('-c', '--config',
                       type=str,
                       default='config.json',
                       help='Path to configuration file (default: config.json)')
    
    args = parser.parse_args()
    
    # Handle commands
    if args.command == 'stop':
        stop_recorder()
        return
    
    if args.command == 'status':
        check_status()
        return
    
    # Start command
    if args.command == 'start':
        # Load configuration
        config = load_config(args.config)
        
        # Generate filename if not provided
        if args.filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            mode_prefix = "continuous" if config['mode'] == 'continuous' else "interval"
            args.filename = f"{mode_prefix}_recording_{timestamp}"
            print(f"No filename provided. Using: {args.filename}")
        
        # Validate inputs
        if config['fps'] <= 0:
            print("Error: FPS must be positive in config.json")
            return
        
        if config['mode'] == 'interval':
            if config['duration'] <= 0:
                print("Error: Duration must be positive in config.json")
                return
            
            if config['interval'] <= 0:
                print("Error: Interval must be positive in config.json")
                return
            
            if config['duration'] > config['interval']:
                print("⚠️  Warning: Recording duration is greater than interval!")
                print("   Recordings will start immediately after the previous one finishes.")
                response = input("Continue? (y/n): ")
                if response.lower() != 'y':
                    return
        
        # Create and start recorder
        recorder = ScreenRecorder(
            base_filename=args.filename,
            mode=config['mode'],
            record_duration=config['duration'],
            interval=config['interval'],
            fps=config['fps'],
            save_mode=config['save_mode'],
            output_dir=config['output_dir']
        )
        
        recorder.start()


if __name__ == "__main__":
    main()
