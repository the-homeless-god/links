.PHONY: install setup test test-coverage format lint docs dev prod help

help: ## Показать эту справку
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Установить зависимости (ASDF, Erlang, Elixir)
	brew install asdf
	asdf plugin add erlang || true
	asdf plugin add elixir || true
	asdf install

setup: ## Настроить проект (установить зависимости для backend и extension)
	cd elixir_backend && mix deps.get
	cd extension && npm install

test: ## Запустить все тесты
	cd elixir_backend && mix test
	cd extension && npm test

test-coverage: ## Запустить тесты с покрытием
	cd elixir_backend && mix test --cover
	cd extension && npm run test:coverage

format: ## Отформатировать код
	cd elixir_backend && mix format
	cd extension && npm run format

lint: ## Проверить код линтерами
	cd elixir_backend && mix credo --strict
	cd extension && npm run lint

docs: ## Запустить локальный сервер документации
	cd docs && hugo server -D

dev: ## Запустить в режиме разработки
	cd elixir_backend && mix phx.server

prod: ## Собрать production релиз
	cd elixir_backend && MIX_ENV=prod mix release

dmg: ## Собрать DMG для macOS (требует собранный релиз)
	@if [ ! -f scripts/build-dmg.sh ]; then \
		echo "Ошибка: скрипт build-dmg.sh не найден"; \
		exit 1; \
	fi
	chmod +x scripts/build-dmg.sh
	./scripts/build-dmg.sh 0.1.0

links: ## Получить список ссылок (требует запущенный сервер)
	curl http://localhost:4000/api/links -H "X-Guest-Token: guest"

clean: ## Очистить временные файлы
	cd elixir_backend && mix clean
	cd extension && rm -rf dist coverage node_modules/.cache
	cd docs && rm -rf public resources/_gen .hugo_build.lock

