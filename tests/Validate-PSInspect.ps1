[CmdletBinding()]
param(
    [string]$ScriptPath = (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'psinspect.ps1')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
    throw "PSInspect script was not found at '$ScriptPath'."
}

$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path -LiteralPath $ScriptPath).Path,
    [ref]$tokens,
    [ref]$parseErrors
) | Out-Null

if (@($parseErrors).Count -gt 0) {
    $messages = @($parseErrors | ForEach-Object {
            'Line {0}, column {1}: {2}' -f $_.Extent.StartLineNumber, $_.Extent.StartColumnNumber, $_.Message
        }) -join [Environment]::NewLine
    throw "PowerShell parser errors were found:$([Environment]::NewLine)$messages"
}

$content = Get-Content -LiteralPath $ScriptPath -Raw -ErrorAction Stop
$prohibitedPatterns = @(
    [PSCustomObject]@{
        Pattern = '(?i)\bGet-WmiObject\b'
        Reason  = 'Use CIM cmdlets instead of the deprecated Get-WmiObject cmdlet.'
    },
    [PSCustomObject]@{
        Pattern = '(?i)\bSend-MailMessage\b'
        Reason  = 'PSInspect does not send evidence by email.'
    },
    [PSCustomObject]@{
        Pattern = '(?i)\bConvertTo-SecureString\b.*\bAsPlainText\b'
        Reason  = 'PSInspect does not accept or convert plaintext passwords.'
    },
    [PSCustomObject]@{
        Pattern = '(?i)PSRecon_\*'
        Reason  = 'Legacy wildcard evidence cleanup must not be restored.'
    },
    [PSCustomObject]@{
        Pattern = '(?i)#requires\s+-version\s+2'
        Reason  = 'PSInspect requires PowerShell 5.1 or later.'
    }
)

foreach ($check in $prohibitedPatterns) {
    if ($content -match $check.Pattern) {
        throw "Safety validation failed: $($check.Reason)"
    }
}

$requiredTokens = @(
    'function Invoke-PSInspectLocal',
    'function Invoke-PSInspectRemote',
    'function Write-PSInspectHashManifest',
    'function Invoke-PSInspectNetworkQuarantine',
    'SHA256SUMS.txt',
    'QuarantineNetwork'
)

foreach ($token in $requiredTokens) {
    if ($content.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "Expected implementation token '$token' was not found."
    }
}

Write-Host 'PSInspect syntax and baseline safety validations passed.'
