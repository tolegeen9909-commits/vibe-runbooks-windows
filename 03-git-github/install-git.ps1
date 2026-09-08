#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Write-RunbookStep 'Устанавливаю Git for Windows'
Install-WinGetPackage -PackageId 'Git.Git' -DisplayName 'Git for Windows' -WhatIf:$WhatIfPreference | Out-Null

if (Test-RunbookCommand 'git') {
    Write-RunbookOk "$(& git --version)"
    Mark-RunbookStep '03-git-github:git'
}
else {
    Write-RunbookWarning 'Git установлен, но текущее окно ещё не видит PATH. Закрой терминал и открой заново.'
}
