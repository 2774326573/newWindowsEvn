# Portable common-file deployment

Keep existing config/scripts/docs boundaries. PowerShell 5.1 and POSIX shell are
small bootstraps; scripts/install.py is the single deployment/verification engine
using Python 3.9+ and no Python packages. config/file-tools.json owns package IDs.
The Windows offline cache list additionally includes native terminal tools.

The repository-owned Office adapter belongs in config/yazi/plugins. The previously
considered office.yazi hardcodes Unix paths/executable names; generate local
Python/helper/dependency paths instead. LibreOffice converts locally with an
isolated profile and macros disabled. Poppler renders one bounded-size page.
No remote converter, daemon or unnecessary service layers are introduced.

Back up differing configs, preserve profile content outside marked blocks, skip
already-installed tools and fail before configuration deployment if dependencies
are missing. Installation processes have timeouts; Ctrl+C kills child process groups.
The Windows preview helper uses a Job Object to terminate LibreOffice descendants
when the helper exits. Conversions time out and clean temporary work on normal/error exit.

Support OS/package-manager adapters, not all historical OS versions. macOS needs
Homebrew; distro repositories must supply requested dependencies. Use the official
digest-verified musl Yazi 26.9.1 release on Linux x86_64/ARM64 to avoid stale APIs.
Keep native shell integration: PowerShell on Windows, Bash/Zsh on Unix, without
switching the user's login shell. Optional Unix developer tools remain separate.

Tests cover config paths, package mappings, backups/idempotence, profile content,
unsupported inputs, process timeout and generated DOCX/XLSX/PPTX/PDF conversion.
CI unit tests run on Windows/Linux/macOS, conversion on Linux. Terminal image
rendering and application associations need interactive local validation.
