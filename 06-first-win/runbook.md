# 06 · Первая мобильная победа

## Цель

Увидеть настоящее Flutter-приложение на Android Emulator, сделать одну понятную правку и сохранить проект в приватном GitHub-репозитории.

## Шаги

1. Запусти Android Emulator через Android Studio → Tools → Device Manager.
2. Создай и запусти приложение:

```powershell
powershell -ExecutionPolicy Bypass -File .\06-first-win\create-and-run.ps1
```

3. Попроси Codex сделать только одну правку:

```text
В проекте C:\Projects\vibecoding\vibecoding_first_app измени только видимый заголовок стартового экрана на «Моё первое приложение». Не меняй другие файлы. Покажи diff.
```

4. В терминале с `flutter run` нажми `r` и проверь новый текст. `q` завершает запуск.
5. Сначала создай локальный commit:

```powershell
powershell -ExecutionPolicy Bypass -File .\06-first-win\first-edit-commit.ps1
```

6. Скрипт остановится перед внешним push. После явного «да», если commit уже создан, выполни:

```powershell
Set-Location C:\Projects\vibecoding\vibecoding_first_app
gh repo create vibecoding_first_app --private --source . --remote origin --push
```

Если `origin` уже существует:

```powershell
git push -u origin HEAD
```

7. Проверка:

```powershell
powershell -ExecutionPolicy Bypass -File .\06-first-win\verify.ps1
```
