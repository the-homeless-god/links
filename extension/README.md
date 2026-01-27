# Links Manager Extension

Chrome расширение для управления короткими ссылками, написанное на TypeScript с использованием Vite и функционального программирования (fp-ts).

## Структура проекта

```
extension/
├── src/
│   ├── auth/          # Авторизация (Keycloak и Guest)
│   ├── background/    # Background service worker
│   ├── content/       # Content script
│   ├── popup/         # Основной UI расширения
│   ├── services/      # API и storage сервисы (функциональный стиль)
│   ├── utils/         # Утилиты
│   ├── tests/         # Тесты
│   ├── config.ts      # Конфигурация
│   └── types.ts       # TypeScript типы
├── dist/              # Собранные файлы (создается после сборки)
├── icons/             # Иконки расширения
├── popup.html         # HTML для popup
├── auth.html          # HTML для авторизации
├── styles.css         # Стили
├── manifest.json      # Манифест расширения
└── package.json       # Зависимости и скрипты
```

## Особенности

- **Функциональное программирование**: Используется `fp-ts` для функционального стиля
- **TypeScript**: Полная типизация
- **Модульная архитектура**: Разделение на сервисы, утилиты и компоненты
- **Тесты**: Покрытие тестами основных модулей
- **CI/CD**: Автоматическая сборка и публикация через GitHub Actions

## Установка зависимостей

```bash
cd extension
npm install
```

## Разработка

Для разработки используйте:

```bash
npm run dev
```

Это запустит Vite в режиме разработки с hot reload.

## Сборка

Для сборки расширения:

```bash
npm run build
```

Это создаст папку `dist/` со всеми необходимыми файлами для установки расширения.

## Тестирование

```bash
# Запустить все тесты
npm test

# Запустить тесты в watch режиме
npm run test:watch

# Запустить тесты с покрытием
npm run test:coverage
```

## Установка расширения в Chrome

1. Соберите расширение: `npm run build`
2. Откройте Chrome и перейдите на `chrome://extensions/`
3. Включите "Режим разработчика"
4. Нажмите "Загрузить распакованное расширение"
5. Выберите папку `extension/dist/`

## Скрипты

- `npm run build` - Сборка расширения
- `npm run build:release` - Очистка и сборка для релиза
- `npm run lint` - Проверка кода линтером
- `npm run lint:fix` - Автоматическое исправление ошибок линтера
- `npm run format` - Форматирование кода с помощью Prettier
- `npm run check-types` - Проверка типов TypeScript
- `npm run validate` - Полная валидация (lint + types)
- `npm test` - Запуск тестов
- `npm run test:watch` - Запуск тестов в watch режиме
- `npm run test:coverage` - Запуск тестов с покрытием

## Технологии

- **TypeScript** - Типизированный JavaScript
- **fp-ts** - Функциональное программирование
- **Vite** - Сборщик и dev-сервер
- **Jest** - Тестирование
- **ESLint** - Линтер для проверки кода
- **Prettier** - Форматирование кода

## Функциональный стиль

Код использует функциональный стиль программирования с `fp-ts`:

```typescript
import * as TE from 'fp-ts/TaskEither';
import { pipe } from 'fp-ts/function';

export const fetchLinks = (): TE.TaskEither<Error, Link[]> =>
  pipe(
    TE.Do,
    TE.bind('apiUrl', () => getApiUrl()),
    TE.bind('headers', () => getAuthHeaders()),
    TE.chain(({ apiUrl, headers }) =>
      TE.tryCatch(
        async () => {
          const response = await fetch(`${apiUrl}/api/links`, { headers });
          // ...
        },
        (error) => new Error(`Failed to fetch links: ${error}`)
      )
    )
  );
```

## CI/CD

Проект использует GitHub Actions для автоматической сборки и публикации:

- **extension-build.yml** - Сборка и тестирование расширения при push/PR
- **extension-release.yml** - Публикация расширения в GitHub Releases при создании релиза

## Авторизация

Расширение поддерживает два режима авторизации:

1. **Keycloak** - Полная авторизация через Keycloak
2. **Guest** - Гостевой режим (работает даже если Keycloak недоступен)

## Публичные ссылки

Пользователи могут создавать публичные ссылки, доступные без авторизации по пути `/u/:name`.
