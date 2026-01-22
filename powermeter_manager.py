#!/usr/bin/env python
"""
POWERMETER Manager - Python Script for POWERMETER BIOS Configuration
Supports: STATUS, ENABLE, DISABLE operations for POWERMETER
"""

import sys
import os
import subprocess
import time
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


class PowerMeterManager:
    """Manages XMLCLI operations for POWERMETER BIOS configuration"""
    
    def __init__(self):
        self.logfile = os.path.join(os.environ.get('TEMP', 'C:\\Temp'), 'powermeter_manager.log')
        self.log(f"POWERMETER Manager started")
        
    def log(self, message, console=True):
        """Log message to file and optionally to console"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        log_msg = f"[{timestamp}] {message}"
        if console:
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
            return False
    
    def get_powermeter_status(self):
        """Get current POWERMETER status from BIOS"""
        try:
            with self.suppress_output():
                cli.clb._setCliAccess("winsdk")
                # Check if POWERMETER is enabled (expecting value 1)
                result = cli.CvReadKnobs("PowermeterDeviceEnable=1")
            
            if result == 0:
                return "ENABLED"
            else:
                return "DISABLED"
                
        except Exception as e:
            self.log(f"[ERROR] Failed to read POWERMETER status: {e}")
            return "UNKNOWN"
    
    def enable_powermeter(self):
        """Enable POWERMETER in BIOS"""
        try:
            with self.suppress_output():
                cli.clb._setCliAccess("winsdk")
                # Check current status
                current_status = cli.CvReadKnobs("PowermeterDeviceEnable=1")
            
            if current_status == 0:
                print("[INFO] POWERMETER is already ENABLED")
                return 50  # Already enabled, no reboot needed
            
            # Enable POWERMETER
            print("[INFO] Current State: POWERMETER is DISABLED")
            print("[INFO] Enabling POWERMETER in BIOS...")
            
            with self.suppress_output():
                cli.CvProgKnobs("PowermeterDeviceEnable=1")
            
            print("[SUCCESS] POWERMETER enabled successfully")
            print("[INFO] New State: POWERMETER is ENABLED")
            # Create .ovr file indicating powermeter is enabled and system to be restarted
            ovr_dir = r"C:\KSR_Package\KSR\Test_Run_KR"
            os.makedirs(ovr_dir, exist_ok=True)
            ovr_path = os.path.join(ovr_dir, "powermeter.OVR")
            with open(ovr_path, "w") as ovr_file:
                ovr_file.write("powermeter is enabled, system to be restarted\n")
            return 100  # Reboot required
            
        except Exception as e:
            self.log(f"[ERROR] Failed to enable POWERMETER: {e}")
            ovr_dir = r"C:\KSR_Package\KSR\Test_Run_KR"
            os.makedirs(ovr_dir, exist_ok=True)
            ovr_path = os.path.join(ovr_dir, "error.OVR")
            with open(ovr_path, "w") as ovr_file:
                ovr_file.write(f"powermeter configuration failed\n {e}")
            return 1
    
    def disable_powermeter(self):
        """Disable POWERMETER in BIOS"""
        try:
            with self.suppress_output():
                cli.clb._setCliAccess("winsdk")
                # Check current status
                current_status = cli.CvReadKnobs("PowermeterDeviceEnable=0")
            
            if current_status == 0:
                print("[INFO] POWERMETER is already DISABLED")
                return 0  # Already disabled, no reboot needed
            
            # Disable POWERMETER
            print("[INFO] Current State: POWERMETER is ENABLED")
            print("[INFO] Disabling POWERMETER in BIOS...")
            
            with self.suppress_output():
                cli.CvProgKnobs("PowermeterDeviceEnable=0")
            
            print("[SUCCESS] POWERMETER disabled successfully")
            print("[INFO] New State: POWERMETER is DISABLED")
            # Create .ovr file indicating powermeter is enabled and system to be restarted
            ovr_dir = r"C:\KSR_Package\KSR\Test_Run_KR"
            os.makedirs(ovr_dir, exist_ok=True)
            ovr_path = os.path.join(ovr_dir, "powermeter.OVR")
            with open(ovr_path, "w") as ovr_file:
                ovr_file.write("powermeter is disabled, system to be restarted\n")
            return 100  # Reboot required
            
        except Exception as e:
            self.log(f"[ERROR] Failed to disable POWERMETER: {e}")
            # Create error.ovr file to indicate failure
            ovr_dir = r"C:\KSR_Package\KSR\Test_Run_KR"
            os.makedirs(ovr_dir, exist_ok=True)
            ovr_path = os.path.join(ovr_dir, "error.OVR")
            with open(ovr_path, "w") as ovr_file:
                ovr_file.write(f"powermeter configuration failed\n {e}")
            return 1


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description='POWERMETER Manager - POWERMETER BIOS Configuration Tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s --action status
  %(prog)s --action enable
  %(prog)s --action disable
        '''
    )
    
    parser.add_argument('--action', '-a',
                        choices=['status', 'enable', 'disable'],
                        required=True,
                        help='Action to perform (status, enable, or disable)')

    args = parser.parse_args()
    
    # Initialize manager
    manager = PowerMeterManager()
    
    # Verify XMLCLI is enabled
    if not manager.verify_xmlcli_enabled():
        print("[ERROR] XMLCLI is not available. Cannot proceed.")
        return 1
    
    # Handle STATUS action
    if args.action == 'status':
        with manager.suppress_output():
            status = manager.get_powermeter_status()
        print("=" * 60)
        print(f"POWERMETER Status: {status}")
        print("=" * 60)
        return 0
    
    # Handle ENABLE/DISABLE actions
    exit_code = 0
    
    if args.action == 'enable':
        exit_code = manager.enable_powermeter()
    elif args.action == 'disable':
        exit_code = manager.disable_powermeter()
    
    # Handle reboot logic
    if exit_code == 100:
        print("\033[91m[REBOOT REQUIRED] System reboot needed to apply BIOS changes\033[0m")
        # print("Rebooting in 15 seconds...")
        # time.sleep(15)
        # # Windows restart command
        # try:
        #     subprocess.run(["shutdown", "/r", "/t", "0"], check=True)
        # except Exception as e:
        #     print(f"[ERROR] Failed to initiate reboot: {e}")
        return 100
    elif exit_code == 50:
        print("\033[92m[NO REBOOT NEEDED] Powermeter is already in the requested state\033[0m")
        return 0
    elif exit_code == 1:
        print("\033[91m[ERROR] Configuration failed. Check the log file for details.\033[0m")
        return 1
    else:
        print("\033[92m[NO REBOOT NEEDED] Configuration completed successfully\033[0m")
        return 0


if __name__ == "__main__":
    sys.exit(main())
