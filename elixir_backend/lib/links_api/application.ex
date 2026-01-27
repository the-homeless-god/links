defmodule LinksApi.Application do
  @moduledoc false
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Определяем какой репозиторий использовать (SQLite или Cassandra)
    repo_module = Application.get_env(:links_api, :repo_module, LinksApi.Repo)
    Logger.info("Используем модуль репозитория: #{repo_module}")

    children = [
      # Запуск Endpoint
      LinksApiWeb.Endpoint,

      # Запуск репозитория (динамически выбираем какой)
      repo_module,

      # Запуск Pubsub для LiveView
      {Phoenix.PubSub, name: LinksApi.PubSub}

      # Запуск :os_mon для LiveDashboard (если доступен)
      # Это требуется для некоторых страниц дашборда
    ]

    # Настройка режима супервизора
    opts = [strategy: :one_for_one, name: LinksApi.Supervisor]

    # Запуск супервизора с дочерними процессами
    result = Supervisor.start_link(children, opts)

    # Настройка Keycloak после запуска Supervisor
    setup_keycloak_if_needed()

    # Настраиваем Telemetry обработчики для диагностики
    setup_telemetry_handlers()

    # Логируем, что приложение запущено - ПРОСТОЙ формат для гарантированного вывода
    IO.puts("=" <> String.duplicate("=", 60))
    IO.puts("🚀 LinksApi application started")
    IO.puts("Environment: #{Mix.env()}")
    IO.puts("Repo: #{repo_module}")
    IO.puts("=" <> String.duplicate("=", 60))

    Logger.info("🚀 LinksApi application started",
      env: Mix.env(),
      repo: repo_module
    )

    result
  end

  # Настраиваем сервер Keycloak если требуется
  defp setup_keycloak_if_needed() do
    setup_keycloak = System.get_env("SETUP_KEYCLOAK", "false")

    if setup_keycloak == "true" do
      Logger.info("Запуск настройки Keycloak...")

      # Запускаем настройку Keycloak в отдельном процессе, чтобы не блокировать запуск приложения
      Task.start(fn ->
        # Ждем некоторое время, чтобы Keycloak успел запуститься
        Logger.info("Ожидание 30 секунд для инициализации Keycloak...")
        :timer.sleep(30_000)

        Logger.info("Начало настройки Keycloak...")

        case LinksApi.Auth.KeycloakToken.setup_realm() do
          :ok ->
            Logger.info("Настройка Keycloak успешно завершена")

          {:error, reason} ->
            Logger.error("Ошибка при настройке Keycloak: #{inspect(reason)}")
        end
      end)
    else
      Logger.debug("Настройка Keycloak пропущена (SETUP_KEYCLOAK=#{setup_keycloak})")
    end
  end

  @impl true
  def config_change(changed, _new, removed) do
    LinksApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Настройка Telemetry обработчиков для диагностики
  defp setup_telemetry_handlers do
    # Логируем все LiveView события для диагностики дашборда, включая ошибки
    :telemetry.attach_many(
      "links-api-dashboard-debug",
      [
        [:phoenix, :live_view, :mount, :start],
        [:phoenix, :live_view, :mount, :stop],
        [:phoenix, :live_view, :handle_params, :start],
        [:phoenix, :live_view, :handle_params, :stop],
        [:phoenix, :live_view, :handle_event, :start],
        [:phoenix, :live_view, :handle_event, :stop],
        [:phoenix, :live_view, :error],
        [:phoenix, :endpoint, :start],
        [:phoenix, :endpoint, :stop]
      ],
      &handle_telemetry_event/4,
      nil
    )
  end

  # Обработчик Telemetry событий для логирования
  defp handle_telemetry_event(event, measurements, metadata, _config) do
    # Логируем все события LiveView, особенно ошибки
    is_dashboard =
      String.contains?(inspect(metadata), "dashboard") or
        (Map.has_key?(metadata, :request_path) and
           String.starts_with?(metadata[:request_path] || "", "/dashboard")) or
        (Map.has_key?(metadata, :view) and
           String.contains?(inspect(metadata[:view]), "Dashboard"))

    if is_dashboard or event == [:phoenix, :live_view, :error] do
      level = if event == [:phoenix, :live_view, :error], do: :error, else: :debug

      IO.puts("🔴 [TELEMETRY] #{inspect(event)}")
      IO.puts("   Measurements: #{inspect(measurements)}")
      IO.puts("   Metadata: #{inspect(metadata)}")

      Logger.log(level, "📊 Telemetry event: #{inspect(event)}",
        event: event,
        measurements: measurements,
        metadata: metadata
      )
    end
  end

  defp metrics do
    [
      # Phoenix метрики
      {:telemetry_metrics, :counter, [:phoenix, :endpoint, :start], name: "phoenix.endpoint.start.count"},
      {:telemetry_metrics, :counter, [:phoenix, :endpoint, :stop], name: "phoenix.endpoint.stop.count"},
      {:telemetry_metrics, :summary, [:phoenix, :router_dispatch, :start],
       name: "phoenix.router_dispatch.start.duration", tags: [:route], unit: {:native, :millisecond}},

      # Метрики для базы данных
      {:telemetry_metrics, :summary, [:links_api, :repo, :query],
       name: "links_api.repo.query.duration", tags: [:query], unit: {:native, :millisecond}}
    ]
  end
end
