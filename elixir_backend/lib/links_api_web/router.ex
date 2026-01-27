defmodule LinksApiWeb.Router do
  use Phoenix.Router
  import Plug.Conn
  import Phoenix.Controller

  # Упрощенный pipeline для редиректов (только для /r/:name)
  pipeline :browser do
    plug :accepts, ["html"]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Pipeline для аутентификации (поддерживает Keycloak и guest режим)
  pipeline :authenticated do
    plug LinksApiWeb.AuthPlug
  end

  # Маршрут для редиректа по короткой ссылке
  scope "/", LinksApiWeb do
    pipe_through :browser

    # Маршрут для редиректа на публичную ссылку по имени
    get "/r/:name", RedirectController, :redirect_by_name
  end

  # Публичные API маршруты (без аутентификации)
  scope "/api", LinksApiWeb do
    pipe_through :api

    get "/health", HealthController, :health
  end

  # API маршруты с аутентификацией
  scope "/api", LinksApiWeb do
    pipe_through [:api, :authenticated]

    # Маршруты для ссылок
    get "/links", LinkController, :index
    get "/links/:id", LinkController, :show
    post "/links", LinkController, :create
    put "/links/:id", LinkController, :update
    delete "/links/:id", LinkController, :delete

    # Маршрут для получения ссылок по группе
    get "/groups/:group_id/links", LinkController, :by_group
  end

  # Веб-интерфейс отключен - используем только Chrome extension
  # Админка через Backpex больше не используется

  # ВРЕМЕННО отключаем LiveDashboard - он вызывает постоянные проблемы с перезагрузкой
  # Если нужен мониторинг, можно использовать альтернативы или включить обратно после исправления проблем
  # if Mix.env() in [:dev, :test] do
  #   import Phoenix.LiveDashboard.Router
  #
  #   scope "/" do
  #     pipe_through [:dashboard]
  #     live_dashboard "/dashboard",
  #       metrics: nil,
  #       ecto_repos: []
  #   end
  # end
end
