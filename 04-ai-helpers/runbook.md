# 04 · Node, Claude Code и Codex CLI

## Зачем

Node.js нужен веб-инструментам. Claude Code и Codex CLI — два помощника, которые умеют читать проект, менять файлы и запускать проверки.

## Шаги

```powershell
powershell -ExecutionPolicy Bypass -File .\04-ai-helpers\install-node.ps1
```

Закрой и заново открой Windows Terminal:

```powershell
powershell -ExecutionPolicy Bypass -File .\04-ai-helpers\install-claude.ps1
powershell -ExecutionPolicy Bypass -File .\04-ai-helpers\install-codex.ps1
```

Перед входом гид ждёт «да». Затем человек запускает по одной команде:

```powershell
claude
codex
```

Claude открывает свой официальный вход, Codex — вход через ChatGPT. Пароли и коды остаются в браузере.

Проверка:

```powershell
powershell -ExecutionPolicy Bypass -File .\04-ai-helpers\verify.ps1
```

После успеха гид предлагает мобильный трек, веб-трек, оба или пропуск.
