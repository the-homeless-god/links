defmodule LinksApiWeb.Router do
  use Phoenix.Router
  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router
  import Backpex.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LinksApiWeb.Layouts, :root}
    # Временно отключаем для отладки
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Backpex.ThemeSelectorPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Временно отключаем аутентификацию для тестирования
  pipeline :authenticated do
    # plug LinksApiWeb.AuthPlug
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

    # Перенаправления для неправильных маршрутов
    get "/admin", RedirectController, :redirect_to_admin
    get "/admin/*path", RedirectController, :redirect_to_admin_path
    get "/dashboard", RedirectController, :redirect_to_dashboard
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

  # Маршруты для админки
  scope "/admin", LinksApiWeb do
    pipe_through :browser

    # Перенаправляем корневой маршрут на страницу со ссылками
    get "/", RedirectController, :admin_redirect

    # Добавляем конкретный маршрут для создания ссылок через POST
    post "/links/new", AdminLinkController, :create

    # Используем LiveSession с Backpex.InitAssigns
    live_session :default, on_mount: Backpex.InitAssigns do
      live_resources "/links", LinksLive
    end

    # Добавляем служебные маршруты Backpex (для cookies и т.д.)
    backpex_routes()
  end

  # Включаем маршруты LiveDashboard в разработке
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:browser]
      live_dashboard "/dashboard", metrics: LinksApiWeb.Telemetry
    end
  end
end
