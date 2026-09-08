#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
Write-RunbookStep 'Настраиваю Проводник и рабочую папку'

$explorerKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
if (-not (Test-Path -LiteralPath $explorerKey)) {
    New-Item -Path $explorerKey -Force | Out-Null
}

New-ItemProperty -Path $explorerKey -Name Hidden -PropertyType DWord -Value 1 -Force | Out-Null
New-ItemProperty -Path $explorerKey -Name HideFileExt -PropertyType DWord -Value 0 -Force | Out-Null
New-ItemProperty -Path $explorerKey -Name ShowSuperHidden -PropertyType DWord -Value 1 -Force | Out-Null
Write-RunbookOk 'Проводник будет показывать расширения, скрытые и системные файлы.'

$projectsPath = Join-Path $env:SystemDrive 'Projects'
if (-not (Test-Path -LiteralPath $projectsPath)) {
    New-Item -ItemType Directory -Path $projectsPath -Force | Out-Null
}
Write-RunbookOk "Рабочая папка готова: $projectsPath"

Write-RunbookWarning 'Шифрование устройства/BitLocker и пароль после сна включаются вручную.'
Write-RunbookInfo 'Открой Параметры → Конфиденциальность и безопасность → Шифрование устройства.'
Write-RunbookInfo 'Не отправляй recovery key в чат. Сохрани его в надёжном личном месте.'

Mark-RunbookStep '01-windows-setup:defaults'
Write-RunbookOk 'Основные безопасные настройки Windows применены.'
