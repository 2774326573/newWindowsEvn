#requires -Version 7.0
# Push reviewed source files to the EXISTING repository; never creates or force-pushes.
[CmdletBinding()]
param([string]$Repository='git@github.com:2774326573/newWindowsEvn.git')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Install Git first.' }
    if (-not (Test-Path '.git')) { & git init -b main; if ($LASTEXITCODE -ne 0) { throw 'git init failed' } }
    $remote = & git remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0) { & git remote add origin $Repository }
    elseif ($remote -ne $Repository -and $remote -ne 'https://github.com/2774326573/newWindowsEvn.git') {
        throw "Unexpected origin: $remote. Review before changing it."
    }
    & git add README.md .gitignore config themes scripts docs
    if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
    & git diff --cached --check
    if ($LASTEXITCODE -ne 0) { throw 'Whitespace errors in staged files' }
    & git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        & git commit -m 'Update Windows developer terminal'
        if ($LASTEXITCODE -ne 0) { throw 'Commit failed: configure git user.name/user.email first.' }
    }
    & git push -u origin HEAD:main
    if ($LASTEXITCODE -ne 0) { throw 'Push failed: check SSH, network and remote branch history.' }
    Write-Host 'Pushed to 2774326573/newWindowsEvn main' -ForegroundColor Green
} finally { Pop-Location }
