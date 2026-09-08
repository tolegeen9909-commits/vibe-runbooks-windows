#requires -Version 5.1

[CmdletBinding()]
param([switch]$AcceptLicenses)

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
if (-not (Test-RunbookCommand 'flutter')) {
    throw 'Flutter не найден. Открой новое окно терминала или повтори install-flutter.ps1.'
}

Write-RunbookStep 'Проверяю Android toolchain'
& flutter doctor -v

if (-not $AcceptLicenses) {
    Write-RunbookWarning 'Лицензии Android принимает человек вручную.'
    Write-RunbookInfo 'Прочитай запросы. Если согласен, повтори: powershell -ExecutionPolicy Bypass -File .\05-flutter\setup-android-toolchain.ps1 -AcceptLicenses'
    exit 2
}

Write-RunbookInfo 'Открываю официальный интерактивный список Android licenses. Отвечай y только если согласен.'
& flutter doctor --android-licenses
if ($LASTEXITCODE -ne 0) {
    throw 'Android licenses не завершились успешно. Проверь, установлен ли Android SDK Command-line Tools.'
}

Mark-RunbookStep '05-flutter:android-licenses'
Write-RunbookOk 'Android licenses обработаны.'
Write-RunbookInfo 'Создай устройство: Android Studio → Tools → Device Manager → Create Virtual Device.'
