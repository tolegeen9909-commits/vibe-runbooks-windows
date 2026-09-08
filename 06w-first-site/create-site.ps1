#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ProjectsRoot = "$env:SystemDrive\Projects\vibecoding",
    [string]$ProjectName = 'vibecoding_first_site'
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\lib.ps1')

Assert-SupportedWindows
Write-RunbookStep 'Создаю первый статический сайт'

$projectPath = Join-Path $ProjectsRoot $ProjectName
New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
$indexPath = Join-Path $projectPath 'index.html'

if (-not (Test-Path -LiteralPath $indexPath)) {
    $html = @'
<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Мой первый сайт</title>
  <style>
    :root { color-scheme: light; font-family: system-ui, sans-serif; }
    body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: #f4f7fb; color: #172033; }
    main { width: min(680px, calc(100% - 48px)); padding: 48px; border-radius: 24px; background: white; box-shadow: 0 20px 60px rgba(23, 32, 51, .12); }
    h1 { margin-top: 0; font-size: clamp(2rem, 7vw, 4.5rem); line-height: 1; }
    p { font-size: 1.15rem; line-height: 1.6; }
    a { display: inline-block; margin-top: 16px; padding: 12px 18px; border-radius: 999px; background: #2256d8; color: white; text-decoration: none; }
  </style>
</head>
<body>
  <main>
    <p>Первая видимая победа</p>
    <h1>Мой первый сайт</h1>
    <p>Он создан на Windows, сохранён с помощью Git и готов к публикации.</p>
    <a href="https://github.com" rel="noreferrer">Открыть GitHub</a>
  </main>
</body>
</html>
'@
    $html | Set-Content -LiteralPath $indexPath -Encoding UTF8
}
else {
    Write-RunbookOk 'index.html уже существует; содержимое не перезаписано.'
}

$projectIgnore = Join-Path $projectPath '.gitignore'
foreach ($line in @('.env', '.env.*', '!.env.example', '!.env.sample', '!.env.template', '.netlify')) {
    Add-LineOnce -Path $projectIgnore -Line $line | Out-Null
}

$projectAgents = Join-Path $projectPath 'AGENTS.md'
if (-not (Test-Path -LiteralPath $projectAgents)) {
    Copy-Item -LiteralPath (Join-Path (Get-RunbookRoot) 'templates\project-AGENTS.md') -Destination $projectAgents
}

Set-RunbookTrack -Track 'web' -Enabled $true
Mark-RunbookStep '06w-first-site:created'
Write-RunbookOk "Сайт готов: $projectPath"
Write-RunbookInfo 'Открой index.html в браузере или попроси Codex проверить его встроенным браузером.'
