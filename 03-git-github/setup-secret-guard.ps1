#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
if (-not (Test-RunbookCommand 'git')) {
    throw 'Git не найден. Сначала установи Git.'
}

Write-RunbookStep 'Устанавливаю защиту от секретов'
Install-WinGetPackage -PackageId 'Gitleaks.Gitleaks' -DisplayName 'Gitleaks' -WhatIf:$WhatIfPreference | Out-Null
if ($WhatIfPreference) {
    Write-RunbookInfo 'WhatIf: глобальные Git-настройки и hook не изменены.'
    return
}
if (-not (Test-RunbookCommand 'gitleaks')) {
    Write-RunbookWarning 'Gitleaks установлен, но текущее окно ещё не видит PATH.'
    Write-RunbookInfo 'Открой новый Windows Terminal и повтори этот скрипт.'
    exit 2
}

$configDir = Join-Path $env:USERPROFILE '.config\git'
New-Item -ItemType Directory -Path $configDir -Force | Out-Null
$configuredIgnoreFile = (& git config --global --get core.excludesfile 2>$null | Out-String).Trim()
if ($configuredIgnoreFile) {
    $ignoreFile = [Environment]::ExpandEnvironmentVariables($configuredIgnoreFile)
    if ($ignoreFile -eq '~') {
        $ignoreFile = $env:USERPROFILE
    }
    elseif ($ignoreFile.StartsWith('~/') -or $ignoreFile.StartsWith('~\')) {
        $ignoreFile = Join-Path $env:USERPROFILE $ignoreFile.Substring(2)
    }
    elseif (-not [IO.Path]::IsPathRooted($ignoreFile)) {
        $ignoreFile = Join-Path $env:USERPROFILE $ignoreFile
    }
    Write-RunbookInfo "Сохраняю существующий global excludes file: $ignoreFile"
}
else {
    $ignoreFile = Join-Path $configDir 'ignore'
}
$ignoreLines = @(
    '.env', '.env.*', '!.env.example', '!.env.sample', '!.env.template',
    '*.key', '*.pem', '*.p8', '*.p12', '*.keystore',
    'id_rsa', 'id_ed25519', 'credentials.json', 'secrets.json'
)
foreach ($line in $ignoreLines) {
    Add-LineOnce -Path $ignoreFile -Line $line | Out-Null
}
& git config --global core.excludesfile $ignoreFile
if ($LASTEXITCODE -ne 0) {
    throw 'Не удалось подключить глобальный ignore-файл.'
}
Write-RunbookOk "Глобальный ignore-файл готов: $ignoreFile"

$hooksDir = Join-Path $env:USERPROFILE '.git-hooks'
$hookPath = Join-Path $hooksDir 'pre-commit'
$marker = 'vibe-runbooks-windows:gitleaks'
New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null

if (Test-Path -LiteralPath $hookPath) {
    $existingHook = Get-Content -LiteralPath $hookPath -Raw
    if ($existingHook -notmatch [regex]::Escape($marker)) {
        if (-not $Force) {
            Write-RunbookWarning "Уже существует чужой hook: $hookPath"
            Write-RunbookInfo 'Ничего не перезаписано. Сначала изучи hook; затем повтори с -Force, если согласен на backup и замену.'
            exit 2
        }
        $backupPath = "$hookPath.backup-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
        Copy-Item -LiteralPath $hookPath -Destination $backupPath
        Write-RunbookWarning "Существующий hook сохранён: $backupPath"
    }
}

$hookContent = @'
#!/usr/bin/env bash
# vibe-runbooks-windows:gitleaks
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks git --pre-commit --staged --redact --no-banner >/dev/null 2>&1
  code=$?
  if [ "$code" -eq 1 ]; then
    echo "STOP: a staged secret may be present. Remove it or move it to .env." >&2
    exit 1
  fi
  if [ "$code" -gt 1 ]; then
    echo "STOP: gitleaks could not complete (exit $code); commit was blocked for safety." >&2
    exit "$code"
  fi
fi
exit 0
'@
$hookContent | Set-Content -LiteralPath $hookPath -Encoding Ascii

$currentHooksPath = (& git config --global --get core.hooksPath 2>$null | Out-String).Trim()
if ($currentHooksPath -and $currentHooksPath -ne $hooksDir) {
    if (-not $Force) {
        Write-RunbookWarning "Git уже использует другой core.hooksPath: $currentHooksPath"
        Write-RunbookInfo 'Hook создан, но не подключён. Проверь настройку и повтори с -Force для сохранения backup и переключения.'
        exit 2
    }
    $backupSetting = Join-Path $configDir 'core-hooks-path.backup.txt'
    $currentHooksPath | Set-Content -LiteralPath $backupSetting -Encoding UTF8
    Write-RunbookWarning "Старое значение сохранено: $backupSetting"
}

& git config --global core.hooksPath $hooksDir
if ($LASTEXITCODE -ne 0) {
    throw 'Не удалось подключить global pre-commit hook.'
}

& (Join-Path (Get-RunbookRoot) 'scripts\test-secret-guard.ps1')
Mark-RunbookStep '03-git-github:secret-guard'
Write-RunbookOk 'Gitleaks pre-commit guard подключён.'
Write-RunbookWarning 'Если проект использует husky или собственный core.hooksPath, добавь Gitleaks в hook самого проекта.'
