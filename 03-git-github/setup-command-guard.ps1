#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
Write-RunbookStep 'Подключаю Windows command guard к Claude Code'

$pythonExe = $null
$pythonPrefix = @()
if (Test-RunbookCommand 'py.exe') {
    $pythonExe = 'py.exe'
    $pythonPrefix = @('-3')
}
elseif (Test-RunbookCommand 'python.exe') {
    $pythonExe = 'python.exe'
}
else {
    Install-WinGetPackage -PackageId 'Python.Python.3.14' -DisplayName 'Python 3.14' | Out-Null
    if (Test-RunbookCommand 'py.exe') {
        $pythonExe = 'py.exe'
        $pythonPrefix = @('-3')
    }
    elseif (Test-RunbookCommand 'python.exe') {
        $pythonExe = 'python.exe'
    }
}

if (-not $pythonExe) {
    Write-RunbookWarning 'Python установлен, но текущее окно не видит его. Открой новый терминал и повтори шаг.'
    exit 2
}

$sourceGuard = Join-Path (Get-RunbookRoot) 'scripts\command-guard.py'
$guardDir = Join-Path $env:USERPROFILE '.vibecoding\hooks'
$guardPath = Join-Path $guardDir 'command-guard.py'
New-Item -ItemType Directory -Path $guardDir -Force | Out-Null
Copy-Item -LiteralPath $sourceGuard -Destination $guardPath -Force

& $pythonExe @pythonPrefix $guardPath '--selftest'
if ($LASTEXITCODE -ne 0) {
    throw 'Self-test command guard не прошёл; настройки Claude Code не изменены.'
}
Write-RunbookOk 'Self-test command guard пройден.'

$claudeDir = Join-Path $env:USERPROFILE '.claude'
$settingsPath = Join-Path $claudeDir 'settings.json'
New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null

$settings = [pscustomobject]@{}
if (Test-Path -LiteralPath $settingsPath) {
    $raw = Get-Content -LiteralPath $settingsPath -Raw
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
        $settings = $raw | ConvertFrom-Json
    }
    $backupPath = "$settingsPath.backup-command-guard-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
    Copy-Item -LiteralPath $settingsPath -Destination $backupPath
    Write-RunbookInfo "Резервная копия настроек: $backupPath"
}

if (-not $settings.PSObject.Properties['hooks'] -or $null -eq $settings.hooks) {
    $settings | Add-Member -MemberType NoteProperty -Name hooks -Value ([pscustomobject]@{})
}
if (-not $settings.hooks.PSObject.Properties['PreToolUse']) {
    $settings.hooks | Add-Member -MemberType NoteProperty -Name PreToolUse -Value @()
}

$existingMatchers = @($settings.hooks.PreToolUse)
$alreadyConfigured = $false
foreach ($matcher in $existingMatchers) {
    foreach ($hook in @($matcher.hooks)) {
        if ($hook.command -like '*command-guard.py*') {
            $alreadyConfigured = $true
        }
    }
}

if (-not $alreadyConfigured) {
    $prefixText = if ($pythonPrefix.Count -gt 0) { ($pythonPrefix -join ' ') + ' ' } else { '' }
    $guardCommand = '{0} {1}"{2}"' -f $pythonExe, $prefixText, $guardPath
    $entry = [pscustomobject]@{
        matcher = 'Bash|PowerShell'
        hooks = @(
            [pscustomobject]@{
                type = 'command'
                command = $guardCommand
            }
        )
    }
    $settings.hooks.PreToolUse = @($existingMatchers + $entry)
    $settings | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $settingsPath -Encoding UTF8
}

Mark-RunbookStep '03-git-github:command-guard'
Write-RunbookOk 'Command guard подключён к Claude Code.'
Write-RunbookInfo 'Codex использует собственные Windows Sandbox и approval prompts.'
