defmodule LinksApiWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :links_api

  # Конфигурация сокетов в реальном приложении может быть добавлена здесь
  # socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Обслуживание статических файлов
  plug Plug.Static,
    at: "/",
    from: :links_api,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  # Код плагинов (plug) для обработки запросов
  # Обработка CORS
  plug CORSPlug, origin: {LinksApiWeb.Endpoint, :get_cors_origins}

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug LinksApiWeb.Router

  # Получение списка разрешенных источников для CORS
  def get_cors_origins do
    Application.get_env(:links_api, :cors_origins, [])
  end
end
