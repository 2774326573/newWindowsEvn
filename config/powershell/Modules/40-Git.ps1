# Read-only Git helpers; no implicit push, reset, checkout or commit.
function lg {
    if (Get-Command lazygit -ErrorAction SilentlyContinue) { & lazygit @args }
    else { Write-Warning 'Lazygit is not installed.' }
}
function gs { & git status --short --branch @args }
function gd { & git diff @args }
function gl { & git log --oneline --decorate -n 12 @args }

function croot {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning 'Git is not installed.'
        return
    }
    $root = & git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and $root) {
        Set-Location -LiteralPath ($root | Select-Object -First 1)
    } else {
        Write-Warning 'Current directory is not inside a Git repository.'
    }
}
