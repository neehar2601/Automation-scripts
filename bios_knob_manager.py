#!/usr/bin/env python
"""
BIOS Knob Manager - Generic Python Script for BIOS Configuration
Supports: STATUS, SET operations for any BIOS knobs via XMLCLI
"""

import sys
import os
import subprocess
import argparse
from datetime import datetime
from io import StringIO
import contextlib

# Try to import xmlcli
try:
    from xmlcli import XmlCli as cli
    XMLCLI_AVAILABLE = True
except ImportError:
    XMLCLI_AVAILABLE = False
    print("[ERROR] XMLCLI is not installed. Please install it first.")
    print("Download setup from https://ubit-artifactory-ba.intel.com/artifactory/ksr-ba-local/OS_Settings/XMLCLI/")
    sys.exit(1)


class BIOSKnobManager:
    """Manages XMLCLI operations for generic BIOS knob configuration"""
    
    def __init__(self, verbose=False):
        self.logfile = os.path.join(os.environ.get('TEMP', 'C:\\Temp'), 'bios_knob_manager.log')
        self.verbose = verbose
        self.log(f"BIOS Knob Manager started")
        
    def log(self, message, console=True):
        """Log message to file and optionally to console"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        log_msg = f"[{timestamp}] {message}"
        if console and self.verbose:
            print(log_msg)
        try:
            with open(self.logfile, 'a') as f:
                f.write(log_msg + '\n')
        except Exception as e:
            if console:
                print(f"[WARNING] Failed to write to log file: {e}")
    
    @contextlib.contextmanager
    def suppress_output(self):
        """Context manager to suppress stdout"""
        old_stdout = sys.stdout
        sys.stdout = StringIO()
        try:
            yield
        finally:
            sys.stdout = old_stdout
    
    def verify_xmlcli_enabled(self):
        """Verify if XMLCLI is enabled in BIOS"""
        try:
            with self.suppress_output():
                cli.clb._setCliAccess("winsdk")
                result = cli.clb.ConfXmlCli()
            
            if result == 0:
                self.log("[SUCCESS] XMLCLI is enabled and ready", console=False)
                return True
            else:
                self.log("[ERROR] XMLCLI is NOT enabled in BIOS")
                print("\nSteps to enable XMLCLI:")
                print("1. Reboot the system and enter BIOS setup (usually F2)")
                print("2. Navigate to 'Intel Advanced' tab")
                print("3. Select 'XMLCLI'")
                print("4. Change setting to 'Enabled'")
                print("5. Save changes and exit BIOS setup")
                return False
        except Exception as e:
            self.log(f"[ERROR] Failed to verify XMLCLI status: {e}")
            print(f"[ERROR] Failed to verify XMLCLI status: {e}")
            return False
    
    def get_knob_status(self, knobs):
        """
        Get current status of BIOS knobs
        
        Args:
            knobs: String of knob settings (e.g., "Txt=0x00, VT=0x00")
        
        Returns:
            int: 0 if knobs match current state, non-zero otherwise
        """
        try:
            with self.suppress_output():
                cli.clb._setCliAccess("winsdk")
                result = cli.CvReadKnobs(knobs)
            
            return result
                
        except Exception as e:
            self.log(f"[ERROR] Failed to read knob status: {e}")
            print(f"[ERROR] Failed to read knob status: {e}")
            return -1
    
    def set_knobs(self, knobs, check_first=True, ovr_name=None):
        """
        Set BIOS knobs to specified values
        
        Args:
            knobs: String of knob settings (e.g., "Txt=0x00, VT=0x00")
            check_first: Whether to check current state before applying
            ovr_name: Optional name for .OVR file (without extension)
        
        Returns:
            int: Exit code (0=success, 1=error, 50=already set, 100=reboot required)
        """
        try:
            cli.clb._setCliAccess("winsdk")
            
            # Check current status if requested
            if check_first:
                self.log(f"[INFO] Checking current knob state: {knobs}")
                current_status = self.get_knob_status(knobs)
                
                if current_status == 0:
                    print(f"[INFO] Knobs are already set to: {knobs}")
                    return 50  # Already set, no reboot needed
                else:
                    print(f"[INFO] Current knob state differs from requested state")
            
            # Set the knobs
            print(f"[INFO] Setting BIOS knobs: {knobs}")
            with self.suppress_output():
                cli.CvProgKnobs(knobs)
            
            print(f"[SUCCESS] Knobs set successfully: {knobs}")
            self.log(f"[SUCCESS] Knobs set successfully: {knobs}")
            
            # Create .ovr file if requested
            if ovr_name:
                ovr_dir = r"C:\KSR_Package\KSR\Test_Run_KR"
                os.makedirs(ovr_dir, exist_ok=True)
                ovr_path = os.path.join(ovr_dir, f"{ovr_name}.OVR")
                with open(ovr_path, "w") as ovr_file:
                    ovr_file.write(f"BIOS knobs set: {knobs}\n")
                    ovr_file.write("System restart required to apply changes\n")
                print(f"[INFO] Created status file: {ovr_path}")
            
            return 100  # Reboot required
            
        except Exception as e:
            self.log(f"[ERROR] Failed to set knobs: {e}")
            print(f"[ERROR] Failed to set knobs: {e}")
            
            # Create error.ovr file
            if ovr_name:
                ovr_dir = r"C:\KSR_Package\KSR\Test_Run_KR"
                os.makedirs(ovr_dir, exist_ok=True)
                ovr_path = os.path.join(ovr_dir, "error.OVR")
                with open(ovr_path, "w") as ovr_file:
                    ovr_file.write(f"BIOS knob configuration failed\n")
                    ovr_file.write(f"Knobs: {knobs}\n")
                    ovr_file.write(f"Error: {e}\n")
            
            return 1
    
    def read_knobs(self, knobs):
        """
        Read current BIOS knob values
        
        Args:
            knobs: String of knob settings to read (e.g., "Txt, VT")
        
        Returns:
            int: Status code from XMLCLI
        """
        try:
            print(f"[INFO] Reading BIOS knobs: {knobs}")
            cli.clb._setCliAccess("winsdk")
            result = cli.CvReadKnobs(knobs)
            
            if result == 0:
                print(f"[SUCCESS] Knobs match requested state: {knobs}")
            else:
                print(f"[INFO] Knobs do not match requested state: {knobs}")
            
            return result
            
        except Exception as e:
            self.log(f"[ERROR] Failed to read knobs: {e}")
            print(f"[ERROR] Failed to read knobs: {e}")
            return -1


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description='BIOS Knob Manager - Generic BIOS Configuration Tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  # Check if knobs match specified values
  %(prog)s --action status --knobs "Txt=0x00, VT=0x00"
  
  # Set BIOS knobs
  %(prog)s --action set --knobs "Txt=0x00, VT=0x00"
  
  # Set knobs without checking current state first
  %(prog)s --action set --knobs "PowermeterDeviceEnable=1" --no-check
  
  # Set knobs and create a named .OVR file
  %(prog)s --action set --knobs "Txt=0x00, VT=0x00" --ovr-name emon
  
  # Set multiple knobs
  %(prog)s --action set --knobs "Txt=0x00, VT=0x00, HyperThreading=1"
  
  # Enable verbose logging
  %(prog)s --action status --knobs "Txt=0x00" --verbose
        '''
    )
    
    parser.add_argument('--action', '-a',
                        choices=['status', 'set', 'read'],
                        required=True,
                        help='Action to perform: status (check if knobs match), set (program knobs), read (read knob values)')
    
    parser.add_argument('--knobs', '-k',
                        required=True,
                        help='BIOS knob settings as a string (e.g., "Txt=0x00, VT=0x00")')
    
    parser.add_argument('--no-check',
                        action='store_true',
                        help='Skip checking current state before setting knobs')
    
    parser.add_argument('--ovr-name',
                        help='Name for the .OVR status file (without extension)')
    
    parser.add_argument('--verbose', '-v',
                        action='store_true',
                        help='Enable verbose logging to console')
    
    args = parser.parse_args()
    
    # Initialize manager
    manager = BIOSKnobManager(verbose=args.verbose)
    
    # Verify XMLCLI is enabled
    if not manager.verify_xmlcli_enabled():
        print("[ERROR] XMLCLI is not available. Cannot proceed.")
        return 1
    
    # Handle STATUS action
    if args.action == 'status':
        result = manager.get_knob_status(args.knobs)
        print("=" * 70)
        if result == 0:
            print(f"✓ Knobs MATCH current BIOS state: {args.knobs}")
        elif result > 0:
            print(f"✗ Knobs DO NOT MATCH current BIOS state: {args.knobs}")
        else:
            print(f"? Unable to determine knob status: {args.knobs}")
        print("=" * 70)
        return 0 if result == 0 else 1
    
    # Handle READ action
    elif args.action == 'read':
        result = manager.read_knobs(args.knobs)
        return 0 if result >= 0 else 1
    
    # Handle SET action
    elif args.action == 'set':
        check_first = not args.no_check
        exit_code = manager.set_knobs(args.knobs, check_first=check_first, ovr_name=args.ovr_name)
        
        # Handle reboot logic
        if exit_code == 100:
            print("\n" + "=" * 70)
            print("\033[91m[REBOOT REQUIRED] System reboot needed to apply BIOS changes\033[0m")
            print("=" * 70)
            return 100
        elif exit_code == 50:
            print("\n" + "=" * 70)
            print("\033[92m[NO REBOOT NEEDED] Knobs are already in the requested state\033[0m")
            print("=" * 70)
            return 0
        elif exit_code == 1:
            print("\n" + "=" * 70)
            print("\033[91m[ERROR] Configuration failed. Check the log file for details.\033[0m")
            print(f"Log file: {manager.logfile}")
            print("=" * 70)
            return 1
        else:
            print("\n" + "=" * 70)
            print("\033[92m[SUCCESS] Configuration completed\033[0m")
            print("=" * 70)
            return 0


if __name__ == "__main__":
    sys.exit(main())
