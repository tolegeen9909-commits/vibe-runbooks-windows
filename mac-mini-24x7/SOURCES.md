# Официальные источники Mac mini 24/7

Дата последней проверки ссылок и ключевых ограничений: **2026-10-03**.

Используются только страницы производителей и официальная документация. Перед изменяющим действием гид открывает нужный источник заново: интерфейсы и установщики могут измениться после даты проверки. Ссылка сама по себе не является разрешением на сетевой запрос, загрузку или установку.

## Apple

| Тема | Официальный источник | Что подтверждает |
|---|---|---|
| Обновление macOS | [Update macOS on Mac](https://support.apple.com/en-us/108382) | Software Update показывает совместимые обновления; установка может запросить пароль администратора и несколько раз перезапустить Mac |
| Remote Login | [Allow a remote computer to access your Mac](https://support.apple.com/guide/mac-help/allow-a-remote-computer-to-access-your-mac-mchlp1066/mac) | Путь `System Settings → General → Sharing → Remote Login`, SSH/SFTP и список разрешённых пользователей |
| Energy на desktop Mac | [Change Energy settings on a Mac desktop computer](https://support.apple.com/guide/mac-help/change-energy-settings-mchlp1168/mac) | Prevent automatic sleeping, Wake for network access и поддерживаемый запуск после восстановления питания; набор опций зависит от модели |
| Сон и пробуждение | [Set sleep and wake settings for your Mac](https://support.apple.com/guide/mac-help/set-sleep-and-wake-settings-mchle41a6ccd/mac) | Разница между сном дисплея, системным сном и network wake |
| FileVault | [Volume encryption with FileVault in macOS](https://support.apple.com/guide/security/volume-encryption-with-filevault-sec4c6dc1b6e/web) | FileVault требует credentials при boot и защищает данные at rest |
| Automatic login | [How to log in automatically to a Mac user account](https://support.apple.com/en-us/102316) | Automatic login снижает защиту и недоступен при включённом FileVault |
| Запуск при подключении питания | [Start up your Mac mini](https://support.apple.com/en-us/125517) | Поведение актуальной модели Mac mini при подключении к питанию; перед тестом нужно сверить точную модель |

## Tailscale

| Тема | Официальный источник | Что подтверждает |
|---|---|---|
| Варианты macOS | [Three ways to run Tailscale on macOS](https://tailscale.com/docs/concepts/macos-variants) | Standalone рекомендован для новичка; GUI-варианты не работают до login; `tailscaled` до login предназначен для опытных администраторов |
| Загрузка для Mac | [Download Tailscale for macOS](https://tailscale.com/download/mac) | Официальная точка загрузки клиента |
| Установка Windows | [Install Tailscale on Windows](https://tailscale.com/docs/install/windows) | Официальная установка Windows-клиента |
| Загрузка Windows | [Download Tailscale for Windows](https://tailscale.com/download/windows) | Официальная точка загрузки Windows-клиента |
| Подключение устройств | [Connect to devices](https://tailscale.com/docs/how-to/connect-to-devices) | Tailnet address и MagicDNS для соединений между устройствами |
| Работа без login | [Run unattended](https://tailscale.com/docs/how-to/run-unattended) | Платформенные ограничения unattended mode; Windows и macOS нельзя считать одинаковыми |
| Access controls | [Access control](https://tailscale.com/docs/features/access-control) | Deny-by-default, Grants/ACL и область действия policy |
| Grants | [Grants](https://tailscale.com/docs/features/access-control/grants) | Ограничение доступа по source, destination, protocol и port |
| Grants syntax | [Grants syntax reference](https://tailscale.com/docs/reference/syntax/grants) | Роли `owner` и `admin` являются разными `autogroup`; также описан синтаксис `tcp:22` |
| Tags | [Group devices with tags](https://tailscale.com/docs/features/tags) | Tags предназначены для service/server devices и заменяют user-based identity устройства |
| Key expiry | [Key expiry](https://tailscale.com/docs/features/access-control/key-expiry) | Для постоянно доступного доверенного устройства expiry можно отключить осознанно; при компрометации node нужно revoke |

## AnyDesk

| Тема | Официальный источник | Что подтверждает |
|---|---|---|
| Загрузка macOS | [AnyDesk for macOS](https://anydesk.com/en/downloads/mac-os) | Официальный installer для Mac |
| Загрузка Windows | [AnyDesk for Windows](https://anydesk.com/en/downloads/windows) | Официальный Windows-клиент |
| Разрешения macOS | [Grant security permissions on macOS](https://support.anydesk.com/docs/security-permissions-on-macos) | Screen Recording нужен для просмотра, Accessibility — для ввода, Full Disk Access — для доступа к файлам |
| Unattended Access | [Set up Unattended Access](https://support.anydesk.com/docs/unattended-access) | Установленная версия полезна после restart/sign-out; existing saved-login tokens нужно отзывать отдельно, а 2FA может отдельно применяться к saved login information и short-term/remote-restart passwords |
| Security и ACL | [Security tips and offboarding](https://support.anydesk.com/security-tips) | 2FA, Access Control List и отзыв доступа |

## SSH и Windows-клиент

| Тема | Официальный источник | Что подтверждает |
|---|---|---|
| Windows OpenSSH | [SSH in Windows Terminal](https://learn.microsoft.com/en-us/windows/terminal/tutorials/ssh) | Windows 11 включает OpenSSH client и поддерживает команду `ssh user@host` |
| Termius docs | [Termius Documentation](https://termius.com/documentation/) | Точка входа в актуальную документацию продукта; названия полей перепроверяются перед настройкой |
| Termius for Windows | [Download Termius for Windows](https://termius.com/download/windows) | Официальная точка загрузки Windows-клиента |

Если интерфейс Termius расходится с runbook, не угадывай и не используй сторонний tutorial: остановись и заново проверь официальную документацию.

## Инструменты фазы 09

| Компонент | Официальный источник |
|---|---|
| Homebrew | [Installation](https://docs.brew.sh/Installation) и [Support Tiers](https://docs.brew.sh/Support-Tiers) |
| Git | [Git for macOS](https://git-scm.com/downloads/mac) |
| GitHub CLI | [Install GitHub CLI](https://github.com/cli/cli/blob/trunk/docs/install_macos.md) |
| Node.js | [Download Node.js](https://nodejs.org/en/download) |
| Python | [Python releases for macOS](https://www.python.org/downloads/macos/) |
| OpenAI Codex CLI | [Codex CLI — official OpenAI documentation](https://learn.chatgpt.com/docs/codex/cli) |
| Claude Code | [Claude Code setup](https://docs.anthropic.com/en/docs/claude-code/setup) |

Официальная страница Codex может показывать короткий download-and-execute pipeline. Этот маршрут не исполняет сетевой ответ напрямую: загрузка, просмотр и запуск всегда разделяются и получают отдельные approval-gates.

Новый Homebrew setup в текущем MVP ограничен официально поддерживаемым путём Apple Silicon с macOS 15+. Для Intel или более старой macOS фаза 09 останавливается до отдельного architecture-specific review; remote-access фазы 00–08 остаются самостоятельными.
