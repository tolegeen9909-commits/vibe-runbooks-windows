# 05 · Flutter и Android Emulator

## Важно

Фаза необязательная. На Windows нельзя локально собирать iOS: Xcode, CocoaPods и iOS Simulator не устанавливаются. Windows-аналог первой мобильной победы — Android Emulator.

Если мобильный трек не нужен:

```powershell
powershell -ExecutionPolicy Bypass -File .\05-flutter\skip.ps1
```

## Требования

- желательно 16 GB RAM или больше;
- около 50 GB свободного места;
- виртуализация включена в BIOS/UEFI;
- процессор Intel/AMD x64.

## Шаги

Перед большой официальной загрузкой Flutter гид объясняет действие и ждёт «да»:

```powershell
powershell -ExecutionPolicy Bypass -File .\05-flutter\install-flutter.ps1
```

Закрой и открой терминал, затем:

```powershell
powershell -ExecutionPolicy Bypass -File .\05-flutter\install-android-studio.ps1
```

Открой Android Studio и пройди Setup Wizard в режиме Standard. Оставь Android SDK, Platform, Build-Tools, Command-line Tools и Emulator.

Лицензии сначала показываются без принятия:

```powershell
powershell -ExecutionPolicy Bypass -File .\05-flutter\setup-android-toolchain.ps1
```

После согласия человека:

```powershell
powershell -ExecutionPolicy Bypass -File .\05-flutter\setup-android-toolchain.ps1 -AcceptLicenses
```

Создай телефон: Android Studio → Tools → Device Manager → Create Virtual Device → обычный Pixel → стабильный Android image. Запусти его.

Проверка:

```powershell
powershell -ExecutionPolicy Bypass -File .\05-flutter\verify.ps1
flutter devices
```

После успеха переходи к `06-first-win/runbook.md`.
