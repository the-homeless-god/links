# Links API

Высокопроизводительная система управления ссылками с Chrome расширением, разграничением прав доступа и централизованным логированием.

[![Backend Coverage](https://codecov.io/gh/the-homeless-god/links/branch/master/graph/badge.svg?flag=backend)](https://codecov.io/gh/the-homeless-god/links)
[![Extension Coverage](https://codecov.io/gh/the-homeless-god/links/branch/master/graph/badge.svg?flag=extension)](https://codecov.io/gh/the-homeless-god/links)
[![CI](https://github.com/the-homeless-god/links/workflows/CI/badge.svg)](https://github.com/the-homeless-god/links/actions)

📚 **[Документация](https://the-homeless-god.github.io/links/)** | [API Reference](https://the-homeless-god.github.io/links/api/) | [Chrome Extension](https://the-homeless-god.github.io/links/extension/) | [Releases](https://github.com/the-homeless-god/links/releases)

## Быстрый старт

### Клонирование и установка

```bash
# Клонировать репозиторий
git clone https://github.com/the-homeless-god/links.git
cd links

# Установить зависимости
asdf install  # Elixir/Erlang версии
cd elixir_backend && mix deps.get
cd ../extension && npm install

# Настроить базу данных (SQLite для разработки)
cd ../elixir_backend
mix sqlite.setup

# Запустить сервер
mix phx.server
```

Сервер будет доступен на `http://localhost:4000`

### Первое использование

**Создать ссылку через API:**
   ```bash
curl -X POST http://localhost:4000/api/links \
  -H "Content-Type: application/json" \
  -H "X-Guest-Token: guest" \
  -d '{"name": "github", "url": "https://github.com", "description": "GitHub"}'
```

**Просмотреть ссылки:**
   ```bash
curl http://localhost:4000/api/links -H "X-Guest-Token: guest"
```

**Использовать короткую ссылку:**
```
http://localhost:4000/u/github
```

## Установка

### macOS (DMG)

1. Скачайте [DMG из релизов](https://github.com/the-homeless-god/links/releases)
2. Откройте DMG и перетащите `Links API.app` в Applications
3. Установите Chrome Extension из папки в DMG
4. Запустите приложение

### Из исходников

**Требования:**
- Git, ASDF, Docker, Node.js 20+

**Установка:**
```bash
git clone https://github.com/the-homeless-god/links.git
cd links
asdf install
cd elixir_backend && mix deps.get
cd ../extension && npm install
```

**Запуск:**
```bash
# С SQLite (разработка)
cd elixir_backend
mix sqlite.setup
mix phx.server

# Или через Docker
docker-compose up -d
```

Подробнее: [Документация по установке](https://the-homeless-god.github.io/links/getting-started/installation/)

## Основные возможности

- 🚀 **Chrome Extension** — управление ссылками прямо из браузера
- 🔗 **Короткие ссылки** — редирект по `/u/:name` (аналог bit.ly)
- 👥 **Разграничение доступа** — роли и группы пользователей через Keycloak
- 🌐 **Публичные ссылки** — доступ без авторизации
- 📊 **Логирование и мониторинг** — ELK Stack, Prometheus, LiveDashboard
- 🎯 **Гостевой режим** — работа без Keycloak

## Технологии

- **Backend**: Elixir 1.16+, Phoenix 1.7+
- **Extension**: TypeScript, Vite
- **База данных**: SQLite (dev) / Apache Cassandra (prod)
- **Аутентификация**: Keycloak 21+ (опционально)
- **CI/CD**: GitHub Actions, semantic-release

## Разработка

### Тестирование

```bash
# Backend
cd elixir_backend
mix test
mix test --cover

# Extension
cd extension
npm test
npm run test:coverage
```

### Проверка качества

```bash
# Backend
mix format
mix credo
mix dialyzer

# Extension
npm run format
npm run lint
npm run check-types
```

### Полезные команды

```bash
# Запуск в режиме разработки
cd elixir_backend && mix phx.server

# Сборка production релиза
MIX_ENV=prod mix release

# Сборка DMG (macOS)
./scripts/build-dmg.sh 0.1.0

# Просмотр ссылок через API
curl http://localhost:4000/api/links -H "X-Guest-Token: guest"
```

## API Примеры

```bash
# Создать ссылку
curl -X POST http://localhost:4000/api/links \
  -H "Content-Type: application/json" \
  -H "X-Guest-Token: guest" \
  -d '{"name": "example", "url": "https://example.com"}'

# Обновить ссылку
curl -X PUT http://localhost:4000/api/links/example \
  -H "Content-Type: application/json" \
  -H "X-Guest-Token: guest" \
  -d '{"url": "https://new-url.com"}'

# Удалить ссылку
curl -X DELETE http://localhost:4000/api/links/example \
  -H "X-Guest-Token: guest"

# Создать публичную ссылку
curl -X POST http://localhost:4000/api/links \
  -H "Content-Type: application/json" \
  -H "X-Guest-Token: guest" \
  -d '{"name": "public", "url": "https://example.com", "public": true}'
```

Полная документация API: [API Reference](https://the-homeless-god.github.io/links/api/)

## Мониторинг

- **API**: `http://localhost:4000/api/links`
- **LiveDashboard**: `http://localhost:4000/dashboard`
- **Метрики Prometheus**: `http://localhost:4000/metrics`
- **Kibana** (если используется ELK): `http://localhost:5601`

## Контрибьютинг

1. Форкните репозиторий: `git clone https://github.com/the-homeless-god/links.git`
2. Создайте ветку: `git checkout -b feature/amazing-feature`
3. Следуйте [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat(api): новая функциональность` → minor релиз
   - `fix(auth): исправление бага` → patch релиз
   - `docs: обновление документации` → без релиза
4. Отправьте PR — все проверки CI/CD запустятся автоматически

**Примечание:** Проект использует [semantic-release](https://github.com/semantic-release/semantic-release) для автоматической генерации changelog и релизов.

## Полезные ссылки

- 📖 [Полная документация](https://the-homeless-god.github.io/links/)
- 🔌 [Chrome Extension](https://the-homeless-god.github.io/links/extension/)
- 📦 [Releases](https://github.com/the-homeless-god/links/releases)
- 📝 [CHANGELOG](CHANGELOG.md)
- 📄 [LICENSE](LICENSE)

## Лицензия

BSD 3-Clause с ограничением на коммерческое использование.

**Требования:**
- Обязательное указание автора: **Marat Zimnurov (zimtir@mail.ru)**
- Коммерческое использование требует письменного согласования

См. [LICENSE](LICENSE) для подробностей.
