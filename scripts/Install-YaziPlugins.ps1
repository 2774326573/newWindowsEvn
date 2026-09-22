#requires -Version 7.0
[CmdletBinding()]
param([switch]$Offline, [switch]$Force)
$ErrorActionPreference = 'Stop'
if (-not $env:APPDATA) { throw 'Windows APPDATA required.' }
$root = Split-Path -Parent $PSScriptRoot
$pluginRoot = Join-Path $env:APPDATA 'yazi\config\plugins'
New-Item -ItemType Directory -Force -Path $pluginRoot | Out-Null
foreach ($name in @('git','smart-enter','full-border','diff')) {
    $dest = Join-Path $pluginRoot "$name.yazi"
    if (Test-Path -LiteralPath $dest) {
        if (-not $Force) { Write-Host "Already present: $dest"; continue }
        Move-Item -LiteralPath $dest -Destination "$dest.bak.$(Get-Date -Format yyyyMMddHHmmssfff)"
    }
    if ($Offline) {
        $src = Join-Path $root "offline\plugins\$name.yazi"
        if (-not (Test-Path -LiteralPath (Join-Path $src 'main.lua'))) { throw "Offline plugin missing: $src" }
        Copy-Item -LiteralPath $src -Destination $dest -Recurse
    } else {
        if (-not (Get-Command ya -ErrorAction SilentlyContinue)) { throw 'ya not found. Install Yazi and reopen pwsh first.' }
        & ya pkg add "yazi-rs/plugins:$name"
        if ($LASTEXITCODE -ne 0) { throw "Plugin install failed: $name" }
    }
    Write-Host "Installed plugin: $name" -ForegroundColor Green
}
