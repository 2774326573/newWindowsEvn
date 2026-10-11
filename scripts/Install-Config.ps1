#requires -Version 7.0
[CmdletBinding()]
param([switch]$Force)
$ErrorActionPreference = 'Stop'
if (-not $env:APPDATA) { throw 'Windows APPDATA required.' }
$root = Split-Path -Parent $PSScriptRoot
$cfg = Join-Path $HOME '.config\powershell7-dev-kit'

function Copy-Safe([string]$Source, [string]$Target) {
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Source missing: $Source" }
    $parent = Split-Path -Parent $Target
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    if (Test-Path -LiteralPath $Target) {
        $srcHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash
        if ($srcHash -eq $dstHash) { return }
        if (-not $Force) {
            Write-Warning "Keeping existing $Target; use -Force to back it up and replace."
            return
        }
        Copy-Item -LiteralPath $Target -Destination "$Target.bak.$(Get-Date -Format yyyyMMddHHmmssfff)" -Force
    }
    Copy-Item -LiteralPath $Source -Destination $Target -Force
    Write-Host "Installed: $Target"
}

Copy-Safe (Join-Path $root 'config\powershell\DevKit.ps1') (Join-Path $cfg 'DevKit.ps1')
$modulesSrc = Join-Path $root 'config\powershell\Modules'
$modulesDest = Join-Path $cfg 'Modules'
foreach ($file in (Get-ChildItem -LiteralPath $modulesSrc -Filter '*.ps1' -File | Sort-Object Name)) {
    Copy-Safe $file.FullName (Join-Path $modulesDest $file.Name)
}

$official = Join-Path $root 'offline\powerlevel10k_rainbow.omp.json'
if (Test-Path -LiteralPath $official -PathType Leaf) { $themeSource = $official }
else {
    $themeSource = Join-Path $root 'themes\10k-local.omp.json'
    Write-Host 'Using the repository 10k-inspired offline-safe theme.'
}
Copy-Safe $themeSource (Join-Path $cfg 'powerlevel10k_rainbow.omp.json')

$ycfg = Join-Path $env:APPDATA 'yazi\config'
foreach ($name in @('init.lua','yazi.toml','keymap.toml')) {
    Copy-Safe (Join-Path $root "config\yazi\$name") (Join-Path $ycfg $name)
}

$fileExe = 'C:\Program Files\Git\usr\bin\file.exe'
if (Test-Path -LiteralPath $fileExe -PathType Leaf) {
    [Environment]::SetEnvironmentVariable('YAZI_FILE_ONE', $fileExe, 'User')
}

$profileFile = $PROFILE.CurrentUserCurrentHost
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $profileFile) | Out-Null
if (-not (Test-Path -LiteralPath $profileFile)) {
    New-Item -ItemType File -Path $profileFile | Out-Null
}
$line = '. (Join-Path $HOME ''.config\powershell7-dev-kit\DevKit.ps1'')'
$existing = Get-Content -LiteralPath $profileFile -Raw -ErrorAction SilentlyContinue
if ($existing -notmatch [regex]::Escape($line)) {
    Copy-Item -LiteralPath $profileFile -Destination "$profileFile.bak.$(Get-Date -Format yyyyMMddHHmmssfff)" -Force
    Add-Content -LiteralPath $profileFile -Value (
        [Environment]::NewLine + '# >>> powershell7-dev-kit >>>' +
        [Environment]::NewLine + $line +
        [Environment]::NewLine + '# <<< powershell7-dev-kit <<<'
    )
    Write-Host "Updated PowerShell 7 profile: $profileFile"
}
Write-Host 'Done. Restart PowerShell 7, then run devhelp.' -ForegroundColor Green
