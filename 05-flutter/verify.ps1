#requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
$passed = 0
$required = 3
$failures = New-Object System.Collections.Generic.List[string]

if (Test-RunbookCommand 'flutter') {
    $passed++
    Write-RunbookOk "Flutter: $((& flutter --version | Select-Object -First 1))"
}
else { $failures.Add('Flutter не найден в PATH.') }

if (Test-WinGetPackageInstalled -PackageId 'Google.AndroidStudio') {
    $passed++
    Write-RunbookOk 'Android Studio установлен.'
}
else { $failures.Add('Android Studio не найден через winget.') }

if (Test-RunbookCommand 'flutter') {
    $doctorOutput = (& flutter doctor -v 2>&1 | Out-String)
    Write-Host $doctorOutput
    $androidLine = ($doctorOutput -split "`r?`n" | Where-Object { $_ -match 'Android toolchain' } | Select-Object -First 1)
    if ($androidLine -and $androidLine -notmatch '\[!\]|\[x\]|\[✗\]') {
        $passed++
        Write-RunbookOk 'Flutter видит Android toolchain.'
    }
    else { $failures.Add('Android toolchain не готов. Проверь строку Android toolchain выше.') }
}

$ok = Complete-RunbookVerification -Phase '05' -Passed $passed -Required $required -Failures @($failures)
if ($ok) {
    Set-RunbookTrack -Track 'flutter' -Enabled $true
    Mark-RunbookStep '05-flutter:verified'
    exit 0
}
exit 1
