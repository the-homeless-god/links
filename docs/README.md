# Документация Links API

Документация построена с помощью [Hugo](https://gohugo.io/) и темы [PaperMod](https://github.com/adityatelange/hugo-PaperMod).

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

### Установка темы

```bash
cd docs
git submodule add https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod
```

### Запуск локального сервера

```bash
cd docs
hugo server -D
```

Документация будет доступна на `http://localhost:1313`

## Структура

- `content/` — содержимое документации (Markdown файлы)
- `static/` — статические файлы (изображения, CSS, JS)
- `config.toml` — конфигурация Hugo
- `themes/PaperMod/` — тема Hugo (git submodule)

## Добавление новой страницы

1. Создайте файл `.md` в соответствующей директории `content/`
2. Добавьте front matter с метаданными
3. Напишите содержимое в Markdown
4. При необходимости добавьте страницу в меню в `config.toml`

## Публикация

Документация автоматически публикуется в GitHub Pages при пуше в ветку `main` или `master`.

Ручной запуск: Actions → "Deploy Documentation" → "Run workflow"
