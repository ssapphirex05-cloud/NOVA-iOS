# NOVA iOS 1.0.1 — TestFlight Ready

Отдельный iPhone-клиент NOVA Messenger на Swift + WKWebView.

## Готово

- NOVA server URL: `https://246830.9yy8ob5y94yx.mjtest.ru/nova_messenger_v1/`
- bundle ID: `com.nova.messenger`
- iPhone-only target
- iOS 15+
- safe-area для Dynamic Island / notch
- cookies + web storage для авторизации
- микрофон, камера, media playback и файлы
- Firebase Messaging / APNs bridge
- production APNs entitlement для TestFlight
- Debug APNs entitlement для локальной разработки
- dSYM в Release
- App Store Connect export options
- export compliance key для стандартного HTTPS/TLS
- обычная Xcode загрузка в TestFlight
- отдельный GitHub Actions workflow для автоматической загрузки в TestFlight после добавления Apple secrets

Основная инструкция: `TESTFLIGHT_SETUP.md`.

## Генерация Xcode проекта

```bash
brew install xcodegen
./scripts/generate_project.sh
open NOVA-iOS.xcodeproj
```

## Версия

NOVA iOS `1.0.1` (build `2`).
