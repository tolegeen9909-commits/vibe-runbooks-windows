#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$InstallParent = "$env:SystemDrive\src",
    [string]$ArchivePath
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
$flutterRoot = Join-Path $InstallParent 'flutter'
$flutterCommand = Join-Path $flutterRoot 'bin\flutter.bat'

Write-RunbookStep 'Устанавливаю стабильный Flutter SDK'
if (Test-Path -LiteralPath $flutterCommand) {
    Add-UserPathEntry -Path (Join-Path $flutterRoot 'bin') | Out-Null
    Write-RunbookOk "Flutter уже установлен: $flutterRoot"
    Mark-RunbookStep '05-flutter:sdk'
    exit 0
}

if ((Test-Path -LiteralPath $flutterRoot) -and -not (Test-Path -LiteralPath $flutterCommand)) {
    throw "Папка $flutterRoot существует, но flutter.bat не найден. Не удаляю её автоматически: проверь содержимое и освободи путь."
}

if (-not $ArchivePath) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $manifestUri = 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
    Write-RunbookInfo 'Получаю официальный Windows release-manifest Flutter.'
    $manifest = Invoke-RestMethod -Uri $manifestUri -UseBasicParsing
    $stableHash = $manifest.current_release.stable
    $release = $manifest.releases | Where-Object { $_.hash -eq $stableHash } | Select-Object -First 1
    if (-not $release) {
        throw 'Официальный manifest не содержит текущий stable release.'
    }

    $ArchivePath = Join-Path $env:TEMP ([IO.Path]::GetFileName($release.archive))
    $downloadUri = 'https://storage.googleapis.com/flutter_infra_release/releases/{0}' -f $release.archive
    if (-not (Test-Path -LiteralPath $ArchivePath)) {
        if ($PSCmdlet.ShouldProcess($downloadUri, "Скачать Flutter в $ArchivePath")) {
            Write-RunbookInfo 'Загрузка большая и может занять несколько минут.'
            Invoke-WebRequest -Uri $downloadUri -OutFile $ArchivePath -UseBasicParsing
        }
    }

    if ($WhatIfPreference -and -not (Test-Path -LiteralPath $ArchivePath)) {
        Write-RunbookInfo 'WhatIf: загрузка и распаковка Flutter пропущены.'
        return
    }

    $sha256Property = $release.PSObject.Properties['sha256']
    if ($sha256Property -and $sha256Property.Value) {
        $actualHash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
        $expectedHash = ([string]$sha256Property.Value).ToLowerInvariant()
        if ($actualHash -ne $expectedHash) {
            throw 'SHA-256 архива Flutter не совпал с официальным manifest. Архив не распакован.'
        }
        Write-RunbookOk 'SHA-256 архива совпадает.'
    }
}

if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
    throw "Архив Flutter не найден: $ArchivePath"
}

New-Item -ItemType Directory -Path $InstallParent -Force | Out-Null
if ($PSCmdlet.ShouldProcess($ArchivePath, "Распаковать в $InstallParent")) {
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $InstallParent
}

if ($WhatIfPreference -and -not (Test-Path -LiteralPath $flutterCommand)) {
    Write-RunbookInfo 'WhatIf: проверка распакованного SDK пропущена.'
    return
}

if (-not (Test-Path -LiteralPath $flutterCommand)) {
    throw "После распаковки не найден $flutterCommand"
}

Add-UserPathEntry -Path (Join-Path $flutterRoot 'bin') | Out-Null
& $flutterCommand --version
if ($LASTEXITCODE -ne 0) {
    throw 'Flutter установлен, но flutter --version завершился ошибкой.'
}

Mark-RunbookStep '05-flutter:sdk'
Write-RunbookOk "Flutter готов: $flutterRoot"
Write-RunbookInfo 'Открой новое окно Windows Terminal, чтобы все приложения увидели PATH.'
