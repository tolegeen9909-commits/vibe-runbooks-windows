#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Write-RunbookStep 'Устанавливаю Claude Code'
Install-WinGetPackage -PackageId 'Anthropic.ClaudeCode' -DisplayName 'Claude Code' -WhatIf:$WhatIfPreference | Out-Null

if (Test-RunbookCommand 'claude') {
    Write-RunbookOk 'Команда claude доступна.'
    Mark-RunbookStep '04-ai-helpers:claude-installed'
}
else {
    Write-RunbookWarning 'Claude Code установлен, но текущее окно не видит PATH. Открой новый терминал.'
}

Write-RunbookInfo 'Первый запуск выполняется отдельно командой claude. Вход проходит в системном браузере.'
