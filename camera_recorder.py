import cv2
import numpy as np
import time
from datetime import datetime
import argparse
import os
import sys

class CameraRecorder:
    def __init__(self, base_filename, camera_index=0, mode='continuous', 
                 record_duration=30, interval=60, fps=30, save_mode='single',
                 resolution='720p'):
        """
        Initialize the camera recorder.
        
        Args:
            base_filename: Base name for output files
            camera_index: Camera device index (0 for default camera)
            mode: 'continuous' or 'interval'
            record_duration: Duration of each recording segment in seconds (for interval mode)
            interval: Time between recording starts in seconds (for interval mode)
            fps: Frames per second for recording
            save_mode: 'single' (one file) or 'multiple' (separate files per segment)
            resolution: Video resolution ('480p', '720p', '1080p', or 'native')
        """
        self.base_filename = base_filename
        self.camera_index = camera_index
        self.mode = mode
        self.record_duration = record_duration
        self.interval = interval
        self.fps = fps
        self.save_mode = save_mode
        self.is_running = False
        self.cap = None
        self.out = None
        self.filename = None
        self.frame_count = 0
        self.total_frames = 0
        self.start_time = None
        self.segment_count = 0
        
        # Control files
        self.pid_file = ".camera_recorder.pid"
        self.stop_file = ".camera_recorder.stop"
        
        # Resolution settings
        self.resolutions = {
            '480p': (640, 480),
            '720p': (1280, 720),
            '1080p': (1920, 1080),
            'native': None  # Use camera's native resolution
        }
        
        self.resolution_setting = resolution
        self.camera_width = None
        self.camera_height = None
        
        # Create output directory if it doesn't exist
        self.output_dir = "camera_recordings"
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Initialize camera
        if not self.initialize_camera():
            raise Exception("Failed to initialize camera")
        
        print(f"Camera Resolution: {self.camera_width}x{self.camera_height}")
        print(f"Recording Mode: {self.mode.upper()}")
        if self.mode == 'interval':
            print(f"Recording Duration: {self.record_duration} seconds")
            print(f"Interval: {self.interval} seconds")
            print(f"Wait Time Between Recordings: {self.interval - self.record_duration} seconds")
            print(f"Save Mode: {'SINGLE FILE' if self.save_mode == 'single' else 'MULTIPLE FILES'}")
        print(f"FPS: {self.fps}")
    
    def initialize_camera(self):
        """Initialize the camera and set resolution."""
        print(f"Initializing camera {self.camera_index}...")
        
        self.cap = cv2.VideoCapture(self.camera_index)
        
        if not self.cap.isOpened():
            print(f"Error: Cannot open camera {self.camera_index}")
            return False
        
        # Set resolution if specified
        if self.resolution_setting != 'native' and self.resolution_setting in self.resolutions:
            width, height = self.resolutions[self.resolution_setting]
            self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
            self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
        
        # Set FPS
        self.cap.set(cv2.CAP_PROP_FPS, self.fps)
        
        # Get actual resolution
        self.camera_width = int(self.cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        self.camera_height = int(self.cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        
        # Test capture
        ret, frame = self.cap.read()
        if not ret:
            print("Error: Cannot read from camera")
            return False
        
        print(f"Camera initialized successfully")
        return True
    
    def release_camera(self):
        """Release the camera resource."""
        if self.cap:
            self.cap.release()
            print("Camera released")
    
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
        """Record camera continuously until stop signal - SINGLE FILE."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.filename = os.path.join(self.output_dir, f"{self.base_filename}_{timestamp}.mp4")
        
        # Define the codec and create VideoWriter object
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        self.out = cv2.VideoWriter(self.filename, fourcc, self.fps, 
                                   (self.camera_width, self.camera_height))
        
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
                
                # Capture frame from camera
                ret, frame = self.cap.read()
                
                if not ret:
                    print(f"Error: Failed to capture frame")
                    break
                
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
                
                # Control frame rate (camera already provides frames at set FPS)
                time.sleep(0.001)
                
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
                
                # Capture frame from camera
                ret, frame = self.cap.read()
                
                if not ret:
                    print(f"Error: Failed to capture frame")
                    break
                
                # Write frame to video
                out.write(frame)
                frame_count += 1
                
                # Control frame rate
                time.sleep(0.001)
                
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
                                     (self.camera_width, self.camera_height))
                
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
                                   (self.camera_width, self.camera_height))
        
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
            print("Error: Camera recorder is already running!")
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
        print(f"Camera Recorder Started")
        print(f"{'='*60}")
        print(f"Output Directory: {os.path.abspath(self.output_dir)}")
        print(f"Base Filename: {self.base_filename}")
        print(f"Camera Index: {self.camera_index}")
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
        self.release_camera()
        self.remove_pid_file()
        
        # Remove stop file if it exists
        if os.path.exists(self.stop_file):
            os.remove(self.stop_file)
        
        print(f"\nAll recordings saved in: {os.path.abspath(self.output_dir)}")


def list_cameras():
    """List available cameras."""
    print("Detecting available cameras...")
    print(f"{'='*60}")
    
    available_cameras = []
    
    for i in range(10):  # Check first 10 camera indices
        cap = cv2.VideoCapture(i)
        if cap.isOpened():
            width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            fps = int(cap.get(cv2.CAP_PROP_FPS))
            
            print(f"Camera {i}: Available")
            print(f"  Resolution: {width}x{height}")
            print(f"  FPS: {fps}")
            print()
            
            available_cameras.append(i)
            cap.release()
    
    if not available_cameras:
        print("No cameras detected!")
    else:
        print(f"Found {len(available_cameras)} camera(s): {available_cameras}")
    
    print(f"{'='*60}")
    return available_cameras


def stop_recorder():
    """Send stop signal to running recorder."""
    pid_file = ".camera_recorder.pid"
    stop_file = ".camera_recorder.stop"
    
    if not os.path.exists(pid_file):
        print("❌ Error: No camera recorder is currently running.")
        print(f"PID file not found: {pid_file}")
        return
    
    # Read PID
    with open(pid_file, 'r') as f:
        pid = int(f.read().strip())
    
    print(f"📡 Sending stop signal to camera recorder (PID: {pid})...")
    
    # Create stop file
    with open(stop_file, 'w') as f:
        f.write(str(datetime.now()))
    
    print("✅ Stop signal sent successfully!")
    print("The camera recorder will stop and save the recording file(s).")


def check_status():
    """Check if recorder is running."""
    pid_file = ".camera_recorder.pid"
    
    if os.path.exists(pid_file):
        with open(pid_file, 'r') as f:
            pid = int(f.read().strip())
        
        # Check if process is actually running
        try:
            os.kill(pid, 0)
            print(f"✅ Camera Recorder is RUNNING (PID: {pid})")
            return True
        except OSError:
            print(f"❌ Camera Recorder is NOT running (stale PID file found)")
            print(f"   Cleaning up stale PID file...")
            os.remove(pid_file)
            return False
    else:
        print("❌ Camera Recorder is NOT running")
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Camera Recorder - Record from webcam or camera',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Commands:
  start     Start the camera recorder
  stop      Stop the running recorder
  status    Check if recorder is running
  list      List available cameras

Recording Modes:
  1. CONTINUOUS MODE: Records until you send stop signal
  2. INTERVAL MODE: Records segments at regular intervals

Examples:
  # List available cameras
  python camera_recorder.py list
  
  # Continuous recording with default camera
  python camera_recorder.py start
  
  # Continuous recording with custom filename
  python camera_recorder.py start meeting_video
  
  # Record from camera 1 instead of default (0)
  python camera_recorder.py start --camera 1
  
  # Record in 1080p resolution
  python camera_recorder.py start --resolution 1080p
  
  # Interval mode: 30sec every 5min
  python camera_recorder.py start --mode interval --duration 30 --interval 300
  
  # Stop recording
  python camera_recorder.py stop
        """
    )
    
    parser.add_argument('command',
                       nargs='?',
                       default='start',
                       choices=['start', 'stop', 'status', 'list'],
                       help='Command to execute (default: start)')
    
    parser.add_argument('filename',
                       nargs='?',
                       type=str,
                       default=None,
                       help='Base filename for recording (default: auto-generated)')
    
    parser.add_argument('-c', '--camera',
                       type=int,
                       default=0,
                       help='Camera device index (default: 0)')
    
    parser.add_argument('-m', '--mode',
                       type=str,
                       choices=['continuous', 'interval'],
                       default='continuous',
                       help='Recording mode (default: continuous)')
    
    parser.add_argument('-d', '--duration',
                       type=int,
                       default=30,
                       help='Recording duration per segment in seconds (interval mode) (default: 30)')
    
    parser.add_argument('-i', '--interval',
                       type=int,
                       default=60,
                       help='Time from start of one recording to start of next in seconds (interval mode) (default: 60)')
    
    parser.add_argument('-s', '--save-mode',
                       type=str,
                       choices=['single', 'multiple'],
                       default='single',
                       help='Save mode for interval recording: single file or multiple files (default: single)')
    
    parser.add_argument('-f', '--fps',
                       type=int,
                       default=30,
                       help='Frames per second (default: 30)')
    
    parser.add_argument('-r', '--resolution',
                       type=str,
                       choices=['480p', '720p', '1080p', 'native'],
                       default='720p',
                       help='Video resolution (default: 720p)')
    
    args = parser.parse_args()
    
    # Handle commands
    if args.command == 'list':
        list_cameras()
        return
    
    if args.command == 'stop':
        stop_recorder()
        return
    
    if args.command == 'status':
        check_status()
        return
    
    # Start command
    if args.command == 'start':
        # Generate filename if not provided
        if args.filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            mode_prefix = "continuous" if args.mode == 'continuous' else "interval"
            args.filename = f"camera_{mode_prefix}_{timestamp}"
            print(f"No filename provided. Using: {args.filename}")
        
        # Validate inputs
        if args.fps <= 0:
            print("Error: FPS must be positive")
            return
        
        if args.mode == 'interval':
            if args.duration <= 0:
                print("Error: Duration must be positive")
                return
            
            if args.interval <= 0:
                print("Error: Interval must be positive")
                return
            
            if args.duration > args.interval:
                print("⚠️  Warning: Recording duration is greater than interval!")
                print("   Recordings will start immediately after the previous one finishes.")
                response = input("Continue? (y/n): ")
                if response.lower() != 'y':
                    return
        
        # Create and start recorder
        try:
            recorder = CameraRecorder(
                base_filename=args.filename,
                camera_index=args.camera,
                mode=args.mode,
                record_duration=args.duration,
                interval=args.interval,
                fps=args.fps,
                save_mode=args.save_mode,
                resolution=args.resolution
            )
            
            recorder.start()
        except Exception as e:
            print(f"Error: {e}")
            return


if __name__ == "__main__":
    main()
