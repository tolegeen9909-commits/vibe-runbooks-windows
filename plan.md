# План реализации Mac mini 24/7

Связанная спецификация: docs/specs/2026-10-03-mac-mini-24x7-runbook.md.

Статус: Gate 4 завершён. Независимые review и tests пройдены без P0/P1/P2 блокеров; feature-ветка опубликована, открыт stacked PR #3, Windows и macOS GitHub CI прошли. Merge не выполнялся.

Рабочая ветка: codex/mac-mini-24x7-runbook, основана на codex/windows-safe-install-rules из открытого PR #2. До объединения Mac-маршрута PR #2 должен быть сохранён и предпочтительно объединён первым.

## Ключевые решения

- Mac-маршрут остаётся в этом же репозитории, но изолируется в mac-mini-24x7/.
- Существующие Windows-фазы не переносятся и не переименовываются.
- Корневые AGENTS.md, CLAUDE.md, README.md и INDEX.md становятся точкой выбора целевой машины, а не пытаются определять маршрут только по ОС, на которой открыт репозиторий.
- Если на Windows настраивают удалённый Mac mini, выбирается Mac-маршрут.
- Основной удалённый канал: Apple Remote Login и обычный SSH поверх Tailscale.
- AnyDesk используется как резервный GUI-канал, а не как единственный способ восстановления.
- Публичный TCP/22 не открывается и не пробрасывается на роутере.
- Безопасный режим по умолчанию: FileVault включён, automatic login выключен. Он честно отмечает, что после холодной загрузки может потребоваться локальная разблокировка.
- Полностью автономный режим допускается только как отдельный opt-in после предупреждения о физическом риске, ручного решения по FileVault/automatic login и полного end-to-end теста.
- Ни один скрипт маршрута не устанавливает программы, не запускает sudo, не меняет pmset, FileVault, automatic login, TCC, Remote Login, VPN, login items или настройки AnyDesk.
- Все системные изменения выполняются по одному: сначала read-only проверка, затем точная команда или ручное действие, отдельное согласие пользователя и повтор той же проверки.
- Команды и интерфейсы изменчивых продуктов перед реализацией сверяются с официальными источниками. Для Codex используется только актуальная официальная документация OpenAI.
- Текущий новый Homebrew-backed setup фазы 09 ограничен Apple Silicon и macOS 15+; Intel/более старая macOS останавливаются до отдельного architecture-specific review, но не ломают remote-access фазы 00–08.

## Архитектура и поток

### 1. Корневой маршрутизатор

AGENTS.md сначала определяет целевую машину:

- Windows 11 → существующие FOR-CODEX.md, RITUALS.md, INDEX.md и PowerShell-фазы;
- Mac mini 24/7 → mac-mini-24x7/AGENTS.md и только macOS-маршрут;
- если цель не названа → один короткий вопрос, без запуска команд.

Общие правила безопасности, один шаг за раз, запрет передачи секретов и раздел Open Design остаются в корне. Windows-only запреты применяются только после выбора Windows-маршрута.

CLAUDE.md повторяет только нейтральную точку входа. README.md и INDEX.md дают видимый выбор двух маршрутов, после чего существующая Windows-карта остаётся доступной без изменения порядка фаз.

### 2. Изолированный Mac-маршрут

Поток Mac-сессии:

    root AGENTS.md
      → mac-mini-24x7/AGENTS.md
      → FOR-CODEX.md + RITUALS.md
      → INDEX.md
      → runbook текущей фазы
      → read-only check или одна ручная стоп-точка
      → отдельное подтверждение изменяющего действия
      → повторная проверка
      → локальный checkpoint
      → следующая фаза

Фазы:

1. 00-preflight — модель без серийного номера, архитектура, версия macOS, обычный/административный пользователь, свободное место и уже установленные инструменты.
2. 01-macos-update — ручная проверка обновлений и безопасная перезагрузка с локальным доступом.
3. 02-power-24x7 — запрет системного сна при допустимом сне дисплея, wake for network access и поддерживаемый механизм запуска после восстановления питания.
4. 03-ssh-termius — Apple Remote Login только для выбранного пользователя, проверка сначала в LAN, затем ключевая аутентификация и Termius.
5. 04-anydesk — установленная версия, минимальные TCC-разрешения, Unattended Access, 2FA/ACL и проверка управления.
6. 05-tailscale — официальные клиенты на Mac и Windows, один tailnet, least-privilege policy, обычный SSH по Tailscale IP или MagicDNS.
7. 06-recovery-security — autorestart, FileVault/automatic-login decision gate и выбранный режим восстановления.
8. 07-reboot-checkpoint — lock, logout и обычная перезагрузка при сохранённом локальном доступе.
9. 08-power-loss-headless — отдельный рискованный тест восстановления питания и затем headless-проверка.
10. 09-development — Homebrew, Git/GitHub, Node.js, Python, Codex и Claude Code только после стабильного удалённого доступа.
11. 10-final-checkpoint — итоговая проверка локальных состояний и подтверждённых удалённых сценариев.

### 3. Состояние и возобновление

Mac-маршрут использует отдельный mac-mini-24x7/state/progress.json, который игнорируется Git.

Схема содержит только:

- schemaVersion;
- route;
- selectedMode: secure или autonomous;
- completedSteps из фиксированного allowlist;
- manualChecks из фиксированного allowlist;
- updatedAt;
- lastCheckpoint.

В state запрещены произвольные notes, имя пользователя, IP, hostname, email, AnyDesk ID, пароли, recovery keys, токены и полный вывод команд.

scripts/record-checkpoint.sh атомарно обновляет только локальный state и принимает только заранее разрешённые marker IDs. scripts/lib.sh остаётся совместимым со штатным Bash 3.2 и встроенными средствами macOS; Homebrew, jq и Python для базовой работы не требуются.

### 4. Проверки и уровни результата

Read-only скрипты выводят только PASS, WARN, FAIL или MANUAL и не печатают сырые IP, AnyDesk ID, email владельца tailnet или секретные значения.

- PASS означает, что состояние доказано локальной проверкой.
- WARN означает необязательное ограничение или неподдерживаемую конкретной моделью настройку.
- FAIL означает, что обязательное локальное условие не выполнено.
- MANUAL означает, что результат можно доказать только с другого устройства, после reboot, через TCC-интерфейс или физическим тестом.

Итог имеет два честных статуса:

- secure-ready — FileVault сохранён, удалённый доступ проверен после входа, а ограничение холодной загрузки явно зафиксировано;
- autonomous-ready — отдельно подтверждены automatic login или другой доказанный pre-login путь, Tailscale/SSH, AnyDesk, reboot, восстановление питания и headless.

Полный критерий из исходного PDF соответствует autonomous-ready. Secure-ready не выдаётся за полностью автономный режим.

### 5. Официальные источники

mac-mini-24x7/SOURCES.md хранит ссылки и дату последней проверки, но не копирует длинные фрагменты документации. Ссылка также указывается рядом с рискованным действием в соответствующем runbook.

Перед реализацией фиксируются официальные источники:

- Apple Remote Login, Energy settings, startup after power failure, FileVault и automatic login;
- Tailscale macOS variants, Windows install, connectivity, unattended behavior и access controls;
- AnyDesk macOS permissions, Unattended Access и security guidance;
- Microsoft OpenSSH on Windows и официальная документация Termius;
- Homebrew, GitHub CLI, Node.js и Python;
- OpenAI Codex CLI;
- Anthropic Claude Code.

Уже проверенные ключевые ограничения:

- стандартный Tailscale GUI на macOS не заменяет Apple Remote Login и обычно недоступен до входа пользователя;
- для beginner-маршрута используется обычный SSH поверх tailnet, а не Tailscale SSH server;
- AnyDesk требует Screen Recording для просмотра и Accessibility для управления; Full Disk Access нужен только при реальной необходимости передачи файлов;
- automatic login несовместим с FileVault и снижает физическую защиту;
- OpenAI Codex CLI должен устанавливаться по актуальной официальной инструкции OpenAI; download-and-execute pipeline не запускается одним непрозрачным шагом.

## Файлы

### Изменить в корне

- AGENTS.md — общий safety-layer и router по целевой машине.
- CLAUDE.md — нейтральная точка входа через AGENTS.md.
- README.md — два маршрута и краткий выбор.
- INDEX.md — chooser и ссылка на Mac-карту при сохранении Windows-карты.
- .gitignore — локальные Mac progress-файлы.
- tests/routing.Tests.ps1 — явная область Windows-runbooks вместо рекурсивного сканирования Mac-документов; проверки обеих ссылок маршрутизации.
- plan.md — этот утверждённый план и отметки выполнения.
- docs/specs/2026-10-03-mac-mini-24x7-runbook.md — при необходимости только уточнения, согласованные с пользователем.

### Добавить в mac-mini-24x7

- AGENTS.md
- FOR-CODEX.md
- RITUALS.md
- INDEX.md
- runbook.md
- SOURCES.md
- TROUBLESHOOTING.md
- scripts/lib.sh
- scripts/record-checkpoint.sh
- state/progress-template.json
- tests/route.sh
- 00-preflight/runbook.md
- 00-preflight/check-system.sh
- 01-macos-update/runbook.md
- 02-power-24x7/runbook.md
- 02-power-24x7/verify.sh
- 03-ssh-termius/runbook.md
- 03-ssh-termius/verify.sh
- 04-anydesk/runbook.md
- 04-anydesk/verify.sh
- 05-tailscale/runbook.md
- 05-tailscale/verify.sh
- 06-recovery-security/runbook.md
- 06-recovery-security/verify.sh
- 07-reboot-checkpoint/runbook.md
- 08-power-loss-headless/runbook.md
- 09-development/runbook.md
- 09-development/verify.sh
- 10-final-checkpoint/runbook.md
- 10-final-checkpoint/self-check.sh

### Добавить в GitHub Actions

- .github/workflows/macos.yml — отдельный macos-latest job; существующий Windows workflow остаётся отдельным и неизменным по назначению.

## MVP и последующие версии

### MVP этой задачи

- два явно разделённых маршрута;
- полный beginner-friendly Mac runbook по фазам 00–10;
- безопасный state/checkpoint;
- только read-only проверки системы;
- secure/autonomous decision gate;
- диагностика SSH, Tailscale, AnyDesk и post-reboot сценариев;
- отдельный macOS CI;
- Windows CI без регрессий;
- feature-ветка, проверенный commit, push и stacked pull request.

### После MVP

- open-source tailscaled, работающий до login, только для опытного администратора;
- автоматизация Tailscale Grants/ACL и MDM;
- удалённая FileVault-разблокировка на поддерживаемых Apple silicon/macOS как отдельный advanced route;
- автоматизированный smart-plug power-cycle;
- mutating install scripts;
- тестовая матрица нескольких поколений Mac mini и macOS;
- переименование репозитория после отдельного решения владельца.

## Чек-лист реализации

- [x] Получить подтверждение, что нужен полноценный runbook, а не загрузка PDF.
- [x] Создать и утвердить спецификацию.
- [x] Подключить origin и создать ветку codex/mac-mini-24x7-runbook поверх safety PR #2.
- [x] Проверить конфликт текущих Windows routing tests с macOS-командами.
- [x] Сверить архитектурно значимые ограничения Apple, Tailscale, AnyDesk и OpenAI по официальным источникам.
- [x] Зафиксировать Windows baseline до изменений.
- [x] Создать Mac instructions, rituals, index, source registry и progress schema.
- [x] Реализовать shell library и allowlisted local checkpoint writer.
- [x] Реализовать фазы 00–06 и их read-only проверки.
- [x] Реализовать ручные checkpoint-фазы 07–08 без ложной автоматической верификации.
- [x] Реализовать фазу 09 development с актуальными официальными источниками.
- [x] Реализовать финальный checkpoint и различие secure-ready/autonomous-ready.
- [x] Превратить корневые инструкции и навигацию в OS/target router.
- [x] Ограничить Windows-only Pester assertions Windows-документами.
- [x] Добавить отдельный macOS workflow и deterministic self-tests.
- [x] Выполнить локальные проверки и устранить ошибки.
- [x] Выполнить независимый review по спецификации.
- [x] Выполнить независимый тестовый проход и повторить проверки после исправлений.
- [x] Проверить diff на секреты, реальные IP/ID, случайные файлы и несвязанные изменения.
- [x] Создать сфокусированный commit, push и stacked PR с prerequisite PR #2.
- [x] Дождаться зелёных Windows и macOS CI; merge не выполнять без команды finish.

## План проверки

### Baseline перед кодом

- git status -sb;
- сохранить список текущих файлов и текущий commit;
- python3 scripts/command-guard.py --selftest;
- проверить JSON-шаблоны;
- зафиксировать, что локально pwsh отсутствует или выполнить доступные Pester-тесты, если он установлен;
- сверить текущий green status PR #2.

### Локальные проверки после реализации

    bash -n mac-mini-24x7/scripts/*.sh
    bash -n mac-mini-24x7/*/*.sh
    bash mac-mini-24x7/tests/route.sh
    python3 -m json.tool mac-mini-24x7/state/progress-template.json
    python3 scripts/command-guard.py --selftest
    git diff --check

Дополнительно:

- запустить check-system.sh на текущем Mac и убедиться, что он ничего не меняет и не печатает серийный номер, IP, email или ID;
- прогнать verify/self-check в deterministic test mode с PASS, FAIL и MANUAL fixtures;
- статически проверить, что Mac-документы не предлагают PowerShell/winget, а Windows-документы не подхватывают macOS-команды;
- проверить ссылки и названия интерфейсов по SOURCES.md;
- поискать секреты, приватные ключи, реальные IPv4/IPv6, AnyDesk ID и debug output.

### GitHub Actions

Windows workflow:

- существующий PowerShell parse;
- Windows PowerShell 5.1 smoke;
- PSScriptAnalyzer;
- command guard self-test;
- Pester, включая routing без рекурсивного захвата Mac-runbooks.

Новый macos-latest workflow:

- bash syntax всех Mac scripts/tests;
- route/static tests;
- JSON lint;
- deterministic tests checkpoint allowlist и redaction;
- read-only check-system smoke на runner;
- без установки приложений, TCC, login, reboot, network reachability и изменения pmset.

### Ручной smoke checklist на реальном оборудовании

Реализация репозитория не выполняет эти действия автоматически. Владелец проходит их позже строго по runbook:

1. локальный SSH;
2. Windows OpenSSH/Termius в LAN;
3. Tailscale ping и обычный SSH через Tailscale;
4. AnyDesk view/control;
5. lock;
6. logout;
7. normal reboot;
8. model-specific power recovery;
9. headless;
10. development tools и их version checks.

Первый reboot и power test выполняются только при физическом доступе, без активных обновлений и несохранённой работы.

## Риски и откат

### Риски

- PR #2 ещё открыт; параллельные изменения AGENTS.md и safety rules могут конфликтовать.
- UI и названия настроек macOS, Tailscale и AnyDesk меняются между версиями.
- TCC, Remote Login, AnyDesk и удалённая доступность нельзя полностью доказать локальным скриптом.
- Стандартный Tailscale GUI не гарантирует pre-login доступ после холодной загрузки.
- FileVault и autonomous recovery находятся в прямом компромиссе; неверное обещание создаст риск потери удалённого доступа.
- Неправильная настройка SSH, tailnet policy или AnyDesk ACL может расширить поверхность доступа.
- Физический power-loss test может повредить несохранённые данные.
- macos-latest CI доказывает синтаксис и контракты, но не поведение конкретного Mac mini.

### Откат репозитория

- Работа идёт только в feature-ветке и stacked PR; main напрямую не меняется.
- Mac subtree, отдельный workflow и router changes можно откатить отдельными focused commits.
- Windows scripts, Windows state schema и порядок фаз не изменяются.
- При провале проверки PR не объединяется.
- PR #2 остаётся самостоятельным prerequisite и не переписывается.

### Откат настроек реальной машины

Каждый изменяющий шаг будущего runbook сначала сохраняет текущее логическое состояние и содержит обратное ручное действие:

- выключить Remote Login или сузить allowed users;
- удалить SSH public key;
- отключить/выйти из Tailscale и revoke device;
- отключить Unattended Access, 2FA token или ACL entry в AnyDesk;
- вернуть прежние Energy settings;
- отключить automatic login;
- вернуть FileVault только отдельной официальной процедурой.

Runbook не обещает мгновенный откат FileVault и не запускает его изменение автоматически.

## Критерий готовности

Gate 3 считается реализованным, когда все файлы из плана созданы, локальные проверки зелёные, Windows-путь не изменил поведение, а недоказуемые аппаратные сценарии честно помечены MANUAL.

Gate 4 считается завершённым после независимого review и тестового прохода, исправления замечаний, зелёных Windows/macOS CI и открытия pull request. Merge и фактическая настройка Mac mini остаются отдельными действиями.

---

# Архив: план реализации Vibe Runbooks Windows

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
