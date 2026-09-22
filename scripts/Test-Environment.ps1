#requires -Version 7.0
$checks = @(
    @{ Name='PowerShell 7'; Command='pwsh' },
    @{ Name='Windows Terminal'; Command='wt' },
    @{ Name='Git'; Command='git' },
    @{ Name='Oh My Posh'; Command='oh-my-posh' },
    @{ Name='Yazi'; Command='yazi' },
    @{ Name='Yazi package manager'; Command='ya' },
    @{ Name='Lazygit'; Command='lazygit' },
    @{ Name='fzf'; Command='fzf' },
    @{ Name='zoxide'; Command='zoxide' },
    @{ Name='bat'; Command='bat' },
    @{ Name='ripgrep'; Command='rg' },
    @{ Name='fd'; Command='fd' }
)
$checks | ForEach-Object {
    [pscustomobject]@{ Name=$_.Name; Command=$_.Command; Available=[bool](Get-Command $_.Command -ErrorAction SilentlyContinue) }
} | Format-Table -AutoSize
Write-Host "Local theme: $(Test-Path -LiteralPath (Join-Path $HOME '.config\powershell7-dev-kit\powerlevel10k_rainbow.omp.json'))"
Write-Host 'Also check Nerd Font rendering, Yazi keybindings and preview interactively on Windows.'
