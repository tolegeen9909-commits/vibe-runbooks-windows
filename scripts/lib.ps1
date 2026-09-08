#requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RunbookRoot = Split-Path -Parent $PSScriptRoot

function Get-RunbookRoot {
    [CmdletBinding()]
    param()

    return $script:RunbookRoot
}

function Write-RunbookStep {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-RunbookInfo {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "    $Message" -ForegroundColor Gray
}

function Write-RunbookOk {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-RunbookWarning {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-RunbookFailure {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Test-RunbookCommand {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name)

    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-IsAdministrator {
    [CmdletBinding()]
    param()

    if ($env:OS -ne 'Windows_NT') {
        return $false
    }

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-SupportedWindows {
    [CmdletBinding()]
    param([switch]$AllowNonWindowsForTests)

    if ($env:OS -ne 'Windows_NT') {
        if ($AllowNonWindowsForTests) {
            return
        }
        throw 'Этот скрипт предназначен только для Windows 11.'
    }

    if (-not [Environment]::Is64BitOperatingSystem) {
        throw 'Нужна 64-битная Windows. 32-битная система не поддерживается.'
    }

    $os = Get-CimInstance Win32_OperatingSystem
    $build = [int]$os.BuildNumber
    if ($build -lt 22000) {
        throw "Нужна Windows 11 (build 22000 или новее). Найден build $build."
    }
}

function Invoke-RunbookCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [switch]$AllowFailure
    )

    & $FilePath @ArgumentList
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) {
        $exitCode = 0
    }

    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "Команда '$FilePath' завершилась с кодом $exitCode."
    }

    return $exitCode
}

function Test-WinGetPackageInstalled {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$PackageId)

    if (-not (Test-RunbookCommand 'winget')) {
        return $false
    }

    $output = & winget list --id $PackageId --exact --accept-source-agreements --disable-interactivity 2>&1 | Out-String
    return $output -match [regex]::Escape($PackageId)
}

function Install-WinGetPackage {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$PackageId,
        [ValidateSet('winget', 'msstore')][string]$Source = 'winget',
        [string]$DisplayName = $PackageId
    )

    Assert-SupportedWindows

    if (-not (Test-RunbookCommand 'winget')) {
        throw 'winget не найден. Установи App Installer из Microsoft Store и повтори шаг.'
    }

    if (Test-WinGetPackageInstalled -PackageId $PackageId) {
        Write-RunbookOk "$DisplayName уже установлен."
        return $false
    }

    if ($PSCmdlet.ShouldProcess($PackageId, 'winget install')) {
        Write-RunbookInfo "Устанавливаю $DisplayName через официальный источник $Source."
        $arguments = @(
            'install', '--id', $PackageId, '--exact', '--source', $Source,
            '--accept-package-agreements', '--accept-source-agreements',
            '--disable-interactivity'
        )
        Invoke-RunbookCommand -FilePath 'winget' -ArgumentList $arguments | Out-Null
        Write-RunbookOk "$DisplayName установлен."
    }

    return $true
}

function Add-UserPathEntry {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Path)

    $normalized = $Path.Trim().TrimEnd('\')
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        throw 'Нельзя добавить пустой путь в PATH.'
    }

    $currentUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @()
    if (-not [string]::IsNullOrWhiteSpace($currentUserPath)) {
        $entries = @($currentUserPath -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    $alreadyPresent = $false
    foreach ($entry in $entries) {
        if ($entry.Trim().TrimEnd('\') -ieq $normalized) {
            $alreadyPresent = $true
            break
        }
    }

    if (-not $alreadyPresent -and $PSCmdlet.ShouldProcess($normalized, 'Добавить в пользовательский PATH')) {
        $entries += $normalized
        [Environment]::SetEnvironmentVariable('Path', ($entries -join ';'), 'User')
    }

    $processEntries = @($env:Path -split ';')
    if (-not ($processEntries | Where-Object { $_.Trim().TrimEnd('\') -ieq $normalized })) {
        $env:Path = "$normalized;$env:Path"
    }

    return -not $alreadyPresent
}

function Add-LineOnce {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Line
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $existing = @()
    if (Test-Path -LiteralPath $Path) {
        $existing = @(Get-Content -LiteralPath $Path -ErrorAction Stop)
    }

    if ($existing -contains $Line) {
        return $false
    }

    Add-Content -LiteralPath $Path -Value $Line -Encoding UTF8
    return $true
}

function Get-RunbookStatePath {
    [CmdletBinding()]
    param()

    return Join-Path $script:RunbookRoot 'state\progress.json'
}

function Initialize-RunbookState {
    [CmdletBinding()]
    param()

    $statePath = Get-RunbookStatePath
    if (Test-Path -LiteralPath $statePath) {
        return $statePath
    }

    $templatePath = Join-Path $script:RunbookRoot 'state\progress-template.json'
    if (-not (Test-Path -LiteralPath $templatePath)) {
        throw "Не найден шаблон прогресса: $templatePath"
    }

    Copy-Item -LiteralPath $templatePath -Destination $statePath
    return $statePath
}

function Read-RunbookState {
    [CmdletBinding()]
    param()

    $statePath = Initialize-RunbookState
    return Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
}

function Write-RunbookState {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$State)

    $statePath = Get-RunbookStatePath
    $State.updatedAt = [DateTime]::UtcNow.ToString('o')
    $temporaryPath = "$statePath.tmp"
    $State | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
    Move-Item -LiteralPath $temporaryPath -Destination $statePath -Force
}

function Add-ProgressLogEntry {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)

    $logPath = Join-Path $script:RunbookRoot 'state\progress.log'
    $safeMessage = $Message -replace "[`r`n]", ' '
    $line = '{0} {1}' -f ([DateTime]::UtcNow.ToString('o')), $safeMessage
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

function Mark-RunbookStep {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Step)

    $state = Read-RunbookState
    $completed = @($state.completedSteps)
    if ($completed -notcontains $Step) {
        $state.completedSteps = @($completed + $Step)
    }
    $state.lastCheckpoint = $Step
    Write-RunbookState -State $state
    Add-ProgressLogEntry -Message "completed $Step"
}

function Test-RunbookStepCompleted {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Step)

    $state = Read-RunbookState
    return @($state.completedSteps) -contains $Step
}

function Set-RunbookTrack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('flutter', 'web')][string]$Track,
        [Parameter(Mandatory)][bool]$Enabled
    )

    $state = Read-RunbookState
    $tracks = @($state.selectedTracks)
    if ($Enabled -and $tracks -notcontains $Track) {
        $tracks += $Track
    }
    if (-not $Enabled) {
        $tracks = @($tracks | Where-Object { $_ -ne $Track })
    }
    $state.selectedTracks = @($tracks | Sort-Object -Unique)
    Write-RunbookState -State $state
    Add-ProgressLogEntry -Message "track $Track enabled=$Enabled"
}

function Complete-RunbookVerification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Phase,
        [Parameter(Mandatory)][int]$Passed,
        [Parameter(Mandatory)][int]$Required,
        [string[]]$Failures = @()
    )

    if ($Passed -ge $Required -and $Failures.Count -eq 0) {
        Write-RunbookOk "Фаза $Phase пройдена ($Passed/$Required)."
        return $true
    }

    Write-RunbookFailure "Фаза $Phase пока не пройдена ($Passed/$Required)."
    foreach ($failure in $Failures) {
        Write-RunbookInfo $failure
    }
    return $false
}
