#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
$passed = 0
$required = 2
$failures = New-Object System.Collections.Generic.List[string]

if (Test-RunbookCommand 'netlify') {
    $passed++
    Write-RunbookOk "Netlify CLI: $(& netlify --version)"
    & netlify status *> $null
    if ($LASTEXITCODE -eq 0) {
        $passed++
        Write-RunbookOk 'Вход в Netlify выполнен.'
    }
    else { $failures.Add('Вход не выполнен: запусти netlify login.') }
}
else { $failures.Add('Netlify CLI не найден.') }

$ok = Complete-RunbookVerification -Phase '05w' -Passed $passed -Required $required -Failures @($failures)
if ($ok) {
    Set-RunbookTrack -Track 'web' -Enabled $true
    Mark-RunbookStep '05w-netlify:verified'
    exit 0
}
exit 1
