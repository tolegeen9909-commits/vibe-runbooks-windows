#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Write-RunbookStep 'Устанавливаю Android Studio'
Install-WinGetPackage -PackageId 'Google.AndroidStudio' -DisplayName 'Android Studio' -WhatIf:$WhatIfPreference | Out-Null

if (Test-WinGetPackageInstalled -PackageId 'Google.AndroidStudio') {
    Mark-RunbookStep '05-flutter:android-studio'
    Write-RunbookOk 'Android Studio установлен.'
}

Write-RunbookWarning 'Теперь человек должен открыть Android Studio и пройти Setup Wizard → Standard.'
Write-RunbookInfo 'Оставь включёнными Android SDK, Platform, Build-Tools, Command-line Tools и Emulator.'
