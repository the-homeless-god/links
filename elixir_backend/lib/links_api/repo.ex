defmodule LinksApi.Repo.Behaviour do
  @moduledoc """
  Определяет поведение репозитория для взаимодействия с данными.
  Используется для мокирования в тестах.
  """

  @callback get_link(String.t()) :: {:ok, map()} | {:error, atom()}
  @callback get_all_links() :: {:ok, list(map())} | {:error, atom()}
  @callback get_links_by_group(String.t()) :: {:ok, list(map())} | {:error, atom()}
  @callback create_link(map()) :: {:ok, map()} | {:error, atom()}
  @callback update_link(String.t(), map()) :: {:ok, map()} | {:error, atom()}
  @callback delete_link(String.t()) :: :ok | {:error, atom()}
end

defmodule LinksApi.Repo do
  @moduledoc """
  Модуль репозитория для работы с Cassandra.
  Реализует Single Table Design для хранения ссылок.
  """
  use GenServer
  require Logger
  @behaviour LinksApi.Repo.Behaviour

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    config = Application.get_env(:links_api, __MODULE__)
    {:ok, conn} = Xandra.start_link(nodes: config[:nodes])

    # Создаем keyspace если он не существует
    create_keyspace_query = """
    CREATE KEYSPACE IF NOT EXISTS #{config[:keyspace]}
    WITH REPLICATION = {'class': 'SimpleStrategy', 'replication_factor': 1}
    """
    {:ok, _} = Xandra.execute(conn, create_keyspace_query, _params = [])

    # Устанавливаем keyspace для соединения
    {:ok, _} = Xandra.execute(conn, "USE #{config[:keyspace]}", _params = [])

    # Создаем таблицу ссылок если она не существует
    create_table_query = """
    CREATE TABLE IF NOT EXISTS links (
      id TEXT PRIMARY KEY,
      name TEXT,
      url TEXT,
      description TEXT,
      group_id TEXT,
      created_at TIMESTAMP,
      updated_at TIMESTAMP
    )
    """
    {:ok, _} = Xandra.execute(conn, create_table_query, _params = [])

    # Создаем индекс по group_id для фильтрации
    create_index_query = """
    CREATE INDEX IF NOT EXISTS links_group_id_idx ON links (group_id)
    """
    {:ok, _} = Xandra.execute(conn, create_index_query, _params = [])

    {:ok, %{conn: conn, keyspace: config[:keyspace]}}
  end

  # API для создания новой ссылки
  @impl true
  def create_link(link_params) do
    now = DateTime.utc_now()
    link = Map.merge(link_params, %{
      "created_at" => now,
      "updated_at" => now
    })

    query = """
    INSERT INTO links (id, name, url, description, group_id, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    """

    params = [
      link["id"],
      link["name"],
      link["url"],
      link["description"] || "",
      link["group_id"] || "",
      link["created_at"],
      link["updated_at"]
    ]

    GenServer.call(__MODULE__, {:execute, query, params})
    {:ok, link}
  end

  # API для обновления ссылки
  @impl true
  def update_link(id, link_params) do
    # Получаем существующую ссылку
    case get_link(id) do
      {:ok, existing_link} ->
        # Обновляем только указанные поля
        updated_link = Map.merge(existing_link, link_params)
        updated_link = Map.put(updated_link, "updated_at", DateTime.utc_now())

        query = """
        UPDATE links
        SET name = ?, url = ?, description = ?, group_id = ?, updated_at = ?
        WHERE id = ?
        """

        params = [
          updated_link["name"],
          updated_link["url"],
          updated_link["description"] || "",
          updated_link["group_id"] || "",
          updated_link["updated_at"],
          id
        ]

        GenServer.call(__MODULE__, {:execute, query, params})
        {:ok, updated_link}

      error ->
        error
    end
  end

  # API для получения ссылки по ID
  @impl true
  def get_link(id) do
    query = "SELECT * FROM links WHERE id = ?"
    params = [id]

    case GenServer.call(__MODULE__, {:execute, query, params}) do
      {:ok, %Xandra.Page{} = page} ->
        case Enum.to_list(page) do
          [row] -> {:ok, row_to_map(row)}
          [] -> {:error, :not_found}
        end
      error -> error
    end
  end

  # API для получения всех ссылок
  @impl true
  def get_all_links() do
    query = "SELECT * FROM links"

    case GenServer.call(__MODULE__, {:execute, query, []}) do
      {:ok, %Xandra.Page{} = page} ->
        links = Enum.map(page, &row_to_map/1)
        {:ok, links}
      error -> error
    end
  end

  # API для получения ссылок по группе
  @impl true
  def get_links_by_group(group_id) do
    query = "SELECT * FROM links WHERE group_id = ? ALLOW FILTERING"
    params = [group_id]

    case GenServer.call(__MODULE__, {:execute, query, params}) do
      {:ok, %Xandra.Page{} = page} ->
        links = Enum.map(page, &row_to_map/1)
        {:ok, links}
      error -> error
    end
  end

  # API для удаления ссылки
  @impl true
  def delete_link(id) do
    query = "DELETE FROM links WHERE id = ?"
    params = [id]

    GenServer.call(__MODULE__, {:execute, query, params})
    :ok
  end

  # Обработка запросов к Cassandra
  @impl true
  def handle_call({:execute, query, params}, _from, %{conn: conn} = state) do
    result = Xandra.execute(conn, query, params)
    {:reply, result, state}
  end

  # Преобразование строки результата в карту
  defp row_to_map(row) do
    row
    |> Map.new(fn {k, v} -> {k, v} end)
    |> Map.update!("created_at", &DateTime.from_naive!(&1, "Etc/UTC"))
    |> Map.update!("updated_at", &DateTime.from_naive!(&1, "Etc/UTC"))
  end
end
