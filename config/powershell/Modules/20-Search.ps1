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

function ftext {
    # Search literal file contents, then open the selected match at its line.
    foreach ($tool in 'rg', 'fzf', 'nvim') {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            Write-Warning "Missing $tool on PATH."
            return
        }
    }

    $query = if ($args.Count) { $args -join ' ' } else { Read-Host 'Search text (literal)' }
    if ([string]::IsNullOrWhiteSpace($query)) { return }

    $selected = & rg --no-config --no-heading --with-filename --line-number --color=never -F -- $query . |
        & fzf --layout=reverse --height=60% --no-multi --exit-0
    if (-not $selected) { return }
    if ($selected -notmatch '^(?<path>.+?):(?<line>[1-9][0-9]*):') {
        Write-Warning 'Could not read the selected file and line.'
        return
    }
    $file = $Matches['path']
    $line = $Matches['line']
    if (Test-Path -LiteralPath $file -PathType Leaf) {
        & nvim "+$line" -- $file
    } else {
        Write-Warning 'The selected file no longer exists.'
    }
}

function vf {
    param([string]$Action = 'help')
    $words = $args
    switch ($Action) {
        'files' { ff }
        'grep'  { ftext @words }
        'help'  { Write-Host 'vf files | vf grep [text] | vf help' }
        default { Write-Warning "Unknown command: $Action. Run vf help." }
    }
}

if ((Get-Command Get-PSReadLineOption -ErrorAction SilentlyContinue) -and
    (Get-PSReadLineOption).EditMode -eq 'Vi') {
    try {
        Set-PSReadLineKeyHandler -ViMode Command -Chord ':' -BriefDescription 'DevKitEx' -ScriptBlock {
            $line = $null
            $cursor = 0
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
            # Do not replace or append to a command the user is already editing.
            if ($line.Length -ne 0) { return }
            [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert('vf ')
        } -ErrorAction Stop
    } catch { Write-Verbose "DevKit : command entry unavailable: $_" }
}
