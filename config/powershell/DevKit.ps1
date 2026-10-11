# Entry point deployed to ~/.config/powershell7-dev-kit/DevKit.ps1.
# Modules are loaded in lexical order; optional tools must never break the shell.
$moduleDir = Join-Path $PSScriptRoot 'Modules'
if (Test-Path -LiteralPath $moduleDir -PathType Container) {
    Get-ChildItem -LiteralPath $moduleDir -Filter '*.ps1' -File |
        Sort-Object Name |
        ForEach-Object {
            try { . $_.FullName }
            catch { Write-Warning "DevKit: unable to load $($_.Name): $_" }
        }
}
