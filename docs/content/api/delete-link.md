---
title: "Удаление ссылки"
description: "Удаление ссылки через API"
weight: 4
---

# Удаление ссылки

**DELETE** `/api/links/:id`

Удаляет ссылку по её UUID.

### Параметры

- `id` (path) - UUID ссылки

### Заголовки

- `X-Guest-Token: guest` (для гостевого режима)
- `Authorization: Bearer YOUR_TOKEN` (для Keycloak)

### Ответ (200 OK)

```json
{
  "message": "Link deleted successfully"
}
```

### Пример с curl

```bash
curl -X DELETE http://localhost:4000/api/links/720cf4d9-db52-4452-a8ca-91afe15cadd8 \
  -H "X-Guest-Token: guest"
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
  "error": "You don't have permission to delete this link"
}
```
