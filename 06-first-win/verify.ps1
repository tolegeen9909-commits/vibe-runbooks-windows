#requires -Version 5.1

[CmdletBinding()]
param([string]$ProjectPath = "$env:SystemDrive\Projects\vibecoding\vibecoding_first_app")

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

$passed = 0
$required = 7
$failures = New-Object System.Collections.Generic.List[string]

if (Test-Path -LiteralPath (Join-Path $ProjectPath 'pubspec.yaml')) { $passed++; Write-RunbookOk 'Flutter-проект существует.' }
else { $failures.Add('pubspec.yaml не найден.') }

if (Test-Path -LiteralPath (Join-Path $ProjectPath 'lib\main.dart')) { $passed++; Write-RunbookOk 'lib/main.dart существует.' }
else { $failures.Add('lib/main.dart не найден.') }

if (Test-Path -LiteralPath (Join-Path $ProjectPath '.git')) { $passed++; Write-RunbookOk 'Git-репозиторий создан.' }
else { $failures.Add('Git-репозиторий не создан.') }

if (Test-Path -LiteralPath (Join-Path $ProjectPath '.git')) {
    Push-Location $ProjectPath
    try {
        & git rev-parse --verify HEAD *> $null
        if ($LASTEXITCODE -eq 0) { $passed++; Write-RunbookOk 'Есть хотя бы один commit.' }
        else { $failures.Add('Commit пока не создан.') }

        $origin = (& git remote get-url origin 2>$null | Out-String).Trim()
        if ($origin) { $passed++; Write-RunbookOk "origin: $origin" }
        else { $failures.Add('GitHub remote origin не настроен.') }

        $upstream = (& git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null | Out-String).Trim()
        if ($upstream) { $passed++; Write-RunbookOk "Upstream branch: $upstream" }
        else { $failures.Add('Ветка ещё не отправлена в GitHub.') }
    }
    finally {
        Pop-Location
    }
}

if (Test-RunbookStepCompleted '06-first-win:pushed') { $passed++; Write-RunbookOk 'GitHub push записан в прогрессе.' }
else { $failures.Add('Нет маркера успешного GitHub push. Повтори first-edit-commit.ps1 -Publish.') }

$ok = Complete-RunbookVerification -Phase '06' -Passed $passed -Required $required -Failures @($failures)
if ($ok) {
    Mark-RunbookStep '06-first-win:verified'
    exit 0
}
exit 1
