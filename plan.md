# План реализации Vibe Runbooks Windows

Связанная спецификация: `docs/specs/2026-09-08-vibe-runbooks-windows.md`.

Статус: Gate 4 пройден — независимое review не нашло оставшихся P1/P2; Windows CI успешен.

## Архитектура и поток работы

### 1. Документация как управляющий слой

`AGENTS.md` будет точкой входа для Codex. Он направляет агента к `FOR-CODEX.md`, `RITUALS.md` и `INDEX.md`, после чего агент выбирает только один следующий шаг.

Поток сессии:

```text
AGENTS.md
  → FOR-CODEX.md + RITUALS.md
  → INDEX.md
  → runbook текущей фазы
  → один PowerShell-скрипт или ручная стоп-точка
  → verify.ps1
  → запись progress
  → следующая фаза
```

Документация не будет советовать новичку запускать весь маршрут одной командой.

### 2. Общая PowerShell-библиотека

`scripts/lib.ps1` будет подключаться всеми скриптами и предоставлять небольшие функции:

- проверка Windows 11/x64 и обычного/повышенного режима;
- единый цветной вывод `Step`, `Info`, `Ok`, `Warn`, `Fail`;
- поиск команды и безопасный запуск внешнего процесса с exit code;
- проверка `winget` package ID и идемпотентная установка;
- добавление пользовательского PATH без дублей;
- добавление строки в текстовый файл без дублей;
- чтение и атомарное обновление `state/progress.json`;
- запись короткого журнала в `state/progress.log`;
- обнаружение корня репозитория независимо от текущего каталога;
- стандартизованный итог проверки и ненулевой exit code при обязательной ошибке.

Скрипты будут совместимы с Windows PowerShell 5.1 и PowerShell 7 и не потребуют сторонних модулей для основного маршрута.

### 3. Модель установки

- Системные пакеты: `winget` с точными package IDs и проверкой уже установленного пакета.
- Node-инструменты: `npm.cmd`, чтобы не зависеть от блокировки `npm.ps1` execution policy.
- Flutter SDK: официальный архив в короткий путь `C:\src\flutter`; загрузка отделена от распаковки и подтверждается пользователем перед сетевым действием.
- Android Studio: `winget`, затем ручной Setup Wizard, Android SDK licenses и AVD.
- Аккаунты: скрипт только запускает официальный login flow или печатает команду; пароль/2FA остаются в системном браузере.
- UAC/admin: скрипт заранее объясняет действие и останавливается, если повышение прав требуется, но текущий процесс не elevated.

### 4. Прогресс и возобновление

`state/progress-template.json` задаёт схему:

```json
{
  "schemaVersion": 1,
  "updatedAt": null,
  "selectedTracks": [],
  "completedSteps": [],
  "lastCheckpoint": null,
  "artifacts": {},
  "notes": []
}
```

`state/progress.json` создаётся локально при первом запуске и игнорируется Git. `progress.log` тоже локальный. Скрипты записывают только названия шагов и результаты, без токенов, email, путей к секретам и полного вывода входа.

### 5. Защита секретов

`setup-secret-guard.ps1`:

1. устанавливает Gitleaks через `winget`;
2. создаёт глобальный exclude-файл Git;
3. сохраняет `.env.example`, `.env.sample`, `.env.template` доступными для Git;
4. создаёт глобальный `pre-commit` hook, который Git for Windows выполняет через Git Bash;
5. не перезаписывает существующую настройку без резервной копии и явного объяснения;
6. запускает самопроверку в временном Git-репозитории.

### 6. Windows command guard

`scripts/command-guard.py` будет расширен под команды Windows и останется стандартной Python-программой без пакетов. Он читает JSON протокола Claude Code `PreToolUse` и выдаёт allow/warn/deny.

Минимальный deny-set:

- force-push в `main`/`master`;
- `git reset --hard`, `git clean -f`;
- удаление `.env`, ключей и credential-файлов;
- `Remove-Item -Recurse -Force`/`rm`/`del`/`rd` для корня диска, профиля пользователя, текущего проекта или `.git`;
- `Format-Volume`, `Clear-Disk`, `Initialize-Disk`, опасные `diskpart`-сценарии;
- скачивание и немедленное исполнение через `irm`/`iwr`/`curl` + `iex`/PowerShell/`cmd`;
- разрушительные операции с защищёнными ветками.

Безопасные операции вроде удаления конкретных `node_modules`, `build` или `dist` должны проходить. Self-test станет обязательным в CI.

### 7. Проверки фаз

Каждый `verify.ps1` возвращает:

- `0`, если обязательные критерии фазы выполнены;
- ненулевой код, если обязательный критерий не выполнен;
- отдельные предупреждения для ручных/необязательных пунктов.

Проверка не должна считать запрос на browser login установленного инструмента поломкой. Flutter verify оценивает только Windows/Android и не требует Xcode или CocoaPods.

## Файлы MVP

### Корень

- `.gitignore`
- `.gitattributes`
- `AGENTS.md`
- `CLAUDE.md`
- `FOR-CODEX.md`
- `RITUALS.md`
- `INDEX.md`
- `README.md`
- `TROUBLESHOOTING.md`
- `plan.md`
- `PSScriptAnalyzerSettings.psd1`

### Фазы

- `00-preflight/check-system.ps1`
- `00-preflight/verify.ps1`
- `00-preflight/runbook.md`
- `01-windows-setup/setup-windows-defaults.ps1`
- `01-windows-setup/install-extra-apps.ps1`
- `01-windows-setup/verify.ps1`
- `01-windows-setup/runbook.md`
- `02-foundation/install-windows-terminal.ps1`
- `02-foundation/verify.ps1`
- `02-foundation/runbook.md`
- `03-git-github/install-git.ps1`
- `03-git-github/install-gh.ps1`
- `03-git-github/setup-git-identity.ps1`
- `03-git-github/setup-secret-guard.ps1`
- `03-git-github/setup-command-guard.ps1`
- `03-git-github/verify.ps1`
- `03-git-github/runbook.md`
- `04-ai-helpers/install-node.ps1`
- `04-ai-helpers/install-claude.ps1`
- `04-ai-helpers/install-codex.ps1`
- `04-ai-helpers/verify.ps1`
- `04-ai-helpers/runbook.md`
- `05-flutter/install-flutter.ps1`
- `05-flutter/install-android-studio.ps1`
- `05-flutter/setup-android-toolchain.ps1`
- `05-flutter/skip.ps1`
- `05-flutter/verify.ps1`
- `05-flutter/runbook.md`
- `06-first-win/create-and-run.ps1`
- `06-first-win/first-edit-commit.ps1`
- `06-first-win/verify.ps1`
- `06-first-win/runbook.md`
- `05w-netlify/install-netlify.ps1`
- `05w-netlify/verify.ps1`
- `05w-netlify/runbook.md`
- `06w-first-site/create-site.ps1`
- `06w-first-site/publish-site.ps1`
- `06w-first-site/verify.ps1`
- `06w-first-site/runbook.md`
- `07-checkpoint/self-check.ps1`
- `07-checkpoint/runbook.md`
- `99-appendix-backend/install-python-venv.ps1`
- `99-appendix-backend/runbook.md`

### Общие файлы и тесты

- `scripts/lib.ps1`
- `scripts/select-tracks.ps1`
- `scripts/test-secret-guard.ps1`
- `scripts/command-guard.py`
- `state/progress-template.json`
- `templates/project-AGENTS.md`
- `tests/lib.Tests.ps1`
- `tests/routing.Tests.ps1`
- `tests/command-guard.Tests.ps1`
- `tests/secret-guard.Tests.ps1`
- `.github/workflows/ci.yml`

## MVP и последующие версии

### MVP 0.1

- весь базовый маршрут;
- Flutter/Android и Netlify треки;
- документация на русском;
- прогресс и возобновление;
- Gitleaks и command guard;
- Pester/self-tests на Windows CI;
- приватный GitHub-репозиторий и pull request.

### После MVP

- отдельный необязательный WSL2-трек;
- поддержка Windows on ARM после подтверждения Android Studio/toolchain;
- подписанные PowerShell-скрипты;
- графический launcher или `.msi`;
- локализация на другие языки;
- Play Store release flow;
- Docker/backend/Railway;
- автоматический интеграционный прогон на чистой Windows VM.

## Чек-лист реализации

- [x] Создать feature-ветку `codex/windows-runbooks-mvp`.
- [x] Добавить корневые правила, `.gitignore`, `.gitattributes` и обязательный раздел Open Design в `AGENTS.md`.
- [x] Реализовать `scripts/lib.ps1` и state-модель.
- [x] Реализовать фазу 00 с проверкой без изменения системных настроек.
- [x] Реализовать фазу 01 без отключения системной безопасности.
- [x] Реализовать фазу 02 и проверку `winget`/Terminal/PowerShell/`tree`.
- [x] Реализовать фазу 03: Git, GitHub, identity, Gitleaks и command guard.
- [x] Реализовать фазу 04: Node.js, Claude Code, Codex CLI.
- [x] Реализовать Flutter/Android фазу 05 и skip-маркер.
- [x] Реализовать первую Flutter-победу и безопасный GitHub publish flow.
- [x] Реализовать Netlify фазу 05w.
- [x] Реализовать первый сайт, preview deploy и подтверждаемый production deploy.
- [x] Реализовать итоговый checkpoint по выбранным трекам.
- [x] Добавить backend appendix без включения в основной маршрут.
- [x] Написать README, INDEX, ритуалы, полную инструкцию гида и troubleshooting.
- [x] Добавить Pester-тесты, Python self-test и Windows GitHub Actions.
- [x] Выполнить отдельный review по спецификации и устранить замечания.
- [x] Создать GitHub-репозиторий `vibe-runbooks-windows`; после приёмки владелец явно изменил его видимость на public.
- [x] Проверить diff на секреты и случайные файлы.
- [x] Сделать сфокусированный commit и push feature-ветки.
- [x] Открыть pull request; дождаться успешного Windows CI.

## План проверки

### Локально в текущей среде

Текущий хост — macOS, и `pwsh` не установлен. Поэтому локально доступны:

- проверка структуры и обязательных файлов;
- Python self-test command guard;
- проверка JSON;
- поиск macOS-only команд и ошибочных `.sh`-ссылок;
- статическая проверка ссылок/маршрутизации;
- просмотр Git diff на секреты и случайные артефакты.

### В GitHub Actions на `windows-latest`

- PowerShell parse check всех `.ps1`;
- Pester-тесты общей библиотеки и маршрутизации;
- self-test command guard;
- временный Git-репозиторий для Gitleaks hook без установки реальных пользовательских настроек;
- проверка идемпотентности функций записи PATH/state/ignore;
- проверка обязательных файлов и соответствия INDEX маршруту.

### Ручные проверки, которые останутся владельцу Windows

- UAC и Windows Sandbox;
- browser login ChatGPT/GitHub/Claude/Netlify;
- Android Studio Setup Wizard;
- Android Emulator и аппаратная виртуализация;
- фактическая сборка Flutter-приложения;
- preview/production deploy учебного сайта.

Эти проверки будут перечислены в PR и README как Windows smoke checklist.

## Риски и откат

### Риски

- Package IDs или интерактивное поведение `winget` могут различаться по региону и версии Windows.
- Android Studio и SDK требуют больших загрузок и ручного Setup Wizard.
- Существующий пользовательский `core.hooksPath` может конфликтовать с глобальным Gitleaks hook.
- Claude Code меняет формат hooks/settings; setup должен создавать резервную копию и проверять JSON.
- PowerShell 5.1 и 7 различаются кодировкой и некоторыми параметрами cmdlets.
- Полная функциональная проверка невозможна на текущем macOS-хосте до запуска Windows CI и ручного smoke test.

### Откат

- Установщики не удаляют существующие пакеты и не делают автоматический uninstall.
- Перед изменением Git/Claude конфигурации создаются timestamped backup-файлы.
- Изменения PATH добавляются только при отсутствии значения и документируются для ручного удаления.
- Системные security-настройки не отключаются и не переписываются автоматически.
- GitHub-работа идёт через feature-ветку и PR; `main` не меняется напрямую.
- Репозиторий не является веб-сайтом, поэтому Netlify deployment для самого runbook-проекта не выполняется.

## Критерий готовности реализации

MVP готов к передаче, когда все acceptance criteria спецификации либо подтверждены автоматическими тестами, либо явно вынесены в Windows smoke checklist; Windows CI зелёный; pull request открыт; GitHub-репозиторий доступен по ссылке владельцу.
