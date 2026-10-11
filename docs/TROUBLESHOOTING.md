# Troubleshooting

## Shell still uses Windows editing keys

Run `Get-PSReadLineOption | Select-Object EditMode` in a **new** PowerShell 7 window. It should show `Vi`. Check that the relevant `$PROFILE.CurrentUserCurrentHost` sources `~/.config/powershell7-dev-kit/DevKit.ps1`, and that the `Modules` directory exists. PowerShell 5.1 and PowerShell 7 use different profile locations.

## Ctrl+R / Ctrl+T not responding

Confirm `Get-Module -ListAvailable PSFzf`, `Get-Command fzf` and PSReadLine loaded successfully. Another module or terminal key mapping may claim the shortcut. Use `Get-PSReadLineKeyHandler` to inspect actual bindings.

## Icons show squares

Install a Nerd Font from its official source; select it under Windows Terminal > Settings > Profiles > PowerShell > Appearance. This repository never bundles font files.

## Yazi previews missing or plugin fails

Check `ya --version`, `yazi --version`, `$env:YAZI_FILE_ONE` and the directories under `$env:APPDATA\yazi\config\plugins`. Follow `docs/SOURCES.md` for the compatible Yazi plugin release. Upstream plugins may require an up-to-date Yazi version.

## Existing configuration wasn't replaced

This is intentional. `Install-Config.ps1` preserves differing files. Review the warning and your changes, then explicitly run `Install-Config.ps1 -Force` if you want automatic backup and replacement. The profile loader is idempotent.

## Build command fails

`build` only detects the current directory: `xmake.lua` or `build/CMakeCache.txt`. Check compiler selection, the required Qt/HALCON dependencies, and the MSVC developer environment. `cl` may be unavailable in an ordinary PowerShell session even when MSVC Build Tools is installed.

## Offline install / company-managed machine

`Restore-Offline.ps1` verifies SHA-256 of copied files, then restores modules/plugins/config. Third-party application installers must be installed separately. The checksum manifest detects accidental changes; it does **not** prove publisher authenticity.

For networking problems, diagnose hotspot signal quality, DNS, routes, proxy and TCP reachability separately. Do not remove workplace endpoint protection or bypass organizational policies. Installer access and network authorization may require IT approval.

## Roll back managed profile integration

Run `pwsh -NoProfile -File .\scripts\Uninstall-Config.ps1`. It backs up the profile, removes only the managed marked block and does not delete other user configuration or uninstall applications.
