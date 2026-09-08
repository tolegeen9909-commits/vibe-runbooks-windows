#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
Write-RunbookStep 'Устанавливаю Codex CLI через npm'

if (Test-RunbookCommand 'codex') {
    Write-RunbookOk 'Codex CLI уже доступен.'
    Mark-RunbookStep '04-ai-helpers:codex-installed'
    exit 0
}

if (-not (Test-RunbookCommand 'npm.cmd')) {
    throw 'npm.cmd не найден. Сначала установи Node.js и открой новое окно терминала.'
}

Invoke-RunbookCommand -FilePath 'npm.cmd' -ArgumentList @('install', '-g', '@openai/codex') | Out-Null
if (Test-RunbookCommand 'codex') {
    Write-RunbookOk 'Codex CLI установлен.'
    Mark-RunbookStep '04-ai-helpers:codex-installed'
}
else {
    Write-RunbookWarning 'Установка завершилась, но PATH ещё не обновился. Открой новое окно терминала.'
}

Write-RunbookInfo 'Первый запуск выполняется отдельно командой codex с входом через ChatGPT.'
