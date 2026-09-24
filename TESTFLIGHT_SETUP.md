# NOVA iOS 1.0.1 — TestFlight setup

Проект уже подготовлен под TestFlight: bundle ID `com.nova.messenger`, Release entitlements для production APNs, dSYM, App Store Connect export options и workflow для автоматической загрузки.

## Что нужно от Apple один раз

1. Вступить в Apple Developer Program.
2. В App Store Connect создать приложение `NOVA` с bundle ID `com.nova.messenger`.
3. В Apple Developer -> Certificates, Identifiers & Profiles убедиться, что App ID `com.nova.messenger` имеет Push Notifications.
4. Создать Apple Distribution certificate (`.p12`) для CI или выбрать свою Team в Xcode для ручной загрузки.
5. В App Store Connect -> Users and Access -> Integrations создать API key с доступом к загрузке builds и сохранить `.p8`, Key ID и Issuer ID.

## Firebase / push

В Firebase добавь iOS app с bundle ID `com.nova.messenger`, скачай `GoogleService-Info.plist` и положи его в:

`NOVA/Resources/GoogleService-Info.plist`

В Firebase Cloud Messaging также загрузи APNs Authentication Key Apple. Сервер NOVA 3.8.89 уже умеет регистрировать iOS FCM tokens.

## Самый простой путь через Xcode

На Mac:

```bash
brew install xcodegen
./scripts/generate_project.sh
open NOVA-iOS.xcodeproj
```

В Xcode выбери Target NOVA -> Signing & Capabilities -> свою Team. Затем `Product -> Archive`, после архива `Distribute App -> App Store Connect -> Upload`.

После обработки сборка появится в App Store Connect -> TestFlight.

## Автоматическая загрузка GitHub Actions

В Repository -> Settings -> Secrets and variables -> Actions добавь:

- `APPLE_TEAM_ID`
- `APPLE_DISTRIBUTION_P12_BASE64`
- `APPLE_DISTRIBUTION_P12_PASSWORD`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_P8_BASE64`
- `GOOGLE_SERVICE_INFO_PLIST_BASE64`

Для base64 на macOS:

```bash
base64 -i distribution.p12 | pbcopy
base64 -i AuthKey_ABC123.p8 | pbcopy
base64 -i GoogleService-Info.plist | pbcopy
```

После этого: GitHub -> Actions -> `Upload NOVA to TestFlight` -> `Run workflow`.

Workflow архивирует Release, экспортирует IPA и отправляет его в App Store Connect. После обработки Apple сборка появится во вкладке TestFlight.

## Versioning

Сейчас:

- Marketing version: `1.0.1`
- Build: `2`

Для каждой следующей загрузки в пределах 1.0.1 увеличивай `CURRENT_PROJECT_VERSION` (3, 4, 5...). Если выпускается новая пользовательская версия, меняй `MARKETING_VERSION`.

## Push entitlements

Debug использует `aps-environment=development`, Release/TestFlight — `aps-environment=production`. Для TestFlight production APNs обязателен.

## Export compliance

В `Info.plist` стоит `ITSAppUsesNonExemptEncryption = NO`, потому что текущий NOVA iOS использует стандартные системные HTTPS/TLS API и не содержит собственной криптографии. Если позже в клиент добавится собственная криптография, этот параметр нужно пересмотреть.
