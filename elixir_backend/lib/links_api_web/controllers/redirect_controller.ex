defmodule LinksApiWeb.RedirectController do
  use Phoenix.Controller
  require Logger
  alias LinksApi.SqliteRepo
  import LinksApiWeb.Layouts, only: [sigil_p: 2]

  # Редирект на публичную ссылку (доступна всем, не требует авторизации)
  def redirect_public_by_name(conn, %{"name" => name}) do
    decoded_name = URI.decode(name)

    case SqliteRepo.get_public_link_by_name(decoded_name) do
      {:ok, link} ->
        Logger.info("Public redirect by name", name: decoded_name, id: link["id"], url: link["url"])

        :telemetry.execute(
          [:links_api, :links, :public_redirect],
          %{count: 1},
          %{id: link["id"], name: decoded_name}
        )

        conn
        |> redirect(external: link["url"])

      {:error, :not_found} ->
        Logger.warning("Public link not found", name: decoded_name)

        conn
        |> put_status(:not_found)
        |> put_view(LinksApiWeb.ErrorHTML)
        |> render("404.html")
    end
  end

  # Редирект на обычную ссылку (требует авторизации, только для владельца)
  def redirect_by_name(conn, %{"name" => name}) do
    # Декодируем name на случай, если он был закодирован в URL
    name = URI.decode(name)

    # Логируем попытку редиректа
    Logger.info("Redirect attempt by name", name: name, ip: conn.remote_ip |> :inet.ntoa() |> to_string())

    case SqliteRepo.get_link_by_name(name) do
      {:ok, link} ->
        # Логируем успешный редирект
        Logger.info("Successful redirect by name",
          name: name,
          id: link["id"],
          url: link["url"],
          group_id: link["group_id"]
        )

        # Добавляем метрику перехода по ссылке
        :telemetry.execute(
          [:links_api, :links, :redirect],
          %{count: 1},
          %{id: link["id"], name: name, group_id: link["group_id"] || "none"}
        )

        # Редирект на целевой URL
        conn
        |> redirect(external: link["url"])

      {:error, :not_found} ->
        # Логируем неудачный редирект
        Logger.warning("Link not found for redirect by name", name: name)

        html_content = """
        <!DOCTYPE html>
        <html>
          <head>
            <title>404 - Not Found</title>
            <meta charset="utf-8" />
          </head>
          <body>
            <h1>404 - Not Found</h1>
            <p>The page you are looking for does not exist.</p>
          </body>
        </html>
        """

        conn
        |> put_resp_content_type("text/html")
        |> put_status(:not_found)
        |> send_resp(404, html_content)

      error ->
        # Логируем ошибку
        Logger.error("Error during redirect by name",
          name: name,
          error: inspect(error)
        )

        html_content = """
        <!DOCTYPE html>
        <html>
          <head>
            <title>500 - Internal Server Error</title>
            <meta charset="utf-8" />
          </head>
          <body>
            <h1>500 - Internal Server Error</h1>
            <p>An error occurred while processing your request.</p>
          </body>
        </html>
        """

        conn
        |> put_resp_content_type("text/html")
        |> put_status(:internal_server_error)
        |> send_resp(500, html_content)
    end
  end

  # Редирект с корня админки на страницу со ссылками
  def admin_redirect(conn, _params) do
    conn
    |> redirect(to: ~p"/admin/links")
  end

  # Перенаправления для неправильных маршрутов API
  def redirect_to_admin(conn, _params) do
    conn
    |> redirect(to: ~p"/admin")
  end

  def redirect_to_admin_path(conn, %{"path" => path}) do
    path_string = Enum.join(path, "/")

    conn
    |> redirect(to: ~p"/admin/#{path_string}")
  end

  def redirect_to_dashboard(conn, _params) do
    # Дашборд временно отключен из-за проблем с перезагрузкой
    html_content = """
    <!DOCTYPE html>
    <html>
      <head>
        <title>404 - Not Found</title>
        <meta charset="utf-8" />
      </head>
      <body>
        <h1>404 - Not Found</h1>
        <p>The page you are looking for does not exist.</p>
      </body>
    </html>
    """

    conn
    |> put_resp_content_type("text/html")
    |> put_status(:not_found)
    |> send_resp(404, html_content)
  end
end
