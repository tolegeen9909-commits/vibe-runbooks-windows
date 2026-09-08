#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$Name,
    [string]$Email
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
if (-not (Test-RunbookCommand 'git')) {
    throw 'Git не найден. Сначала запусти install-git.ps1 и открой новое окно терминала.'
}

Write-RunbookStep 'Настраиваю подпись Git'
if ([string]::IsNullOrWhiteSpace($Name)) {
    $Name = Read-Host 'Напиши имя для подписи коммитов'
}
if ([string]::IsNullOrWhiteSpace($Email)) {
    $Email = Read-Host 'Напиши email GitHub для подписи коммитов'
}

if ([string]::IsNullOrWhiteSpace($Name)) {
    throw 'Имя не может быть пустым.'
}
if ($Email -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$') {
    throw 'Email выглядит неверно. Проверь адрес и повтори.'
}

& git config --global user.name $Name
& git config --global user.email $Email
& git config --global init.defaultBranch main
& git config --global core.autocrlf true
if ($LASTEXITCODE -ne 0) {
    throw 'Git не смог сохранить настройки.'
}

Mark-RunbookStep '03-git-github:identity'
Write-RunbookOk "Коммиты будут подписаны: $Name <$Email>."
