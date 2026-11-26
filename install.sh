#!/bin/sh
# POSIX bootstrap. Package manager actions can ask for sudo in this terminal.
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if ! command -v python3 >/dev/null 2>&1; then
    case "${1:-}" in --check|--config-only|--offline) echo 'Python 3.9+ required; no changes made.'; exit 1 ;; esac
    case "$(uname -s)" in
        Darwin)
            if ! command -v brew >/dev/null 2>&1; then
                if [ -x /opt/homebrew/bin/brew ]; then PATH="/opt/homebrew/bin:$PATH"; export PATH
                elif [ -x /usr/local/bin/brew ]; then PATH="/usr/local/bin:$PATH"; export PATH
                else echo 'Homebrew required: install from https://brew.sh and rerun.'; exit 1; fi
            fi
            brew install python ;;
        Linux)
            if [ "$(id -u)" = 0 ]; then SUDO=''; else SUDO='sudo'; fi
            if command -v apt-get >/dev/null 2>&1; then $SUDO apt-get update; $SUDO apt-get install -y python3
            elif command -v dnf >/dev/null 2>&1; then $SUDO dnf install -y python3
            elif command -v pacman >/dev/null 2>&1; then $SUDO pacman -S --needed --noconfirm python
            elif command -v zypper >/dev/null 2>&1; then $SUDO zypper --non-interactive install python3
            elif command -v apk >/dev/null 2>&1; then $SUDO apk add python3
            else echo 'Unsupported package manager. Install Python 3.9+ and rerun.'; exit 1; fi ;;
        *) echo 'Unsupported operating system'; exit 1 ;;
    esac
fi
exec python3 scripts/install.py "$@"
