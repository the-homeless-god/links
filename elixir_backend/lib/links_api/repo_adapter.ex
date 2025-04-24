defmodule LinksApi.RepoAdapter do
  @moduledoc """
  Адаптер для работы Backpex с нашим Cassandra репозиторием.
  Имитирует поведение Ecto.Repo для совместимости с Backpex.
  """
  alias LinksApi.Repo
  alias LinksApi.Schemas.Link

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
    {:ok, links} = Repo.get_all_links()

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
    case Repo.get_link(id) do
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

    case Repo.create_link(params) do
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

    case Repo.update_link(id, changes) do
      {:ok, link} -> {:ok, to_schema(link)}
      error -> {:error, changeset_with_error(changeset, error)}
    end
  end

  # Удаление записи
  def delete(%Link{id: id}) do
    case Repo.delete_link(id) do
      :ok -> {:ok, %Link{id: id}}
      error -> {:error, error}
    end
  end

  # Преобразование данных из Cassandra в схему Ecto
  defp to_schema(link) when is_map(link) do
    %Link{
      id: link["id"],
      name: link["name"],
      url: link["url"],
      description: link["description"],
      group_id: link["group_id"],
      created_at: link["created_at"],
      updated_at: link["updated_at"]
    }
  end

  # Преобразование ошибки в changeset с ошибкой
  defp changeset_with_error(changeset, error) do
    Ecto.Changeset.add_error(changeset, :base, "Database error: #{inspect(error)}")
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
    Enum.sort_by(links, &(&1[field_str]), sort_direction(direction))
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
