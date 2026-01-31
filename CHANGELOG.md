## [0.2.4](https://github.com/the-homeless-god/links/compare/v0.2.3...v0.2.4) (2026-01-31)

### Bug Fixes

* **release:** исправлено определение версии для DMG и обработка созданного файла ([f3e13e2](https://github.com/the-homeless-god/links/commit/f3e13e2aa2dc542ff04008a02010e29fea95c0ed))

## [0.2.3](https://github.com/the-homeless-god/links/compare/v0.2.2...v0.2.3) (2026-01-31)

### Bug Fixes

* **release:** добавлен триггер на push тегов для сборки артефактов ([ff3dff5](https://github.com/the-homeless-god/links/commit/ff3dff5f31d9a72cb1fd5704f8d5afa87a103c4b))

## [0.2.2](https://github.com/the-homeless-god/links/compare/v0.2.1...v0.2.2) (2026-01-31)

### Bug Fixes

* **release:** update release message format to remove [skip ci] ([eb5df30](https://github.com/the-homeless-god/links/commit/eb5df30e5c346fb26dbf2931ec3fea92b91e7bc6))

## [0.2.1](https://github.com/the-homeless-god/links/compare/v0.2.0...v0.2.1) (2026-01-31)

### Bug Fixes

* **release:** обновлен workflow для обработки релизов и версий ([766c727](https://github.com/the-homeless-god/links/commit/766c72776b6906cac8ea149336f993d7acdbd4c5))

## [0.2.0](https://github.com/the-homeless-god/links/compare/v0.1.8...v0.2.0) (2026-01-31)

### Features

* **release:** добавлен semantic-release для автоматической генерации changelog и релизов ([4598421](https://github.com/the-homeless-god/links/commit/45984212c6d10a33db13a4731c6a182cb82210f0))

### Bug Fixes

* **release:** добавлен conventional-changelog-conventionalcommits ([ebacd1b](https://github.com/the-homeless-god/links/commit/ebacd1b1b60748403fbff8638b55f577a8f5696f))
* **release:** добавлены недостающие плагины semantic-release ([8dfdaa3](https://github.com/the-homeless-god/links/commit/8dfdaa31a29a0910a661cd35e36dc5b2fbbd52e6))
* **release:** убрано кеширование npm из workflow ([fd7f780](https://github.com/the-homeless-god/links/commit/fd7f78075b7f1fcb849d30052e069209f32a4c21))

# Changelog

Все значимые изменения в проекте будут документироваться в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/),
и проект придерживается [Semantic Versioning](https://semver.org/lang/ru/).

> **Примечание:** Этот файл автоматически генерируется с помощью [semantic-release](https://github.com/semantic-release/semantic-release).
> Коммиты должны следовать [Conventional Commits](https://www.conventionalcommits.org/) для автоматической генерации.

## [Unreleased]

## [0.1.8] - 2025-01-26

### Исправлено
- Исправлена сборка DMG (убраны опциональные параметры create-dmg, добавлен полный путь)
- Добавлена проверка существования DMG файла после создания
- Добавлен отдельный шаг загрузки DMG в артефакты для macOS
- DMG теперь включается в GitHub Release вместе с tar.gz архивами

## [0.1.7] - 2025-01-26

### Исправлено
- Исправлен working-directory для шага сборки DMG в GitHub Actions
- Скрипт scripts/build-dmg.sh теперь находится корректно при выполнении в workflow

## [0.1.6] - 2025-01-26

### Исправлено
- Исправлен путь к артефактам (elixir_backend/links-api-*.tar.gz) для корректной работы с working-directory
- Исправлен токен на secrets.GITHUB_TOKEN в backend-release.yml
- Добавлена расширенная отладка для диагностики проблем с архивами

## [0.1.5] - 2025-01-26

### Исправлено
- Улучшена обработка архивов релиза (используется явное имя файла через ls)
- Исправлена ошибка "No files were found with the provided path: links-api-*.tar.gz"
- Добавлена отладочная информация для диагностики проблем с архивами

## [0.1.4] - 2025-01-26

### Исправлено
- Исправлен путь к архивам релиза (используется готовый архив из mix release вместо создания нового)
- Исправлена ошибка "No files were found with the provided path: links-api-*.tar.gz"

## [0.1.3] - 2025-01-26

### Исправлено
- Исправлена ошибка с Windows runner в GitHub Actions (windows-latest -> windows-2022)

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

[Unreleased]: https://github.com/the-homeless-god/links/compare/v0.1.8...HEAD
[0.1.8]: https://github.com/the-homeless-god/links/compare/v0.1.7...v0.1.8
[0.1.7]: https://github.com/the-homeless-god/links/compare/v0.1.6...v0.1.7
[0.1.6]: https://github.com/the-homeless-god/links/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/the-homeless-god/links/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/the-homeless-god/links/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/the-homeless-god/links/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/the-homeless-god/links/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/the-homeless-god/links/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/the-homeless-god/links/releases/tag/v0.1.0
