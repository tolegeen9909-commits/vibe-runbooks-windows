#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
$passed = 0
$failures = New-Object System.Collections.Generic.List[string]

if (Test-RunbookCommand 'winget') { $passed++; Write-RunbookOk "winget: $(& winget --version)" }
else { $failures.Add('winget не найден. Нужен App Installer из Microsoft Store.') }

if ($PSVersionTable.PSVersion -ge [version]'5.1') { $passed++; Write-RunbookOk "PowerShell: $($PSVersionTable.PSVersion)" }
else { $failures.Add('Нужен PowerShell 5.1 или новее.') }

if (Test-RunbookCommand 'tree.com') { $passed++; Write-RunbookOk 'Встроенная команда tree.com доступна.' }
else { $failures.Add('Встроенная команда tree.com не найдена.') }

if (Test-RunbookCommand 'wt.exe') { Write-RunbookOk 'Windows Terminal доступен.' }
else { Write-RunbookWarning 'wt.exe пока не виден. Закрой терминал и открой заново.' }

$ok = Complete-RunbookVerification -Phase '02' -Passed $passed -Required 3 -Failures @($failures)
if ($ok) {
    Mark-RunbookStep '02-foundation:verified'
    exit 0
}
exit 1
