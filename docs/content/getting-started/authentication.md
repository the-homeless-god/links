---
title: "Авторизация"
description: "Настройка Keycloak и гостевого режима"
weight: 3
---

# Авторизация

Links API поддерживает два режима авторизации:

1. **Keycloak** — полная авторизация с ролями и группами
2. **Guest режим** — работа без Keycloak

## Guest режим

Самый простой способ начать работу — использовать гостевой токен:

```bash
curl -H "X-Guest-Token: guest" http://localhost:4000/api/links
```

## Настройка Keycloak

### 1. Запуск Keycloak

```bash
docker-compose up -d keycloak
```

Keycloak будет доступен на `http://localhost:8080`

### 2. Создание Realm

1. Откройте `http://localhost:8080`
2. Войдите с учетными данными `admin:admin`
3. Создайте новый realm `links`

### 3. Создание клиента

1. Перейдите в Clients → Create client
2. Client ID: `elixir-backend`
3. Client protocol: `openid-connect`
4. Access Type: `confidential`
5. Сохраните и скопируйте Secret

### 4. Создание ролей

Создайте следующие роли:

- `links-admin` — полный доступ
- `links-editor` — создание и редактирование
- `links-viewer` — только просмотр

### 5. Создание групп

Создайте группы пользователей, например:

- `team-a`
- `team-b`
- `development`

### 6. Настройка переменных окружения

```bash
export KEYCLOAK_URL=http://localhost:8080
export KEYCLOAK_REALM=links
export KEYCLOAK_CLIENT_ID=elixir-backend
export KEYCLOAK_CLIENT_SECRET=your-secret-here
```

## Использование токена Keycloak

После получения токена из Keycloak:

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:4000/api/links
```

## Разграничение доступа

### Роли

- **links-admin**: полный доступ ко всем ссылкам
- **links-editor**: создание и редактирование ссылок
- **links-viewer**: только просмотр ссылок

### Группы

Пользователи видят только ссылки своих групп. Администраторы видят все ссылки.

## Следующие шаги

- [API документация](/api/)
- [Развертывание](/deployment/)
