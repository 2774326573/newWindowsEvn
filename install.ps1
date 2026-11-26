# Windows 10/11 bootstrap; also works from Windows PowerShell 5.1.
[CmdletBinding()]
param([switch]$Check, [switch]$ConfigOnly, [switch]$SkipModules, [switch]$WithYaziNvim)
$ErrorActionPreference = 'Stop'
$python = $null
foreach ($name in @('python', 'python3')) {
    $candidate = Get-Command $name -ErrorAction SilentlyContinue
    if ($candidate) {
        & $candidate.Source -c 'import sys; sys.exit(sys.version_info < (3,9))' 2>$null
        if ($LASTEXITCODE -eq 0) { $python = $candidate.Source; break }
    }
}
if (-not $python) {
    if ($Check -or $ConfigOnly) { throw 'Python 3.9+ required. Run install.ps1 without options first.' }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'Install Microsoft App Installer (WinGet), then rerun install.ps1.' }
    & winget install --id Python.Python.3.13 --exact --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) { throw "Python installation failed: $LASTEXITCODE" }
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
    $python = Join-Path $env:LOCALAPPDATA 'Programs\Python\Python313\python.exe'
    if (-not (Test-Path -LiteralPath $python)) { $python = (Get-Command python -ErrorAction Stop).Source }
}
$installArgs = @((Join-Path $PSScriptRoot 'scripts\install.py'))
if ($Check) { $installArgs += '--check' }
if ($ConfigOnly) { $installArgs += '--config-only' }
if ($SkipModules) { $installArgs += '--skip-modules' }
if ($WithYaziNvim) { $installArgs += '--with-yazi-nvim' }
& $python @installArgs
exit $LASTEXITCODE
