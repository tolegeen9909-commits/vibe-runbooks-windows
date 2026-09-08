#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Write-RunbookStep 'Устанавливаю Node.js LTS и npm'
Install-WinGetPackage -PackageId 'OpenJS.NodeJS.LTS' -DisplayName 'Node.js LTS' -WhatIf:$WhatIfPreference | Out-Null

if ((Test-RunbookCommand 'node') -and (Test-RunbookCommand 'npm.cmd')) {
    Write-RunbookOk "Node: $(& node --version), npm: $(& npm.cmd --version)"
    Mark-RunbookStep '04-ai-helpers:node'
}
else {
    Write-RunbookWarning 'Node установлен, но PATH текущего окна не обновился. Открой новое окно терминала.'
}
