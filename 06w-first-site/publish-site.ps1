#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ProjectPath = "$env:SystemDrive\Projects\vibecoding\vibecoding_first_site",
    [string]$CommitMessage = 'feat: create first website',
    [switch]$Push,
    [switch]$Preview,
    [switch]$Production
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath 'index.html'))) {
    throw "index.html не найден: $ProjectPath"
}

Push-Location $ProjectPath
try {
    if (-not (Test-Path -LiteralPath '.git')) {
        if (-not (Test-RunbookCommand 'git')) { throw 'Git не найден.' }
        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('init', '-b', 'main') | Out-Null
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
        Mark-RunbookStep '06w-first-site:committed'
        Write-RunbookOk 'Сайт сохранён локальным commit.'
    }
    else {
        & git rev-parse --verify HEAD *> $null
        if ($LASTEXITCODE -ne 0) {
            throw 'Нет изменений и ещё нет первого commit.'
        }
        Write-RunbookOk 'Новых изменений нет; существующий commit будет использован.'
    }

    if ($Push) {
        if (-not (Test-RunbookCommand 'gh')) { throw 'GitHub CLI не найден.' }
        & gh auth status *> $null
        if ($LASTEXITCODE -ne 0) { throw 'Вход GitHub не выполнен.' }

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
        Mark-RunbookStep '06w-first-site:pushed'
        Write-RunbookOk 'Сайт отправлен в приватный GitHub-репозиторий.'
    }

    if ($Preview) {
        if (-not (Test-RunbookCommand 'netlify')) { throw 'Netlify CLI не найден.' }
        Invoke-RunbookCommand -FilePath 'netlify' -ArgumentList @('deploy', '--dir', '.') | Out-Null
        Mark-RunbookStep '06w-first-site:previewed'
        Write-RunbookOk 'Preview deploy завершён. Открой Draft URL и проверь страницу.'
    }

    if ($Production) {
        if (-not (Test-RunbookStepCompleted '06w-first-site:previewed')) {
            throw 'Production остановлен: сначала сделай и проверь preview deploy.'
        }
        if (-not (Test-RunbookCommand 'netlify')) { throw 'Netlify CLI не найден.' }
        Invoke-RunbookCommand -FilePath 'netlify' -ArgumentList @('deploy', '--prod', '--dir', '.') | Out-Null
        Mark-RunbookStep '06w-first-site:production'
        Write-RunbookOk 'Production deploy завершён. Проверь Website URL в браузере.'
    }

    if (-not ($Push -or $Preview -or $Production)) {
        Write-RunbookWarning 'Внешние действия не выполнены.'
        Write-RunbookInfo 'Используй -Push, затем -Preview, и только после проверки -Production.'
    }
}
finally {
    Pop-Location
}
