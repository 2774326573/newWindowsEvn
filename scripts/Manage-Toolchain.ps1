#requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet('Check','Export')]
    [string]$Mode = 'Check',
    [ValidateSet('All','qt5-msvc','qt5-mingw')]
    [string]$Profile = 'All',
    [string]$Output
)
$ErrorActionPreference = 'Stop'
if (-not $IsWindows) { throw 'Manage-Toolchain.ps1 currently supports Windows only.' }
$root = Split-Path -Parent $PSScriptRoot
$policyPath = Join-Path $root 'config\toolchains.json'
$policy = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$items = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param([string]$Id, [string]$Name, [bool]$Found, [string]$Version, [string]$Path, [string]$Detail = '')
    $items.Add([pscustomobject]@{
        Id = $Id; Name = $Name; Found = $Found
        Version = $Version; Path = $Path; Detail = $Detail
    })
}
function Get-CommandInfo {
    param([string]$Name, [string[]]$Arguments)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cmd) { return $null }
    $output = (& $cmd.Source @Arguments 2>&1 | Out-String).Trim()
    [pscustomobject]@{ Path = $cmd.Source; Output = $output }
}
function Get-Version {
    param([string]$Text)
    $m = [regex]::Match($Text, '(?<!\d)(\d+\.\d+(?:\.\d+){0,2})')
    if ($m.Success) { return $m.Groups[1].Value }
    return ''
}

# MSVC: use vswhere to detect the installed compiler workload without requiring
# the current shell to be an initialized Developer Command Prompt.
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vs = $null
if (Test-Path -LiteralPath $vswhere) {
    $vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
}
if ($vs) {
    $cl = Get-ChildItem -LiteralPath (Join-Path $vs 'VC\Tools\MSVC') -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    Add-Result 'msvc' 'Visual Studio C++ Build Tools' $true $(if ($cl) { $cl.Name } else { '' }) $vs 'VC x86/x64 component detected; cl.exe requires a Developer environment.'
} else {
    Add-Result 'msvc' 'Visual Studio C++ Build Tools' $false '' '' 'Install VS 2022 C++ workload or Build Tools.'
}

# Windows SDK versions are installed side-by-side.
$sdkRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10'
$sdkVersions = @()
if (Test-Path -LiteralPath (Join-Path $sdkRoot 'Include')) {
    $sdkVersions = @(Get-ChildItem -LiteralPath (Join-Path $sdkRoot 'Include') -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^10\.\d+\.\d+\.\d+$' } | Select-Object -ExpandProperty Name | Sort-Object -Descending)
}
Add-Result 'windows-sdk' 'Windows SDK' ($sdkVersions.Count -gt 0) ($sdkVersions -join ', ') $sdkRoot

# Qt: discover qmake on PATH and from common Qt installations.
$qmakeCandidates = [System.Collections.Generic.List[string]]::new()
$qmake = Get-Command qmake -ErrorAction SilentlyContinue | Select-Object -First 1
if ($qmake) { $qmakeCandidates.Add($qmake.Source) }
foreach ($base in @($env:QT_DIR, $env:QTDIR, (Join-Path ${env:ProgramFiles} 'Qt'), (Join-Path $HOME 'Qt'))) {
    if (-not $base -or -not (Test-Path -LiteralPath $base)) { continue }
    if ((Get-Item -LiteralPath $base).PSIsContainer) {
        $qmakeCandidates.AddRange(@(Get-ChildItem -LiteralPath $base -Filter qmake.exe -File -Recurse -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName))
    } elseif ((Split-Path $base -Leaf) -match '^qmake\.exe$') {
        $qmakeCandidates.Add($base)
    }
}
$qtRows = foreach ($candidate in ($qmakeCandidates | Select-Object -Unique)) {
    $q = & $candidate -query QT_VERSION 2>$null
    if ($LASTEXITCODE -eq 0 -and $q) {
        $spec = & $candidate -query QMAKE_XSPEC 2>$null
        [pscustomobject]@{ Version = [string]$q; Path = $candidate; Spec = [string]$spec }
    }
}
$qtRows = @($qtRows | Sort-Object Version -Descending -Unique)
if ($qtRows.Count) {
    foreach ($qt in $qtRows) { Add-Result 'qt5' 'Qt SDK' ($qt.Version -like '5.*') $qt.Version $qt.Path ("Kit: " + $qt.Spec) }
} else {
    Add-Result 'qt5' 'Qt SDK' $false '' '' 'qmake.exe not found. Add the intended Qt kit to PATH or QT_DIR.'
}

$gxx = Get-CommandInfo 'g++' @('--version')
if ($gxx) { Add-Result 'mingw' 'MinGW-w64 GCC' $true (Get-Version $gxx.Output) $gxx.Path $gxx.Output.Split("`n")[0] }
else { Add-Result 'mingw' 'MinGW-w64 GCC' $false '' '' 'g++ not found on PATH.' }

foreach ($tool in @(
    @{ Id='cmake'; Name='CMake'; Command='cmake'; Args=@('--version') },
    @{ Id='xmake'; Name='Xmake'; Command='xmake'; Args=@('--version') }
)) {
    $info = Get-CommandInfo $tool.Command $tool.Args
    if ($info) { Add-Result $tool.Id $tool.Name $true (Get-Version $info.Output) $info.Path $info.Output.Split("`n")[0] }
    else { Add-Result $tool.Id $tool.Name $false '' '' ($tool.Command + ' not found on PATH.') }
}

# OpenCV: prefer an explicit OpenCV_DIR, then inspect common installation roots.
$opencvCandidates = [System.Collections.Generic.List[string]]::new()
if ($env:OpenCV_DIR) { $opencvCandidates.Add($env:OpenCV_DIR) }
foreach ($base in @($env:OPENCV_ROOT, (Join-Path ${env:ProgramFiles} 'OpenCV'), (Join-Path $HOME 'opencv'))) {
    if ($base -and (Test-Path -LiteralPath $base)) {
        $opencvCandidates.AddRange(@(Get-ChildItem -LiteralPath $base -Filter OpenCVConfig.cmake -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object { $_.DirectoryName }))
    }
}
$opencvCandidates = @($opencvCandidates | Select-Object -Unique)
if ($opencvCandidates.Count) {
    Add-Result 'opencv' 'OpenCV' $true '' ($opencvCandidates -join '; ') 'CMake package config found; compiler ABI and modules need project-level validation.'
} else {
    Add-Result 'opencv' 'OpenCV' $false '' '' 'OpenCV_DIR / OpenCVConfig.cmake not found.'
}

$selected = if ($Profile -eq 'All') { @('msvc','windows-sdk','qt5','mingw','cmake','xmake','opencv') } else {
    ($policy.profiles | Where-Object Id -eq $Profile | Select-Object -ExpandProperty required)
}
$report = [pscustomobject]@{
    SchemaVersion = 1
    GeneratedAt = (Get-Date).ToString('o')
    Computer = $env:COMPUTERNAME
    OS = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    Architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    Profile = $Profile
    Policy = $policy.policy
    Results = @($items)
    RequiredForProfile = @($selected)
    MissingForProfile = @($items | Where-Object { $_.Id -in $selected -and -not $_.Found } | Select-Object -ExpandProperty Id -Unique)
    Notes = @('Read-only inventory; no software is installed, removed or switched.',
              'MSVC detection uses vswhere; a Developer PowerShell is still needed to expose cl.exe.',
              'Qt kit/compiler ABI compatibility is not inferred from qmake alone.',
              'HALCON and vendor SDKs/licenses are intentionally not inspected or copied.')
}
$report | ConvertTo-Json -Depth 8 | ForEach-Object { $json = $_ }
if ($Output) {
    $destination = [IO.Path]::GetFullPath($Output)
    $parent = Split-Path -Parent $destination
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    $json | Set-Content -LiteralPath $destination -Encoding UTF8
    Write-Host "Inventory exported: $destination" -ForegroundColor Green
}
if ($Mode -eq 'Export' -and -not $Output) { $json }
else {
    $items | Format-Table Id, Name, Found, Version, Path -AutoSize
    if ($report.MissingForProfile.Count) {
        Write-Warning ("Missing for profile {0}: {1}" -f $Profile, ($report.MissingForProfile -join ', '))
    } else {
        Write-Host "PASS: detected required components for $Profile." -ForegroundColor Green
    }
}
