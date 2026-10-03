# 04 · AnyDesk как резервный GUI-канал

## Результат фазы

Установленный AnyDesk запускается на Mac, принимает Unattended Access с 2FA и ограничением доступа, показывает экран и позволяет управлять мышью/клавиатурой с Windows.

AnyDesk — резерв. Он не заменяет SSH поверх Tailscale.

Официальные источники:

- [AnyDesk for macOS](https://anydesk.com/en/downloads/mac-os);
- [macOS security permissions](https://support.anydesk.com/docs/security-permissions-on-macos);
- [Unattended Access](https://support.anydesk.com/docs/unattended-access);
- [Security tips and ACL](https://support.anydesk.com/security-tips).

## Шаг 1 · Read-only проверка

На Mac mini:

```bash
bash ./mac-mini-24x7/04-anydesk/verify.sh
```

Скрипт проверяет наличие установленного приложения и доступные локальные признаки запуска. Если приложение установлено, но текущий процесс не доказан, результат останется `MANUAL`, даже при старых checkpoint-markers. Скрипт не читает и не выводит AnyDesk ID/Alias, password, ACL или 2FA secret. TCC и remote control могут остаться `MANUAL`.

## Шаг 2 · Установить AnyDesk на Mac, только если отсутствует

Выполняй как отдельные действия:

1. отдельное `да` на открытие [официальной страницы macOS](https://anydesk.com/en/downloads/mac-os);
2. отдельное `да` на загрузку installer;
3. проверка официального домена и подписи приложения;
4. отдельное `да` на запуск installer и установку AnyDesk в Applications.

### Последствие установки

Установленная версия может запускать background components, необходимые после sign-out/restart. macOS может запросить admin password. Пользователь вводит его локально; гид не запускает installer скрытно.

Откат — отключить Unattended Access, отозвать tokens/ACL, затем удалить AnyDesk по официальной процедуре. Не удаляй приложение во время этой фазы.

## Шаг 3 · Установить Windows-клиент, только если отсутствует

Сначала проверь `Settings → Apps → Installed apps` на Windows.

Если AnyDesk отсутствует, отдельно согласуй открытие [официальной Windows-страницы](https://anydesk.com/en/downloads/windows), отдельно download и отдельно запуск подписанного installer. Не передавай AnyDesk ID гиду и не публикуй его в screenshot.

## Шаг 4 · Разрешить просмотр экрана

### Шлюз согласия — Screen Recording

> **Устройство:** Mac mini.
> **Точное действие:** из AnyDesk открыть System Permission Status, перейти в `System Settings → Privacy & Security → Screen & System Audio Recording` и включить AnyDesk.
> **Последствие:** удалённая AnyDesk-session сможет видеть содержимое экрана.
> **Риск и откат:** приложение получает чувствительное разрешение; вернуть Off можно в том же разделе. После изменения AnyDesk может потребовать restart.
> **Проверка:** AnyDesk больше не показывает missing Screen Recording, а remote test отображает экран.
> Выполнить именно это действие? Ответьте `да`.

Если macOS просит Quit & Reopen, это отдельное state-changing действие с отдельным `да`.

## Шаг 5 · Разрешить управление

### Шлюз согласия — Accessibility

> **Устройство:** Mac mini.
> **Точное действие:** из AnyDesk открыть System Permission Status, перейти в `System Settings → Privacy & Security → Accessibility` и включить AnyDesk.
> **Последствие:** удалённая session сможет управлять мышью и клавиатурой.
> **Риск и откат:** это сильное разрешение; вернуть Off можно в том же разделе.
> **Проверка:** remote test может безопасно переместить указатель и набрать текст в пустом локальном документе.
> Выполнить именно это действие? Ответьте `да`.

**Full Disk Access оставь выключенным.** Он нужен только для реальной задачи file transfer и выдаётся позже отдельным решением. Просмотр и управление сами по себе его не требуют.

## Шаг 6 · Включить Unattended Access

Создай уникальный длинный password в менеджере паролей. Не показывай его гиду, не сохраняй в проект и не включай в screenshot.

### Шлюз согласия — unattended password

> **Устройство:** Mac mini.
> **Точное действие:** `AnyDesk → Settings → Access → Unattended Access → Set password`, затем локально ввести сгенерированный password и Apply.
> **Последствие:** удалённый клиент с AnyDesk ID и этим credential сможет запрашивать session без человека у Mac.
> **Риск и откат:** компрометация credential даёт удалённый доступ; отключить Unattended Access или сменить password можно в том же разделе, что также отзывает сохранённые tokens.
> **Проверка:** настройка показывает Unattended Access enabled, но password не выводится.
> Выполнить именно это действие? Ответьте `да`.

Не включай автоматическое сохранение login token до проверки 2FA и ACL.

Не записывай `anydesk-unattended` сразу после создания password: сначала нужен connection test с Windows без локального принятия session.

## Шаг 7 · Включить 2FA

### Шлюз согласия — второй фактор

> **Устройство:** Mac mini и личный authenticator.
> **Точное действие:** `AnyDesk → Settings → Access → Unattended Access → Enable Two-Factor Authentication`, отсканировать QR локально и подтвердить текущим кодом.
> **Последствие:** unattended connection потребует одноразовый код дополнительно к password.
> **Риск и откат:** потеря authenticator без recovery path может заблокировать remote access; recovery data хранится только в менеджере паролей.
> **Проверка:** следующая тестовая session запрашивает второй фактор.
> Выполнить именно это действие? Ответьте `да`.

QR и 2FA code не отправляются в чат.

### Saved login information и short-term passwords

Сохранённый login token может входить без повторного password, а отключение выдачи новых tokens не отзывает уже выданные. Перед изменением заново сверь [официальную инструкцию](https://support.anydesk.com/docs/unattended-access) с текущим интерфейсом. Гид копирует в approval-gate фактическое название каждого видимого переключателя или кнопки; не угадывай label.

Безопасный вариант по умолчанию выполняется двумя разными действиями:

1. отдельный gate запрещает другим компьютерам сохранять login information;
2. новый gate отзывает все ранее выданные saved-login tokens.

В каждом gate укажи Mac mini, точный путь и label из текущего UI, последствие, откат и проверку, затем спроси отдельное `да`. Отзыв tokens обяжет доверенный Windows-клиент вновь ввести password при следующем входе.

Даже если saved login позже действительно понадобится, сначала отзови старые tokens и проведи базовую fresh session с повторным вводом password и 2FA. Затем saved login можно вернуть только как отдельный opt-in: сначала отдельным gate включи применение 2FA к saved login information, затем другим gate разреши выдачу token. Если будут использоваться short-term passwords или automatic reconnect после remote restart, отдельным gate включи 2FA и для этого типа входа. Если не используются, не включай их ради теста.

## Шаг 8 · Ограничить ACL

На Windows локально посмотри AnyDesk ID/Alias доверенного клиента, но не сообщай его гиду и не записывай в state.

### Шлюз согласия — Access Control List

> **Устройство:** Mac mini.
> **Точное действие:** в AnyDesk security/access settings включить Access Control List и локально добавить только ID/Alias доверенного Windows-клиента.
> **Последствие:** входящие sessions от других идентификаторов будут отклоняться даже при знании password.
> **Риск и откат:** ошибка в ID может заблокировать резервный канал; физический доступ сохраняется, ACL можно исправить локально.
> **Проверка:** allowlist содержит ровно доверенный клиент без публикации значения.
> Выполнить именно это действие? Ответьте `да`.

Если текущая редакция/лицензия не предоставляет ACL, не записывай hardening marker и не выдавай фазу как завершённую. Остановись для отдельного безопасного решения; не расширяй доступ молча.

Не записывай `anydesk-hardened` пока не обработаны saved-login и short-term access, fresh remote test не покажет запрос 2FA, а ACL не будет повторно проверена в интерфейсе.

## Шаг 9 · Remote test с Windows

Это внешнее сетевое подключение. Сначала полностью заверши предыдущую session на Windows, чтобы тест был fresh. Перед новым подключением гид показывает точное ручное действие «ввести локально сохранённый AnyDesk ID/Alias в доверенном Windows-клиенте и начать session» и получает отдельное `да`.

Успешная проверка состоит из четырёх разных доказательств:

1. доверенный Windows-клиент заново вводит password и входит без локального принятия session на Mac;
2. в этой fresh session AnyDesk после password обязательно запрашивает 2FA code; connection проходит только после его локального ввода, а ACL по-прежнему содержит только этот доверенный клиент;
3. после password и 2FA экран Mac виден;
4. в пустом TextEdit-документе удалённо вводится безопасная тестовая строка и затем удаляется.

Если после базового теста выбран opt-in saved login, заверши session и проведи ещё один отдельно согласованный fresh connection test: token может убрать повторный ввод password, но 2FA code должен остаться обязательным.

После каждого доказательства отдельно запиши соответствующий marker на Mac. `anydesk-hardened` записывается только после базовой fresh session и, если saved login включён, после дополнительного token-based теста:

```bash
./mac-mini-24x7/scripts/record-checkpoint.sh manual anydesk-unattended
```

```bash
./mac-mini-24x7/scripts/record-checkpoint.sh manual anydesk-hardened
```

```bash
./mac-mini-24x7/scripts/record-checkpoint.sh manual anydesk-view
```

```bash
./mac-mini-24x7/scripts/record-checkpoint.sh manual anydesk-control
```

Каждая запись требует собственного `да`.

## Шаг 10 · Итоговая проверка

На Mac:

```bash
bash ./mac-mini-24x7/04-anydesk/verify.sh
```

Локальный script не подменяет remote test. После `PASS` и четырёх manual markers отдельно запиши:

```bash
./mac-mini-24x7/scripts/record-checkpoint.sh step 04-anydesk:verified
```

## Готово, когда

- AnyDesk установлен на Mac и Windows;
- Screen Recording и Accessibility выданы осознанно;
- Full Disk Access не выдан без причины;
- Unattended Access защищён unique password, 2FA и ACL, в котором оставлен только доверенный Windows-клиент;
- выдача saved-login tokens запрещена и прежние tokens отозваны либо saved login осознанно оставлен только с обязательным 2FA; используемые short-term/remote-restart logins тоже требуют 2FA;
- удалённо доказаны view и control;
- записаны `anydesk-unattended`, `anydesk-hardened`, `anydesk-view`, `anydesk-control` и `04-anydesk:verified`.

Post-reboot доступ проверяется позже, в фазе 07.

Следующий файл: [05-tailscale/runbook.md](../05-tailscale/runbook.md).
