#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
Write-RunbookStep 'Устанавливаю Netlify CLI'

if (Test-RunbookCommand 'netlify') {
    Write-RunbookOk 'Netlify CLI уже доступен.'
    Mark-RunbookStep '05w-netlify:installed'
    exit 0
}

if (-not (Test-RunbookCommand 'npm.cmd')) {
    throw 'npm.cmd не найден. Сначала пройди фазу 04.'
}

Invoke-RunbookCommand -FilePath 'npm.cmd' -ArgumentList @('install', '-g', 'netlify-cli') | Out-Null
if (Test-RunbookCommand 'netlify') {
    Write-RunbookOk 'Netlify CLI установлен.'
    Mark-RunbookStep '05w-netlify:installed'
}
else {
    Write-RunbookWarning 'CLI установлен, но PATH текущего окна не обновился. Открой новый терминал.'
}

Write-RunbookInfo 'Вход выполняется отдельно командой netlify login в системном браузере.'
