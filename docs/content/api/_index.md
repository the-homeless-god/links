---
title: "API Документация"
description: "Полная документация REST API Links API"
weight: 20
---

# API Документация

## Базовый URL

```
http://localhost:4000/api
```

## Аутентификация

API поддерживает два способа аутентификации:

1. **Guest токен**: `X-Guest-Token: guest`
2. **Keycloak токен**: `Authorization: Bearer YOUR_TOKEN`

## Структура ссылки

```json
{
  "id": "720cf4d9-db52-4452-a8ca-91afe15cadd8",
  "name": "Название ссылки",
  "url": "https://example.com",
  "description": "Описание ссылки",
  "group_id": "dev",
  "public": false,
  "created_at": "2025-04-24T19:56:16.212714Z",
  "updated_at": "2025-04-24T19:56:16.212714Z"
}
```

## Эндпоинты

- [Получение ссылок](/api/get-links/)
- [Создание ссылки](/api/create-link/)
- [Обновление ссылки](/api/update-link/)
- [Удаление ссылки](/api/delete-link/)
- [Публичные ссылки](/api/public-links/)

## Коды ответов

- `200` — успешный запрос
- `201` — ресурс создан
- `400` — неверный запрос
- `401` — не авторизован
- `403` — нет доступа
- `404` — ресурс не найден
- `500` — внутренняя ошибка сервера
