# Prefer local theme (works offline); avoid startup network calls.
$theme = Join-Path $HOME '.config\powershell7-dev-kit\powerlevel10k_rainbow.omp.json'
if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and
    (Test-Path -LiteralPath $theme -PathType Leaf)) {
    try { & oh-my-posh init pwsh --config $theme | Invoke-Expression }
    catch { Write-Verbose "oh-my-posh initialization unavailable: $_" }
}
