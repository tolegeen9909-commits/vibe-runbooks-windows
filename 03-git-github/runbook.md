# 03 · Git и GitHub

## Зачем

Git сохраняет версии проекта, GitHub хранит удалённую копию, Gitleaks не пускает секреты в коммиты, а command guard останавливает известные разрушительные команды Claude Code.

## Шаги

Выполняй по одному:

```powershell
powershell -ExecutionPolicy Bypass -File .\03-git-github\install-git.ps1
```

Закрой и заново открой Windows Terminal, затем:

```powershell
powershell -ExecutionPolicy Bypass -File .\03-git-github\install-gh.ps1
```

Если аккаунта GitHub нет, сначала создай его на `https://github.com/signup`. Перед браузерным входом гид ждёт «да»:

```powershell
gh auth login --web --git-protocol https
```

Пароль и 2FA-код вводятся только в браузере.

Настрой подпись:

```powershell
powershell -ExecutionPolicy Bypass -File .\03-git-github\setup-git-identity.ps1
```

Подключи защиты:

```powershell
powershell -ExecutionPolicy Bypass -File .\03-git-github\setup-secret-guard.ps1
powershell -ExecutionPolicy Bypass -File .\03-git-github\setup-command-guard.ps1
```

Защита Gitleaks сама создаёт временный локальный репозиторий и проверяет, что тестовый секрет блокируется, а обычный файл проходит. Временная папка удаляется после проверки.

Если найден чужой Git hook, скрипт ничего не перезапишет. Сначала попроси Codex объяснить конфликт; `-Force` допустим только после осознанного решения и создаёт backup.

Проверка:

```powershell
powershell -ExecutionPolicy Bypass -File .\03-git-github\verify.ps1
```

После успеха переходи к `04-ai-helpers/runbook.md`.
