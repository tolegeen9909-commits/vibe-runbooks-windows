#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Set-RunbookTrack -Track 'flutter' -Enabled $false
Mark-RunbookStep '05-flutter:skipped'
Write-RunbookWarning 'Мобильный трек осознанно пропущен. Его можно пройти позже.'
