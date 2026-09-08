# Project instructions

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
