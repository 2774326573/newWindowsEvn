#requires -Version 7.0
[CmdletBinding()]
param([switch]$SkipModules)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'WinGet missing: install Windows App Installer first.'
}

# Shared with Prepare-Offline.ps1 to prevent install/cache drift.
$ids = Get-Content -LiteralPath (Join-Path $root 'config\packages.txt') |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith('#') }

$failed = @()
foreach ($id in $ids) {
    Write-Host "Installing/checking $id" -ForegroundColor Cyan
    & winget install --id $id --exact --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        $failed += $id
        Write-Warning "WinGet returned $LASTEXITCODE for $id. Check whether it is already installed or retry manually."
    }
}
if (-not $SkipModules) {
    foreach ($name in @('PSFzf','Terminal-Icons')) {
        if (-not (Get-Module -ListAvailable -Name $name)) {
            try {
                Install-Module -Name $name -Scope CurrentUser -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
            } catch { Write-Warning "Optional PowerShell module $name unavailable: $_" }
        }
    }
}
if ($failed.Count -gt 0) {
    Write-Warning "Review failed/not-confirmed packages: $($failed -join ', ')"
}
Write-Host 'Reopen PowerShell 7 to refresh PATH; then install Yazi plugins and configuration.' -ForegroundColor Green
Write-Host 'Install a Nerd Font manually. MSVC/Qt/HALCON/vendor SDKs are intentionally not auto-installed.'
