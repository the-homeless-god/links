import Config
# alias Telemetry.Metrics

# Базовая конфигурация
config :links_api,
  namespace: LinksApi,
  ecto_repos: [LinksApi.Repo]

# Настройки для приложения Phoenix
config :links_api, LinksApiWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: LinksApiWeb.ErrorHTML, json: LinksApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LinksApi.PubSub,
  live_view: [signing_salt: "links_salt"]

# Настройки для логгера
config :logger,
  backends: [
    :console,
    LoggerJSON.Backend,
    {LoggerFileBackend, :error_log}
  ]

# Настройки для вывода логов в консоль
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :trace_id, :span_id]

# Настройки для файла с логами
config :logger, :error_log,
  path: "log/error.log",
  level: :error,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :trace_id, :span_id, :user_id, :client_ip]

# Настройки для отправки логов в JSON формате
config :logger_json, :backend,
  formatter: LoggerJSON.Formatters.BasicLogger,
  metadata: [:request_id, :trace_id, :span_id, :user_id, :client_ip]

# Настройки для использования JSON
config :phoenix, :json_library, Jason

# Настройки для Backpex
config :backpex, :pubsub_server, LinksApi.PubSub

# Настройки для Cassandra
config :links_api, LinksApi.Repo,
  nodes: [
    "cassandra:9042"
  ],
  keyspace: "links_keyspace",
  pool_size: 10

# Настройки для Keycloak
config :links_api, LinksApi.Auth.KeycloakToken,
  issuer: "http://keycloak:8080/auth/realms/links",
  jwks_url: "http://keycloak:8080/auth/realms/links/protocol/openid-connect/certs",
  client_id: "elixir-backend"

# Конфигурация LiveView
config :links_api, :phoenix_live_view,
  layout: {LinksApiWeb.Layouts, :app}

# Конфигурация Floki для LiveView тестирования
config :links_api, :floki,
  html_parser: Floki.HTMLParser.Html5ever

# Конфигурация Telemetry для метрик
config :links_api, LinksApiWeb.Telemetry,
  metrics: []

# Включение Prometheus метрик
config :links_api, LinksApiWeb.Metrics,
  enabled: true,
  endpoint: LinksApiWeb.Endpoint,
  path: "/metrics"

# Конфигурация esbuild
config :esbuild,
  version: "0.17.11",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Конфигурация Tailwind
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Импорт конфигурации для конкретной среды
import_config "#{config_env()}.exs"
