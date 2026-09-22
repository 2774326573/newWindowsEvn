#requires -Version 7.0
[CmdletBinding()]
param([switch]$Force)
$ErrorActionPreference = 'Stop'
if (-not $env:APPDATA) { throw 'Windows APPDATA required.' }
$root = Split-Path -Parent $PSScriptRoot
$cfg = Join-Path $HOME '.config\powershell7-dev-kit'
New-Item -ItemType Directory -Force -Path $cfg | Out-Null
function Copy-Safe([string]$Source, [string]$Target) {
    if (Test-Path -LiteralPath $Target) {
        if ((Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash) { return }
        if (-not $Force) { Write-Warning "Keeping existing $Target; review then use -Force to replace."; return }
        Copy-Item -LiteralPath $Target -Destination "$Target.bak.$(Get-Date -Format yyyyMMddHHmmssfff)" -Force
    }
    Copy-Item -LiteralPath $Source -Destination $Target -Force
    Write-Host "Installed: $Target"
}
Copy-Safe (Join-Path $root 'config\powershell\DevKit.ps1') (Join-Path $cfg 'DevKit.ps1')
$official = Join-Path $root 'offline\powerlevel10k_rainbow.omp.json'
if (Test-Path -LiteralPath $official) { $themeSource = $official }
else {
    $themeSource = Join-Path $root 'themes\10k-local.omp.json'
    Write-Warning 'Using the checked-in 10k-inspired fallback, not the original upstream theme.'
}
Copy-Safe $themeSource (Join-Path $cfg 'powerlevel10k_rainbow.omp.json')
$ycfg = Join-Path $env:APPDATA 'yazi\config'
New-Item -ItemType Directory -Force -Path $ycfg | Out-Null
foreach ($name in @('init.lua','yazi.toml','keymap.toml')) {
    Copy-Safe (Join-Path $root "config\yazi\$name") (Join-Path $ycfg $name)
}
$fileExe = 'C:\Program Files\Git\usr\bin\file.exe'
if (Test-Path -LiteralPath $fileExe) { [Environment]::SetEnvironmentVariable('YAZI_FILE_ONE',$fileExe,'User') }
$profileFile = $PROFILE.CurrentUserCurrentHost
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $profileFile) | Out-Null
if (-not (Test-Path -LiteralPath $profileFile)) { New-Item -ItemType File -Path $profileFile | Out-Null }
$line = '. (Join-Path $HOME ''.config\powershell7-dev-kit\DevKit.ps1'')'
$existing = Get-Content -LiteralPath $profileFile -Raw -ErrorAction SilentlyContinue
if ($existing -notmatch [regex]::Escape($line)) {
    Copy-Item -LiteralPath $profileFile -Destination "$profileFile.bak.$(Get-Date -Format yyyyMMddHHmmssfff)" -Force
    Add-Content -LiteralPath $profileFile -Value ([Environment]::NewLine + '# >>> powershell7-dev-kit >>>' + [Environment]::NewLine + $line + [Environment]::NewLine + '# <<< powershell7-dev-kit <<<')
}
Write-Host 'Restart PowerShell 7 and select a Nerd Font in Windows Terminal.' -ForegroundColor Green
