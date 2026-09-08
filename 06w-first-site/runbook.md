# 06w · Первый сайт и живая ссылка

## Ритм веб-разработки

```text
правка → commit → push → preview → проверка → production
```

## Шаги

Создай сайт:

```powershell
powershell -ExecutionPolicy Bypass -File .\06w-first-site\create-site.ps1
```

Открой `C:\Projects\vibecoding\vibecoding_first_site\index.html` в браузере и проверь содержимое.

Создай локальный commit без внешних действий:

```powershell
powershell -ExecutionPolicy Bypass -File .\06w-first-site\publish-site.ps1
```

После явного согласия отправить private-репозиторий в GitHub:

```powershell
powershell -ExecutionPolicy Bypass -File .\06w-first-site\publish-site.ps1 -Push
```

После отдельного согласия сделай preview:

```powershell
powershell -ExecutionPolicy Bypass -File .\06w-first-site\publish-site.ps1 -Preview
```

При первом запуске Netlify попросит создать или связать сайт, выбрать team и уникальное имя. Это ожидаемая ручная стоп-точка; связь хранится в `.netlify\state.json`, а папка `.netlify` уже исключена из Git.

Открой Draft URL. Только после проверки и нового явного «да»:

```powershell
powershell -ExecutionPolicy Bypass -File .\06w-first-site\publish-site.ps1 -Production
```

Проверка:

```powershell
powershell -ExecutionPolicy Bypass -File .\06w-first-site\verify.ps1
```
