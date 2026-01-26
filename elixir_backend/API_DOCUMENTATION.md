# API Документация - Управление ссылками

## Базовый URL
```
http://localhost:4000/api
```

## Структура ссылки

```json
{
  "id": "720cf4d9-db52-4452-a8ca-91afe15cadd8",
  "name": "Название ссылки",
  "url": "https://example.com",
  "description": "Описание ссылки",
  "group_id": "dev",
  "created_at": "2025-04-24T19:56:16.212714Z",
  "updated_at": "2025-04-24T19:56:16.212714Z"
}
```

### Поля:
- `id` (string, UUID) - уникальный идентификатор (генерируется автоматически, если не указан)
- `name` (string, **обязательно**) - название ссылки
- `url` (string, **обязательно**) - URL ссылки (должен быть валидным, с протоколом http/https)
- `description` (string, опционально) - описание ссылки
- `group_id` (string, опционально) - идентификатор группы (например: "dev", "prod", "personal")
- `created_at` (datetime) - дата создания (автоматически)
- `updated_at` (datetime) - дата обновления (автоматически)

---

## Эндпоинты

### 1. Получить все ссылки

**GET** `/api/links`

**Ответ:**
```json
[
  {
    "id": "720cf4d9-db52-4452-a8ca-91afe15cadd8",
    "name": "gh",
    "url": "https://github.com/phoenixframework/phoenix_live_reload",
    "description": "g",
    "group_id": "dev",
    "created_at": "2025-04-24T19:56:16.212714Z",
    "updated_at": "2025-04-24T19:56:16.212714Z"
  }
]
```

**Пример с curl:**
```bash
curl http://localhost:4000/api/links
```

---

### 2. Получить ссылку по ID

**GET** `/api/links/:id`

**Параметры:**
- `id` (path) - UUID ссылки

**Ответ:**
```json
{
  "id": "720cf4d9-db52-4452-a8ca-91afe15cadd8",
  "name": "gh",
  "url": "https://github.com/phoenixframework/phoenix_live_reload",
  "description": "g",
  "group_id": "dev",
  "created_at": "2025-04-24T19:56:16.212714Z",
  "updated_at": "2025-04-24T19:56:16.212714Z"
}
```

**Пример с curl:**
```bash
curl http://localhost:4000/api/links/720cf4d9-db52-4452-a8ca-91afe15cadd8
```

**Ошибка 404:**
```json
{
  "error": "Link not found"
}
```

---

### 3. Создать новую ссылку

**POST** `/api/links`

**Тело запроса:**
```json
{
  "name": "Новая ссылка",
  "url": "https://example.com",
  "description": "Описание",
  "group_id": "dev"
}
```

**Ответ (201 Created):**
```json
{
  "id": "новый-uuid-автоматически",
  "name": "Новая ссылка",
  "url": "https://example.com",
  "description": "Описание",
  "group_id": "dev",
  "created_at": "2025-04-24T20:00:00.000000Z",
  "updated_at": "2025-04-24T20:00:00.000000Z"
}
```

**Пример с curl:**
```bash
curl -X POST http://localhost:4000/api/links \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Новая ссылка",
    "url": "https://example.com",
    "description": "Описание",
    "group_id": "dev"
  }'
```

**Минимальный запрос (только обязательные поля):**
```bash
curl -X POST http://localhost:4000/api/links \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Минимальная ссылка",
    "url": "https://example.com"
  }'
```

---

### 4. Обновить ссылку

**PUT** `/api/links/:id`

**Параметры:**
- `id` (path) - UUID ссылки

**Тело запроса:**
```json
{
  "name": "Обновленное название",
  "url": "https://new-url.com",
  "description": "Новое описание",
  "group_id": "prod"
}
```

**Ответ:**
```json
{
  "id": "720cf4d9-db52-4452-a8ca-91afe15cadd8",
  "name": "Обновленное название",
  "url": "https://new-url.com",
  "description": "Новое описание",
  "group_id": "prod",
  "created_at": "2025-04-24T19:56:16.212714Z",
  "updated_at": "2025-04-24T20:05:00.000000Z"
}
```

**Пример с curl:**
```bash
curl -X PUT http://localhost:4000/api/links/720cf4d9-db52-4452-a8ca-91afe15cadd8 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Обновленное название",
    "url": "https://new-url.com"
  }'
```

**Ошибка 404:**
```json
{
  "error": "Link not found"
}
```

---

### 5. Удалить ссылку

**DELETE** `/api/links/:id`

**Параметры:**
- `id` (path) - UUID ссылки

**Ответ (204 No Content):**
```json
{}
```

**Пример с curl:**
```bash
curl -X DELETE http://localhost:4000/api/links/720cf4d9-db52-4452-a8ca-91afe15cadd8
```

**Ошибка 404:**
```json
{
  "error": "Link not found"
}
```

---

### 6. Получить ссылки по группе

**GET** `/api/groups/:group_id/links`

**Параметры:**
- `group_id` (path) - идентификатор группы

**Ответ:**
```json
[
  {
    "id": "720cf4d9-db52-4452-a8ca-91afe15cadd8",
    "name": "gh",
    "url": "https://github.com/phoenixframework/phoenix_live_reload",
    "description": "g",
    "group_id": "dev",
    "created_at": "2025-04-24T19:56:16.212714Z",
    "updated_at": "2025-04-24T19:56:16.212714Z"
  }
]
```

**Пример с curl:**
```bash
curl http://localhost:4000/api/groups/dev/links
```

---

## Публичный редирект

### Редирект по короткой ссылке (по имени)

**GET** `/r/:name`

**Параметры:**
- `name` (path) - название ссылки (поле `name`)

**Действие:** Редирект на URL ссылки (302 Redirect)

**Пример:**
```
http://localhost:4000/r/gh
```

Перенаправит на URL ссылки с названием "gh".

**Примечание:** Если найдено несколько ссылок с одинаковым названием, будет использована первая найденная.

---

## Примеры использования

### Создание ссылки с помощью JavaScript (fetch)

```javascript
const createLink = async () => {
  const response = await fetch('http://localhost:4000/api/links', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      name: 'GitHub',
      url: 'https://github.com',
      description: 'GitHub repository',
      group_id: 'dev'
    })
  });
  
  const link = await response.json();
  console.log('Создана ссылка:', link);
};
```

### Обновление ссылки с помощью Python (requests)

```python
import requests

url = 'http://localhost:4000/api/links/720cf4d9-db52-4452-a8ca-91afe15cadd8'
data = {
    'name': 'Обновленное название',
    'url': 'https://new-url.com',
    'description': 'Новое описание'
}

response = requests.put(url, json=data)
print(response.json())
```

### Получение всех ссылок с помощью curl

```bash
# Получить все ссылки
curl http://localhost:4000/api/links

# Получить ссылки группы "dev"
curl http://localhost:4000/api/groups/dev/links

# Получить конкретную ссылку
curl http://localhost:4000/api/links/720cf4d9-db52-4452-a8ca-91afe15cadd8
```

---

## Коды ответов

- `200 OK` - успешный запрос
- `201 Created` - ресурс успешно создан
- `204 No Content` - успешное удаление
- `404 Not Found` - ресурс не найден
- `500 Internal Server Error` - ошибка сервера

---

## Валидация

### Обязательные поля:
- `name` - не может быть пустым
- `url` - должен быть валидным URL с протоколом (http/https)

### Правила валидации URL:
- URL должен содержать схему (http:// или https://)
- URL должен содержать хост (домен)

### Примеры невалидных URL:
- `example.com` ❌ (нет схемы)
- `http://` ❌ (нет хоста)
- `ftp://example.com` ✅ (валидный, но может не поддерживаться)

---

## Примечания

1. **ID генерируется автоматически**: Если не указать `id` при создании, он будет сгенерирован автоматически (UUID v4)

2. **group_id опционален**: Если не указать `group_id`, он будет установлен в пустую строку `""`

3. **Даты автоматически**: `created_at` и `updated_at` устанавливаются автоматически

4. **Аутентификация**: В текущей версии аутентификация временно отключена для тестирования
