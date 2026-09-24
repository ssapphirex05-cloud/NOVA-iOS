# Firebase / APNs для NOVA iOS

1. Firebase Console -> текущий проект NOVA -> Add app -> iOS.
2. Bundle ID: `com.nova.messenger`.
3. Скачай `GoogleService-Info.plist`.
4. В Xcode добавь его в `NOVA/Resources` и убедись, что он входит в target NOVA.
5. Apple Developer -> Keys -> создай APNs Authentication Key (.p8).
6. Firebase Console -> Project settings -> Cloud Messaging -> Apple app configuration -> APNs Authentication Key.
7. Загрузи `.p8`, укажи Key ID и Team ID.
8. На сервер NOVA установи версию с endpoint `push/ios/subscribe`.

Не клади APNs `.p8` или серверный Firebase service-account JSON в публичный GitHub.
