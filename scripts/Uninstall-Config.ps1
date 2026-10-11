#requires -Version 7.0
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$profileFile = $PROFILE.CurrentUserCurrentHost
if (-not (Test-Path -LiteralPath $profileFile -PathType Leaf)) {
    Write-Host 'No current-host PowerShell profile found.'
    return
}
$content = Get-Content -LiteralPath $profileFile -Raw
$pattern = '(?ms)\r?\n?# >>> powershell7-dev-kit >>>\r?\n.*?# <<< powershell7-dev-kit <<<\r?\n?'
$updated = [regex]::Replace($content, $pattern, '')
if ($updated -eq $content) {
    Write-Host 'No managed profile block found; nothing changed.'
    return
}
$backup = "$profileFile.bak.$(Get-Date -Format yyyyMMddHHmmssfff)"
Copy-Item -LiteralPath $profileFile -Destination $backup
[System.IO.File]::WriteAllText($profileFile, $updated)
Write-Host "Disabled DevKit in this PowerShell host. Backup: $backup"
Write-Host 'Installed tools and saved configuration files were left untouched.'
