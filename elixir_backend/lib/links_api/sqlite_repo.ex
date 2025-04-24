defmodule LinksApi.SqliteRepo do
  @moduledoc """
  Модуль репозитория для работы с SQLite.
  Реализует тот же интерфейс, что и LinksApi.Repo для Cassandra.
  """
  use GenServer
  require Logger
  @behaviour LinksApi.Repo.Behaviour

  # Путь к файлу базы данных
  @db_path Path.join([File.cwd!(), "priv/db/links.db"])

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    # Создаем директорию для базы данных, если она не существует
    db_dir = Path.dirname(@db_path)
    File.mkdir_p!(db_dir)

    # Инициализация подключения к SQLite через ecto_sqlite3
    {:ok, conn} = Exqlite.Sqlite3.open(@db_path)

    # Создаем таблицу ссылок если она не существует
    create_table_query = """
    CREATE TABLE IF NOT EXISTS links (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      url TEXT NOT NULL,
      description TEXT,
      group_id TEXT,
      created_at TEXT,
      updated_at TEXT
    );
    """
    :ok = Exqlite.Sqlite3.execute(conn, create_table_query)

    # Создаем индекс по group_id для фильтрации
    create_index_query = """
    CREATE INDEX IF NOT EXISTS links_group_id_idx ON links (group_id);
    """
    :ok = Exqlite.Sqlite3.execute(conn, create_index_query)

    {:ok, %{conn: conn}}
  end

  # API для создания новой ссылки
  @impl true
  def create_link(link_params) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
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
        updated_link = Map.put(updated_link, "updated_at", DateTime.utc_now() |> DateTime.to_iso8601())

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

    case GenServer.call(__MODULE__, {:query, query, params}) do
      {:ok, []} -> {:error, :not_found}
      {:ok, [row]} -> {:ok, row_to_map(row)}
      error -> error
    end
  end

  # API для получения всех ссылок
  @impl true
  def get_all_links() do
    query = "SELECT * FROM links"

    case GenServer.call(__MODULE__, {:query, query, []}) do
      {:ok, rows} ->
        links = Enum.map(rows, &row_to_map/1)
        {:ok, links}
      error -> error
    end
  end

  # API для получения ссылок по группе
  @impl true
  def get_links_by_group(group_id) do
    query = "SELECT * FROM links WHERE group_id = ?"
    params = [group_id]

    case GenServer.call(__MODULE__, {:query, query, params}) do
      {:ok, rows} ->
        links = Enum.map(rows, &row_to_map/1)
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

  # Обработка запросов к SQLite
  @impl true
  def handle_call({:execute, query, params}, _from, %{conn: conn} = state) do
    result = case Exqlite.Sqlite3.prepare(conn, query) do
      {:ok, statement} ->
        case bind_params(conn, statement, params) do
          :ok ->
            case Exqlite.Sqlite3.step(conn, statement) do
              :done -> {:ok, []}
              error -> error
            end
          error -> error
        end
      error -> error
    end
    {:reply, result, state}
  end

  @impl true
  def handle_call({:query, query, params}, _from, %{conn: conn} = state) do
    result = case Exqlite.Sqlite3.prepare(conn, query) do
      {:ok, statement} ->
        case bind_params(conn, statement, params) do
          :ok ->
            fetch_all_rows(conn, statement, [])
          error -> error
        end
      error -> error
    end
    {:reply, result, state}
  end

  # Привязка параметров к запросу
  defp bind_params(_conn, statement, []) do
    :ok
  end

  defp bind_params(_conn, statement, params) do
    case Exqlite.Sqlite3.bind(statement, params) do
      :ok -> :ok
      error -> error
    end
  end

  # Получение всех строк результата запроса
  defp fetch_all_rows(conn, statement, acc) do
    case Exqlite.Sqlite3.step(conn, statement) do
      {:row, row} ->
        # Получаем имена колонок
        {:ok, columns} = Exqlite.Sqlite3.columns(conn, statement)
        # Создаем карту из названий колонок и значений
        row_map = Enum.zip(columns, row) |> Enum.into(%{})
        fetch_all_rows(conn, statement, [row_map | acc])
      :done ->
        {:ok, Enum.reverse(acc)}
      error ->
        error
    end
  end

  # Преобразование строки результата в карту
  defp row_to_map(row) do
    # Преобразуем ключи из атомов в строки (если нужно)
    row = Enum.map(row, fn {k, v} -> {to_string(k), v} end) |> Enum.into(%{})

    # Преобразуем ISO8601 строки в DateTime
    row = if row["created_at"] do
      {:ok, dt, _} = DateTime.from_iso8601(row["created_at"])
      Map.put(row, "created_at", dt)
    else
      row
    end

    if row["updated_at"] do
      {:ok, dt, _} = DateTime.from_iso8601(row["updated_at"])
      Map.put(row, "updated_at", dt)
    else
      row
    end
  end
end
