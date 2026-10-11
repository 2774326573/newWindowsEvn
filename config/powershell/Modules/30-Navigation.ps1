# Navigation and file management.
function v {
    if (Get-Command nvim -ErrorAction SilentlyContinue) { & nvim @args }
    else { Write-Warning 'Neovim is not installed.' }
}

function ll {
    if (-not (Get-Module -Name Terminal-Icons) -and
        (Get-Module -ListAvailable -Name Terminal-Icons)) {
        Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    }
    Get-ChildItem -Force @args
}

function catp {
    if (Get-Command bat -ErrorAction SilentlyContinue) { & bat @args }
    else { Get-Content @args }
}

function y {
    if (-not (Get-Command yazi -ErrorAction SilentlyContinue)) {
        Write-Warning 'Yazi is not installed.'
        return
    }
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        & yazi @args "--cwd-file=$tmp"
        $next = Get-Content -LiteralPath $tmp -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($next) {
            $next = $next.Trim()
            if ($next -and $next -ne $PWD.Path -and (Test-Path -LiteralPath $next -PathType Container)) {
                Set-Location -LiteralPath $next
            }
        }
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    try { & zoxide init powershell | Out-String | Invoke-Expression }
    catch { Write-Verbose "zoxide initialization unavailable: $_" }
}
