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
      {Phoenix.PubSub, name: LinksApi.PubSub},

    ]

    # Настройка режима супервизора
    opts = [strategy: :one_for_one, name: LinksApi.Supervisor]

    # Запуск супервизора с дочерними процессами
    result = Supervisor.start_link(children, opts)

    # Настройка Keycloak после запуска Supervisor
    setup_keycloak_if_needed()

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

  defp metrics do
    [
      # Phoenix метрики
      {:telemetry_metrics, :counter, [:phoenix, :endpoint, :start], name: "phoenix.endpoint.start.count"},
      {:telemetry_metrics, :counter, [:phoenix, :endpoint, :stop], name: "phoenix.endpoint.stop.count"},
      {:telemetry_metrics, :summary, [:phoenix, :router_dispatch, :start],
        name: "phoenix.router_dispatch.start.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      },

      # Метрики для базы данных
      {:telemetry_metrics, :summary, [:links_api, :repo, :query],
        name: "links_api.repo.query.duration",
        tags: [:query],
        unit: {:native, :millisecond}
      }
    ]
  end
end
