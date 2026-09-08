#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
$state = Read-RunbookState
$tracks = @($state.selectedTracks)
$checks = New-Object System.Collections.Generic.List[object]

function Add-CheckResult {
    param([string]$Name, [bool]$Passed)
    $checks.Add([pscustomobject]@{ Name = $Name; Passed = $Passed })
}

Add-CheckResult 'winget' (Test-RunbookCommand 'winget')
Add-CheckResult 'Preflight verified' (Test-RunbookStepCompleted '00-preflight:verified')
Add-CheckResult 'Windows setup verified' (Test-RunbookStepCompleted '01-windows-setup:verified')
Add-CheckResult 'Foundation verified' (Test-RunbookStepCompleted '02-foundation:verified')
Add-CheckResult 'Git' (Test-RunbookCommand 'git')

$gitIdentityReady = $false
if (Test-RunbookCommand 'git') {
    $gitName = (& git config --global --get user.name 2>$null | Out-String).Trim()
    $gitEmail = (& git config --global --get user.email 2>$null | Out-String).Trim()
    $gitIdentityReady = [bool]($gitName -and $gitEmail)
}
Add-CheckResult 'Git identity' $gitIdentityReady

$ghAuthenticated = $false
if (Test-RunbookCommand 'gh') {
    & gh auth status *> $null
    $ghAuthenticated = $LASTEXITCODE -eq 0
}
Add-CheckResult 'GitHub login' $ghAuthenticated
Add-CheckResult 'Gitleaks' (Test-RunbookCommand 'gitleaks')

$guardPath = Join-Path $env:USERPROFILE '.vibecoding\hooks\command-guard.py'
$settingsPath = Join-Path $env:USERPROFILE '.claude\settings.json'
$guardConfigured = $false
if ((Test-Path -LiteralPath $guardPath) -and (Test-Path -LiteralPath $settingsPath)) {
    $guardConfigured = (Get-Content -LiteralPath $settingsPath -Raw) -match 'command-guard\.py'
}
Add-CheckResult 'Claude command guard' $guardConfigured
Add-CheckResult 'Git/GitHub phase verified' (Test-RunbookStepCompleted '03-git-github:verified')
Add-CheckResult 'Node + npm' ((Test-RunbookCommand 'node') -and (Test-RunbookCommand 'npm.cmd'))
Add-CheckResult 'Claude Code' (Test-RunbookCommand 'claude')
Add-CheckResult 'Codex CLI' (Test-RunbookCommand 'codex')
Add-CheckResult 'AI helpers phase verified' (Test-RunbookStepCompleted '04-ai-helpers:verified')

$trackSelectionRecorded = @($state.completedSteps | Where-Object { $_ -like 'tracks:selected-*' }).Count -gt 0
Add-CheckResult 'Track selection recorded' $trackSelectionRecorded

if ($tracks -contains 'flutter') {
    Add-CheckResult 'Flutter' (Test-RunbookCommand 'flutter')
    Add-CheckResult 'Android Studio' (Test-WinGetPackageInstalled -PackageId 'Google.AndroidStudio')
    Add-CheckResult 'Flutter phase verified' (Test-RunbookStepCompleted '05-flutter:verified')
    Add-CheckResult 'Flutter project pushed' (Test-RunbookStepCompleted '06-first-win:pushed')
    Add-CheckResult 'Flutter project in GitHub' (Test-RunbookStepCompleted '06-first-win:verified')
}

if ($tracks -contains 'web') {
    Add-CheckResult 'Netlify CLI' (Test-RunbookCommand 'netlify')

    $netlifyAuthenticated = $false
    if (Test-RunbookCommand 'netlify') {
        & netlify status *> $null
        $netlifyAuthenticated = $LASTEXITCODE -eq 0
    }
    Add-CheckResult 'Netlify login' $netlifyAuthenticated
    Add-CheckResult 'Website in GitHub' (Test-RunbookStepCompleted '06w-first-site:pushed')
    Add-CheckResult 'Website preview deploy' (Test-RunbookStepCompleted '06w-first-site:previewed')
    Add-CheckResult 'Website production deploy' (Test-RunbookStepCompleted '06w-first-site:production')
    Add-CheckResult 'Website phase verified' (Test-RunbookStepCompleted '06w-first-site:verified')
    Add-CheckResult 'Preview URL saved' ((Get-RunbookArtifact -Name 'netlifyPreviewUrl') -match '^https://')
    Add-CheckResult 'Production URL saved' ((Get-RunbookArtifact -Name 'netlifyProductionUrl') -match '^https://')
}

$passed = @($checks | Where-Object Passed).Count
$total = $checks.Count
$required = $total

Write-RunbookStep 'Итоговый чек-поинт'
foreach ($check in $checks) {
    if ($check.Passed) { Write-RunbookOk $check.Name }
    else { Write-Host "[ ]  $($check.Name)" }
}

Write-Host "`nРезультат: $passed/$total; проходной порог: $required."
if ($passed -ge $required) {
    Mark-RunbookStep '07-checkpoint:passed'
    Write-RunbookOk 'Установка завершена.'
    Write-RunbookInfo 'Следующий шаг: https://academy.adarasoft.com/course/vibecoding'
    Write-RunbookInfo 'Открой урок 1.1 «Режим плана (Plan Mode): сначала план, потом дело».'
    exit 0
}

Write-RunbookFailure 'Чек-поинт пока не пройден. Исправь один первый пустой пункт и повтори проверку.'
exit 1
