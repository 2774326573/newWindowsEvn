#requires -Version 7.0
[CmdletBinding()]
param([switch]$Strict)
$ErrorActionPreference = 'Stop'
$checks = @(
    @{ Name='PowerShell 7'; Command='pwsh'; Required=$true },
    @{ Name='Windows Terminal'; Command='wt'; Required=$true },
    @{ Name='Git'; Command='git'; Required=$true },
    @{ Name='Neovim'; Command='nvim'; Required=$true },
    @{ Name='Yazi'; Command='yazi'; Required=$true },
    @{ Name='Yazi package manager'; Command='ya'; Required=$true },
    @{ Name='Lazygit'; Command='lazygit'; Required=$true },
    @{ Name='fzf'; Command='fzf'; Required=$true },
    @{ Name='zoxide'; Command='zoxide'; Required=$true },
    @{ Name='bat'; Command='bat'; Required=$true },
    @{ Name='ripgrep'; Command='rg'; Required=$true },
    @{ Name='fd'; Command='fd'; Required=$true },
    @{ Name='Xmake'; Command='xmake'; Required=$true },
    @{ Name='CMake'; Command='cmake'; Required=$true },
    @{ Name='Oh My Posh'; Command='oh-my-posh'; Required=$true },
    @{ Name='MSVC (optional)'; Command='cl'; Required=$false }
)
$results = foreach ($check in $checks) {
    [pscustomobject]@{
        Name = $check.Name
        Command = $check.Command
        Available = [bool](Get-Command $check.Command -ErrorAction SilentlyContinue)
        Required = $check.Required
    }
}
$results | Format-Table -AutoSize
$cfg = Join-Path $HOME '.config\powershell7-dev-kit'
$requiredFiles = @(
    (Join-Path $cfg 'DevKit.ps1'),
    (Join-Path $cfg 'Modules\10-PSReadLine.ps1'),
    (Join-Path $cfg 'Modules\50-Build.ps1'),
    (Join-Path $cfg 'powerlevel10k_rainbow.omp.json')
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
Write-Host "PSFzf installed: $([bool](Get-Module -ListAvailable PSFzf))"
Write-Host "Terminal-Icons installed: $([bool](Get-Module -ListAvailable Terminal-Icons))"
Write-Host "Deployed config files present: $($missingFiles.Count -eq 0)"
Write-Host 'Run devhelp in a NEW, interactive PowerShell 7 window to confirm profile loading.'
Write-Host 'Check Nerd Font rendering, Yazi plugins and MSVC development shell interactively.'
if ($Strict) {
    $missingTools = @($results | Where-Object { $_.Required -and -not $_.Available })
    if ($missingTools.Count -or $missingFiles.Count) {
        throw "Environment incomplete: $($missingTools.Count) required commands and $($missingFiles.Count) config files missing."
    }
}
