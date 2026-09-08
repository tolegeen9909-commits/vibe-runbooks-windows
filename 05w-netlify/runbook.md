# 05w · Netlify — веб-трек

## Зачем

Netlify публикует папку сайта и даёт ссылку. Веб-трек не требует Flutter и Android Studio.

## Шаги

```powershell
powershell -ExecutionPolicy Bypass -File .\05w-netlify\install-netlify.ps1
```

Перед входом гид ждёт «да»:

```powershell
netlify login
```

Войди или зарегистрируйся в системном браузере и нажми Authorize. Пароль и коды в чат не отправляй.

Проверка:

```powershell
powershell -ExecutionPolicy Bypass -File .\05w-netlify\verify.ps1
```

После успеха переходи к `06w-first-site/runbook.md`.
