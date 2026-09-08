# Полный маршрут Windows

Это карта, а не команда «запустить всё». Codex читает карту и выполняет только один следующий скрипт, затем соответствующий `verify.ps1`.

Все команды выполняются из корня репозитория в Windows Terminal → PowerShell.

## Базовый маршрут

| Фаза | Результат | Следующая команда |
|---|---|---|
| 00 | Карта готовности Windows 11 | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\00-preflight\check-system.ps1` |
| 01 | Безопасные настройки Windows | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\01-windows-setup\setup-windows-defaults.ps1` |
| 02 | Terminal, PowerShell и `winget` готовы | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\02-foundation\install-windows-terminal.ps1` |
| 03 | Git, GitHub и защита секретов | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\03-git-github\install-git.ps1` |
| 04 | Node.js, Claude Code и Codex CLI | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\04-ai-helpers\install-node.ps1` |

### Фаза 00 · Preflight

Прочитай `00-preflight/runbook.md`, затем:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\00-preflight\check-system.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\00-preflight\verify.ps1
```

Этот шаг не меняет системные настройки и только записывает локальный прогресс. Если Windows не поддерживается или места недостаточно, сначала реши этот вопрос.

### Фаза 01 · Windows setup

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\01-windows-setup\setup-windows-defaults.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\01-windows-setup\install-extra-apps.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\01-windows-setup\verify.ps1
```

Скрипты не отключают Defender, Firewall, UAC и не меняют BIOS/BitLocker.

### Фаза 02 · Foundation

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\02-foundation\install-windows-terminal.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\02-foundation\verify.ps1
```

После установки Terminal открой новое окно PowerShell.

### Фаза 03 · Git и GitHub

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\03-git-github\install-git.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\03-git-github\install-gh.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\03-git-github\setup-git-identity.ps1 -Name "ТВОЁ ИМЯ" -Email "ТВОЙ_EMAIL"
gh auth login --web --git-protocol https
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\03-git-github\setup-secret-guard.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\03-git-github\setup-command-guard.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\03-git-github\verify.ps1
```

Вводи данные GitHub только в системном браузере. Перед заменой существующих global hooks скрипт остановится.

### Фаза 04 · AI helpers

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\04-ai-helpers\install-node.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\04-ai-helpers\install-claude.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\04-ai-helpers\install-codex.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\04-ai-helpers\verify.ps1
```

Первый запуск `claude` и `codex` выполняй отдельно после согласия пользователя на browser login.

## Выбор трека

После фазы 04 спроси пользователя. Сохрани один вариант: `base`, `flutter`, `web` или `both`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\select-tracks.ps1 -Selection both
```

Если мобильный трек не выбран, запусти `.\05-flutter\skip.ps1`. Если веб-трек не выбран, просто не добавляй `web` в state.

## Трек A · Flutter/Android

### Фаза 05 · Flutter и Android Studio

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\05-flutter\install-flutter.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\05-flutter\install-android-studio.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\05-flutter\setup-android-toolchain.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\05-flutter\verify.ps1
```

Android Studio Setup Wizard и создание виртуального устройства — ручные стоп-точки из `05-flutter/runbook.md`.

### Фаза 06 · Первое Flutter-приложение

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\06-first-win\create-and-run.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\06-first-win\first-edit-commit.ps1
```

После явного согласия на внешнее действие:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\06-first-win\first-edit-commit.ps1 -Publish
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\06-first-win\verify.ps1
```

## Трек B · Web/Netlify

### Фаза 05w · Netlify CLI

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\05w-netlify\install-netlify.ps1
netlify login
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\05w-netlify\verify.ps1
```

### Фаза 06w · Первый сайт

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\06w-first-site\create-site.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\06w-first-site\publish-site.ps1
```

После согласия на GitHub push и preview:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\06w-first-site\publish-site.ps1 -Push -Preview
```

Только после проверки preview и отдельного «да»:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\06w-first-site\publish-site.ps1 -Production
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\06w-first-site\verify.ps1
```

## Финальная фаза 07

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\07-checkpoint\self-check.ps1
```

Exit code `0` означает, что обязательная база и реально выбранные треки готовы. Backend appendix `99-appendix-backend` не входит в основной маршрут.

Если скрипт остановился, открой [TROUBLESHOOTING.md](TROUBLESHOOTING.md), исправь одну причину и повтори тот же шаг.
