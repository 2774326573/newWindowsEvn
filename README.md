# newWindowsEvn · Windows developer terminal

Windows 10/11 x64 + PowerShell 7 + Oh My Posh 10k-style theme + Yazi (git, smart-enter, full-border, diff) + Lazygit + fzf/PSFzf + zoxide + bat + ripgrep + fd.

**This is a public configuration repository, not an offline binary distribution.** No credentials, fonts, third-party installers or application binaries should be committed.

## Deploy on an online Windows PC

```powershell
git clone git@github.com:2774326573/newWindowsEvn.git
cd newWindowsEvn
pwsh -NoProfile -File .\scripts\Install-Online.ps1
# Open a new PowerShell 7 window to refresh PATH:
pwsh -NoProfile -File .\scripts\Install-YaziPlugins.ps1
pwsh -NoProfile -File .\scripts\Install-Config.ps1
pwsh -NoProfile -File .\scripts\Test-Environment.ps1
```

If SSH is not configured, use `https://github.com/2774326573/newWindowsEvn.git` instead of the SSH clone URL.

## Offline deployment

On an **online** Windows x64 computer with PowerShell 7 + a recent WinGet:

```powershell
pwsh -NoProfile -File .\scripts\Prepare-Offline.ps1
```

Copy the **entire** repository folder with its excluded `offline/` cache to a USB drive. Install the downloaded programs from `offline/installers/` on the offline PC, accounting for installer formats and dependencies. Then run:

```powershell
pwsh -NoProfile -File .\scripts\Restore-Offline.ps1
pwsh -NoProfile -File .\scripts\Test-Environment.ps1
```

The restore script verifies cached file hashes and restores modules, plugins, local theme and configuration; **it does not automatically install every third-party program**. Some WinGet packages may require manual download from the official publisher. Download and install a Nerd Font separately (font files are never distributed from this repository).

## Shortcuts

`y`: Yazi, with PowerShell directory sync on exit; `lg`: Lazygit; `ll`: file icons loaded on first use; `catp`: bat code preview; `Ctrl+R`: fuzzy history; `Ctrl+T`: fuzzy path; `z keyword`: jump directory.

Yazi: `l` smart-enter, `Ctrl+D` compare selected/hovered files, Git status indicators, rounded borders. For Git status on Windows, Yazi may need Git for Windows' `file.exe`; see `docs/SOURCES.md`.

## Safety / maintenance

Scripts back up differing existing configuration instead of silently overwriting it; review before using `-Force`. The checked-in `themes/10k-local.omp.json` is a **10k-inspired local fallback**, not the upstream Powerlevel10k theme. `Prepare-Offline.ps1` downloads the official `powerlevel10k_rainbow.omp.json`, which is preferred when available. Review `docs/SOURCES.md` for official upstream sources and licensing. Do not commit anything from `offline/` beyond its placeholder files.