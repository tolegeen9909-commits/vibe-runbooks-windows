# Vibe Runbooks: Windows и Mac mini 24/7

Два независимых пошаговых маршрута для новичка:

- Windows 11 — настройка среды для вайбкодинга через PowerShell;
- Mac mini 24/7 — безопасная настройка постоянно доступной удалённой машины.

Codex сначала спрашивает, какую целевую машину ты настраиваешь, затем ведёт только по выбранному маршруту: одно действие, одна проверка и одна точка подтверждения за раз. Команды двух ОС не смешиваются.

## С чего начать

- Windows 11: открой корневой AGENTS.md и скажи «Настраиваем Windows».
- Mac mini 24/7: открой корневой AGENTS.md и скажи «Настраиваем Mac mini 24/7». Полная карта находится в mac-mini-24x7/INDEX.md.

Клиентский компьютер может работать на Windows, пока целевой машиной остаётся Mac mini. Маршрут выбирается по цели, а не по компьютеру, с которого выполняется подключение.

## Что получится в Windows-маршруте

Базовый маршрут настраивает:

- Windows Terminal и PowerShell;
- Git, GitHub CLI и безопасный вход через браузер;
- защиту от случайного коммита секретов;
- Node.js LTS, Claude Code и Codex CLI.

Затем можно пройти один или оба трека:

- **Flutter/Android:** Flutter SDK, Android Studio, Android Emulator, первое приложение и приватный GitHub-репозиторий;
- **Web/Netlify:** Netlify CLI, первый сайт, приватный GitHub-репозиторий, preview и подтверждаемый production deploy.

## Что получится в Mac mini-маршруте

Маршрут проверяет и настраивает по отдельным подтверждаемым фазам:

- обновления macOS, питание и отсутствие системного сна;
- Apple Remote Login и обычный SSH;
- Termius с Windows;
- AnyDesk как резервный GUI-доступ;
- Tailscale на обеих машинах и SSH внутри tailnet без публичного порта 22;
- восстановление после logout, reboot и питания;
- headless-режим;
- среду разработки только после стабильного удалённого доступа.

Безопасный вариант сохраняет FileVault и честно предупреждает об ограничении холодной загрузки. Полностью автономный вариант требует отдельного осознанного решения и реального теста на конкретном Mac.

## Что понадобится для Windows

- компьютер Intel/AMD с 64-битной Windows 11;
- учётная запись администратора Windows и пароль/PIN для UAC;
- стабильный интернет;
- минимум 35 ГБ свободного места для базового и мобильного трека;
- 16 ГБ RAM рекомендуется для Android Emulator, 8 ГБ допустимо для базового и веб-трека;
- аккаунты ChatGPT и GitHub;
- аккаунт Netlify только для веб-трека;
- аппаратная виртуализация только для Android Emulator.

Apple ID не нужен. Пароли, 2FA-коды, recovery keys, токены и API-ключи вводятся только в официальном приложении или системном браузере — никогда не отправляй их в чат.

## Новый Windows → Codex → первый шаг

### 1. Обнови Windows

Открой **Параметры → Центр обновления Windows**, установи обычные обновления и перезагрузи компьютер. Не отключай Defender, Firewall или UAC.

### 2. Установи ChatGPT с Codex

Открой обычный PowerShell и выполни:

```powershell
winget install --id 9PLM9XGG6VKS --source msstore
```

Либо скачай приложение по ссылке из [официальной инструкции OpenAI для Windows](https://learn.chatgpt.com/docs/windows/windows-app). Открой ChatGPT и войди в свой аккаунт. Для этого комплекта оставь **Windows native**, терминал **PowerShell** и режим **Ask for approval**.

Если команда `winget` не найдена, сначала установи или обнови **App Installer** из Microsoft Store. Подробности есть в [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

### 3. Установи Git для загрузки комплекта

В PowerShell выполни:

```powershell
winget install --id Git.Git --exact --source winget
```

Закрой PowerShell, открой новое окно и проверь:

```powershell
git --version
```

### 4. Склонируй комплект

Репозиторий публичный: его можно скачать без GitHub-аккаунта. Выполни:

```powershell
New-Item -ItemType Directory -Path C:\Projects -Force
Set-Location C:\Projects
git clone https://github.com/tolegeen9909-commits/vibe-runbooks-windows.git
Set-Location C:\Projects\vibe-runbooks-windows
```

Для этого публичного клонирования вход в GitHub не нужен. Пароли и токены никогда не вставляй в терминал или чат.

### 5. Открой папку в Codex

В приложении ChatGPT:

1. Открой Codex.
2. Нажми **Add project** или `Ctrl+O`.
3. Выбери `C:\Projects\vibe-runbooks-windows`.
4. Разреши доступ только к этой папке.

### 6. Отправь одно сообщение

```text
Прочитай AGENTS.md в корне проекта и делай ровно то, что там написано. Веди меня как гида с самого начала, по одному шагу, начиная с проверки нового Windows-компьютера.
```

После этого не запускай все скрипты самостоятельно. Гид будет объяснять один шаг, ждать ручные подтверждения и проверять результат.

### Как включается безопасный режим

Корневой `AGENTS.md` — это общий safety-layer и маршрутизатор. После выбора Windows он передаёт управление существующему PowerShell-маршруту.

Перед любым `*.ps1`, установкой, сетевым запросом, удалением или `git push` гид обязан показать точную команду и дождаться отдельного «да». После него Codex может автоматически запустить только один показанный неадминистративный Windows-скрипт. Команды с UAC или правами администратора гид сам не запускает.

Когда маршрут создаст первый учебный проект, `06-first-win/first-edit-commit.ps1` скопирует `templates/project-AGENTS.md` в его корень. Так те же правила будут действовать и после перехода в новый проект.

## Как устроен репозиторий

- [AGENTS.md](AGENTS.md) — точка входа и постоянные правила для Codex;
- [INDEX.md](INDEX.md) — полный маршрут и команды;
- [mac-mini-24x7/INDEX.md](mac-mini-24x7/INDEX.md) — отдельная карта Mac mini 24/7;
- `*/runbook.md` — понятное объяснение каждой фазы;
- `*.ps1` — Windows-скрипты;
- `mac-mini-24x7/**/*.sh` — read-only проверки Mac и локальные checkpoint helpers;
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — помощь при типичных ошибках;
- [mac-mini-24x7/TROUBLESHOOTING.md](mac-mini-24x7/TROUBLESHOOTING.md) — диагностика Mac-маршрута;
- `state/progress.json` — локальная точка продолжения, не попадает в Git;
- `scripts/command-guard.py` — защита Claude Code от опасных команд;
- `.github/workflows/ci.yml` — автоматическая проверка PowerShell на Windows;
- `.github/workflows/macos.yml` — статические и read-only проверки Mac-маршрута.

## Важные ограничения

- Flutter-трек на Windows собирает и запускает Android-приложения. Для сборки iOS нужен Mac с Xcode.
- Production deploy Netlify выполняется только после явного подтверждения. Preview можно сделать раньше.
- Скрипты не меняют BIOS/UEFI и не включают BitLocker автоматически.
- Корпоративные политики могут запретить Store, `winget`, виртуализацию или входы; в таком случае обратись к администратору.
- Mac-фазы 00–08 допускают совместимый Intel или Apple Silicon Mac mini, но новая Homebrew-backed фаза 09 в этом MVP ограничена Apple Silicon и macOS 15+.

Спецификации: [Windows MVP](docs/specs/2026-09-08-vibe-runbooks-windows.md) и [Mac mini 24/7](docs/specs/2026-10-03-mac-mini-24x7-runbook.md).
