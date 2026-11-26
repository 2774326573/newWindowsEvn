# PowerShell 7 + Neovim keyboard-first workflow

The terminal is the command launcher; Neovim remains the editor. This setup does **not** replace or overwrite your Neovim Lua configuration.

## Daily usage

1. Open Windows Terminal with the **PowerShell 7** profile.
2. `z nodeflow` or `z dc` after zoxide has learned those directories, or `cd D:\\Projects\\nodeflow`.
3. `v .` opens Neovim; `ff` selects a file with fzf; `y` opens Yazi and returns to the selected directory.
4. `gs` for Git status, `lg` for Lazygit, `croot` to return to the Git repository root.
5. `build` from a folder with `xmake.lua` uses Xmake; in a configured CMake project (`build/CMakeCache.txt`) it uses `cmake --build build`.
6. `cmconfig` creates a CMake build directory; `cmtest` runs CTest there. Use project-specific build instructions where required.
7. `devhelp` prints the shortcut reference.

## Optional Neovim Yazi bridge

The normal environment install leaves your Neovim configuration untouched. If you want Yazi inside Neovim as a floating file manager, opt in on Windows 11+:

```powershell
.\install.ps1 -WithYaziNvim
# Existing installation:
.\install.ps1 -ConfigOnly -WithYaziNvim
```

This adds a backed-up Lazy.nvim spec only; it does not replace Neo-tree or the existing PowerShell `y` command. Run `:Lazy sync` once, then use `<leader>fy` for the current file or `<leader>fY` for the working directory. See [Neovim + Yazi](NEOVIM-YAZI.md). Windows 10 keeps the terminal Yazi workflow and skips this bridge.

## Command-line Vi mode

PSReadLine enables `Set-PSReadLineOption -EditMode Vi`. Press `Esc` for normal mode and `i` for insert mode. The cursor indicator requires terminal support. These are **command-line** keys, not a full Vim instance.

PSFzf maps **Ctrl+R** to fuzzy history search and **Ctrl+T** to fuzzy path selection. The PSFzf key mappings are separate from Yazi's or Neovim's own bindings.

## File and text search

- `ff` or `vf files`: pick a filename and open it in Neovim.
- `ftext '关键词'` or `vf grep '关键词'`: search file contents literally with ripgrep, select a result in fzf, and open Neovim at that line. Without a keyword, `ftext` asks for one. ripgrep honors the project's ignore files.
- Press `Esc`, then `:` on an **empty** command line. It inserts `vf ` and returns to insert mode. Type `files`, `grep '关键词'`, or `help`, then Enter. This is a Vim-style entry to the supported shortcuts, not a Vim Ex interpreter. It never replaces an in-progress command.
- In fzf, use Ctrl+N / Ctrl+P to navigate and Enter to select. Tab completion and Ctrl+R history bindings are unchanged.

## Configuration ownership

`config/powershell/DevKit.ps1` loads sorted scripts from `config/powershell/Modules`:
- `10-PSReadLine.ps1`: Vi mode and history
- `20-Search.ps1`: fzf + PSFzf bindings + `ff`, `ftext`, `vf`
- `30-Navigation.ps1`: `v`, `ll`, `catp`, `y`, zoxide
- `40-Git.ps1`: read-only Git shortcuts + Lazygit
- `50-Build.ps1`: Xmake/CMake routing
- `60-Prompt.ps1`: local Oh My Posh theme
- `70-Help.ps1`: `devhelp`

To customize, edit the **repository copies**, then run `scripts/Install-Config.ps1 -Force` to back up deployed copies and deploy changes. Alternatively edit the deployed copies locally without overwriting them.

## Windows C++ / Qt / HALCON development

- A command-line editor does **not** provide a compiler. Build DC/NodeFlow with their required **MSVC toolchain**, Windows SDK, Qt, HALCON and vendor SDKs installed separately.
- Visual Studio **Build Tools** plus the applicable C++ workload may be enough for MSVC compilation without using the Visual Studio IDE.
- Open an MSVC developer shell or initialize the compiler environment before building MSVC-dependent targets.
- Xmake and CMake are build tools and do not replace Qt/HALCON SDK licenses or compiler installation.
- Keep product SDKs, licenses, secrets, private paths, downloaded installers and fonts out of this public repository.

## Quick verification

```powershell
pwsh -NoProfile -File .\scripts\Test-Syntax.ps1
pwsh -NoProfile -File .\scripts\Test-Environment.ps1
# Restart the terminal; then type:
devhelp
Get-PSReadLineOption | Select-Object EditMode
```
