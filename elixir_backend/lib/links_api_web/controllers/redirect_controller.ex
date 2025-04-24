defmodule LinksApiWeb.RedirectController do
  use Phoenix.Controller
  require Logger
  alias LinksApi.Repo
  alias LinksApi.SystemMetrics
  import LinksApiWeb.Layouts, only: [sigil_p: 2]

  # Обработка публичного доступа к ссылке по ID
  def redirect_by_id(conn, %{"id" => id}) do
    # Логируем попытку редиректа
    Logger.info("Redirect attempt", id: id, ip: conn.remote_ip |> :inet.ntoa() |> to_string())

    case Repo.get_link(id) do
      {:ok, link} ->
        # Логируем успешный редирект
        Logger.info("Successful redirect",
          id: id,
          url: link["url"],
          group_id: link["group_id"]
        )

        # Добавляем метрику перехода по ссылке
        :telemetry.execute(
          [:links_api, :links, :redirect],
          %{count: 1},
          %{id: id, group_id: link["group_id"] || "none"}
        )

        # Редирект на целевой URL
        conn
        |> redirect(external: link["url"])

      {:error, :not_found} ->
        # Логируем неудачный редирект
        Logger.warn("Link not found for redirect", id: id)

        conn
        |> put_status(:not_found)
        |> put_view(LinksApiWeb.ErrorHTML)
        |> render("404.html")

      error ->
        # Логируем ошибку
        Logger.error("Error during redirect",
          id: id,
          error: inspect(error)
        )

        conn
        |> put_status(:internal_server_error)
        |> put_view(LinksApiWeb.ErrorHTML)
        |> render("500.html")
    end
  end

  # Редирект с корня админки на страницу со ссылками
  def admin_redirect(conn, _params) do
    conn
    |> redirect(to: ~p"/admin/links")
  end
end
