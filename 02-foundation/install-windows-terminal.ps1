#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
Write-RunbookStep 'Проверяю Windows Terminal'
Install-WinGetPackage -PackageId 'Microsoft.WindowsTerminal' -Source 'winget' -DisplayName 'Windows Terminal' -WhatIf:$WhatIfPreference | Out-Null
if (Test-WinGetPackageInstalled -PackageId 'Microsoft.WindowsTerminal') {
    Mark-RunbookStep '02-foundation:terminal'
    Write-RunbookOk 'Windows Terminal готов. Изменение PATH лучше проверять в новом окне.'
}
else {
    Write-RunbookInfo 'Windows Terminal пока не установлен; при WhatIf это ожидаемо.'
}
