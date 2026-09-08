# 01 · Настройка Windows

## Зачем

Проводник должен показывать настоящие имена файлов, а проекты должны лежать в коротком понятном пути. Настройки безопасности остаются под контролем человека.

## Шаги

1. Установи все обновления Windows и перезагрузи компьютер.
2. Выполни:

```powershell
powershell -ExecutionPolicy Bypass -File .\01-windows-setup\setup-windows-defaults.ps1
```

3. Вручную проверь шифрование устройства/BitLocker и пароль после сна. Recovery key в чат не отправляй.
4. По желанию после проверки `winget` установи VS Code и PowerShell 7:

```powershell
powershell -ExecutionPolicy Bypass -File .\01-windows-setup\install-extra-apps.ps1
```

5. Проверка:

```powershell
powershell -ExecutionPolicy Bypass -File .\01-windows-setup\verify.ps1
```

После успеха переходи к `02-foundation/runbook.md`.
