#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('base', 'flutter', 'web', 'both')]
    [string]$Selection
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib.ps1')

$enableFlutter = $Selection -in @('flutter', 'both')
$enableWeb = $Selection -in @('web', 'both')

Set-RunbookTrack -Track flutter -Enabled $enableFlutter
Set-RunbookTrack -Track web -Enabled $enableWeb
Mark-RunbookStep "tracks:selected-$Selection"

Write-RunbookOk "Выбран маршрут: $Selection"
if (-not $enableFlutter) {
    Write-RunbookInfo 'Flutter/Android можно добавить позже.'
}
if (-not $enableWeb) {
    Write-RunbookInfo 'Netlify можно добавить позже.'
}
