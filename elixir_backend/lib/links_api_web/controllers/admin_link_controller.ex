defmodule LinksApiWeb.AdminLinkController do
  use Phoenix.Controller
  alias LinksApi.Schemas.Link
  alias LinksApi.SqliteRepo

  def index(conn, _params) do
    # Перенаправляем на LiveView
    redirect(conn, to: "/admin/links")
  end

  def new(conn, _params) do
    # Перенаправляем на LiveView
    redirect(conn, to: "/admin/links/new")
  end

  def create(conn, %{"link" => link_params}) do
    # Генерируем UUID для новой ссылки, если он не указан
    link_params_with_id = Map.put_new(link_params, "id", UUID.uuid4())

    # Добавляем временные метки
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    link_params_with_timestamps = Map.merge(link_params_with_id, %{
      "created_at" => now,
      "updated_at" => now
    })

    case SqliteRepo.create_link(link_params_with_timestamps) do
      {:ok, _link} ->
        conn
        |> put_flash(:info, "Ссылка успешно создана.")
        |> redirect(to: "/admin/links")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Ошибка при создании ссылки: #{inspect(reason)}")
        |> redirect(to: "/admin/links/new")
    end
  end

  # Добавляем обработку формата Backpex
  def create(conn, %{"change" => change_params} = params) do
    # Генерируем UUID для новой ссылки, если он не указан
    link_params_with_id = Map.put_new(change_params, "id", UUID.uuid4())

    # Добавляем временные метки
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    link_params_with_timestamps = Map.merge(link_params_with_id, %{
      "created_at" => now,
      "updated_at" => now
    })

    case SqliteRepo.create_link(link_params_with_timestamps) do
      {:ok, _link} ->
        conn
        |> put_flash(:info, "Ссылка успешно создана.")
        |> redirect(to: "/admin/links")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Ошибка при создании ссылки: #{inspect(reason)}")
        |> redirect(to: "/admin/links/new")
    end
  end

  def show(conn, %{"id" => id}) do
    # Перенаправляем на LiveView
    redirect(conn, to: "/admin/links/#{id}/show")
  end

  def edit(conn, %{"id" => id}) do
    # Перенаправляем на LiveView
    redirect(conn, to: "/admin/links/#{id}/edit")
  end

  def update(conn, %{"id" => id, "link" => link_params}) do
    # Обновляем временную метку
    link_params_with_timestamp = Map.put(link_params, "updated_at", DateTime.utc_now() |> DateTime.to_iso8601())

    case SqliteRepo.update_link(id, link_params_with_timestamp) do
      {:ok, _link} ->
        conn
        |> put_flash(:info, "Ссылка успешно обновлена.")
        |> redirect(to: "/admin/links")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Ошибка при обновлении ссылки: #{inspect(reason)}")
        |> redirect(to: "/admin/links/#{id}/edit")
    end
  end

  def delete(conn, %{"id" => id}) do
    case SqliteRepo.delete_link(id) do
      :ok ->
        conn
        |> put_flash(:info, "Ссылка успешно удалена.")
        |> redirect(to: "/admin/links")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Ошибка при удалении ссылки: #{inspect(reason)}")
        |> redirect(to: "/admin/links")
    end
  end
end
