# Changelog

Все значимые изменения в проекте будут документироваться в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/),
и проект придерживается [Semantic Versioning](https://semver.org/lang/ru/).

## [Unreleased]

## [0.1.2] - 2025-01-26

### Изменено
- Лицензия изменена с MIT на BSD 3-Clause с ограничением на коммерческое использование
- Добавлено обязательное требование указания автора (Marat Zimnurov, zimtir@mail.ru) при использовании
- Обновлен README с информацией о лицензии и требованиях

### Добавлено
- Документация на Hugo с автоматической публикацией в GitHub Pages
- Code coverage badges в README
- Улучшенный Makefile с полезными командами
- LICENSE файл (BSD 3-Clause)
- CHANGELOG.md для отслеживания изменений

### Исправлено
- Ошибка сборки релиза с cookie
- Ошибка загрузки артефактов в GitHub Actions (overwrite: true)
- Версия action-gh-release обновлена на v2
- Структура workflow для корректной сборки всех платформ

## [0.1.1] - 2025-01-26

### Исправлено
- Исправлена ошибка сборки релиза с cookie
- Исправлена ошибка загрузки артефактов в GitHub Actions
- Обновлена версия action-gh-release на v2
- Исправлена структура workflow для корректной сборки всех платформ

## [0.1.0] - 2025-01-26

### Добавлено
- Backend API на Elixir/Phoenix
- Chrome Extension на TypeScript
- Поддержка Keycloak авторизации
- Guest режим для работы без Keycloak
- Публичные ссылки
- Группировка ссылок
- Короткие ссылки с редиректом
- CI/CD через GitHub Actions
- Документация API

[Unreleased]: https://github.com/the-homeless-god/links/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/the-homeless-god/links/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/the-homeless-god/links/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/the-homeless-god/links/releases/tag/v0.1.0
