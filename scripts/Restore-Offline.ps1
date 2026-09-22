#requires -Version 7.0
[CmdletBinding()]
param([switch]$Force)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$off = Join-Path $root 'offline'
$manifest = Join-Path $off 'SHA256SUMS.csv'
if (-not (Test-Path -LiteralPath $manifest)) { throw 'Offline SHA256SUMS.csv missing. Run Prepare-Offline.ps1 online and copy the full offline/ directory.' }
foreach ($entry in (Import-Csv -LiteralPath $manifest)) {
    $path = Join-Path $off $entry.Path
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing cached file $($entry.Path)" }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $entry.SHA256) { throw "Checksum mismatch: $($entry.Path)" }
}
Write-Host 'Offline cache integrity verified (this does not verify publisher authenticity).' -ForegroundColor Green
$srcModules = Join-Path $off 'modules'
if (Test-Path -LiteralPath $srcModules) {
    $modules = Join-Path $HOME 'Documents\PowerShell\Modules'
    New-Item -ItemType Directory -Force -Path $modules | Out-Null
    foreach ($name in @('PSFzf','Terminal-Icons')) {
        $src = Join-Path $srcModules $name
        if (-not (Test-Path -LiteralPath $src)) { continue }
        $dest = Join-Path $modules $name
        if (Test-Path -LiteralPath $dest) {
            if (-not $Force) { Write-Warning "Keeping existing module $dest"; continue }
            Move-Item -LiteralPath $dest -Destination "$dest.bak.$(Get-Date -Format yyyyMMddHHmmssfff)"
        }
        Copy-Item -LiteralPath $src -Destination $dest -Recurse
    }
}
& (Join-Path $PSScriptRoot 'Install-YaziPlugins.ps1') -Offline -Force:$Force
& (Join-Path $PSScriptRoot 'Install-Config.ps1') -Force:$Force
Write-Host 'Configuration restored. Install cached third-party programs and Nerd Font separately, then restart pwsh.' -ForegroundColor Green
