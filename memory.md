# Project memory

## 2026-09-09 — Windows runbooks MVP

### Session goal

Создать и опубликовать отдельный набор пошаговых runbook-инструкций для нового Windows 11: базовая среда, Git/GitHub, Node.js, Codex, Claude Code, Flutter/Android и Web/Netlify.

### Changes made

- Добавлены `AGENTS.md`, `FOR-CODEX.md`, `RITUALS.md`, `INDEX.md`, пофазные `runbook.md` и `TROUBLESHOOTING.md` на русском языке.
- Реализованы идемпотентные PowerShell-скрипты фаз 00–07 и необязательного backend appendix.
- Добавлено локальное возобновление через `state/progress.json`, маркеры фаз и сохранение Netlify URL.
- Добавлены Gitleaks fail-closed pre-commit hook и Windows command guard с защитой от shell-wrapper, substitution, destructive Git/disk/delete и secret-file команд.
- Flutter archive загружается в `.partial`, проверяется по SHA-256 и только затем атомарно перемещается.
- Добавлен Windows GitHub Actions CI: PowerShell 7, Windows PowerShell 5.1, PSScriptAnalyzer, Pester, Gitleaks и Python self-test.
- Репозиторий создан private, а после приёмки по явному решению владельца переведён в public.

### Decisions

- Основная среда: Windows 11 x64, Windows-native Codex и PowerShell; WSL не входит в MVP.
- Гид даёт только один шаг за раз и останавливается перед UAC, browser login, push и production deploy.
- Базовый, Flutter, Web и combined треки выбираются явно; финальный checkpoint требует все применимые проверки.
- Учебные проекты по-прежнему создаются private по умолчанию, даже если сам runbook-репозиторий public.
- Сам runbook-репозиторий не деплоится на Netlify: он распространяется через GitHub.

### Lessons learned

- На Windows Store `python.exe` может быть только App Execution Alias; нужна проверка реального Python runtime.
- Защита команд должна учитывать `cmd /c`, `powershell -Command`, script blocks, `$()` и Bash backticks, а не только прямую команду.
- Gitleaks нужно тестировать через реальный `git commit`, чтобы подтвердить весь hook path.
- Для Windows PowerShell 5.1 важны UTF-8 BOM, CRLF и отдельный runtime smoke test.

### Verification

- `python3 scripts/command-guard.py --selftest` → `pass=70 fail=0`.
- `python3 -m json.tool state/progress-template.json` → success.
- `git diff --check` → success.
- Локальный поиск типичных token/secret patterns → совпадений нет.
- Независимое Gate 4 review → PASS, незакрытых P1/P2 нет.
- GitHub Actions `PowerShell and safety tests` для PR #1 → pass (`2m0s`) на branch HEAD `f7cb114`.

### Remaining work and risks

- Нужен ручной end-to-end smoke test на чистой Windows 11: UAC, Store/`winget`, browser login, PATH refresh, Android Studio/Emulator, Flutter download/build и Netlify preview/production.
- Корпоративные политики могут блокировать Store, `winget`, browser login или виртуализацию.
- Package IDs и интерактивные installer flows могут меняться; перед крупным релизом нужен повторный smoke test.

### Links

- Repository: https://github.com/tolegeen9909-commits/vibe-runbooks-windows
- Pull request: https://github.com/tolegeen9909-commits/vibe-runbooks-windows/pull/1
- Deploy: not applicable; this repository is distributed through GitHub.
