# newWindowsEvn — PowerShell 7 + Neovim Windows development environment

A reproducible **keyboard-first Windows 10/11 x64** developer terminal: PowerShell 7 with PSReadLine Vi editing, Neovim, Yazi, Lazygit, fzf/PSFzf, zoxide, Oh My Posh, Git, Xmake and CMake.

**Neovim remains the code editor.** The shell launches workflows, and all shell configuration is split into focused modules. The installer does not change your existing Neovim configuration.

## Quick start (online)

Prerequisites: Windows 10/11 x64, WinGet, PowerShell 7 and Git. Run from a normal PowerShell 7 terminal; use elevation only when a particular publisher installer requires it.

```powershell
git clone https://github.com/2774326573/newWindowsEvn.git
cd newWindowsEvn
pwsh -NoProfile -File .\scripts\Install-Online.ps1

# Restart PowerShell 7 to update PATH, then:
pwsh -NoProfile -File .\scripts\Install-YaziPlugins.ps1
pwsh -NoProfile -File .\scripts\Install-Config.ps1
pwsh -NoProfile -File .\scripts\Test-Syntax.ps1
pwsh -NoProfile -File .\scripts\Test-Environment.ps1
```

Open a **new PowerShell 7** window and run `devhelp`. `Install-Config.ps1` keeps differing files; to upgrade an existing deployment after reviewing changes, use `-Force` (which creates timestamped backups).

## Keyboard shortcuts

| Command / shortcut | Purpose |
| --- | --- |
| `Esc`, `i`, `h`, `l`, `w`, `b` | PSReadLine Vi editing |
| `Ctrl+R`, `Ctrl+T` | Fuzzy history / file selection |
| `v .`, `ff` | Open Neovim / pick a file |
| `y`, `z keyword` | Yazi (directory sync) / zoxide navigation |
| `ll`, `catp file` | File icons on demand / bat preview |
| `gs`, `gd`, `gl`, `lg`, `croot` | Git shortcuts / Lazygit / repository root |
| `build`, `cmconfig`, `cmtest` | Xmake or CMake build / configure / test |

More examples in [docs/WORKFLOW.md](docs/WORKFLOW.md). Detailed error handling in [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## Layout

```text
config/
  packages.txt                  # WinGet IDs shared by online/offline scripts
  powershell/
    DevKit.ps1                  # lightweight module loader
    Modules/
      10-PSReadLine.ps1
      20-Search.ps1
      30-Navigation.ps1
      40-Git.ps1
      50-Build.ps1
      60-Prompt.ps1
      70-Help.ps1
  yazi/                         # existing Yazi configuration
scripts/
  Install-Online.ps1
  Install-YaziPlugins.ps1
  Install-Config.ps1
  Test-Syntax.ps1
  Test-Environment.ps1
  Uninstall-Config.ps1
  Prepare-Offline.ps1
  Restore-Offline.ps1
docs/
  WORKFLOW.md
  TROUBLESHOOTING.md
  SOURCES.md
offline/                        # ignored local download cache
themes/                         # repo-owned fallback theme
```

## Offline deployment

On a networked Windows x64 machine with PowerShell 7 and WinGet:

```powershell
pwsh -NoProfile -File .\scripts\Prepare-Offline.ps1
```

Copy the whole folder, including the Git-ignored `offline/` cache, using removable media. On the target machine, install appropriate verified third-party packages from `offline/installers` and install PowerShell 7 first if needed. Then:

```powershell
pwsh -NoProfile -File .\scripts\Restore-Offline.ps1
pwsh -NoProfile -File .\scripts\Test-Environment.ps1
```

The offline restoration verifies cached SHA-256 files, restores modules and Yazi plugins, and installs configs; it **does not silently install every downloaded program**. Some downloads may require manual acquisition. Hashes from the same cache are an integrity check, not a vendor-signature verification.

## Development scope & safety

- For DC / NodeFlow C++/Qt, install **MSVC Build Tools**, Windows SDK, Qt, HALCON, camera/PLC SDKs and appropriate licenses separately. Visual Studio IDE is optional; the C++ compiler is not.
- Windows Terminal needs a separately installed Nerd Font for fancy prompt icons. **No font files** or third-party binaries are committed.
- No invasive changes to proxies, VPN, Windows security, organization policy, or firewall are performed.
- Scripts back up changed configs on `-Force`. Roll back the profile integration using `scripts/Uninstall-Config.ps1`.
- Treat this public repository as configuration/scripts only. Do not publish API keys, machine credentials, vendor SDKs, cached installers or license files.
