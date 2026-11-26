# Sourced by Bash/Zsh only; no network or background jobs at startup.
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim
v() { nvim "$@"; }
lg() { lazygit "$@"; }
gs() { git status --short --branch "$@"; }
gd() { git diff "$@"; }
gl() { git log --oneline --decorate -n 12 "$@"; }
catp() { if command -v bat >/dev/null 2>&1; then bat "$@"; else batcat "$@"; fi; }
y() {
    local tmp next result
    tmp="$(mktemp)" || return
    yazi "$@" --cwd-file="$tmp"; result=$?
    next="$(cat "$tmp")"
    rm -f -- "$tmp"
    if [ -n "$next" ] && [ -d "$next" ]; then cd -- "$next" || return; fi
    return "$result"
}
ff() { local chosen; chosen="$(rg --files --hidden -g '!**/.git/**' | fzf)" && [ -n "$chosen" ] && nvim -- "$chosen"; }
if command -v zoxide >/dev/null 2>&1; then
    if [ -n "${ZSH_VERSION:-}" ]; then eval "$(zoxide init zsh)"; else eval "$(zoxide init bash)"; fi
fi
devhelp() { printf '%s\n' 'y: file manager | v FILE: Neovim | ff: find file | z: jump directory' 'Yazi: hover to preview | O: default app | o: choose opener | J/K: scroll preview' 'gs/gd/gl: Git | catp: preview text | build tools: cmake'; }
