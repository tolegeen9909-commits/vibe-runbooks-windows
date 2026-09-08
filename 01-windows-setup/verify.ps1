#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
$passed = 0
$failures = New-Object System.Collections.Generic.List[string]
$explorerKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

$hidden = (Get-ItemProperty -Path $explorerKey -Name Hidden -ErrorAction SilentlyContinue).Hidden
if ($hidden -eq 1) { $passed++; Write-RunbookOk 'Скрытые файлы видны.' }
else { $failures.Add('Скрытые файлы пока не включены.') }

$hideExtensions = (Get-ItemProperty -Path $explorerKey -Name HideFileExt -ErrorAction SilentlyContinue).HideFileExt
if ($hideExtensions -eq 0) { $passed++; Write-RunbookOk 'Расширения файлов видны.' }
else { $failures.Add('Расширения файлов пока скрыты.') }

$projectsPath = Join-Path $env:SystemDrive 'Projects'
if (Test-Path -LiteralPath $projectsPath -PathType Container) { $passed++; Write-RunbookOk "$projectsPath существует." }
else { $failures.Add("Нет рабочей папки $projectsPath.") }

$ok = Complete-RunbookVerification -Phase '01' -Passed $passed -Required 3 -Failures @($failures)
if ($ok) {
    Mark-RunbookStep '01-windows-setup:verified'
    exit 0
}
exit 1
