defmodule LinksApiWeb.Router do
  use Phoenix.Router
  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LinksApiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug LinksApiWeb.AuthPlug
  end

  # Маршрут для редиректа по короткой ссылке
  scope "/", LinksApiWeb do
    pipe_through :browser

    # Маршрут для редиректа на публичную ссылку
    get "/r/:id", RedirectController, :redirect_by_id
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

  # Маршруты для админки Backpex
  scope "/admin", LinksApiWeb do
    pipe_through [:browser, :authenticated]

    # Перенаправляем корневой маршрут на админку
    get "/", RedirectController, :admin_redirect

    # Добавляем маршруты для Backpex
    live_session :admin, on_mount: [{LinksApiWeb.LiveSessionGuard, :auth}] do
      live "/links", LinksLiveResource, :index, as: :admin_live_resource
      live "/links/new", LinksLiveResource, :new, as: :admin_live_resource
      live "/links/:id", LinksLiveResource, :show, as: :admin_live_resource
      live "/links/:id/edit", LinksLiveResource, :edit, as: :admin_live_resource
    end
  end

  # Включаем маршруты LiveDashboard в разработке
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:browser, :authenticated]
      live_dashboard "/dashboard", metrics: LinksApiWeb.Telemetry
    end
  end
end
