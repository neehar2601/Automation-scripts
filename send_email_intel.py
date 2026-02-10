"""
Intel Authenticated SMTP Email Sender
======================================

Python equivalent of the .NET SmtpClient code for sending emails
through Intel's authenticated SMTP server (Smtpauth.intel.com).

Requirements:
1. Set environment variables:
   - MailUserName: Your Intel email username (e.g., firstname.lastname@intel.com)
   - MailPassword: Your Intel email password

2. Install Python (already done if you're running this)

Usage:
    python send_email_intel.py
"""

import os
import smtplib
import time
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
from pathlib import Path

# -------------------- CONFIG --------------------

# Intel Authenticated SMTP Server Settings
SMTP_HOST = "Smtpauth.intel.com"
SMTP_PORT = 587
USE_TLS = True  # EnableSsl in .NET

# Get credentials from environment variables (like your .NET code)
MAIL_USERNAME = os.environ.get("MailUserName")
MAIL_PASSWORD = os.environ.get("MailPassword")

# -------------------- FUNCTION --------------------

def send_email_intel(to_email, subject, body, attachment_path=None, from_email=None):
    """
    Send email via Intel's authenticated SMTP server.
    
    This is the Python equivalent of your .NET SmtpClient code.
    
    Args:
        to_email: Recipient email address
        subject: Email subject
        body: Email body text
        attachment_path: Optional path to file attachment
        from_email: Sender email (defaults to MailUserName)
    
    Returns:
        True if email sent successfully, False otherwise
    """
    
    # Validate credentials
    if not MAIL_USERNAME or not MAIL_PASSWORD:
        print("ERROR: Email credentials not found in environment variables!")
        print("\nPlease set the following environment variables:")
        print("  MailUserName - Your Intel email (e.g., firstname.lastname@intel.com)")
        print("  MailPassword - Your Intel email password")
        print("\nWindows PowerShell:")
        print('  $env:MailUserName = "your.email@intel.com"')
        print('  $env:MailPassword = "your_password"')
        print("\nOr set them permanently in System Environment Variables.")
        return False
    
    # Use username as from_email if not specified
    if not from_email:
        from_email = MAIL_USERNAME
    
    print(f"\n{'='*80}")
    print("SENDING EMAIL VIA INTEL AUTHENTICATED SMTP")
    print(f"{'='*80}\n")
    print(f"Server: {SMTP_HOST}:{SMTP_PORT}")
    print(f"From:   {from_email}")
    print(f"To:     {to_email}")
    print(f"Auth:   {MAIL_USERNAME}")
    
    # Create message (equivalent to MailMessage in .NET)
    msg = MIMEMultipart()
    msg['From'] = from_email
    msg['To'] = to_email
    msg['Subject'] = subject
    
    # Add body
    msg.attach(MIMEText(body, 'plain'))
    
    # Add attachment if provided
    if attachment_path and Path(attachment_path).exists():
        print(f"Attachment: {Path(attachment_path).name}")
        with open(attachment_path, 'rb') as f:
            part = MIMEBase('application', 'octet-stream')
            part.set_payload(f.read())
            encoders.encode_base64(part)
            part.add_header(
                'Content-Disposition',
                f'attachment; filename={Path(attachment_path).name}'
            )
            msg.attach(part)
    
    try:
        # Create SMTP client (equivalent to SmtpClient in .NET)
        print(f"\nConnecting to {SMTP_HOST}:{SMTP_PORT}...")
        
        # Use SMTP with TLS (equivalent to EnableSsl = true)
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=30) as smtp:
            smtp.set_debuglevel(0)  # Set to 1 for debugging
            
            # Start TLS encryption (equivalent to EnableSsl = true)
            print("Starting TLS encryption...")
            smtp.starttls()
            
            # Login with credentials (equivalent to smtp.Credentials in .NET)
            print(f"Authenticating as {MAIL_USERNAME}...")
            smtp.login(MAIL_USERNAME, MAIL_PASSWORD)
            
            # Send email (equivalent to smtp.Send(mm) in .NET)
            print(f"Sending email...")
            smtp.send_message(msg)
            
            # Wait (equivalent to Thread.Sleep(1000) in .NET)
            time.sleep(1)
            
            # Connection automatically closed (equivalent to smtp.Dispose() in .NET)
        
        print(f"\nSUCCESS: Email sent successfully!")
        return True
        
    except smtplib.SMTPAuthenticationError as e:
        print(f"\nERROR - Authentication Failed: {e}")
        print("\nPossible reasons:")
        print("  1. Incorrect username or password")
        print("  2. Account requires 2FA (use app password)")
        print("  3. Account is locked or disabled")
        return False
        
    except smtplib.SMTPException as e:
        print(f"\nERROR - SMTP Error: {e}")
        print("\nPossible reasons:")
        print("  1. Not connected to Intel network/VPN")
        print("  2. Firewall blocking port 587")
        print("  3. Server is down or unreachable")
        return False
        
    except Exception as e:
        print(f"\nERROR - Unexpected Error: {e}")
        return False


# -------------------- EXAMPLE USAGE --------------------

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Send email via Intel authenticated SMTP server',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Send simple email
  python send_email_intel.py --to someone@intel.com --subject "Test" --body "Hello World"
  
  # Send email with attachment
  python send_email_intel.py --to someone@intel.com --subject "Report" --body "See attachment" --attach report.txt
  
  # Set environment variables first (PowerShell):
  $env:MailUserName = "your.email@intel.com"
  $env:MailPassword = "your_password"
  python send_email_intel.py --to someone@intel.com --subject "Test" --body "Hello"
        """
    )
    
    parser.add_argument('--to', required=True, help='Recipient email address')
    parser.add_argument('--subject', required=True, help='Email subject')
    parser.add_argument('--body', required=True, help='Email body text')
    parser.add_argument('--attach', help='Path to attachment file')
    parser.add_argument('--from', dest='from_email', help='Sender email (defaults to MailUserName)')
    
    args = parser.parse_args()
    
    # Send email
    success = send_email_intel(
        to_email=args.to,
        subject=args.subject,
        body=args.body,
        attachment_path=args.attach,
        from_email=args.from_email
    )
    
    # Exit with appropriate code
    exit(0 if success else 1)
