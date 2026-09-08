#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Write-RunbookStep 'Проверяю компьютер — ничего не устанавливаю и не меняю'

if ($env:OS -ne 'Windows_NT') {
    Write-RunbookFailure 'Этот комплект предназначен только для Windows 11.'
    exit 1
}

$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
$processor = Get-CimInstance Win32_Processor | Select-Object -First 1
$systemDrive = if ($env:SystemDrive) { $env:SystemDrive } else { 'C:' }
$driveName = $systemDrive.TrimEnd(':')
$drive = Get-PSDrive -Name $driveName
$memoryGb = [math]::Round($computer.TotalPhysicalMemory / 1GB, 1)
$freeGb = [math]::Round($drive.Free / 1GB, 1)
$build = [int]$os.BuildNumber

Write-Host ('Windows:       {0} (build {1})' -f $os.Caption, $build)
Write-Host ('Архитектура:   {0}' -f $os.OSArchitecture)
Write-Host ('Процессор:     {0}' -f $processor.Name.Trim())
Write-Host ('Оперативная:   {0} GB' -f $memoryGb)
Write-Host ('Свободно на {0} {1} GB' -f $systemDrive, $freeGb)
Write-Host ('Виртуализация: {0}' -f $processor.VirtualizationFirmwareEnabled)
Write-Host ('Администратор: {0}' -f (Test-IsAdministrator))

$problems = New-Object System.Collections.Generic.List[string]
if ($build -lt 22000) {
    $problems.Add('Нужна Windows 11 build 22000 или новее.')
}
if (-not [Environment]::Is64BitOperatingSystem) {
    $problems.Add('Нужна 64-битная Windows.')
}
if ($memoryGb -lt 8) {
    $problems.Add('Меньше 8 GB RAM: базовый маршрут может работать медленно.')
}
if ($freeGb -lt 15) {
    $problems.Add('Меньше 15 GB свободного места: сначала освободи диск.')
}
if (-not (Test-RunbookCommand 'winget')) {
    $problems.Add('winget не найден. Установи App Installer из Microsoft Store и повтори проверку.')
}

Write-RunbookStep 'Карта инструментов'
$tools = @(
    @{ Name = 'winget'; Command = 'winget' },
    @{ Name = 'Git'; Command = 'git' },
    @{ Name = 'GitHub CLI'; Command = 'gh' },
    @{ Name = 'Node.js'; Command = 'node' },
    @{ Name = 'npm'; Command = 'npm.cmd' },
    @{ Name = 'Python'; Command = 'python' },
    @{ Name = 'Claude Code'; Command = 'claude' },
    @{ Name = 'Codex CLI'; Command = 'codex' },
    @{ Name = 'Flutter'; Command = 'flutter' },
    @{ Name = 'Netlify CLI'; Command = 'netlify' }
)

foreach ($tool in $tools) {
    if (Test-RunbookCommand $tool.Command) {
        Write-RunbookOk $tool.Name
    }
    else {
        Write-Host ('[ ]  {0} — установим позже' -f $tool.Name)
    }
}

if (-not $processor.VirtualizationFirmwareEnabled) {
    Write-RunbookWarning 'Виртуализация выключена или не определяется. Она понадобится Android Emulator.'
}

if ($problems.Count -gt 0) {
    foreach ($problem in $problems) {
        Write-RunbookFailure $problem
    }
    exit 1
}

Mark-RunbookStep '00-preflight:passed'
Write-RunbookOk 'Базовые требования выполнены. Пустые пункты — это будущие шаги, не ошибки.'
