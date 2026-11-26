#requires -Version 7.0
[CmdletBinding()]
param([switch]$SkipModules)
$ErrorActionPreference = 'Stop'
# Compatibility entry: run the complete workflow once.
& (Join-Path (Split-Path -Parent $PSScriptRoot) 'install.ps1') -SkipModules:$SkipModules
if ($LASTEXITCODE -ne 0) { throw "Deployment failed: $LASTEXITCODE" }
