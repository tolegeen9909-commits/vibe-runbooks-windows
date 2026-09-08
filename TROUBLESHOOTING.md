# Помощь при ошибках

Сначала повтори короткую проверку из нужного раздела. Делай одно исправление и снова запускай ту же проверку.

## `winget` не найден

Проверь:

```powershell
winget --version
```

Открой Microsoft Store, найди **App Installer** от Microsoft и обнови или установи его. Затем перезайди в Windows или открой новый Terminal. На корпоративном компьютере Store и `winget` может блокировать администратор.

## PowerShell запрещает запуск скрипта

Проверь политику:

```powershell
Get-ExecutionPolicy -List
```

Для одного запуска используй процессный режим, который исчезнет после закрытия окна:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Затем повтори текущий `*.ps1`. Не ставь глобально `Unrestricted` и не отключай защиту Windows.

Если файлы были скачаны ZIP-архивом, можно снять интернет-метку только с этого репозитория:

```powershell
Get-ChildItem -Path C:\Projects\vibe-runbooks-windows -Recurse -File | Unblock-File
```

## Команда установлена, но не найдена

Закрой все окна Windows Terminal, открой новое и повтори команду версии. Проверь:

```powershell
Get-Command git,node,npm.cmd,gh,claude,codex,flutter,netlify -ErrorAction SilentlyContinue
```

Не добавляй случайные каталоги в PATH. Повтори установочный скрипт: он не должен создавать дубли.

## `npm.ps1 cannot be loaded`

Используй `npm.cmd`, например:

```powershell
npm.cmd --version
```

Скрипты этого комплекта уже используют `npm.cmd`.

## Git Bash или global hook не работает

Проверь Git и путь hooks:

```powershell
git --version
git config --global --get core.hooksPath
```

Git for Windows выполняет `pre-commit` через свой Bash. Если другой инструмент уже настроил `core.hooksPath`, `setup-secret-guard.ps1` остановится и ничего не перезапишет без `-Force`. Сначала изучи старый hook и его backup.

## Gitleaks не найден или не блокирует тест

Проверь:

```powershell
gitleaks version
git config --global --get core.hooksPath
```

Открой новый Terminal и повтори `.\03-git-github\setup-secret-guard.ps1`. Не вставляй настоящий секрет для проверки — используй только тестовую строку из автоматического теста.

## GitHub login не завершён

Проверь:

```powershell
gh auth status
```

Если входа нет:

```powershell
gh auth login --web --git-protocol https
```

Заверши вход в системном браузере. Пароль и 2FA-код не отправляй в чат.

## Claude Code или Codex CLI просит войти

Запускай инструменты по одному:

```powershell
claude
codex
```

Подтверди browser login только для официального сервиса. После успешного входа закрой сеанс командой самого инструмента и снова запусти `.\04-ai-helpers\verify.ps1`.

Для Windows-приложения Codex сверяйся с [официальной документацией OpenAI](https://learn.chatgpt.com/docs/windows/windows-app). Этот комплект использует Windows native + PowerShell; переключать агент в WSL не нужно.

## Netlify login не завершён

Проверь:

```powershell
netlify status
```

Если входа нет, выполни `netlify login`, заверши вход в браузере и повтори проверку. Production deploy не запускай, пока preview-ссылка не открыта и не проверена.

## Android licenses не принимаются

В Android Studio открой **More Actions → SDK Manager → SDK Tools**, установи **Android SDK Command-line Tools (latest)** и **Android SDK Platform-Tools**. Затем:

```powershell
flutter doctor --android-licenses
flutter doctor -v
```

Принимай лицензии клавишей `y`, читая текст. Если используется корпоративный proxy, попроси администратора разрешить официальные Android/Google endpoints.

## Виртуализация выключена

Проверь **Диспетчер задач → Производительность → ЦП → Виртуализация**. Если указано «Отключено», её нужно включить в BIOS/UEFI. Скрипты намеренно этого не делают. Найди инструкцию производителя конкретной модели или обратись к специалисту.

## Android Emulator не стартует

1. Закрой Emulator и Android Studio.
2. Убедись, что виртуализация включена.
3. В **SDK Manager → SDK Tools** проверь Android Emulator и hypervisor driver.
4. В **Device Manager** выбери устройство с x86_64 system image и сделай **Cold Boot Now**.
5. Выполни `flutter devices`, затем повтори `flutter run`.

Если памяти мало, закрой тяжёлые программы или используй физический Android-телефон с USB debugging. Не включай неизвестные драйверы со сторонних сайтов.

## Слишком длинный путь или кириллица в SDK

Flutter SDK держи в `C:\src\flutter`, а учебные проекты — в `C:\Projects\vibecoding`. Эти короткие ASCII-пути уменьшают число проблем с Android tools. Сам профиль Windows с русским именем поддерживается, но SDK лучше не переносить внутрь глубоко вложенных папок.

## Defender поместил файл в карантин

Не отключай Defender. Открой **Безопасность Windows → Защита от вирусов и угроз → Журнал защиты**, проверь точное имя и источник файла. Повторно скачивай только с официального сайта или через официальный `winget` package ID. Если это корпоративная политика, обратись к администратору.

## Скрипт оборвался посередине

1. Не удаляй созданные папки наугад.
2. Открой новый PowerShell в корне репозитория.
3. Запусти `verify.ps1` текущей фазы.
4. Исправь первый обязательный пункт.
5. Повтори тот же установочный скрипт — основные шаги идемпотентны.

Прогресс хранится локально в `state\progress.json`. Если файл повреждён, сохрани его копию и восстанови из `state\progress-template.json`; не вставляй в state токены и пароли.

## Нужен iPhone/iOS Simulator

Это не ошибка Windows-настройки. Xcode и iOS Simulator работают только на macOS. На Windows проходи Android-трек; для iOS позже понадобится Mac.
