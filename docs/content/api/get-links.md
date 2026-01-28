---
title: "Получение ссылок"
description: "Эндпоинты для получения списка ссылок"
weight: 1
---

# Получение ссылок

## Получить все ссылки

**GET** `/api/links`

Возвращает список всех ссылок, доступных текущему пользователю.

### Заголовки

- `X-Guest-Token: guest` (для гостевого режима)
- `Authorization: Bearer YOUR_TOKEN` (для Keycloak)

### Ответ

```json
[
  {
    "id": "720cf4d9-db52-4452-a8ca-91afe15cadd8",
    "name": "github",
    "url": "https://github.com",
    "description": "GitHub",
    "group_id": "dev",
    "public": false,
    "created_at": "2025-04-24T19:56:16.212714Z",
    "updated_at": "2025-04-24T19:56:16.212714Z"
  }
]
```

### Пример с curl

```bash
curl http://localhost:4000/api/links \
  -H "X-Guest-Token: guest"
```

### Фильтрация по группе

Добавьте параметр `group_id`:

```bash
curl "http://localhost:4000/api/links?group_id=dev" \
  -H "X-Guest-Token: guest"
```

## Получить ссылку по ID

**GET** `/api/links/:id`

Возвращает конкретную ссылку по её UUID.

### Параметры

- `id` (path) - UUID ссылки

### Ответ

```json
{
  "id": "720cf4d9-db52-4452-a8ca-91afe15cadd8",
  "name": "github",
  "url": "https://github.com",
  "description": "GitHub",
  "group_id": "dev",
  "public": false,
  "created_at": "2025-04-24T19:56:16.212714Z",
  "updated_at": "2025-04-24T19:56:16.212714Z"
}
```

### Пример с curl

```bash
curl http://localhost:4000/api/links/720cf4d9-db52-4452-a8ca-91afe15cadd8 \
  -H "X-Guest-Token: guest"
```

### Ошибки

**404 Not Found:**
```json
{
  "error": "Link not found"
}
```
