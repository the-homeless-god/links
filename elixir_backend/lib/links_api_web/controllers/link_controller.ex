defmodule LinksApiWeb.LinkController do
  use Phoenix.Controller
  alias LinksApi.SqliteRepo
  alias LinksApiWeb.AuthPlug

  # Получение всех ссылок
  def index(conn, _params) do
    # Получаем user_id из assigns (установлен AuthPlug)
    user_id = Map.get(conn.assigns, :user_id, "guest")

    with {:ok, links} <- SqliteRepo.get_all_links_by_user(user_id) do
      json(conn, links)
    else
      error -> handle_error(conn, error)
    end
  end

  # Получение ссылки по ID
  def show(conn, %{"id" => id}) do
    with {:ok, link} <- SqliteRepo.get_link(id) do
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
  def create(conn, _params) do
    # Получаем параметры из тела запроса
    params = conn.body_params
    # Генерируем UUID для новой ссылки если он не был предоставлен
    params = Map.put_new(params, "id", UUID.uuid4())

    # Получаем user_id из assigns (установлен AuthPlug)
    user_id = Map.get(conn.assigns, :user_id, "guest")
    params = Map.put(params, "user_id", user_id)

    # Упрощаем логику с группами для тестирования
    params = if params["group_id"] == nil, do: Map.put(params, "group_id", ""), else: params

    case SqliteRepo.create_link(params) do
      {:ok, link} ->
        conn
        |> put_status(:created)
        |> json(link)
      {:error, :name_already_exists} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "name_already_exists", message: "Имя ссылки уже существует"})
      {:error, :name_required} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "name_required", message: "Имя ссылки обязательно для заполнения"})
      error ->
        handle_error(conn, error)
    end
  end

  # Обновление ссылки
  def update(conn, %{"id" => id}) do
    # Получаем параметры из тела запроса
    params = conn.body_params

    # Получаем user_id из assigns (установлен AuthPlug)
    user_id = Map.get(conn.assigns, :user_id, "guest")
    params = Map.put(params, "user_id", user_id)

    case SqliteRepo.get_link(id) do
      {:ok, link} ->
        # Проверяем, что ссылка принадлежит пользователю
        if link["user_id"] != user_id do
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Forbidden: Link does not belong to user"})
        else
          case SqliteRepo.update_link(id, params) do
            {:ok, updated_link} ->
              json(conn, updated_link)
            {:error, :name_already_exists} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "name_already_exists", message: "Имя ссылки уже существует"})
            error ->
              handle_error(conn, error)
          end
        end
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Link not found"})
      error ->
        handle_error(conn, error)
    end
  end

  # Удаление ссылки
  def delete(conn, %{"id" => id}) do
    # Получаем user_id из assigns (установлен AuthPlug)
    user_id = Map.get(conn.assigns, :user_id, "guest")

    case SqliteRepo.get_link(id) do
      {:ok, link} ->
        # Проверяем, что ссылка принадлежит пользователю
        if link["user_id"] != user_id do
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Forbidden: Link does not belong to user"})
        else
          case SqliteRepo.delete_link(id) do
            :ok ->
              conn
              |> put_status(:no_content)
              |> json(%{success: true})
            error ->
              handle_error(conn, error)
          end
        end
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Link not found"})
      error ->
        handle_error(conn, error)
    end
  end

  # Получение ссылок по группе
  def by_group(conn, %{"group_id" => group_id}) do
    # Отключаем проверку прав на доступ к группе
    with {:ok, links} <- SqliteRepo.get_links_by_group(group_id) do
      json(conn, links)
    else
      error -> handle_error(conn, error)
    end
  end

  # Обработка ошибок
  defp handle_error(conn, error) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{error: "Server error: #{inspect(error)}"})
  end
end
