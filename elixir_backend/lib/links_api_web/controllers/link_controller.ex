defmodule LinksApiWeb.LinkController do
  use Phoenix.Controller
  alias LinksApi.Repo
  alias LinksApiWeb.AuthPlug

  # Получение всех ссылок
  def index(conn, _params) do
    with {:ok, links} <- Repo.get_all_links() do
      # Фильтруем ссылки на основе прав доступа пользователя
      filtered_links = Enum.filter(links, fn link ->
        try do
          # Проверяем доступ к каждой ссылке
          AuthPlug.check_link_access(%{assigns: conn.assigns}, link)
          true
        catch
          # Если доступ запрещен, исключаем ссылку из результата
          :error, _ -> false
        end
      end)

      json(conn, filtered_links)
    else
      error -> handle_error(conn, error)
    end
  end

  # Получение ссылки по ID
  def show(conn, %{"id" => id}) do
    with {:ok, link} <- Repo.get_link(id),
         # Проверяем доступ к ссылке
         conn <- AuthPlug.check_link_access(conn, link) do
      json(conn, link)
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Link not found"})
      error -> handle_error(conn, error)
    end
  end

  # Создание новой ссылки
  def create(conn, params) do
    # Проверяем права на создание
    roles = ["links-admin", "links-editor"]
    conn = AuthPlug.require_any_role(conn, roles)

    # Генерируем UUID для новой ссылки если он не был предоставлен
    params = Map.put_new(params, "id", UUID.uuid4())

    # Добавляем информацию о группе, если она не была предоставлена
    # и пользователь не админ
    params =
      if not AuthPlug.KeycloakToken.has_role?(conn.assigns.current_user, "links-admin") and
         (params["group_id"] == nil or params["group_id"] == "") do
        # Получаем первую группу пользователя или пустую строку
        user_groups = conn.assigns.current_user["groups"] || []
        group_id = if Enum.empty?(user_groups), do: "", else: List.first(user_groups)
        Map.put(params, "group_id", group_id)
      else
        params
      end

    with {:ok, link} <- Repo.create_link(params) do
      conn
      |> put_status(:created)
      |> json(link)
    else
      error -> handle_error(conn, error)
    end
  end

  # Обновление ссылки
  def update(conn, %{"id" => id} = params) do
    with {:ok, link} <- Repo.get_link(id),
         # Проверяем доступ к ссылке
         conn <- AuthPlug.check_link_access(conn, link),
         {:ok, updated_link} <- Repo.update_link(id, params) do
      json(conn, updated_link)
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Link not found"})
      error -> handle_error(conn, error)
    end
  end

  # Удаление ссылки
  def delete(conn, %{"id" => id}) do
    # Только администраторы могут удалять ссылки
    conn = AuthPlug.require_role(conn, "links-admin")

    with {:ok, link} <- Repo.get_link(id),
         :ok <- Repo.delete_link(id) do
      conn
      |> put_status(:no_content)
      |> json(%{})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Link not found"})
      error -> handle_error(conn, error)
    end
  end

  # Получение ссылок по группе
  def by_group(conn, %{"group_id" => group_id}) do
    # Проверяем, есть ли у пользователя доступ к группе
    user_groups = conn.assigns.current_user["groups"] || []

    if AuthPlug.KeycloakToken.has_role?(conn.assigns.current_user, "links-admin") or
       Enum.member?(user_groups, group_id) do
      with {:ok, links} <- Repo.get_links_by_group(group_id) do
        json(conn, links)
      else
        error -> handle_error(conn, error)
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "You don't have access to this group"})
    end
  end

  # Обработка ошибок
  defp handle_error(conn, error) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{error: "Server error: #{inspect(error)}"})
  end
end
