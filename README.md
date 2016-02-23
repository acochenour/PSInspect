# PSInspect
PowerShell script useful for Incident Response and security/configuration baselines for Windows Vista and later.  Self-contained 

# Windows Metadata Extraction:
* User Accounts
* System Configuration Files (.sys and .ini)
* Environment Variables
* Group Policy Objects
* Windows Patches
* Firewall Configuration
* Command Line History
* Scheduled Tasks
* Sidebar Gadgets
* Installed Printers & Drivers
* Shared Printers
* Internet Explorer Browser History
* Recent Emails (last 30-days)
* Downloaded Files & MD5 Hashes

# Remote & Log Data Extraction
* USB Device History
* Remote Desktop History
* Successul & Unsuccessful Logons
* Registry Persistence Entries
* Startup Drivers
* User & Temporary Drivers
* PowerShell Scripts
* Microsoft Office Addins (all versions)
* Internet Explorer Addins

# Software
* Installed Software
* AV Software List
* Services
* Running Prcess Hashes
* Service Details
* Prefetch Files
* AT Jobs
 
# Network Metadata & Configuration
* Hosts
* Networks
* Network Shares
* Open SMB Sessions
* DNS
* ARP Table
* Network Status
* Listening Processes
* Network Services
* LMHosts
* MAC Addresses
* Network Configuration
 
# User Documents
* Complete List of User Documents
* MD5 Hash of User Documents

# Usage Examples:
* Capture all standard metadata, save report locally: .\PSInspect.ps1
* Capture all standard metadata, email report: .\PSInspect.ps1 -sendEmail -emailFrom user1@domain.com -emailTo user2@domain.com -smtpServer 172.16.1.1
* Capture all standard metadata, save report to a network share: .\PSInspect.ps1 -share \\share\path -username myUser -password myPassword
* Capture all standard metadata and user's email metadata, save report locally: .\PSInspect.ps1 -email
* Capture all standard metadata and user's email metadata, email report:  .\PSInspect.ps1 -email -sendEmail -emailFrom user1@domain.com -emailTo user2@domain.com -smtpServer 172.16.1.1

# PowerShell Permissions -- Run PowerShell as Administrator
* Get-ExecutionPolicy –List           # Check your current PowerShell permissions
* Set-ExecutionPolicy Unrestricted
* Set-ExecutionPolicy -Scope CurrentUser Unrestricted
* Set-ExecutionPolicy -Scope Process Unrestricted

* Set-ExecutionPolicy Restricted      # Reset PowerShell script permissions back to Restricted
* Set-ExecutionPolicy -Scope CurrentUser Restricted
* Set-ExecutionPolicy -Scope Process Restricted
* Get-ExecutionPolicy –List           #Confirm the updated settings before exiting

# TODO
* Firefox & Chrome browser history support
* Memory acquisition
* Disk acquisition

