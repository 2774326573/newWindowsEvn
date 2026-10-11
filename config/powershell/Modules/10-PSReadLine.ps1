# Vim-style command-line editing (independent from Neovim itself).
# Every setting is applied independently: one unsupported option must not silently
# disable the rest. For example, a console without virtual terminal processing
# rejects -PredictionSource, which previously skipped every setting after it.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    $options = @(
        @{ EditMode            = 'Vi' }
        @{ ViModeIndicator     = 'Cursor' }
        @{ HistoryNoDuplicates = $true }
        @{ PredictionSource    = 'History' }
        @{ PredictionViewStyle = 'InlineView' }
    )
    foreach ($option in $options) {
        try { Set-PSReadLineOption @option -ErrorAction Stop }
        catch { Write-Verbose "PSReadLine: $($option.Keys -join ',') unavailable: $_" }
    }
}
