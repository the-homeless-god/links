---
title: "Обновление ссылки"
description: "Обновление существующей ссылки через API"
weight: 3
---

# Обновление ссылки

**PUT** `/api/links/:id`

Обновляет существующую ссылку.

### Параметры

- `id` (path) - UUID ссылки

### Заголовки

- `Content-Type: application/json`
- `X-Guest-Token: guest` (для гостевого режима)
- `Authorization: Bearer YOUR_TOKEN` (для Keycloak)

### Тело запроса

```json
{
  "name": "Обновленное название",
  "url": "https://new-url.com",
  "description": "Новое описание",
  "group_id": "prod",
  "public": true
}
```

Все поля опциональны — обновляются только указанные.

### Ответ (200 OK)

```json
{
  "id": "720cf4d9-db52-4452-a8ca-91afe15cadd8",
  "name": "Обновленное название",
  "url": "https://new-url.com",
  "description": "Новое описание",
  "group_id": "prod",
  "public": true,
  "created_at": "2025-04-24T19:56:16.212714Z",
  "updated_at": "2025-04-24T20:05:00.000000Z"
}
```

### Пример с curl

```bash
curl -X PUT http://localhost:4000/api/links/720cf4d9-db52-4452-a8ca-91afe15cadd8 \
  -H "Content-Type: application/json" \
  -H "X-Guest-Token: guest" \
  -d '{
    "url": "https://new-url.com",
    "description": "Обновленное описание"
  }'
```

### Ошибки

**404 Not Found:**
```json
{
  "error": "Link not found"
}
```

**403 Forbidden:**
```json
{
  "error": "You don't have permission to update this link"
}
```
