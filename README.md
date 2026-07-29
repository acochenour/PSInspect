# PSInspect

PSInspect is a self-contained PowerShell live-response and Windows security-baselining collector. It collects endpoint evidence into an auditable directory and, by default, creates a ZIP archive with SHA-256 integrity information.

This is a modernized replacement for the 2015–2016 release. It targets Windows PowerShell 5.1 or later and current Windows clients and servers.

## What it collects

The Standard profile collects a broad, non-destructive set of endpoint artifacts, including:

- System identity, operating system, patches, environment, PowerShell configuration, installed software, local accounts and group membership
- Services, drivers, processes and command lines, scheduled tasks, startup commands, common registry persistence, AV/Defender status, USB history, RDP client history, and Prefetch metadata
- Network adapters, IP configuration, addresses, routes, active TCP/UDP endpoints, DNS cache, neighbor table, firewall profiles, SMB shares/sessions, and raw ipconfig, netstat, route, and ARP output
- Recent event records from Security, System, Application, PowerShell Operational, and Microsoft Defender Operational logs, when available

The Full profile additionally collects detailed firewall-rule information and user file metadata from common Desktop, Documents, Downloads, and Recent directories. Optional switches enable user-file hashes, running executable hashes, raw EVTX export, selected browser artifacts, and screenshots.

The tool does not copy user documents by default. Browser artifacts and screenshots are opt-in because they can contain especially sensitive data.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+ running on Windows
- Windows 10/11 or Windows Server 2016 or later is recommended
- Run from an elevated PowerShell session for Security log access and the most complete results
- No external PowerShell modules are required

PSInspect is designed for Windows and stops immediately on non-Windows platforms.

## Quick start

Run the standard, non-destructive collection:

~~~powershell
.\psinspect.ps1
~~~

Write the result to a controlled evidence location:

~~~powershell
.\psinspect.ps1 -OutputDirectory 'D:\IR\Evidence'
~~~

Run a full collection with process hashes, user-file metadata, user-file hashes, and raw event logs:

~~~powershell
.\psinspect.ps1 -Profile Full -HashProcessExecutables -HashUserFiles -ExportEvtx -OutputDirectory 'D:\IR\Evidence'
~~~

Collect browser-history artifacts intentionally:

~~~powershell
.\psinspect.ps1 -IncludeBrowserArtifacts -OutputDirectory 'D:\IR\Evidence'
~~~

Capture the active interactive desktop intentionally:

~~~powershell
.\psinspect.ps1 -IncludeScreenshot -OutputDirectory 'D:\IR\Evidence'
~~~

**-IncludeBrowserArtifacts** copies selected Chrome, Edge, Brave, and Firefox history/configuration artifacts when accessible. It deliberately does not collect credential databases or cookie databases.

## Profiles and optional collection

| Option | Behavior |
|---|---|
| **-Profile Quick** | Core system and network configuration only; event collection is off unless **-IncludeEventLogs** is supplied. |
| **-Profile Standard** | Default. Core evidence plus bounded recent event records. |
| **-Profile Full** | Standard plus detailed firewall rules and user-file metadata. |
| **-IncludeUserArtifacts** | Adds metadata for files in Desktop, Documents, Downloads, and Recent directories. |
| **-HashUserFiles** | Hashes the user files identified by **-IncludeUserArtifacts** or Full. Can be time-consuming. |
| **-HashProcessExecutables** | Computes SHA-256 for unique executable paths associated with running processes. |
| **-IncludeBrowserArtifacts** | Copies selected browser history/configuration artifacts; this is privacy-sensitive. |
| **-IncludeScreenshot** | Captures the current interactive desktop only when an interactive desktop is available. |
| **-ExportEvtx** | Exports raw EVTX files for the selected event logs. |
| **-SkipEventLogs** | Suppresses the default event-record collection. |
| **-NoArchive** | Retains the evidence directory without creating a ZIP archive. |
| **-NoHash** | Suppresses SHA-256 manifest generation. Use only when integrity data cannot be generated. |

**-MaximumEventsPerLog**, **-EventLogDays**, and **-MaximumUserArtifactFiles** bound potentially large collections.

## Evidence output and integrity

Each run creates a unique directory such as:

~~~text
PSInspect_HOSTNAME_20260729T150000Z_1a2b3c4d/
├── Report.html
├── manifest.json
├── collection-status.json
├── collection-status.csv
├── hashes.json
├── SHA256SUMS.txt
├── config/
├── system/
├── network/
├── events/
└── user/
~~~

The report is an offline index; the authoritative evidence is in the structured JSON, text, EVTX, and copied artifact files. **collection-status.csv** records each collector, its output, result count, execution time, and any error. A failed optional collector does not erase successful evidence or stop the remaining collection.

By default, PSInspect also creates a ZIP archive beside the run directory and writes a separate archive SHA-256 file.

To verify the directory contents in PowerShell:

~~~powershell
$run = 'D:\IR\Evidence\PSInspect_HOSTNAME_20260729T150000Z_1a2b3c4d'
Get-Content (Join-Path $run 'SHA256SUMS.txt') | ForEach-Object {
    $expected, $relativePath = $_ -split ' \*', 2
    $actual = (Get-FileHash -LiteralPath (Join-Path $run $relativePath) -Algorithm SHA256).Hash
    [PSCustomObject]@{
        Path     = $relativePath
        Expected = $expected
        Actual   = $actual
        Match    = ($expected -eq $actual)
    }
}
~~~

## Remote collection

Remote collection uses WinRM/PowerShell remoting and a PSCredential object; PSInspect never accepts a plaintext password parameter. The target creates its own evidence bundle, then the invoking host retrieves the archive.

~~~powershell
$credential = Get-Credential
.\psinspect.ps1 -ComputerName WS-014,WS-015 -Credential $credential -OutputDirectory 'D:\IR\RemoteEvidence' -RemoteOutputDirectory 'C:\ProgramData\PSInspect' -Profile Standard
~~~

For HTTPS WinRM, add **-UseSSL -Port 5986**.

Remote staging is retained by default to preserve evidence. Only use **-RemoveRemoteStaging** after confirming the archive arrived intact. This explicitly removes only the PSInspect run directory and archive beneath the approved **-RemoteOutputDirectory**.

Remote collection requires an account authorized for PowerShell remoting and, for a complete collection, local administrator privileges on the target. The remote target must have PowerShell 5.1 or later and **Compress-Archive** available.

## Network containment

PSInspect is an evidence collector first. Network containment is intentionally a separate, local-only, confirmation-protected action:

~~~powershell
.\psinspect.ps1 -OutputDirectory 'D:\IR\Evidence' -QuarantineNetwork -Confirm
~~~

When confirmed, it collects evidence first and then disables active physical network adapters. It does not log off users, disable Active Directory accounts, or attempt remote containment. Those actions should be performed through an approved incident-response workflow with the appropriate identity, change, and audit controls.

## Important modernization changes

The legacy script was a PowerShell 2.0-era, monolithic report generator. This version intentionally removes several unsafe or unreliable behaviors:

- No global SilentlyContinue, destructive wildcard cleanup, or automatic deletion of collected evidence
- No plaintext password parameter or SMTP email delivery of incident evidence
- No legacy Get-WmiObject, Internet Explorer COM history collection, netsh firewall, or at.exe dependence
- No automatic Active Directory account disablement
- No hard-coded screenshot overwrite
- SHA-256 integrity manifests replace MD5 evidence verification
- Individual collectors report failures rather than masking them or terminating the full collection

If your response workflow requires artifact transfer, use a controlled share, secure evidence platform, or case-management process after verifying the local manifest and archive hash.

## Validation

Run the built-in validation script from a Windows PowerShell 5.1+ host:

~~~powershell
.\tests\Validate-PSInspect.ps1
~~~

It uses PowerShell's parser to check syntax and verifies that the legacy plaintext-password, SMTP-email, WMI, and destructive PSRecon wildcard patterns are not present.

## License and attribution

Licensed under the [Apache License 2.0](LICENSE). The original PSInspect release was authored and maintained by Hoplite Industries, Inc., with contributions and references acknowledged in its historical source. This rewrite preserves the project's live-response purpose while updating its safety, compatibility, and evidence-handling model.
