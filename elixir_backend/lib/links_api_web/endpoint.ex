defmodule LinksApiWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :links_api

  # Настройка сессий
  @session_options [
    store: :cookie,
    key: "_links_api_key",
    signing_salt: "KWaQn6qj",
    same_site: "Lax"
  ]

  # Конфигурация сокетов в реальном приложении может быть добавлена здесь
  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Обслуживание статических файлов
  plug Plug.Static,
    at: "/",
    from: :links_api,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  # Код плагинов (plug) для обработки запросов
  # Обработка CORS
  plug CORSPlug, origin: ["*"]

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # Плагин для обработки сессий
  plug Plug.Session, @session_options

  plug LinksApiWeb.Router

  # Получение списка разрешенных источников для CORS
  def get_cors_origins do
    Application.get_env(:links_api, :cors_origins, [])
  end
end
