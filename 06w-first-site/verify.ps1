#requires -Version 5.1

[CmdletBinding()]
param([string]$ProjectPath = "$env:SystemDrive\Projects\vibecoding\vibecoding_first_site")

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

$passed = 0
$required = 8
$failures = New-Object System.Collections.Generic.List[string]

$indexPath = Join-Path $ProjectPath 'index.html'
if ((Test-Path -LiteralPath $indexPath) -and (Get-Content -LiteralPath $indexPath -Raw) -match '<html') {
    $passed++
    Write-RunbookOk 'index.html существует.'
}
else { $failures.Add('Рабочий index.html не найден.') }

$gitDir = Join-Path $ProjectPath '.git'
if (Test-Path -LiteralPath $gitDir) {
    Push-Location $ProjectPath
    try {
        & git rev-parse --verify HEAD *> $null
        if ($LASTEXITCODE -eq 0) { $passed++; Write-RunbookOk 'Есть commit.' }
        else { $failures.Add('Нет commit.') }

        $origin = (& git remote get-url origin 2>$null | Out-String).Trim()
        if ($origin) { $passed++; Write-RunbookOk "origin: $origin" }
        else { $failures.Add('Нет GitHub remote origin.') }
    }
    finally { Pop-Location }
}
else {
    $failures.Add('Git-репозиторий не создан.')
    $failures.Add('Нет GitHub remote origin.')
}

if (Test-RunbookStepCompleted '06w-first-site:pushed') { $passed++; Write-RunbookOk 'GitHub push записан в прогрессе.' }
else { $failures.Add('Нет маркера успешного GitHub push.') }

$netlifyState = Join-Path $ProjectPath '.netlify\state.json'
if (Test-Path -LiteralPath $netlifyState) { $passed++; Write-RunbookOk 'Проект связан с Netlify.' }
else { $failures.Add('Netlify state не найден: сначала preview deploy.') }

$previewUrl = Get-RunbookArtifact -Name 'netlifyPreviewUrl'
if ($previewUrl -match '^https://') { $passed++; Write-RunbookOk "Preview URL: $previewUrl" }
else { $failures.Add('Preview URL не сохранён. Повтори publish-site.ps1 -Preview.') }

if (Test-RunbookStepCompleted '06w-first-site:production') { $passed++; Write-RunbookOk 'Production deploy записан в прогрессе.' }
else { $failures.Add('Production deploy ещё не подтверждён.') }

$productionUrl = Get-RunbookArtifact -Name 'netlifyProductionUrl'
if ($productionUrl -match '^https://') { $passed++; Write-RunbookOk "Production URL: $productionUrl" }
else { $failures.Add('Production URL не сохранён. Повтори publish-site.ps1 -Production.') }

$ok = Complete-RunbookVerification -Phase '06w' -Passed $passed -Required $required -Failures @($failures)
if ($ok) {
    Mark-RunbookStep '06w-first-site:verified'
    exit 0
}
exit 1
