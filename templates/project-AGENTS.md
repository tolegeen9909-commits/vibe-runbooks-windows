# Project instructions

- До согласия работай только внутри текущей папки проекта. Заранее названный Windows-скрипт может затронуть только объявленные пути после отдельного явного «да».
- Не запускай команды с правами администратора. Глобальную установку или изменение Windows разрешай только после показа точной команды и отдельного явного «да».
- Не отправляй в сеть локальные файлы вне отдельно согласованного `git push`. Никогда не отправляй `.env`, ключи, пароли, токены или данные клиентов.
- Перед удалением, любым PowerShell-скриптом, `git push`, установкой зависимостей, сетевым или иным внешним запросом покажи точную команду, кратко объясни её последствия и дождись явного «да». Согласие действует только на показанную команду.
- После явного «да» можно автоматически выполнить один показанный неадминистративный Windows-скрипт. Команду с UAC или правами администратора Codex не запускает; её вручную выполняет пользователь.
- Объясняй действия простым русским языком.
- Один prompt — одна небольшая задача.
- Перед изменением покажи краткий план; после изменения покажи diff и выполни подходящую проверку.
- Не удаляй пользовательские файлы и не выполняй destructive Git-команды без явного подтверждения.
- Не коммить `.env`, токены, пароли, private keys или recovery codes.
- Сохраняй безопасные шаблоны `.env.example`, `.env.sample`, `.env.template`.
- Репозиторий создавай private по умолчанию.
- Перед push проверь `git status`, staged diff и отсутствие секретов.

## Open Design MCP For Design Work

- For any design work, use the `open-design` MCP server by default instead of designing directly in Codex.
- This includes UI/UX concepts, visual direction, layouts, landing pages, app screens, dashboards, decks, prototypes, design-system exploration, and image/video design artifacts.
- Prefer Open Design artifacts and previews as the source of truth, then implement the approved design.
- Skip Open Design for tiny CSS fixes, obvious layout bugs, copy edits, or implementation-only tasks where the design is already decided.
- If the `open-design` MCP server is unavailable, report that it is not connected before falling back to manual design work.
