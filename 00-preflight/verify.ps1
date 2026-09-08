#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'check-system.ps1')
if ($LASTEXITCODE -ne 0) {
    Write-RunbookFailure 'Фаза 00 не пройдена.'
    exit 1
}

Mark-RunbookStep '00-preflight:verified'
Write-RunbookOk 'Фаза 00 пройдена.'
exit 0
