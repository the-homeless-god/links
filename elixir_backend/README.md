# Links API Backend

Elixir/Phoenix backend для управления короткими ссылками с поддержкой Keycloak авторизации и SQLite базы данных.

## Особенности

- **Elixir/Phoenix** - Современный веб-фреймворк
- **SQLite** - Легковесная база данных
- **Keycloak** - Интеграция с Keycloak для авторизации
- **Guest режим** - Работа без Keycloak
- **Публичные ссылки** - Ссылки доступные без авторизации
- **CI/CD** - Автоматическая сборка и публикация

## Установка

### Требования

- Elixir 1.14+
- Erlang/OTP 25+
- SQLite3

### Установка зависимостей

```bash
mix deps.get
```

### Настройка базы данных

```bash
mix sqlite.setup
```

### Запуск в режиме разработки

```bash
mix run.dev
```

Сервер будет доступен на `http://localhost:4000`

## Сборка релиза

### Локальная сборка

```bash
MIX_ENV=prod mix release
```

### Запуск релиза

```bash
_build/prod/rel/links_api/bin/links_api start
```

Или в интерактивном режиме:

```bash
_build/prod/rel/links_api/bin/links_api daemon
```

### Остановка

```bash
_build/prod/rel/links_api/bin/links_api stop
```

## Конфигурация

### Переменные окружения

- `PORT` - Порт сервера (по умолчанию: 4000)
- `DATABASE_PATH` - Путь к SQLite базе данных (по умолчанию: `priv/db/links.db`)
- `KEYCLOAK_URL` - URL Keycloak сервера
- `KEYCLOAK_REALM` - Realm в Keycloak
- `KEYCLOAK_CLIENT_ID` - Client ID в Keycloak

### Пример запуска с переменными окружения

```bash
PORT=8080 DATABASE_PATH=/path/to/db.sqlite _build/prod/rel/links_api/bin/links_api start
```

## Использование бинарника

После сборки релиза, бинарник можно запустить локально:

1. Скачайте архив для вашей ОС из GitHub Releases
2. Распакуйте архив
3. Запустите:
   - Linux/macOS: `./bin/links_api start`
   - Windows: `bin\links_api.bat start`

Бинарник включает в себя:
- Erlang/OTP runtime
- Все зависимости
- SQLite базу данных (создается автоматически)

## API

### Авторизация

Все API запросы требуют авторизации через:
- Keycloak JWT токен в заголовке `Authorization: Bearer <token>`
- Или Guest токен в заголовке `X-Guest-Token: guest`

### Эндпоинты

- `GET /api/links` - Получить все ссылки пользователя
- `POST /api/links` - Создать новую ссылку
- `GET /api/links/:id` - Получить ссылку по ID
- `PUT /api/links/:id` - Обновить ссылку
- `DELETE /api/links/:id` - Удалить ссылку
- `GET /r/:name` - Редирект по короткой ссылке (требует авторизации)
- `GET /u/:name` - Редирект по публичной ссылке (без авторизации)

## Тестирование

```bash
# Запустить все тесты
mix test

# Запустить тесты с покрытием
mix coveralls.html
```

## CI/CD

Проект использует GitHub Actions для автоматической сборки и публикации:

- **backend-build.yml** - Сборка и тестирование при push/PR
- **backend-release.yml** - Публикация бинарников в GitHub Releases при создании релиза

Бинарники собираются для:
- Linux
- macOS
- Windows

## Разработка

### Структура проекта

```
lib/
├── links_api/          # Основная логика приложения
│   ├── schemas/        # Ecto схемы
│   ├── sqlite_repo.ex  # Репозиторий для работы с SQLite
│   └── auth/           # Модули авторизации
└── links_api_web/      # Web слой
    ├── controllers/    # Контроллеры
    ├── plugs/          # Plugs (авторизация и т.д.)
    └── router.ex       # Маршруты
```

### Миграции

```bash
# Создать миграцию
mix ecto.gen.migration create_links

# Применить миграции
mix ecto.migrate
```

## Лицензия

MIT
