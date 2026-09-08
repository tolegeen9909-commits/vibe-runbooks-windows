#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param([string]$ProjectPath = "$env:SystemDrive\Projects\vibecoding\backend_sandbox")

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Write-RunbookWarning 'Это приложение к будущей фазе курса, а не продолжение первого маршрута.'
Install-WinGetPackage -PackageId 'Python.Python.3.14' -DisplayName 'Python 3.14' -WhatIf:$WhatIfPreference | Out-Null

if (-not (Test-RunbookCommand 'python.exe')) {
    Write-RunbookWarning 'Открой новое окно терминала после установки Python и повтори.'
    exit 2
}

New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
Push-Location $ProjectPath
try {
    if (-not (Test-Path -LiteralPath '.venv')) {
        Invoke-RunbookCommand -FilePath 'python.exe' -ArgumentList @('-m', 'venv', '.venv') | Out-Null
    }
}
finally { Pop-Location }

Write-RunbookOk "Python venv готов: $ProjectPath\.venv"
