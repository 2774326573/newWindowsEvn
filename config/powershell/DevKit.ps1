# PowerShell 7 terminal setup. All startup resources are local.
$theme = Join-Path $HOME '.config\powershell7-dev-kit\powerlevel10k_rainbow.omp.json'
if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $theme)) {
    oh-my-posh init pwsh --config $theme | Invoke-Expression
}
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    try {
        Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView -ErrorAction Stop
    } catch { Write-Verbose "PSReadLine prediction unavailable: $_" }
}
function ll {
    if (-not (Get-Module Terminal-Icons) -and (Get-Module -ListAvailable Terminal-Icons)) {
        Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    }
    Get-ChildItem -Force @args
}
if ((Get-Command fzf -ErrorAction SilentlyContinue) -and (Get-Module -ListAvailable PSFzf)) {
    Import-Module PSFzf -ErrorAction SilentlyContinue
    if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    }
}
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    zoxide init powershell | Out-String | Invoke-Expression
}
function y {
    if (-not (Get-Command yazi -ErrorAction SilentlyContinue)) { Write-Warning 'yazi not found'; return }
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        yazi @args --cwd-file="$tmp"
        $cwd = Get-Content -LiteralPath $tmp -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($cwd) {
            $cwd = $cwd.Trim()
            if ($cwd -and $cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
                Set-Location -LiteralPath $cwd
            }
        }
    } finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
}
function lg { if (Get-Command lazygit -ErrorAction SilentlyContinue) { lazygit @args } else { Write-Warning 'lazygit not found' } }
function catp { if (Get-Command bat -ErrorAction SilentlyContinue) { bat @args } else { Get-Content @args } }
