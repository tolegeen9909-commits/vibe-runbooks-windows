#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Write-RunbookStep 'Устанавливаю GitHub CLI'
Install-WinGetPackage -PackageId 'GitHub.cli' -DisplayName 'GitHub CLI' -WhatIf:$WhatIfPreference | Out-Null

if (-not (Test-RunbookCommand 'gh')) {
    Write-RunbookWarning 'gh установлен, но ещё не виден. Открой новое окно терминала.'
    exit 0
}

Write-RunbookOk "GitHub CLI доступен: $((& gh --version | Select-Object -First 1))"
& gh auth status *> $null
if ($LASTEXITCODE -eq 0) {
    Write-RunbookOk 'Вход в GitHub уже выполнен.'
    Mark-RunbookStep '03-git-github:gh-auth'
}
else {
    Write-RunbookWarning 'Нужен видимый вход через системный браузер.'
    Write-RunbookInfo 'Когда человек скажет «да», выполни: gh auth login --web --git-protocol https'
    Write-RunbookInfo 'Пароль и 2FA-код в чат не отправлять.'
    Mark-RunbookStep '03-git-github:gh-installed'
}
