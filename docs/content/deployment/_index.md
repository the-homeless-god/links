---
title: "Развертывание"
description: "Руководство по развертыванию Links API в production"
weight: 40
---

# Развертывание

## Сборка DMG для macOS

Для создания DMG установщика для macOS используйте скрипт:

```bash
# Сначала соберите релиз
cd elixir_backend
MIX_ENV=prod mix release

# Затем соберите DMG
cd ..
./scripts/build-dmg.sh 0.1.0
```

DMG файл будет создан в корне проекта. Скрипт автоматически:
- Распакует релиз приложения
- Соберет расширение Chrome
- Создаст DMG с удобной структурой
- Добавит postinstall скрипт с инструкциями

**Требования для сборки DMG:**
- macOS
- `create-dmg` (устанавливается автоматически через Homebrew)
- Собранный релиз приложения
- Собранное расширение Chrome

## Production сборка

### Backend

```bash
cd elixir_backend
MIX_ENV=prod mix release
```

Релиз будет создан в `_build/prod/rel/links_api/`

### Запуск релиза

```bash
_build/prod/rel/links_api/bin/links_api start
```

Или в интерактивном режиме:

```bash
_build/prod/rel/links_api/bin/links_api daemon
```

## Docker

### Сборка образа

```bash
cd elixir_backend
docker build -t links-api:latest .
```

### Запуск контейнера

```bash
docker run -d \
  -p 4000:4000 \
  -e PORT=4000 \
  -e DATABASE_PATH=/app/priv/db/links.db \
  links-api:latest
```

## Docker Compose

Полный стек с Keycloak и ELK:

```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Переменные окружения

### Обязательные

- `PORT` — порт сервера (по умолчанию: 4000)

### Опциональные

- `DATABASE_PATH` — путь к SQLite базе данных
- `KEYCLOAK_URL` — URL Keycloak сервера
- `KEYCLOAK_REALM` — Realm в Keycloak
- `KEYCLOAK_CLIENT_ID` — Client ID в Keycloak
- `KEYCLOAK_CLIENT_SECRET` — Client Secret в Keycloak
- `LOGSTASH_HOST` — хост Logstash для логирования
- `LOGSTASH_PORT` — порт Logstash

## Мониторинг

- **LiveDashboard**: `http://your-server:4000/dashboard`
- **Prometheus метрики**: `http://your-server:4000/metrics`
- **Kibana**: `http://your-server:5601` (если используется ELK)

## Безопасность

1. Измените секретные ключи в production
2. Настройте HTTPS через reverse proxy (nginx, Caddy)
3. Ограничьте доступ к метрикам и dashboard
4. Используйте Keycloak для авторизации в production

## Масштабирование

Для горизонтального масштабирования:

1. Используйте Cassandra вместо SQLite
2. Настройте load balancer
3. Используйте общий storage для базы данных
