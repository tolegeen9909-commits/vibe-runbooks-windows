# 03 · Apple Remote Login, SSH-ключ и Termius

## Результат фазы

Remote Login доступен только выбранному пользователю, Windows OpenSSH входит по SSH-ключу в LAN, а Termius повторяет тот же безопасный вход.

Официальные источники:

- [Apple — Remote Login](https://support.apple.com/guide/mac-help/allow-a-remote-computer-to-access-your-mac-mchlp1066/mac);
- [Microsoft — SSH in Windows Terminal](https://learn.microsoft.com/en-us/windows/terminal/tutorials/ssh);
- [Termius — official documentation](https://termius.com/documentation/).

Публичный порт 22, port forwarding, DMZ и Tailscale SSH server не нужны и запрещены этим маршрутом.

## Перед началом

- Mac и Windows находятся в одной доверенной LAN.
- Есть физический доступ к Mac.
- Фазы 00–02 завершены.
- Пользователь знает локальный login password, но не сообщает его гиду.
- Временный password login используется только для доставки public key; рабочий вход проверяется ключом.

## Шаг 1 · Локальная read-only проверка

На Mac mini:

```bash
bash ./mac-mini-24x7/03-ssh-termius/verify.sh
```

До включения Remote Login ожидаем `FAIL` или `MANUAL`. Скрипт не должен выводить username, hostname или адрес.

Для безопасного первого подключения локально узнай fingerprint публичного host key:

```bash
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Fingerprint можно сравнить глазами, но не нужно сохранять в репозитории.

## Шаг 2 · Ограничить разрешённых пользователей

Сначала подготовь allowlist, затем включай сервис.

### Шлюз согласия — SSH allowlist

> **Устройство:** Mac mini.
> **Точное действие:** `System Settings → General → Sharing → ⓘ рядом с Remote Login → Allow access for → Only these users`, затем оставить только выбранную рабочую учётную запись.
> **Последствие:** только этот локальный пользователь сможет проходить SSH-аутентификацию.
> **Откат:** добавить/удалить пользователя в том же списке.
> **Проверка:** в списке нет `All users` и лишних аккаунтов.
> Выполнить именно это действие? Ответьте `да`.

`Allow full disk access for remote users` оставь выключенным. Если он уже включён, его выключение — отдельное действие с отдельным `да`.

## Шаг 3 · Включить Remote Login

### Шлюз согласия — системный сетевой сервис

> **Устройство:** Mac mini.
> **Точное действие:** `System Settings → General → Sharing → Remote Login → On`.
> **Последствие:** macOS запустит SSH-сервис на локальном порту 22 для allowlisted пользователя. Порт на роутере не открывается.
> **Откат:** вернуть `Remote Login → Off`.
> **Проверка:** повторный `verify.sh` видит активный Remote Login.
> Выполнить именно это действие? Ответьте `да`.

## Шаг 4 · Первый LAN-вход из Windows

Apple показывает SSH-target в окне Remote Login. Не пересылай username и local name гиду: точная PowerShell-команда ниже запрашивает их локально через `Read-Host` и не печатает в чат.

Шаблон для Windows Terminal:

```powershell
$MacUser = Read-Host "Mac username"; $MacLocalName = Read-Host "Mac local name without .local"; ssh -o StrictHostKeyChecking=ask "$MacUser@${MacLocalName}.local"
```

### Шлюз согласия — LAN connection

Объясни, что команда создаёт сетевое подключение к Mac. На первом входе пользователь сравнивает предложенный fingerprint с локальным результатом предыдущего шага. При несовпадении выбирает `no` и останавливается. Пароль вводится только в prompt Windows Terminal и не отображается.

После входа выполни одну безвредную команду `pwd`, затем `exit`. Только после этого можно считать первичную LAN-связь доказанной.

## Шаг 5 · Создать отдельный SSH-ключ на Windows

Сначала read-only проверь, не существует ли файл:

```powershell
Test-Path "$HOME\.ssh\mac-mini-24x7"
```

Если результат `True`, не перезаписывай ключ. Остановись и реши, использовать существующий ключ или выбрать новое имя.

Если файла нет, покажи отдельный gate:

```powershell
ssh-keygen -t ed25519 -a 100 -f "$HOME\.ssh\mac-mini-24x7" -C "mac-mini-24x7"
```

Команда создаёт private/public key в профиле Windows и спрашивает passphrase локально. Это state-changing действие. Используй уникальную passphrase из менеджера паролей; не присылай её в чат. Private key без расширения никогда не копируется на Mac и не загружается в репозиторий.

## Шаг 6 · Передать только public key

Следующая точная команда запускается в Windows PowerShell. LAN target вводится локально. Команда подключается по SSH, создаёт `~/.ssh` на Mac и идемпотентно добавляет только public key:

```powershell
$MacUser = Read-Host "Mac username"; $MacLocalName = Read-Host "Mac local name without .local"; Get-Content -Raw "$HOME\.ssh\mac-mini-24x7.pub" | ssh "$MacUser@${MacLocalName}.local" 'umask 077; mkdir -p "$HOME/.ssh"; touch "$HOME/.ssh/authorized_keys"; chmod 700 "$HOME/.ssh"; chmod 600 "$HOME/.ssh/authorized_keys"; key="$(cat)"; grep -qxF "$key" "$HOME/.ssh/authorized_keys" || printf "%s\n" "$key" >> "$HOME/.ssh/authorized_keys"'
```

Это одновременно сетевое и удалённое state-changing действие, поэтому требует отдельного `да`. Пароль Mac вводится только в SSH prompt. Не вставляй private key или passphrase.

## Шаг 7 · Доказать key-only вход

После отдельного согласия выполни из Windows Terminal итоговую команду с подставленным target:

```powershell
$MacUser = Read-Host "Mac username"; $MacLocalName = Read-Host "Mac local name without .local"; ssh -i "$HOME\.ssh\mac-mini-24x7" -o PreferredAuthentications=publickey -o PasswordAuthentication=no "$MacUser@${MacLocalName}.local"
```

Успех означает, что сервер принял ключ без password authentication. Выполни `pwd` и выйди командой `exit`.

После доказательства отдельно запиши manual marker:

```bash
./mac-mini-24x7/scripts/record-checkpoint.sh manual ssh-lan
```

Запись выполняется на Mac и требует отдельного `да`.

## Шаг 8 · Проверить и при необходимости установить Termius

На Windows сначала найди Termius в `Settings → Apps → Installed apps`. Это локальная проверка.

Если Termius отсутствует, действия разделяются:

1. после отдельного `да` открыть [официальную страницу загрузки](https://termius.com/download/windows);
2. после отдельного `да` загрузить Windows installer;
3. проверить, что файл пришёл с официального домена, а Windows подтверждает его digital signature; при неизвестном издателе не запускать;
4. после нового `да` запустить installer и установить приложение.

Не используй сторонние каталоги загрузок. Если приложение требует вход или cloud sync, это отдельный сетевой account gate; password/2FA вводятся только в Termius. Для этого маршрута не включай синхронизацию private key без отдельного осознанного решения.

## Шаг 9 · Создать LAN host в Termius

Названия полей могут меняться. Ориентируйся на `Hosts`, `Address/Hostname`, `Username` и `Key/Identity`, но перед действием сверяй [официальную документацию Termius](https://termius.com/documentation/).

### Шлюз согласия — локальная конфигурация Termius

> **Устройство:** Windows-компьютер.
> **Точное действие:** создать один Host с LAN hostname Mac, выбранным username и импортировать private key `$HOME\.ssh\mac-mini-24x7`; поле password оставить пустым.
> **Последствие:** Termius сохранит локальную конфигурацию host и доступ к private key в своём credential store.
> **Риск и откат:** удаление Host/Key из Termius отменяет конфигурацию; public key на Mac удаляется отдельно. Не включать cloud sync автоматически.
> **Проверка:** первый connection показывает host fingerprint, совпадающий с Mac, затем открывает shell без Mac password.
> Выполнить именно это действие? Ответьте `да`.

Подключение Termius — отдельное сетевое действие и получает ещё одно `да`. При успешном входе выполни `pwd`, выйди и запиши marker:

```bash
./mac-mini-24x7/scripts/record-checkpoint.sh manual termius-lan
```

## Шаг 10 · Итоговая проверка

На Mac снова выполни:

```bash
bash ./mac-mini-24x7/03-ssh-termius/verify.sh
```

Скрипт доказывает локальный сервис и безопасные permissions, а markers доказывают внешние подключения. Он не должен объявлять LAN tests успешными самостоятельно.

После успеха покажи отдельный checkpoint:

```bash
./mac-mini-24x7/scripts/record-checkpoint.sh step 03-ssh-termius:verified
```

## Готово, когда

- Remote Login включён только для выбранного пользователя;
- full disk access для SSH не выдан без причины;
- Windows OpenSSH работает с key-only authentication;
- Termius работает с тем же ключом;
- fingerprints были сравнены;
- записаны `ssh-lan`, `termius-lan` и `03-ssh-termius:verified`.

Следующий файл: [04-anydesk/runbook.md](../04-anydesk/runbook.md).
