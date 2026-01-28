---
title: "Создание ссылки"
description: "Создание новой ссылки через API"
weight: 2
---

# Создание ссылки

**POST** `/api/links`

Создает новую ссылку.

### Заголовки

- `Content-Type: application/json`
- `X-Guest-Token: guest` (для гостевого режима)
- `Authorization: Bearer YOUR_TOKEN` (для Keycloak)

### Тело запроса

```json
{
  "name": "Новая ссылка",
  "url": "https://example.com",
  "description": "Описание ссылки",
  "group_id": "dev",
  "public": false
}
```

### Поля

- `name` (string, **обязательно**) - название ссылки (уникальное для пользователя)
- `url` (string, **обязательно**) - URL ссылки (должен быть валидным, с протоколом http/https)
- `description` (string, опционально) - описание ссылки
- `group_id` (string, опционально) - идентификатор группы
- `public` (boolean, опционально) - публичная ссылка (доступна без авторизации)
- `id` (string, опционально) - UUID ссылки (генерируется автоматически, если не указан)

### Ответ (201 Created)

```json
{
  "id": "новый-uuid-автоматически",
  "name": "Новая ссылка",
  "url": "https://example.com",
  "description": "Описание ссылки",
  "group_id": "dev",
  "public": false,
  "created_at": "2025-04-24T20:00:00.000000Z",
  "updated_at": "2025-04-24T20:00:00.000000Z"
}
```

### Пример с curl

```bash
curl -X POST http://localhost:4000/api/links \
  -H "Content-Type: application/json" \
  -H "X-Guest-Token: guest" \
  -d '{
    "name": "github",
    "url": "https://github.com",
    "description": "GitHub",
    "group_id": "dev"
  }'
```

### Ошибки

**400 Bad Request:**
```json
{
  "error": "Validation failed",
  "details": {
    "url": ["can't be blank"],
    "name": ["can't be blank"]
  }
}
```

**409 Conflict:**
```json
{
  "error": "Link with this name already exists"
}
```
