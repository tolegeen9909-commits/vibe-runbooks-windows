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

    $sha256Property = $release.PSObject.Properties['sha256']
    if (-not $sha256Property -or -not $sha256Property.Value) {
        throw 'Официальный manifest Flutter не содержит SHA-256; загрузка остановлена.'
    }
    $expectedHash = ([string]$sha256Property.Value).ToLowerInvariant()
    $ArchivePath = Join-Path $env:TEMP ([IO.Path]::GetFileName($release.archive))
    $downloadUri = 'https://storage.googleapis.com/flutter_infra_release/releases/{0}' -f $release.archive

    $needsDownload = $true
    if (Test-Path -LiteralPath $ArchivePath -PathType Leaf) {
        $cachedHash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($cachedHash -eq $expectedHash) {
            $needsDownload = $false
            Write-RunbookOk 'Кэшированный архив Flutter прошёл проверку SHA-256.'
        }
        else {
            $invalidPath = "$ArchivePath.invalid-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
            if ($PSCmdlet.ShouldProcess($ArchivePath, "Сохранить повреждённый архив как $invalidPath")) {
                Move-Item -LiteralPath $ArchivePath -Destination $invalidPath
                Write-RunbookWarning "Старый архив не прошёл SHA-256 и сохранён как: $invalidPath"
            }
        }
    }

    if ($needsDownload) {
        $partialPath = "$ArchivePath.$([guid]::NewGuid().ToString('N')).partial"
        if ($PSCmdlet.ShouldProcess($downloadUri, "Скачать Flutter во временный файл $partialPath")) {
            Write-RunbookInfo 'Загрузка большая и может занять несколько минут.'
            Invoke-WebRequest -Uri $downloadUri -OutFile $partialPath -UseBasicParsing
            $actualHash = (Get-FileHash -LiteralPath $partialPath -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($actualHash -ne $expectedHash) {
                throw "SHA-256 загруженного архива Flutter не совпал. Неполный файл оставлен для диагностики: $partialPath"
            }
            Move-Item -LiteralPath $partialPath -Destination $ArchivePath
            Write-RunbookOk 'SHA-256 архива совпадает; атомарная замена завершена.'
        }
    }

    if ($WhatIfPreference) {
        Write-RunbookInfo 'WhatIf: загрузка и распаковка Flutter пропущены.'
        return
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
