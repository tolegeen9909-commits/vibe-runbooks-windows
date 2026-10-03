# 05 · Tailscale и обычный SSH без публичного порта

## Результат фазы

Mac mini и Windows находятся в одном личном tailnet, policy разрешает владельцу только обычный SSH к Mac, а key-auth connection работает по MagicDNS/tailnet address.

Мы **не** включаем Tailscale SSH server. Сервером SSH остаётся Apple Remote Login.

Официальные источники:

- [варианты Tailscale для macOS](https://tailscale.com/docs/concepts/macos-variants);
- [Windows install](https://tailscale.com/docs/install/windows);
- [connect to devices](https://tailscale.com/docs/how-to/connect-to-devices);
- [access control](https://tailscale.com/docs/features/access-control);
- [Grants](https://tailscale.com/docs/features/access-control/grants);
- [tags](https://tailscale.com/docs/features/tags).

## Важное ограничение macOS

Standalone и Mac App Store GUI-варианты Tailscale не работают до входа пользователя. Только CLI-only `tailscaled` может работать pre-login, но Tailscale рекомендует его опытным macOS-администраторам; он вне beginner MVP.

Поэтому эта фаза доказывает remote access **после login**. Она не доказывает автономность после холодной загрузки с FileVault.

## Шаг 1 · Read-only проверка

На Mac mini:

```bash
bash ./mac-mini-24x7/05-tailscale/verify.sh
```

Скрипт не должен выводить tailnet IP, MagicDNS name, account email или node ID. Локальный `PASS` требует валидный JSON-ответ с `BackendState=Running` и `Self.Online=true`; ошибка CLI, `NeedsLogin`, `Stopped` или недоказанный online-state оставляют фазу в `MANUAL`, даже при старых checkpoint-markers. Если обнаружены одновременно App Store и Standalone variants, остановись: нельзя запускать обе.

## Шаг 2 · Установить рекомендованный Standalone client на Mac

Если Tailscale уже установлен одной поддерживаемой variant, не переустанавливай его.

Если отсутствует, раздели действия:

1. отдельное `да` на открытие [официальной страницы Mac](https://tailscale.com/download/mac);
2. отдельное `да` на загрузку рекомендованного Standalone package;
3. проверка официального домена и подписи Tailscale;
4. отдельное `да` на запуск package installer.

### Последствие installer

macOS установит приложение и system/network extension, может запросить admin password и подтверждение VPN configuration. Пользователь выполняет prompts локально. Не устанавливай App Store variant поверх Standalone.

Откат — sign out/disconnect, revoke node в admin console и удалить приложение официальным способом; это не выполняется автоматически.

## Шаг 3 · Подключить Mac к личному tailnet

### Шлюз согласия — browser login

> **Устройство:** Mac mini и официальный браузер.
> **Точное действие:** открыть Tailscale, выбрать `Log in/Connect` и завершить официальный browser login владельца tailnet.
> **Последствие:** устройство регистрируется в tailnet и получает private network identity.
> **Риск и откат:** владелец tailnet сможет видеть metadata устройства; node можно disconnect/revoke.
> **Проверка:** Tailscale показывает Connected, а Machines page — online Mac без публикации его адреса.
> Выполнить именно это действие? Ответьте `да`.

Password и 2FA вводятся только в браузере. Auth key для beginner-пути не создаётся и не передаётся в чат.

## Шаг 4 · Установить и подключить Windows-клиент

Сначала проверь `Settings → Apps → Installed apps` на Windows.

Если клиента нет, отдельно согласуй:

1. открытие [официальной Windows-страницы](https://tailscale.com/download/windows);
2. download installer;
3. запуск подписанного installer.

После установки отдельным browser-login gate подключи Windows **к тому же tailnet**. Не создавай второй tailnet случайно.

Проверка: в Machines page оба устройства online. Имена, адреса и account email не копируются в репозиторий или progress.

## Шаг 5 · Настроить least-privilege policy

Этот шаг применим только к новому пустому личному tailnet, где текущий пользователь имеет роль Owner или Admin и нет других сервисов. Если tailnet общий, корпоративный или policy уже изменена, остановись и передай задачу администратору. Нельзя заменять существующую policy шаблоном.

Для личного tailnet целевая логика:

- Mac mini получает service tag `tag:mac-mini-24x7`;
- только устройства участников с ролью Owner или Admin могут обращаться к нему;
- разрешён только `tcp:22`;
- Tailscale SSH section не добавляется.

Минимальный policy для **нового пустого личного tailnet**:

```jsonc
{
  "tagOwners": {
    "tag:mac-mini-24x7": ["autogroup:owner", "autogroup:admin"]
  },
  "grants": [
    {
      "src": ["autogroup:owner", "autogroup:admin"],
      "dst": ["tag:mac-mini-24x7"],
      "ip": ["tcp:22"]
    }
  ]
}
```

### Шлюз согласия — access policy

> **Устройство:** официальный Tailscale admin console в браузере.
> **Точное действие:** на странице Access controls заменить только подтверждённую default policy нового личного tailnet на полностью показанный выше документ и сохранить после успешной встроенной проверки.
> **Последствие:** tailnet станет deny-by-default; устройства Owner и Admin смогут обращаться к tagged Mac только по TCP 22. Другой трафик будет запрещён.
> **Риск и откат:** неверная policy может оборвать существующие соединения; перед сохранением сохранить прежнюю policy локально вне репозитория и использовать встроенную validation.
> **Проверка:** редактор принимает policy без ошибки; SSH test ниже проходит, лишний доступ не добавлен.
> Выполнить именно это действие? Ответьте `да`.

Если текущая policy содержит другие поля, не объединяй их автоматически и не применяй шаблон.

## Шаг 6 · Назначить tag Mac mini

Tags меняют identity устройства с user-based на service-based. Это отдельное изменение.

### Шлюз согласия — tag identity

> **Устройство:** Tailscale admin console.
> **Точное действие:** `Machines → строка Mac mini → … → Edit tags → tag:mac-mini-24x7 → Save`.
> **Последствие:** Mac станет tagged service device; его прежняя user identity будет заменена tag identity.
> **Риск и откат:** все permissions теперь определяет policy; неверная policy может закрыть доступ. Физический доступ и AnyDesk уже проверены.
> **Проверка:** Machines page показывает нужный tag и Mac online.
> Выполнить именно это действие? Ответьте `да`.

Не назначай этот service tag Windows-компьютеру: это пользовательское устройство.

## Шаг 7 · Решить key expiry для 24/7 Mac

Сначала в Machines page проверь expiry Mac. Если expiry уже disabled для tagged device, ничего не меняй.

Если expiry включён, для постоянно удалённого Mac допустимо отключить его только после оценки риска:

> **Точное действие:** `Tailscale admin console → Machines → Mac mini → … → Disable key expiry`.
> **Последствие:** node key не потребует периодической re-authentication и останется действительным до ручного revoke.
> **Риск и откат:** украденное/скомпрометированное устройство останется доверенным дольше; при потере немедленно revoke node. Вернуть срок можно через Enable key expiry.
> **Проверка:** Machines page показывает expiry disabled.
> Выполнить именно это действие? Ответьте `да`.

Источник: [Tailscale — Key expiry](https://tailscale.com/docs/features/access-control/key-expiry).

## Шаг 8 · Доказать видимость peers

В Windows Tailscale найди MagicDNS name Mac локально. Не присылай name или address гиду и не сохраняй их.

Точная команда ниже запрашивает MagicDNS name локально в Windows Terminal. Не присылай его гиду. После отдельного `да` выполни:

```powershell
$MacTailnetName = Read-Host "Mac MagicDNS name"; tailscale ping $MacTailnetName
```

Успех подтверждает tailnet path, но ещё не SSH. После наблюдаемого ответа отдельно запиши на Mac:

```bash
./mac-mini-24x7/scripts/record-checkpoint.sh manual tailscale-peers
```

## Шаг 9 · Доказать обычный SSH поверх Tailscale

Команда запрашивает username и MagicDNS name только в локальном Windows Terminal. Гид показывает эту точную команду и получает новое `да`:

```powershell
$MacUser = Read-Host "Mac username"; $MacTailnetName = Read-Host "Mac MagicDNS name"; ssh -i "$HOME\.ssh\mac-mini-24x7" -o PreferredAuthentications=publickey -o PasswordAuthentication=no "$MacUser@$MacTailnetName"
```

Это обычный OpenSSH, а не `tailscale ssh`. Выполни `pwd`, затем `exit`. Не открывай порт на роутере.

После успеха обнови Address/Hostname существующего Termius Host на MagicDNS name отдельным local state-change gate и проведи отдельный network connection test. Private key остаётся прежним.

Затем после отдельного согласия запиши:

```bash
./mac-mini-24x7/scripts/record-checkpoint.sh manual ssh-over-tailscale
```

## Шаг 10 · Итоговая проверка

На Mac:

```bash
bash ./mac-mini-24x7/05-tailscale/verify.sh
```

Локальный script не должен печатать address или account identity и не может сам доказать Windows connection.

После `PASS` и двух manual markers отдельно запиши:

```bash
./mac-mini-24x7/scripts/record-checkpoint.sh step 05-tailscale:verified
```

## Готово, когда

- на Mac установлена одна поддерживаемая Tailscale variant;
- Mac и Windows online в одном tailnet;
- личная policy ограничивает tagged Mac до Owner/Admin → TCP 22 либо корпоративный администратор предоставил эквивалентную least-privilege policy;
- публичного port forwarding нет;
- `tailscale ping` и обычный key-only SSH по tailnet доказаны;
- записаны `tailscale-peers`, `ssh-over-tailscale` и `05-tailscale:verified`;
- ограничение pre-login macOS зафиксировано и не выдано за autonomous readiness.

Следующий файл: [06-recovery-security/runbook.md](../06-recovery-security/runbook.md).
