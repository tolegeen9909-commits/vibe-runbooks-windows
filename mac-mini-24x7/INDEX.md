# Карта маршрута Mac mini 24/7

Это навигация, а не команда «запустить всё». Каждый раз открывай один runbook, выполняй одно действие и проверяй результат.

Все shell-команды маршрута запускаются из корня репозитория. До рабочего SSH macOS-команды вводятся физически на Mac mini.

## Фазы

| Фаза | Результат | Проверка или точка входа |
|---|---|---|
| 00 · Preflight | Поддерживаемый Mac, место и исходное состояние известны без personal identifiers | `bash ./mac-mini-24x7/00-preflight/check-system.sh` |
| 01 · macOS update | Установлена актуальная совместимая macOS; reboot выполнен локально и безопасно | ручная проверка Software Update |
| 02 · Power 24/7 | Системный сон запрещён, сетевое пробуждение и поддерживаемый power recovery настроены | `bash ./mac-mini-24x7/02-power-24x7/verify.sh` |
| 03 · SSH и Termius | Remote Login ограничен одним пользователем; SSH-ключ и LAN-подключения проверены | `bash ./mac-mini-24x7/03-ssh-termius/verify.sh` |
| 04 · AnyDesk | Резервный GUI показывает экран и принимает ввод с минимальными TCC-разрешениями | `bash ./mac-mini-24x7/04-anydesk/verify.sh` |
| 05 · Tailscale | Mac и Windows в одном tailnet; обычный SSH работает по MagicDNS/tailnet | `bash ./mac-mini-24x7/05-tailscale/verify.sh` |
| 06 · Recovery и security | Выбран `secure` или осознанный `autonomous` режим | `bash ./mac-mini-24x7/06-recovery-security/verify.sh` |
| 07 · Reboot checkpoint | Lock, logout и обычный reboot проверены по одному | ручной runbook |
| 08 · Power loss и headless | Восстановление питания и работа без дисплея проверены физически | ручной runbook |
| 09 · Development | На Apple Silicon/macOS 15+ инструменты установлены только после стабильного remote access | `bash ./mac-mini-24x7/09-development/verify.sh` |
| 10 · Final checkpoint | Получен честный итог `secure-ready` или `autonomous-ready` | `bash ./mac-mini-24x7/10-final-checkpoint/self-check.sh` |

## Как проходить фазу

1. Прочитай runbook фазы полностью.
2. Выполни первую read-only проверку.
3. Исправляй только один обязательный пункт.
4. После изменения повтори ту же проверку.
5. Проведи перечисленные manual tests.
6. Только после доказательства запиши step/manual checkpoint.
7. Перейди к следующей фазе.

## Порядок runbook-файлов

1. [00-preflight/runbook.md](00-preflight/runbook.md)
2. [01-macos-update/runbook.md](01-macos-update/runbook.md)
3. [02-power-24x7/runbook.md](02-power-24x7/runbook.md)
4. [03-ssh-termius/runbook.md](03-ssh-termius/runbook.md)
5. [04-anydesk/runbook.md](04-anydesk/runbook.md)
6. [05-tailscale/runbook.md](05-tailscale/runbook.md)
7. [06-recovery-security/runbook.md](06-recovery-security/runbook.md)
8. [07-reboot-checkpoint/runbook.md](07-reboot-checkpoint/runbook.md)
9. [08-power-loss-headless/runbook.md](08-power-loss-headless/runbook.md)
10. [09-development/runbook.md](09-development/runbook.md)
11. [10-final-checkpoint/runbook.md](10-final-checkpoint/runbook.md)

При ошибке открой [TROUBLESHOOTING.md](TROUBLESHOOTING.md), но применяй только одну ветку диагностики.

## Обязательные ручные доказательства до фазы 06

- `ssh-lan` — Windows OpenSSH вошёл на Mac по LAN, fingerprint был сравнен;
- `termius-lan` — Termius вошёл тем же SSH-ключом;
- `anydesk-view` — удалённый экран виден;
- `anydesk-control` — мышь и клавиатура работают;
- `anydesk-unattended` — вход без локального подтверждения доказан;
- `anydesk-hardened` — Unattended Access защищён 2FA и ACL;
- `tailscale-peers` — оба устройства видны online в одном tailnet;
- `ssh-over-tailscale` — обычный SSH работает через MagicDNS или tailnet address.

Ни один marker не хранит фактический адрес, username или ID.

## Два допустимых результата

**Secure route** сохраняет FileVault и выключенный automatic login. Это рекомендуемый вариант. После холодной загрузки может потребоваться локальная разблокировка.

**Autonomous route** — отдельный opt-in с меньшей физической защитой. Он считается готовым только после фаз 06–10 и реального power-recovery test.

## Неподвижные правила

- порт 22 не публикуется в интернет;
- используется Apple Remote Login, а не Tailscale SSH server;
- AnyDesk остаётся резервом;
- standard Tailscale GUI на macOS не доказывает pre-login доступ;
- FileVault не отключается автоматически;
- environment setup начинается только в фазе 09.
