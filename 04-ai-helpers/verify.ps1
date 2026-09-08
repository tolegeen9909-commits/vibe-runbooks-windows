#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
$passed = 0
$required = 4
$failures = New-Object System.Collections.Generic.List[string]

if (Test-RunbookCommand 'node') { $passed++; Write-RunbookOk "Node: $(& node --version)" }
else { $failures.Add('Node.js не найден.') }

if (Test-RunbookCommand 'npm.cmd') { $passed++; Write-RunbookOk "npm: $(& npm.cmd --version)" }
else { $failures.Add('npm.cmd не найден.') }

if (Test-RunbookCommand 'claude') { $passed++; Write-RunbookOk 'Claude Code запускается из PATH.' }
else { $failures.Add('Команда claude не найдена.') }

if (Test-RunbookCommand 'codex') { $passed++; Write-RunbookOk 'Codex CLI запускается из PATH.' }
else { $failures.Add('Команда codex не найдена.') }

$ok = Complete-RunbookVerification -Phase '04' -Passed $passed -Required $required -Failures @($failures)
if ($ok) {
    Mark-RunbookStep '04-ai-helpers:verified'
    exit 0
}
exit 1
