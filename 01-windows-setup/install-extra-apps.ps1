#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
Write-RunbookStep 'Устанавливаю необязательные удобные приложения'

Install-WinGetPackage -PackageId 'Microsoft.VisualStudioCode' -DisplayName 'Visual Studio Code' -WhatIf:$WhatIfPreference | Out-Null
Install-WinGetPackage -PackageId 'Microsoft.PowerShell' -DisplayName 'PowerShell 7' -WhatIf:$WhatIfPreference | Out-Null

Write-RunbookOk 'Дополнительные приложения обработаны. Открой новое окно терминала.'
