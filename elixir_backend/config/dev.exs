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
  ],
  # Секретный ключ для шифрования cookie
  secret_key_base: "QUMCdNJUxPbPZDkwHohNa23ljsV3aMXxYGfkJ4+gMedxBsXyi6h++HO24wd/ybYW"

# Указываем, что хотим использовать SQLite репозиторий вместо Cassandra
config :links_api, :repo_module, LinksApi.SqliteRepo

# Уровень логгирования
config :logger, :console, level: :info

# Отключаем логи в Logstash для локальной разработки
config :logger, backends: [:console]

# Разрешаем корс для разработки - добавляем все возможные источники
config :links_api, cors_origins: ["*"]
