defmodule LinksApi.RepoAdapter do
  @moduledoc """
  Адаптер для работы Backpex с нашим репозиторием.
  Имитирует поведение Ecto.Repo для совместимости с Backpex.
  Поддерживает как Cassandra, так и SQLite.
  """
  alias LinksApi.Schemas.Link

  # Получаем модуль репозитория динамически из конфигурации
  defp repo_module do
    Application.get_env(:links_api, :repo_module, LinksApi.Repo)
  end

  @doc """
  Валидирует конфигурацию адаптера
  """
  def validate_config!(config) do
    if Keyword.get(config, :schema) != Link do
      raise "LinksApi.RepoAdapter работает только с LinksApi.Schemas.Link"
    end

    config
  end

  # Получение всех записей с поддержкой пагинации и сортировки
  def all(Link, opts \\ []) do
    {:ok, links} = repo_module().get_all_links()

    # Применяем фильтры, если они есть
    links = apply_filters(links, opts[:filters])

    # Получаем общее количество записей (для пагинации)
    total_count = length(links)

    # Применяем сортировку
    links = apply_sort(links, opts[:order_by])

    # Применяем пагинацию
    links = apply_pagination(links, opts[:limit], opts[:offset])

    # Возвращаем результат в формате Backpex
    %{
      entries: links |> Enum.map(&to_schema/1),
      total_count: total_count
    }
  end

  # Получение записи по ID
  def get(Link, id) do
    case repo_module().get_link(id) do
      {:ok, link} -> to_schema(link)
      _ -> nil
    end
  end

  # Вставка новой записи
  def insert(changeset) do
    params =
      changeset.changes
      |> Map.take([:id, :name, :url, :description, :group_id])
      |> Map.new(fn {k, v} -> {to_string(k), v} end)

    case repo_module().create_link(params) do
      {:ok, link} -> {:ok, to_schema(link)}
      error -> {:error, changeset_with_error(changeset, error)}
    end
  end

  # Обновление записи
  def update(changeset) do
    id = changeset.data.id

    changes =
      changeset.changes
      |> Map.take([:name, :url, :description, :group_id])
      |> Map.new(fn {k, v} -> {to_string(k), v} end)

    case repo_module().update_link(id, changes) do
      {:ok, link} ->
        {:ok, to_schema(link)}

      {:error, :name_already_exists} ->
        {:error, changeset_with_error(changeset, {:error, :name_already_exists})}

      error ->
        {:error, changeset_with_error(changeset, error)}
    end
  end

  # Подсчет количества записей
  def count(criteria, _params, _live_resource) do
    {:ok, links} = repo_module().get_all_links()

    # Получаем фильтры
    filters_criteria = Keyword.get(criteria, :filters, [])

    # Применяем фильтры
    links = apply_filters(links, filters_criteria)

    # Возвращаем общее количество записей
    {:ok, length(links)}
  end

  # Получение списка записей
  def list(criteria, _params, _live_resource) do
    {:ok, links} = repo_module().get_all_links()

    # Получаем фильтры и параметры пагинации
    filters_criteria = Keyword.get(criteria, :filters, [])
    limit = Keyword.get(criteria, :limit)
    offset = Keyword.get(criteria, :offset, 0)
    order_by = Keyword.get(criteria, :order_by)

    # Применяем фильтры
    links = apply_filters(links, filters_criteria)

    # Применяем сортировку
    links = apply_sort(links, order_by)

    # Применяем пагинацию
    links = apply_pagination(links, limit, offset)

    # Преобразуем в схему и возвращаем результат
    {:ok, Enum.map(links, &to_schema/1)}
  end

  # Удаление записи
  def delete(%Link{id: id}) do
    case repo_module().delete_link(id) do
      :ok -> {:ok, %Link{id: id}}
      error -> {:error, error}
    end
  end

  # Преобразование данных из репозитория в схему Ecto
  defp to_schema(link) when is_map(link) do
    name = link["name"] || link["id"]
    is_public = link["is_public"] == true || link["is_public"] == 1
    # Публичные ссылки используют /u/, обычные - /r/
    short_link = if is_public, do: "/u/#{URI.encode(name)}", else: "/r/#{URI.encode(name)}"

    %Link{
      id: link["id"],
      name: link["name"],
      url: link["url"],
      description: link["description"],
      group_id: link["group_id"],
      user_id: link["user_id"],
      is_public: is_public,
      created_at: link["created_at"],
      updated_at: link["updated_at"],
      # Добавляем виртуальное поле для отображения короткой ссылки
      short_link: short_link
    }
  end

  # Преобразование ошибки в changeset с ошибкой
  defp changeset_with_error(changeset, error) do
    case error do
      {:error, :name_already_exists} ->
        Ecto.Changeset.add_error(changeset, :name, "уже существует. Пожалуйста, выберите другое имя.")

      {:error, :name_required} ->
        Ecto.Changeset.add_error(changeset, :name, "обязательно для заполнения")

      {:error, reason} ->
        Ecto.Changeset.add_error(changeset, :base, "Database error: #{inspect(reason)}")

      _ ->
        Ecto.Changeset.add_error(changeset, :base, "Database error: #{inspect(error)}")
    end
  end

  # Применение фильтров
  defp apply_filters(links, nil), do: links

  defp apply_filters(links, filters) when is_list(filters) do
    Enum.reduce(filters, links, fn filter, acc ->
      apply_filter(acc, filter)
    end)
  end

  defp apply_filters(links, _), do: links

  # Применение отдельного фильтра
  defp apply_filter(links, {field, value}) do
    field_str = to_string(field)

    Enum.filter(links, fn link ->
      String.contains?(String.downcase(link[field_str] || ""), String.downcase(value))
    end)
  end

  # Применение сортировки
  defp apply_sort(links, nil), do: links

  defp apply_sort(links, [{field, direction}]) do
    field_str = to_string(field)
    Enum.sort_by(links, & &1[field_str], sort_direction(direction))
  end

  defp apply_sort(links, _), do: links

  # Преобразование направления сортировки
  defp sort_direction(:asc), do: :asc
  defp sort_direction(:desc), do: :desc
  defp sort_direction(_), do: :asc

  # Применение пагинации
  defp apply_pagination(links, nil, _), do: links

  defp apply_pagination(links, limit, offset) when is_integer(limit) and is_integer(offset) do
    links
    |> Enum.drop(offset)
    |> Enum.take(limit)
  end

  defp apply_pagination(links, _, _), do: links
end
