#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ProjectsRoot = "$env:SystemDrive\Projects\vibecoding",
    [string]$ProjectName = 'vibecoding_first_app'
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
if (-not (Test-RunbookCommand 'flutter')) {
    throw 'Flutter не найден. Сначала пройди фазу 05.'
}

Write-RunbookStep 'Создаю первое Flutter-приложение'
New-Item -ItemType Directory -Path $ProjectsRoot -Force | Out-Null
$projectPath = Join-Path $ProjectsRoot $ProjectName

if (-not (Test-Path -LiteralPath (Join-Path $projectPath 'pubspec.yaml'))) {
    Push-Location $ProjectsRoot
    try {
        Invoke-RunbookCommand -FilePath 'flutter' -ArgumentList @('create', $ProjectName) | Out-Null
    }
    finally {
        Pop-Location
    }
}
else {
    Write-RunbookOk "Проект уже существует: $projectPath"
}

$devicesJson = (& flutter devices --machine 2>$null | Out-String)
$androidDevices = @()
if (-not [string]::IsNullOrWhiteSpace($devicesJson)) {
    try {
        $androidDevices = @($devicesJson | ConvertFrom-Json | Where-Object { $_.targetPlatform -match 'android' })
    }
    catch {
        Write-RunbookWarning 'Не удалось разобрать список устройств; покажу обычный вывод.'
        & flutter devices
    }
}

if ($androidDevices.Count -eq 0) {
    Write-RunbookWarning 'Запущенный Android Emulator не найден.'
    Write-RunbookInfo 'Открой Android Studio → Tools → Device Manager, запусти телефон и повтори этот скрипт.'
    exit 2
}

Set-RunbookTrack -Track 'flutter' -Enabled $true
Mark-RunbookStep '06-first-win:created'
Write-RunbookOk "Проект готов: $projectPath"
Write-RunbookInfo 'Сейчас flutter run займёт терминал. Нажми r для hot reload или q для выхода.'

Push-Location $projectPath
try {
    & flutter run
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter run завершился ошибкой.'
    }
}
finally {
    Pop-Location
}
