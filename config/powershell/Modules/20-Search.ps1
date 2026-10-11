# Ctrl+R: history search; Ctrl+T: file selection while editing.
if ((Get-Command fzf -ErrorAction SilentlyContinue) -and
    (Get-Module -ListAvailable -Name PSFzf)) {
    Import-Module PSFzf -ErrorAction SilentlyContinue
    if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
        try {
            Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
        } catch { Write-Verbose "PSFzf key binding unavailable: $_" }
    }
}

function ff {
    # Pick a file and open it in Neovim. Supports filenames containing spaces.
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Warning 'fzf is not installed.'
        return
    }
    if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
        Write-Warning 'Neovim is not installed.'
        return
    }
    if (Get-Command rg -ErrorAction SilentlyContinue) {
        $selected = & rg --files --hidden -g '!**/.git/**' | & fzf --layout=reverse --height=60%
    } else {
        $selected = Get-ChildItem -File -Recurse -Name -ErrorAction SilentlyContinue |
            & fzf --layout=reverse --height=60%
    }
    if ($selected) { & nvim -- $selected }
}
