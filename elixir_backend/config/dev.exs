import Config

# Настройки для Phoenix в окружении разработки
config :links_api, LinksApiWeb.Endpoint,
  # Режим отладки для разработки
  debug_errors: true,
  # ВРЕМЕННО отключаем code_reloader, чтобы проверить, не он ли вызывает перезагрузку
  code_reloader: false,
  # Отключаем check_origin для WebSocket - это важно для LiveView
  check_origin: false,
  watchers: [],
  # ПОЛНОСТЬЮ отключаем Live Reload, чтобы избежать проблем с перезагрузкой
  live_reload: false,
  http: [
    # Хост и порт для API
    ip: {0, 0, 0, 0},
    port: 4000
  ],
  # Секретный ключ для шифрования cookie
  secret_key_base: "QUMCdNJUxPbPZDkwHohNa23ljsV3aMXxYGfkJ4+gMedxBsXyi6h++HO24wd/ybYW"

# Указываем, что хотим использовать SQLite репозиторий вместо Cassandra
config :links_api, :repo_module, LinksApi.SqliteRepo

# ПЕРЕОПРЕДЕЛЯЕМ backends для dev - только консоль, чтобы логи точно выводились
# Это переопределяет настройки из config.exs
config :logger, backends: [:console]

# Уровень логгирования - включаем debug для диагностики
config :logger, :console,
  level: :debug,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :method, :request_path]

# Включаем логирование всех запросов Phoenix
config :phoenix, :logger, true

# Включаем логирование LiveView событий
config :phoenix, :live_view,
  debug_heex_annotations: true,
  log: :debug,
  # Добавляем таймауты для предотвращения утечек памяти
  hibernate_after: 15_000

# Разрешаем корс для разработки - добавляем все возможные источники
config :links_api, cors_origins: ["*"]
