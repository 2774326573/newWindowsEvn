function devhelp {
    $lines = @(
        'PowerShell 7 + Neovim workflow'
        '  Esc/i/h/j/k/l/w/b   Vi-style command editing (PSReadLine)'
        '  Ctrl+R / Ctrl+T     Search history / select a path (PSFzf)'
        '  v [file]            Open Neovim'
        '  ff                  Pick a file with fzf and edit in Neovim'
        '  y                   Yazi with directory sync on exit'
        '  z <keyword>         Jump to a previously visited directory'
        '  ll / catp           Directory list / syntax-highlighted preview'
        '  gs / gd / gl        Git status / diff / short log'
        '  lg / croot          Lazygit / go to Git repository root'
        '  build               Auto-detect xmake or configured CMake'
        '  cmconfig / cmtest   Configure CMake / run CTest'
        '  devhelp             Show these shortcuts'
    )
    $lines | ForEach-Object { Write-Host $_ }
}
