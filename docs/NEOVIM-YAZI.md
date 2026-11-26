# Optional Neovim + Yazi integration

newWindowsEvn already installs and configures the Yazi executable, preview tools and Yazi-side plugins. This optional integration adds the Neovim bridge `mikavilpas/yazi.nvim`; it does not install a second Yazi binary.

## Enable it

Windows 11 or later, after cloning this repository:

```powershell
.\install.ps1 -WithYaziNvim
```

If the base environment is already installed and only the Neovim plugin spec is needed:

```powershell
.\install.ps1 -ConfigOnly -WithYaziNvim
```

Linux/macOS (with the base Yazi environment already installed):

```sh
python3 scripts/install.py --config-only --with-yazi-nvim
```

Offline Windows restore also accepts:

```powershell
.\scripts\Restore-Offline.ps1 -WithYaziNvim
```

The option deploys `config/nvim/lua/plugins/yazi.lua` to the active Neovim config's `lua/plugins/yazi.lua`. It never edits `init.lua`, other plugin specs, or the user's Yazi configuration. If a file with that exact name already exists, it is backed up as `yazi.lua.bak.TIMESTAMP` before replacement. Re-running is idempotent.

Config root resolution:
- Windows: `%LOCALAPPDATA%\nvim` (or `%LOCALAPPDATA%\%NVIM_APPNAME%`)
- Linux/macOS: `$XDG_CONFIG_HOME/nvim`, otherwise `~/.config/nvim`
- Override: set `NVIM_CONFIG_HOME` to the exact Neovim config directory.

## Activate in Neovim

The deployed file is a Lazy.nvim plugin spec. It requires an existing Lazy.nvim setup that loads `lua/plugins/*.lua`.

```vim
:Lazy sync
:checkhealth yazi
```

| Shortcut | Action |
| --- | --- |
| `<leader>fy` | Open Yazi at the current file |
| `<leader>fY` | Open Yazi at Neovim's current working directory |

Neo-tree remains the in-editor tree. The existing PowerShell/Bash/Zsh `y` command remains unchanged. The bridge does not hijack directory opening and does not change Neovim's working directory when closed.

## Platform and offline notes

- The yazi.nvim upstream currently requires Windows 11 or later. On Windows 10, the optional switch is rejected before deployment; the repository's existing Yazi CLI workflow continues to work.
- Linux and macOS can use the optional bridge where Neovim, Lazy.nvim and Yazi are installed.
- The plugin spec is deployed locally; the plugin source is fetched by Lazy.nvim. Run `:Lazy sync` while online before going offline, then include the Neovim plugin data directory (including `yazi.nvim` and its dependencies such as `plenary.nvim`) in your own offline Neovim backup. The newWindowsEvn offline cache does not silently bundle a second Neovim distribution.
- The bridge needs the same `yazi` executable installed by this repository. No duplicate Yazi package or extra Yazi configuration is created.

Upstream: [mikavilpas/yazi.nvim](https://github.com/mikavilpas/yazi.nvim).
