import Config

# Настройки для Phoenix в окружении разработки
config :links_api, LinksApiWeb.Endpoint,
  # Режим отладки для разработки
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [],
  http: [
    # Хост и порт для API
    ip: {0, 0, 0, 0},
    port: 4000
  ]

# Уровень логгирования
config :logger, :console, level: :info

# Разрешаем корс для разработки
config :links_api, cors_origins: ["http://localhost:8000", "http://django_admin:8000"]
