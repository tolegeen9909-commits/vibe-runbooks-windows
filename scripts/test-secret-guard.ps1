#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib.ps1')

Assert-SupportedWindows
if (-not (Test-RunbookCommand 'git')) {
    throw 'Git не найден; self-test Gitleaks не запущен.'
}
if (-not (Test-RunbookCommand 'gitleaks')) {
    throw 'Gitleaks не найден; открой новый терминал и повтори установку защиты.'
}

$testRoot = Join-Path $env:TEMP ("vibe-gitleaks-test-{0}" -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null

try {
    Push-Location $testRoot
    try {
        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('init', '--quiet') | Out-Null
        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('config', 'user.name', 'Vibe Runbooks Test') | Out-Null
        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('config', 'user.email', 'test@example.invalid') | Out-Null
        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('config', 'commit.gpgsign', 'false') | Out-Null
        'baseline' | Set-Content -LiteralPath 'README.md' -Encoding Ascii
        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('add', 'README.md') | Out-Null
        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('commit', '--quiet', '-m', 'test: baseline') | Out-Null

        $testToken = 'AK' + 'IA' + 'Q7W8E9R0T1Y2U3I4'
        "aws_access_key_id=$testToken" | Set-Content -LiteralPath 'test-secret.txt' -Encoding Ascii
        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('add', 'test-secret.txt') | Out-Null
        & gitleaks git --pre-commit --staged --redact --no-banner *> $null
        if ($LASTEXITCODE -ne 1) {
            throw "Gitleaks не заблокировал тестовый секрет (exit $LASTEXITCODE)."
        }

        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('reset', '--quiet') | Out-Null
        'обычный безопасный текст' | Set-Content -LiteralPath 'safe.txt' -Encoding UTF8
        Invoke-RunbookCommand -FilePath 'git' -ArgumentList @('add', 'safe.txt') | Out-Null
        & gitleaks git --pre-commit --staged --redact --no-banner *> $null
        if ($LASTEXITCODE -ne 0) {
            throw "Gitleaks заблокировал безопасный файл (exit $LASTEXITCODE)."
        }
    }
    finally {
        Pop-Location
    }
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}

Write-RunbookOk 'Self-test Gitleaks пройден: тестовый секрет блокируется, обычный файл проходит.'
