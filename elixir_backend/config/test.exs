import Config

# Конфигурация для тестовой среды
config :links_api, LinksApiWeb.Endpoint,
  http: [port: 4002],
  server: false

# Используем SQLite для тестов
config :links_api, :repo_module, LinksApi.SqliteRepo

# Отключаем логирование в тестах
config :logger, level: :warning, backends: [:console]

# Отключаем настройку Keycloak в тестах
config :links_api, :setup_keycloak, false
