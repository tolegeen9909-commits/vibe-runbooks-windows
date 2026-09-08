#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ProjectPath = "$env:SystemDrive\Projects\vibecoding\vibecoding_first_app",
    [string]$CommitMessage = 'feat: create first Flutter app',
    [switch]$Publish
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
if (-not (Test-RunbookCommand 'git')) {
    throw 'git не найден. Сначала пройди фазу 03.'
}
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath 'pubspec.yaml'))) {
    throw "Flutter-проект не найден: $ProjectPath"
}

Push-Location $ProjectPath
try {
    if (-not (Test-Path -LiteralPath '.git')) {
        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('init', '-b', 'main') | Out-Null
    }

    $projectIgnore = Join-Path $ProjectPath '.gitignore'
    foreach ($line in @('.env', '.env.*', '!.env.example', '!.env.sample', '!.env.template')) {
        Add-LineOnce -Path $projectIgnore -Line $line | Out-Null
    }

    $projectAgents = Join-Path $ProjectPath 'AGENTS.md'
    if (-not (Test-Path -LiteralPath $projectAgents)) {
        Copy-Item -LiteralPath (Join-Path (Get-RunbookRoot) 'templates\project-AGENTS.md') -Destination $projectAgents
    }

    $changes = (& git status --porcelain | Out-String).Trim()
    if ($changes) {
        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('add', '.') | Out-Null
        $stagedFiles = @(& git diff --cached --name-only)
        $unsafeFiles = @($stagedFiles | Where-Object {
            $_ -match '(^|/)(\.env(?:\..+)?|.*\.(?:pem|key|p8|p12)|credentials\.json|secrets\.json)$' -and
            $_ -notmatch '(^|/)\.env\.(?:example|sample|template)$'
        })
        if ($unsafeFiles.Count -gt 0) {
            & git restore --staged -- @unsafeFiles
            throw "Секретные файлы убраны из staging: $($unsafeFiles -join ', ')"
        }

        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('commit', '-m', $CommitMessage) | Out-Null
        Write-RunbookOk 'Первый commit сохранён локально.'
    }
    else {
        & git rev-parse --verify HEAD *> $null
        if ($LASTEXITCODE -ne 0) {
            throw 'Нет изменений и ещё нет первого commit. Сначала сделай видимую правку в lib/main.dart.'
        }
        Write-RunbookInfo 'Новых изменений нет: использую уже сохранённый commit.'
    }
    Mark-RunbookStep '06-first-win:committed'

    if (-not $Publish) {
        Write-RunbookWarning 'Push не выполнен: это внешнее действие.'
        Write-RunbookInfo 'После явного «да» повтори этот же скрипт с -Publish.'
        exit 0
    }

    if (-not (Test-RunbookCommand 'gh')) {
        throw 'gh не найден. Сначала пройди фазу 03.'
    }
    & gh auth status *> $null
    if ($LASTEXITCODE -ne 0) {
        throw 'Вход GitHub не выполнен. Запусти gh auth login --web --git-protocol https.'
    }

    $origin = (& git remote get-url origin 2>$null | Out-String).Trim()
    if (-not $origin) {
        Invoke-RunbookCommand -FilePath 'gh' -ArgumentList @(
            'repo', 'create', (Split-Path -Leaf $ProjectPath), '--private',
            '--source', '.', '--remote', 'origin', '--push'
        ) | Out-Null
    }
    else {
        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('push', '-u', 'origin', 'HEAD') | Out-Null
    }

    Mark-RunbookStep '06-first-win:pushed'
    Write-RunbookOk 'Проект отправлен в приватный GitHub-репозиторий.'
}
finally {
    Pop-Location
}
