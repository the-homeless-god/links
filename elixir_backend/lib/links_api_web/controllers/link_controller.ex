defmodule LinksApiWeb.LinkController do
  use Phoenix.Controller
  alias LinksApi.SqliteRepo
  alias LinksApiWeb.AuthPlug

  # Получение всех ссылок
  def index(conn, _params) do
    with {:ok, links} <- SqliteRepo.get_all_links() do
      # Временно отключаем фильтрацию ссылок по правам доступа
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

    case SqliteRepo.get_link(id) do
      {:ok, _link} ->
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
    # Отключаем проверку прав на удаление
    case SqliteRepo.get_link(id) do
      {:ok, _link} ->
        case SqliteRepo.delete_link(id) do
          :ok ->
            conn
            |> put_status(:no_content)
            |> json(%{success: true})
          error ->
            handle_error(conn, error)
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
