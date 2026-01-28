---
title: "Быстрый старт"
description: "Первые шаги после установки Links API"
weight: 2
---

# Быстрый старт

После установки Links API вы можете начать работу с системой.

## Создание первой ссылки

### Через API

```bash
curl -X POST http://localhost:4000/api/links \
  -H "Content-Type: application/json" \
  -H "X-Guest-Token: guest" \
  -d '{
    "name": "github",
    "url": "https://github.com",
    "description": "GitHub"
  }'
```

### Через Chrome Extension

1. Установите расширение из `extension/dist`
2. Откройте popup расширения
3. Нажмите "Добавить ссылку"
4. Заполните форму и сохраните

## Просмотр ссылок

```bash
curl http://localhost:4000/api/links \
  -H "X-Guest-Token: guest"
```

## Использование коротких ссылок

После создания ссылки с именем `github`, она будет доступна по адресу:

```
http://localhost:4000/u/github
```

## Публичные ссылки

Чтобы создать публичную ссылку (доступную без авторизации), установите `public: true`:

```bash
curl -X POST http://localhost:4000/api/links \
  -H "Content-Type: application/json" \
  -H "X-Guest-Token: guest" \
  -d '{
    "name": "public-link",
    "url": "https://example.com",
    "public": true
  }'
```

## Группировка ссылок

Ссылки можно группировать по группам:

```bash
curl -X POST http://localhost:4000/api/links \
  -H "Content-Type: application/json" \
  -H "X-Guest-Token: guest" \
  -d '{
    "name": "dev-tool",
    "url": "https://dev-tool.com",
    "group_id": "development"
  }'
```

## Следующие шаги

- [API документация](/api/)
- [Настройка авторизации](/getting-started/authentication/)
- [Chrome Extension](/extension/)
