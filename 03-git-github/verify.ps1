#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
$passed = 0
$required = 7
$failures = New-Object System.Collections.Generic.List[string]

if (Test-RunbookCommand 'git') { $passed++; Write-RunbookOk "$(& git --version)" }
else { $failures.Add('Git не найден.') }

if (Test-RunbookCommand 'gh') { $passed++; Write-RunbookOk 'GitHub CLI найден.' }
else { $failures.Add('GitHub CLI не найден.') }

if (Test-RunbookCommand 'gh') {
    & gh auth status *> $null
    if ($LASTEXITCODE -eq 0) { $passed++; Write-RunbookOk 'Вход в GitHub выполнен.' }
    else { $failures.Add('Вход в GitHub не выполнен: gh auth login --web --git-protocol https') }
}

$gitName = ''
$gitEmail = ''
if (Test-RunbookCommand 'git') {
    $gitName = (& git config --global --get user.name 2>$null | Out-String).Trim()
    $gitEmail = (& git config --global --get user.email 2>$null | Out-String).Trim()
}
if ($gitName -and $gitEmail) { $passed++; Write-RunbookOk "Git identity: $gitName <$gitEmail>" }
else { $failures.Add('Git name/email не настроены.') }

if (Test-RunbookCommand 'gitleaks') { $passed++; Write-RunbookOk 'Gitleaks найден.' }
else { $failures.Add('Gitleaks не найден или PATH ещё не обновился.') }

$hooksPath = ''
if (Test-RunbookCommand 'git') {
    $hooksPath = (& git config --global --get core.hooksPath 2>$null | Out-String).Trim()
}
if ($hooksPath -and (Test-Path -LiteralPath (Join-Path $hooksPath 'pre-commit'))) {
    $passed++
    Write-RunbookOk 'Global pre-commit hook подключён.'
}
else { $failures.Add('Global pre-commit hook не подключён.') }

$guardPath = Join-Path $env:USERPROFILE '.vibecoding\hooks\command-guard.py'
$settingsPath = Join-Path $env:USERPROFILE '.claude\settings.json'
$guardConfigured = $false
if ((Test-Path -LiteralPath $guardPath) -and (Test-Path -LiteralPath $settingsPath)) {
    $guardConfigured = (Get-Content -LiteralPath $settingsPath -Raw) -match 'command-guard\.py'
}
if ($guardConfigured) { $passed++; Write-RunbookOk 'Claude command guard подключён.' }
else { $failures.Add('Claude command guard не подключён.') }

$ok = Complete-RunbookVerification -Phase '03' -Passed $passed -Required $required -Failures @($failures)
if ($ok) {
    Mark-RunbookStep '03-git-github:verified'
    exit 0
}
exit 1
