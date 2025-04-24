# Сервис управления ссылками

Высокопроизводительная система для управления ссылками с реактивным интерфейсом на Phoenix LiveView, разграничением прав доступа через Keycloak и централизованным логированием в ELK Stack.

## Обзор системы

Система предоставляет полный набор функций для создания, редактирования и управления ссылками:

- **Административный интерфейс** на Phoenix LiveView + Backpex
- **Группировка ссылок** по категориям/группам
- **Разграничение доступа** по ролям и группам пользователей
- **Короткие ссылки** с возможностью редиректа (аналог bit.ly)
- **Централизованное логирование** действий пользователей
- **Метрики и мониторинг** производительности

## Структура проекта

```
.
├── .tool-versions                # Конфигурация ASDF для локальной разработки
├── elixir_backend/              # Основное приложение Elixir/Phoenix
│   ├── lib/                     # Код приложения
│   │   ├── links_api/           # Бизнес-логика, репозитории, схемы
│   │   │   ├── auth/            # Модули аутентификации и авторизации
│   │   │   ├── repo/            # Взаимодействие с Cassandra
│   │   │   ├── schemas/         # Схемы данных (Ecto)
│   │   │   ├── telemetry.ex     # Настройка телеметрии и метрик
│   │   │   └── system_metrics.ex # Сбор системных метрик
│   │   └── links_api_web/       # Веб-слой (контроллеры, маршруты, LiveView)
│   │       ├── controllers/     # API и редирект контроллеры 
│   │       ├── live/            # LiveView компоненты и ресурсы
│   │       ├── components/      # Многоразовые UI компоненты
│   │       └── router.ex        # Маршрутизация запросов
│   ├── test/                    # Тесты
│   │   ├── links_api/           # Юнит-тесты бизнес-логики
│   │   ├── links_api_web/       # Тесты веб-слоя
│   │   ├── integration/         # Интеграционные тесты
│   │   ├── load/                # Нагрузочные тесты
│   │   └── support/             # Вспомогательные модули для тестов
│   ├── config/                  # Конфигурация приложения
│   ├── priv/                    # Ресурсы приложения
│   └── mix.exs                  # Зависимости и настройки проекта
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

- **Бэкенд**: Elixir 1.14+, Phoenix 1.7+
- **Админ-интерфейс**: Phoenix LiveView, Backpex
- **База данных**: Apache Cassandra 4+
- **Аутентификация**: Keycloak 21+
- **Логирование**: ELK Stack (Elasticsearch, Logstash, Kibana)
- **Метрики**: Prometheus, Telemetry
- **Тестирование**: ExUnit, Wallaby для интеграционных тестов, k6 для нагрузочных
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

4. Подготовка базы данных Cassandra:

   ```bash
   docker-compose up -d cassandra
   mix cassandra.setup
   ```

### Запуск для разработки

Локальный запуск приложения без Docker:

```bash
cd elixir_backend
mix phx.server
```

Или полный запуск всей системы через Docker Compose:

```bash
docker-compose up -d
```

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

## Контрибьютинг

1. Форкните репозиторий
2. Создайте ветку для вашей функциональности (`git checkout -b feature/amazing-feature`)
3. Закоммитьте изменения (`git commit -m 'Add some amazing feature'`)
4. Отправьте ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

## Лицензия

MIT
