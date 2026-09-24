# Установка NOVA на iPhone через TestFlight

1. Проект загружается в App Store Connect как подписанный Release build.
2. Apple обрабатывает build.
3. В App Store Connect -> TestFlight владелец добавляет тестера по Apple Account email или создаёт external testing link после beta review.
4. На iPhone ставится официальное приложение TestFlight из App Store.
5. Открывается приглашение NOVA и нажимается Install.

Одна TestFlight-сборка доступна для тестирования до 90 дней. Для новой сборки увеличивается build number и выполняется следующая загрузка.

Полная подготовка и CI: `TESTFLIGHT_SETUP.md`.
