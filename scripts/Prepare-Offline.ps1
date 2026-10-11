#requires -Version 7.0
[CmdletBinding()]
param([switch]$SkipInstallers, [switch]$SkipModules)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$off = Join-Path $root 'offline'
New-Item -ItemType Directory -Force -Path $off | Out-Null
if (-not $SkipInstallers) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'WinGet required for online installer caching.' }
    $ids = Get-Content -LiteralPath (Join-Path $root 'config\packages.txt') |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') }
    foreach ($id in $ids) {
        $dest = Join-Path $off "installers\$id"
        New-Item -ItemType Directory -Force -Path $dest | Out-Null
        & winget download --id $id --exact --source winget --architecture x64 --download-directory $dest --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) { Write-Warning "Unable to cache $id; manually download its Windows x64 installer from official publisher." }
    }
}
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/powerlevel10k_rainbow.omp.json' -OutFile (Join-Path $off 'powerlevel10k_rainbow.omp.json')
$archive = Join-Path $off 'yazi-plugins-upstream.zip'
Invoke-WebRequest -Uri 'https://github.com/yazi-rs/plugins/archive/refs/heads/main.zip' -OutFile $archive
$tmp = Join-Path $off '_plugin_extract'
if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
Expand-Archive -LiteralPath $archive -DestinationPath $tmp
foreach ($name in @('git','smart-enter','full-border','diff')) {
    $source = Join-Path $tmp "plugins-main\$name.yazi"
    if (-not (Test-Path -LiteralPath (Join-Path $source 'main.lua'))) { throw "Missing upstream plugin $name" }
    $dest = Join-Path $off "plugins\$name.yazi"
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    Copy-Item -LiteralPath $source -Destination $dest -Recurse
}
Remove-Item -LiteralPath $tmp -Recurse -Force
if (-not $SkipModules) {
    $modDir = Join-Path $off 'modules'
    New-Item -ItemType Directory -Force -Path $modDir | Out-Null
    foreach ($name in @('PSFzf','Terminal-Icons')) {
        try { Save-Module -Name $name -Path $modDir -Repository PSGallery -Force -ErrorAction Stop }
        catch { Write-Warning "Optional PowerShell module $name unavailable: $_" }
    }
}
Get-ChildItem -LiteralPath $off -File -Recurse |
    Where-Object { $_.Name -ne 'SHA256SUMS.csv' } |
    ForEach-Object { [pscustomobject]@{ Path = [IO.Path]::GetRelativePath($off, $_.FullName); SHA256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash } } |
    Export-Csv -LiteralPath (Join-Path $off 'SHA256SUMS.csv') -NoTypeInformation -Encoding UTF8
Write-Host 'Offline cache prepared. Copy the entire folder to USB. Do not commit cached installers or fonts.' -ForegroundColor Green
