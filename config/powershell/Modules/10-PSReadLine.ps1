# Vim-style command-line editing (independent from Neovim itself).
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    try {
        Set-PSReadLineOption -EditMode Vi -ErrorAction Stop
        Set-PSReadLineOption -ViModeIndicator Cursor -ErrorAction Stop
        Set-PSReadLineOption -HistoryNoDuplicates -ErrorAction Stop
        Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView -ErrorAction Stop
    } catch {
        Write-Verbose "PSReadLine customization unavailable: $_"
    }
}
