#requires -Version 7.0
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$files = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.ps1' |
    Where-Object { $_.FullName -notmatch '[\\/]offline[\\/]' })
$failed = @()
foreach ($file in $files) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName, [ref]$tokens, [ref]$errors
    )
    if ($errors.Count) {
        foreach ($errorItem in $errors) {
            $failed += "$($file.FullName): $($errorItem.Message)"
        }
    }
}
if ($failed.Count) { throw ($failed -join [Environment]::NewLine) }
Write-Host "PASS: Parsed $($files.Count) PowerShell files without syntax errors." -ForegroundColor Green
