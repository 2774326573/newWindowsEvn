# newWindowsEvn — portable terminal and common-file workflow

One installation entry per OS, backed by the same Python standard-library engine.
Neovim edits code; Yazi browses and previews files; system-associated apps open
documents for full viewing/editing. Existing Neovim configuration is untouched by default; an explicit opt-in can add the Yazi bridge.

## One-command installation

Download/clone this repository, open a terminal in its directory, and run:

**Windows 10/11** (Windows PowerShell 5.1 or PowerShell 7):

Double-click **install.bat** after extracting the entire repository. It calls the
same installer, displays success/failure and keeps the window open for review.
No administrator launch is required up front; vendor installers may request elevation.
For terminal use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

**Linux / macOS**:

```sh
sh install.sh
```

Windows requires WinGet (Microsoft App Installer); Python 3.13 is installed if no
working Python 3.9+ exists. Linux bootstraps Python via the detected package manager
and may request sudo. macOS requires Homebrew; missing Python is installed via brew.
Internet access and permission to install packages are required. Machine execution
policies, proxies, security settings and the default login shell are not changed.

Existing commands are skipped. Missing dependencies are installed; compatible Yazi
and plugins are checked before configuration deployment. Every differing config is
backed up as `*.bak.TIMESTAMP` and replaced. Repeated installation does not append
duplicate profile blocks. Errors return a nonzero status; existing packages are not
bulk-upgraded. Review backups if you have custom Yazi bindings.

Reopen your terminal and run `y` (PowerShell 7/Bash/Zsh) or `yazi` (any shell).
Hover to preview, `J/K` to scroll preview pages, `O` for the default application,
`o` to choose an opener, `devhelp` for shell shortcuts. Use a graphical terminal
with Yazi image support for PDF/Office/image previews. Font rendering and GUI
application associations still require an interactive check.

## Optional Neovim + Yazi bridge

The default installer keeps your existing Neovim configuration untouched. On Windows 11+, opt in with `install.ps1 -WithYaziNvim`; on an existing installation use `install.ps1 -ConfigOnly -WithYaziNvim`. Linux/macOS can use `python3 scripts/install.py --config-only --with-yazi-nvim`. This deploys a Lazy.nvim spec with backup protection; it does not install another Yazi executable. Then run `:Lazy sync` in Neovim. Shortcuts: `<leader>fy` (current file) and `<leader>fY` (working directory). Windows 10 keeps the existing Yazi CLI workflow but does not enable yazi.nvim. See [Neovim + Yazi guide](docs/NEOVIM-YAZI.md).

## File coverage

| Files | Preview | Open/edit |
| --- | --- | --- |
| Text, source, Markdown, CSV/TSV | Text/code pane | Neovim; CSV/TSV default spreadsheet app |
| PDF | Standalone Poppler page images | Default PDF app |
| DOC/DOCX, XLS/XLSX, PPT/PPTX, ODT/ODS/ODP, RTF | LibreOffice -> PDF -> page image | Default Office app |
| Common images | Built-in image preview | Default image app |
| Video | FFmpeg thumbnails | Default media player |
| ZIP, 7z, TAR and supported archives | 7-Zip contents | Extract / system app |
| Other files | Metadata or available built-in preview | Default associated app (`O`) |

This is not a universal file decoder. Office previews use LibreOffice layout, cannot
edit cells or run macros, and may differ from Microsoft Office. Encrypted, corrupt,
unsupported and >200 MiB Office/PDF files require an external app. Conversions stay
local, use isolated temporary LibreOffice profiles with macros disabled, and time
out after 60 seconds; rasterization times out after 30 seconds. No watchers, servers
or login-time network requests are installed.

## Platform scope

| Platform | Route | Scope |
| --- | --- | --- |
| Windows 10 build 19041+ / Windows 11 | WinGet | Common files plus PS7/Vi/PSFzf, Lazygit, Xmake, CMake, Oh My Posh |
| Current Homebrew-supported macOS | brew, Intel/Apple Silicon | Common files, Neovim, fzf, zoxide, CMake, Bash/Zsh helpers |
| Debian/Ubuntu | apt-get | Common workflow; official static x86_64/ARM64 Yazi |
| Fedora/RHEL family | dnf | Adapter; repositories must supply dependencies including FFmpeg |
| Arch family | pacman | Adapter; repositories must supply dependencies |
| openSUSE | zypper | Adapter; repositories must supply dependencies |
| Alpine | apk | Adapter; GUI/image opening needs a graphical session |

**Not all OS versions are supported.** End-of-life systems, 32-bit Windows,
unsupported CPUs, locked-down repositories and headless GUI opening may fail
explicitly. Linux/macOS do not install PowerShell or Windows-only tools. Lazygit,
Xmake and prompt tools are optional separate Unix installs. Linux `batcat`,
`fdfind` and ImageMagick 6 `convert` are adapted to expected names. Yazi 26.9.1+
is required; future upstream breaking changes may need updates. A distro adapter
does not mean every historical distro version has been tested. Fish is not configured.

## Check and redeploy

```powershell
.\install.ps1 -Check       # read-only checks
.\install.ps1 -ConfigOnly  # use installed dependencies; back up and replace config
```

```sh
sh install.sh --check
sh install.sh --config-only
```

All platforms can also call `python scripts/install.py` (or `python3`) directly.
Respects `YAZI_CONFIG_HOME` and Unix `XDG_CONFIG_HOME`. Python/helper paths are
generated locally, never committed or copied from another machine. Rerun after
moving Python, LibreOffice or other dependency executables.

## C++ / Qt toolchain inventory

A read-only toolchain manager detects Visual Studio 2022 C++ tools, Windows SDK, Qt 5 kits, MinGW GCC, CMake, Xmake and OpenCV. It records two profiles: `qt5-msvc` and `qt5-mingw`, with C++20 and Qt 5 preferred (reference Qt 5.12.12). Qt 6 is not auto-installed. HALCON and vendor SDKs/licenses remain separately managed.

```powershell
pwsh -NoProfile -File .\scripts\Manage-Toolchain.ps1 -Profile qt5-msvc
pwsh -NoProfile -File .\scripts\Manage-Toolchain.ps1 -Profile qt5-mingw
pwsh -NoProfile -File .\scripts\Manage-Toolchain.ps1 -Mode Export -Output .\offline\toolchain-inventory.json
```

The manager reports installed components; it does not yet switch compilers or install licensed SDKs. See [C++ / Qt toolchain guide](docs/TOOLCHAIN.md).

## Offline Windows deployment

Run `pwsh -NoProfile -File .\scripts\Prepare-Offline.ps1` online, then copy the
complete directory including ignored `offline/`. Install cached vendor programs
(including Python, PowerShell 7, Poppler and LibreOffice) first, then run
`scripts/Restore-Offline.ps1`. It checks SHA-256, restores modules/cached plugins,
and calls the same config generator without downloads. It also includes `toolchain-inventory.json` for comparing the source and target C++/Qt environments; this report does not install licensed SDKs. Offline caching remains
Windows-specific; Unix installation currently needs online repositories. Cache
hashes verify copying integrity, not vendor authenticity. Do not commit installers,
credentials or licensed SDKs.

## Layout and validation

```text
install.bat                 Windows double-click entry
install.ps1 / install.sh     OS bootstrap, one-command entry
scripts/install.py          shared install/deploy/verify engine
config/file-tools.json      package IDs and distro aliases
config/toolchains.json      C++20 / Qt5 MSVC and MinGW profile policy
config/yazi/                Yazi rules and owned Office previewer
config/nvim/lua/plugins/    Optional Lazy.nvim Yazi bridge
config/powershell/          existing Windows shell modules
config/shell/devkit.sh      Bash/Zsh helpers
scripts/                    Windows compatibility/offline/check scripts, toolchain inventory
tests/                      backup, path, package and conversion tests
docs/                       workflows, troubleshooting, sources, toolchain and Neovim guides
```

```sh
python -m unittest discover -s tests -v
# Real generated DOCX/XLSX/PPTX/PDF conversion; LibreOffice/Poppler on PATH:
DEVKIT_INTEGRATION=1 python3 -m unittest discover -s tests -v
```

CI runs unit tests on Windows/Linux/macOS and real conversion on Linux. On Windows,
set `DEVKIT_RUNTIME` to the deployed previewer's runtime.json for explicit dependency
paths. PowerShell syntax: `scripts/Test-Syntax.ps1`; shell syntax: `sh -n install.sh`
and `bash -n config/shell/devkit.sh`. Interactive image rendering is a separate check.

MSVC, Windows SDK, Qt, HALCON, vendor SDKs/licenses and Nerd Fonts remain separate.
For Windows profile rollback use `scripts/Uninstall-Config.ps1`, then restore Yazi
backups as needed. On Unix remove the marked profile blocks and restore backups.
Uninstall third-party packages separately with the native package manager.

See [workflow](docs/WORKFLOW.md), [troubleshooting](docs/TROUBLESHOOTING.md),
[sources](docs/SOURCES.md), [design decision](docs/decisions/portable-files.md), [C++/Qt toolchain decision](docs/decisions/cpp-toolchain.md).
