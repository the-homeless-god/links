# Сервис управления ссылками

Высокопроизводительная система для управления ссылками с Chrome расширением для удобного доступа, разграничением прав доступа через Keycloak (с поддержкой гостевого режима) и централизованным логированием в ELK Stack.

## Обзор системы

Система предоставляет полный набор функций для создания, редактирования и управления ссылками:

- **Chrome Extension** — удобный интерфейс для управления ссылками прямо из браузера, написанный на TypeScript
- **REST API** — полнофункциональный API на Elixir/Phoenix для работы со ссылками
- **Группировка ссылок** по категориям/группам
- **Разграничение доступа** по ролям и группам пользователей (с поддержкой гостевого режима)
- **Короткие ссылки** с возможностью редиректа (аналог bit.ly)
- **Публичные ссылки** — доступные без авторизации по пути `/u/:name`
- **Централизованное логирование** действий пользователей
- **Метрики и мониторинг** производительности

## Структура проекта

```text
.
├── .tool-versions                # Конфигурация ASDF для локальной разработки
├── .github/workflows/            # CI/CD пайплайны (GitHub Actions)
│   ├── ci.yml                   # Общий CI пайплайн для PR
│   ├── backend-build.yml         # Сборка и тестирование backend
│   ├── backend-release.yml       # Релиз backend
│   ├── extension-build.yml       # Сборка и тестирование extension
│   └── extension-release.yml    # Релиз extension
├── elixir_backend/              # Основное приложение Elixir/Phoenix
│   ├── lib/                     # Код приложения
│   │   ├── links_api/           # Бизнес-логика, репозитории, схемы
│   │   │   ├── auth/            # Модули аутентификации и авторизации
│   │   │   ├── repo.ex          # Адаптер репозитория
│   │   │   ├── sqlite_repo.ex   # Репозиторий для SQLite
│   │   │   ├── schemas/         # Схемы данных (Ecto)
│   │   │   ├── telemetry.ex     # Настройка телеметрии и метрик
│   │   │   └── system_metrics.ex # Сбор системных метрик
│   │   └── links_api_web/       # Веб-слой (контроллеры, маршруты)
│   │       ├── controllers/      # API и редирект контроллеры 
│   │       └── router.ex         # Маршрутизация запросов
│   ├── test/                    # Тесты
│   │   ├── links_api/           # Юнит-тесты бизнес-логики
│   │   ├── links_api_web/       # Тесты веб-слоя
│   │   ├── integration/         # Интеграционные тесты
│   │   ├── load/                # Нагрузочные тесты
│   │   └── support/             # Вспомогательные модули для тестов
│   ├── config/                  # Конфигурация приложения
│   ├── priv/                    # Ресурсы приложения
│   └── mix.exs                  # Зависимости и настройки проекта
├── extension/                   # Chrome Extension на TypeScript
│   ├── src/                     # Исходный код
│   │   ├── auth/                # Авторизация (Keycloak и Guest)
│   │   ├── background/          # Background service worker
│   │   ├── content/             # Content script
│   │   ├── popup/                # Основной UI расширения
│   │   ├── services/             # API и storage сервисы
│   │   ├── utils/                # Утилиты
│   │   └── tests/                # Тесты
│   ├── dist/                     # Собранные файлы (после сборки)
│   ├── manifest.json             # Манифест расширения
│   └── package.json              # Зависимости и скрипты
├── logstash/                    # Конфигурация системы логирования
│   ├── config/                  # Основные настройки Logstash
│   └── pipeline/                # Пайплайны для обработки логов
├── diagrams/                    # Диаграммы архитектуры
│   ├── c4_component_diagram.puml # C4 модель системы
│   ├── sequence_diagram.puml    # Диаграмма последовательности
│   └── description.md           # Описание архитектуры
└── docker-compose.yml           # Конфигурация Docker для запуска всей системы
```

## Технологический стек

- **Бэкенд**: Elixir 1.16+, Phoenix 1.7+
- **Chrome Extension**: TypeScript, Vite, fp-ts (функциональное программирование)
- **База данных**: Apache Cassandra 4+ (production) или SQLite (локальная разработка)
- **Аутентификация**: Keycloak 21+ (с поддержкой гостевого режима)
- **Логирование**: ELK Stack (Elasticsearch, Logstash, Kibana)
- **Метрики**: Prometheus, Telemetry
- **Тестирование**:
  - Backend: ExUnit, Wallaby для интеграционных тестов, k6 для нагрузочных
  - Extension: Jest для unit-тестов
- **Качество кода**:
  - Backend: Credo (линтер), Dialyzer (статический анализ), mix format
  - Extension: ESLint, Prettier, TypeScript
- **CI/CD**: GitHub Actions с автоматической проверкой качества, тестированием и релизами
- **Контейнеризация**: Docker, Docker Compose

## Подготовка к разработке

### Предварительные требования

- [Git](https://git-scm.com/)
- [ASDF](https://asdf-vm.com/) для управления версиями языков
- [Docker](https://www.docker.com/) и [Docker Compose](https://docs.docker.com/compose/)

### Настройка локальной среды

1. Клонирование репозитория:

   ```bash
   git clone <репозиторий>
   cd <директория-проекта>
   ```

2. Установка всех необходимых версий с помощью ASDF:

   ```bash
   asdf install
   ```

   Это установит правильную версию Elixir и Erlang в соответствии с файлом `.tool-versions`.

3. Установка зависимостей Elixir:

   ```bash
   cd elixir_backend
   mix deps.get
   ```

### Запуск для разработки

#### С Cassandra

Подготовка базы данных Cassandra:

```bash
docker-compose up -d cassandra
mix cassandra.setup
```

Локальный запуск приложения без Docker:

```bash
cd elixir_backend
mix phx.server
```

Или полный запуск всей системы через Docker Compose:

```bash
docker-compose up -d
```

#### С SQLite (без внешних зависимостей)

Для локальной разработки без необходимости запускать Cassandra, Keycloak и ELK Stack, можно использовать SQLite:

1. Подготовка SQLite базы данных:

   ```bash
   cd elixir_backend
   mix sqlite.setup
   ```

2. Запуск приложения с SQLite:

   ```bash
   cd elixir_backend
   MIX_ENV=dev mix phx.server
   ```

   Приложение будет использовать SQLite вместо Cassandra для хранения данных, и не будет требовать запуска других сервисов.

3. Или через Docker Compose:

   ```bash
   docker-compose up -d elixir_backend_lite
   ```

   Это запустит только контейнер с Elixir, используя SQLite для хранения данных.

## Запуск в производственной среде

### С использованием Docker

1. Настройка переменных окружения:

   ```bash
   cp .env.example .env
   # Отредактируйте .env для вашей среды
   ```

2. Запуск всех компонентов:

   ```bash
   docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
   ```

### Настройка Keycloak

1. Откройте интерфейс Keycloak по адресу `http://localhost:8080`
2. Войдите с учетными данными `admin:admin` (смените в производственной среде)
3. Создайте realm `links`
4. Создайте клиент `elixir-backend`
5. Создайте роли: `links-admin`, `links-editor`, `links-viewer`
6. Создайте группы пользователей, например: `team-a`, `team-b`
7. Создайте тестовых пользователей и назначьте им роли и группы

## Тестирование

Система поддерживает несколько уровней тестирования:

### Юнит-тесты

```bash
cd elixir_backend
mix test
```

### Тесты с покрытием

```bash
mix test --cover
mix coveralls.html  # Генерация HTML-отчета о покрытии
```

После этого HTML-отчет будет доступен в `elixir_backend/cover/excoveralls.html`.

### Интеграционные тесты

```bash
# Убедитесь, что Cassandra и Keycloak запущены
mix test.integration
```

### Нагрузочные тесты

```bash
cd elixir_backend/test/load
k6 run load_test.js
```

## Проверка качества кода

```bash
mix format         # Форматирование кода
mix dialyzer       # Статический анализ типов
mix credo          # Линтер кода
```

## Разграничение прав доступа

Система поддерживает следующие типы пользователей:

1. **Администраторы** (роль `links-admin`) - имеют полный доступ ко всем ссылкам
2. **Редакторы** (роль `links-editor`) - могут создавать и редактировать ссылки
3. **Просмотрщики** (роль `links-viewer`) - могут только просматривать ссылки

Дополнительно, доступ к ссылкам ограничивается на уровне групп:

- Каждый пользователь входит в одну или несколько групп
- Ссылки могут быть привязаны к определенной группе
- Пользователь видит только ссылки, принадлежащие его группам, либо общедоступные ссылки

### Режимы авторизации

Система поддерживает два режима работы:

1. **Keycloak** - полная авторизация через Keycloak с поддержкой ролей и групп
2. **Guest режим** - работа без Keycloak, используя гостевой токен (`X-Guest-Token: guest`)

### Публичные ссылки

Пользователи могут создавать публичные ссылки, доступные без авторизации по пути `/u/:name`. Такие ссылки доступны всем пользователям, даже без токена авторизации.

## Мониторинг и логи

- **Kibana**: Доступна по адресу `http://localhost:5601` - анализ логов, дашборды и визуализация
- **Prometheus метрики**: Доступны по адресу `http://localhost:4000/metrics` - сырые метрики производительности
- **LiveDashboard**: Доступен по адресу `http://localhost:4000/dashboard` - мониторинг Elixir приложения

## Решение проблем

### Проблемы с Cassandra

1. Проверьте статус контейнера:

   ```bash
   docker-compose ps cassandra
   ```

2. Проверьте логи:

   ```bash
   docker-compose logs cassandra
   ```

3. Проверьте подключение:

   ```bash
   docker-compose exec cassandra cqlsh -u cassandra -p cassandra
   ```

### Проблемы с Keycloak

1. Проверьте статус контейнера:

   ```bash
   docker-compose ps keycloak
   ```

2. Проверьте логи:

   ```bash
   docker-compose logs keycloak
   ```

## CI/CD

Проект использует GitHub Actions для автоматической проверки качества кода, тестирования и релизов:

### Проверки на Pull Request

При создании PR автоматически запускаются следующие проверки:

**Backend:**

- Проверка форматирования кода (`mix format --check-formatted`)
- Линтер (`mix credo --strict`)
- Статический анализ типов (`mix dialyzer`)
- Юнит-тесты (`mix test`)
- Тесты с покрытием (`mix test --cover`)

**Extension:**

- Проверка форматирования (`prettier --check`)
- Линтер (`eslint`)
- Проверка типов TypeScript (`tsc --noEmit`)
- Тесты с покрытием (`jest --coverage`)
- Сборка (`npm run build`)

Все проверки должны пройти успешно перед мерджем PR.

### Релизы

При создании релиза автоматически:

- Собираются бинарники backend для Linux, macOS и Windows
- Собирается Chrome Extension
- Все артефакты загружаются в GitHub Releases

## Контрибьютинг

1. Форкните репозиторий
2. Создайте ветку для вашей функциональности (`git checkout -b feature/amazing-feature`)
3. Убедитесь, что код отформатирован и проходит все проверки:
   - Backend: `mix format`, `mix credo`, `mix test`
   - Extension: `npm run format`, `npm run lint`, `npm test`
4. Закоммитьте изменения (`git commit -m 'Add some amazing feature'`)
5. Отправьте ветку (`git push origin feature/amazing-feature`)
6. Откройте Pull Request — все проверки CI/CD запустятся автоматически

## Лицензия

MIT
