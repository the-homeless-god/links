# Инструкция по настройке автоматической публикации документации

## Что было настроено

✅ Создана структура Hugo проекта в директории `docs/`
✅ Настроена конфигурация Hugo с темой PaperMod
✅ Создана базовая документация:
   - Начало работы (установка, быстрый старт, авторизация)
   - API документация (все эндпоинты)
   - Chrome Extension
   - Развертывание
   - Участие в проекте
✅ Настроен GitHub Actions workflow для автоматической публикации

## Что нужно сделать

### 1. Настроить GitHub Pages

1. Перейдите в Settings → Pages вашего репозитория на GitHub
2. В разделе "Source" выберите **"GitHub Actions"**
3. Сохраните настройки

### 2. Обновить baseURL в config.toml

Откройте `docs/config.toml` и замените:

```toml
baseURL = 'https://YOUR_USERNAME.github.io/links/'
```

На ваш реальный URL. Например:
- Если репозиторий: `https://github.com/username/links`
- То baseURL: `https://username.github.io/links/`

### 3. Добавить тему как submodule (опционально)

Если хотите использовать тему локально:

```bash
cd docs
git submodule add https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod
```

Но это не обязательно - GitHub Actions установит тему автоматически.

### 4. Закоммитить и запушить

```bash
git add docs/ .github/workflows/docs.yml
git commit -m "docs: добавлена документация на Hugo с автоматической публикацией"
git push origin master
```

После пуша workflow автоматически запустится и опубликует документацию.

## Локальная разработка

### Установка Hugo

```bash
# macOS
brew install hugo

# Linux
sudo apt-get install hugo

# Windows
choco install hugo-extended
```

### Запуск локального сервера

```bash
cd docs
hugo server -D
```

Документация будет доступна на `http://localhost:1313`

## Структура документации

```
docs/
├── config.toml          # Конфигурация Hugo
├── content/             # Содержимое документации
│   ├── _index.md        # Главная страница
│   ├── getting-started/  # Начало работы
│   ├── api/             # API документация
│   ├── extension/       # Chrome Extension
│   ├── deployment/       # Развертывание
│   └── contributing/    # Участие в проекте
├── static/              # Статические файлы
└── themes/             # Темы (git submodule)
```

## Добавление новой страницы

1. Создайте `.md` файл в соответствующей директории `content/`
2. Добавьте front matter:
```markdown
---
title: "Название страницы"
description: "Описание"
weight: 10
---
```
3. Напишите содержимое в Markdown
4. При необходимости добавьте в меню в `config.toml`

## Публикация

Документация автоматически публикуется при:
- Пуше в ветку `main` или `master` с изменениями в `docs/`
- Ручном запуске workflow через Actions → "Deploy Documentation"

## Полезные ссылки

- [Hugo документация](https://gohugo.io/documentation/)
- [PaperMod тема](https://github.com/adityatelange/hugo-PaperMod)
- [GitHub Pages](https://docs.github.com/en/pages)
