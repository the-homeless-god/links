---
title: "Установка"
description: "Руководство по установке Links API"
weight: 1
---

# Установка Links API

## Предварительные требования

- [Git](https://git-scm.com/)
- [ASDF](https://asdf-vm.com/) для управления версиями языков
- [Docker](https://www.docker.com/) и [Docker Compose](https://docs.docker.com/compose/)
- [Node.js](https://nodejs.org/) 20+ (для Chrome Extension)

## Клонирование репозитория

```bash
git clone https://github.com/the-homeless-god/links.git
cd links
```

## Установка зависимостей

### Backend (Elixir)

1. Установка версий через ASDF:

```bash
asdf install
```

2. Установка зависимостей Elixir:

```bash
cd elixir_backend
mix deps.get
mix deps.compile
```

### Chrome Extension

```bash
cd extension
npm install
```

## Настройка базы данных

### С SQLite (для разработки)

```bash
cd elixir_backend
mix sqlite.setup
```

### С Cassandra (для production)

```bash
docker-compose up -d cassandra
mix cassandra.setup
```

## Запуск

### Режим разработки

```bash
cd elixir_backend
mix phx.server
```

Сервер будет доступен на `http://localhost:4000`

### Через Docker Compose

```bash
docker-compose up -d
```

## Проверка установки

Откройте в браузере:

- API: `http://localhost:4000/api/links`
- LiveDashboard: `http://localhost:4000/dashboard`
- Метрики: `http://localhost:4000/metrics`

## Следующие шаги

- [Быстрый старт](/getting-started/quick-start/)
- [Настройка авторизации](/getting-started/authentication/)
