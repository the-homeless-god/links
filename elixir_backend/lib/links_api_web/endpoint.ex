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
  socket("/live", Phoenix.LiveView.Socket,
    websocket: [
      connect_info: [session: @session_options],
      # Логируем подключения WebSocket для диагностики
      log: :debug,
      # Отключаем проверку origin для разработки (может вызывать проблемы)
      check_origin: false,
      # Добавляем таймауты для предотвращения утечек памяти
      timeout: 45_000,
      # Закрываем соединение при ошибках
      compress: false
    ]
  )

  # ВРЕМЕННО отключаем longpoll - он вызывает постоянные запросы
  # longpoll: [
  #   connect_info: [session: @session_options],
  #   window_ms: 30_000
  # ]

  # Обслуживание статических файлов
  # НЕ ограничиваем статические файлы для LiveDashboard - он сам обслуживает свои файлы
  plug(Plug.Static,
    at: "/",
    from: :links_api,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)
  )

  # LiveDashboard обслуживает свои статические файлы через свой собственный маршрут

  # Код плагинов (plug) для обработки запросов
  # Обработка CORS - пропускаем для дашборда, чтобы не мешать WebSocket
  plug(:conditional_cors)

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  # Диагностический plug для логирования ВСЕХ запросов
  plug(:log_all_requests)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # Плагин для обработки сессий
  plug(Plug.Session, @session_options)

  # ПОЛНОСТЬЮ отключаем Live Reload - он вызывает постоянные перезагрузки
  # Если нужен Live Reload, можно включить обратно через конфигурацию
  # if Mix.env() == :dev do
  #   plug Phoenix.LiveReloader
  # end

  plug(LinksApiWeb.Router)

  # Диагностический plug для логирования ВСЕХ запросов
  defp log_all_requests(conn, _opts) do
    path = conn.request_path
    method = conn.method

    # Простой вывод для гарантированного логирования
    if String.starts_with?(path, "/dashboard") do
      IO.puts("🔍 [DASHBOARD] #{method} #{path} - #{DateTime.utc_now() |> DateTime.to_iso8601()}")
    end

    require Logger

    Logger.info("📥 Request: #{method} #{path}",
      method: method,
      path: path,
      remote_ip: conn.remote_ip |> :inet.ntoa() |> to_string()
    )

    conn
  end

  # Условный CORS - пропускаем для дашборда
  defp conditional_cors(conn, _opts) do
    if String.starts_with?(conn.request_path, "/dashboard") or
         String.starts_with?(conn.request_path, "/live") do
      conn
    else
      CORSPlug.call(conn, CORSPlug.init(origin: ["*"]))
    end
  end

  # Получение списка разрешенных источников для CORS
  def get_cors_origins do
    Application.get_env(:links_api, :cors_origins, [])
  end
end
