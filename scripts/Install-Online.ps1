#requires -Version 7.0
$ErrorActionPreference = 'Stop'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'WinGet missing: install Windows App Installer first.' }
$ids = @('Microsoft.WindowsTerminal','Microsoft.PowerShell','Git.Git','JanDeDobbeleer.OhMyPosh','sxyazi.yazi','JesseDuffield.lazygit','junegunn.fzf','ajeetdsouza.zoxide','sharkdp.bat','BurntSushi.ripgrep.MSVC','sharkdp.fd')
foreach ($id in $ids) {
    Write-Host "Installing $id" -ForegroundColor Cyan
    & winget install --id $id --exact --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { Write-Warning "WinGet returned $LASTEXITCODE for $id (may already be installed)." }
}
foreach ($name in @('PSFzf','Terminal-Icons')) {
    if (-not (Get-Module -ListAvailable -Name $name)) {
        try { Install-Module -Name $name -Scope CurrentUser -Repository PSGallery -Force -AllowClobber -ErrorAction Stop }
        catch { Write-Warning "Optional module $name not installed: $_" }
    }
}
Write-Host 'Reopen PowerShell 7 to refresh PATH. Then run Install-YaziPlugins.ps1 and Install-Config.ps1.' -ForegroundColor Green
Write-Host 'Install a Nerd Font separately and select it in Windows Terminal.'
