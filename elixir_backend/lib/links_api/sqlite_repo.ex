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
      user_id TEXT,
      is_public INTEGER DEFAULT 0,
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

    # Удаляем старый уникальный индекс, если он существует (на случай если он был создан с ошибкой)
    drop_old_index_query = """
    DROP INDEX IF EXISTS links_name_unique_idx;
    """

    case Exqlite.Sqlite3.execute(conn, drop_old_index_query) do
      :ok -> :ok
      # Игнорируем ошибки
      {:error, _} -> :ok
    end

    # Обрабатываем дубликаты имен перед созданием уникального индекса
    # Оставляем первую запись с каждым именем (по rowid), остальные переименовываем
    cleanup_duplicates_query = """
    UPDATE links
    SET name = name || '-' || substr(id, 1, 8)
    WHERE rowid NOT IN (
      SELECT MIN(rowid)
      FROM links
      GROUP BY name
    )
    AND name IN (
      SELECT name
      FROM links
      GROUP BY name
      HAVING COUNT(*) > 1
    );
    """

    # Выполняем очистку дубликатов (может не найти дубликаты - это нормально)
    case Exqlite.Sqlite3.execute(conn, cleanup_duplicates_query) do
      :ok ->
        :ok

      {:error, reason} ->
        require Logger
        Logger.debug("Очистка дубликатов: #{inspect(reason)} (может быть нормально, если дубликатов нет)")
        :ok
    end

    # Создаем уникальный индекс по name для предотвращения дублирования
    create_unique_index_query = """
    CREATE UNIQUE INDEX IF NOT EXISTS links_name_unique_idx ON links (name);
    """

    case Exqlite.Sqlite3.execute(conn, create_unique_index_query) do
      :ok ->
        :ok

      {:error, reason} ->
        # Если все еще есть дубликаты, логируем и продолжаем без уникального индекса
        require Logger

        Logger.warning(
          "Не удалось создать уникальный индекс на name: #{inspect(reason)}. " <>
            "В базе данных могут быть дубликаты имен."
        )

        :ok
    end

    # Добавляем колонку user_id если её нет (для существующих БД)
    add_user_id_column_query = """
    ALTER TABLE links ADD COLUMN user_id TEXT;
    """

    case Exqlite.Sqlite3.execute(conn, add_user_id_column_query) do
      :ok -> :ok
      # Колонка уже существует - это нормально
      {:error, _} -> :ok
    end

    # Добавляем колонку is_public если её нет (для существующих БД)
    add_is_public_column_query = """
    ALTER TABLE links ADD COLUMN is_public INTEGER DEFAULT 0;
    """

    case Exqlite.Sqlite3.execute(conn, add_is_public_column_query) do
      :ok -> :ok
      # Колонка уже существует - это нормально
      {:error, _} -> :ok
    end

    # Создаем индекс по user_id для фильтрации по пользователю
    create_user_index_query = """
    CREATE INDEX IF NOT EXISTS links_user_id_idx ON links (user_id);
    """

    :ok = Exqlite.Sqlite3.execute(conn, create_user_index_query)

    # Создаем индекс по is_public для быстрого поиска публичных ссылок
    create_public_index_query = """
    CREATE INDEX IF NOT EXISTS links_is_public_idx ON links (is_public);
    """

    :ok = Exqlite.Sqlite3.execute(conn, create_public_index_query)

    {:ok, %{conn: conn}}
  end

  # API для создания новой ссылки
  @impl true
  def create_link(link_params) do
    # Проверяем уникальность name перед созданием
    if link_params["name"] do
      case get_link_by_name(link_params["name"]) do
        {:ok, _existing_link} ->
          {:error, :name_already_exists}

        {:error, :not_found} ->
          # name уникален, продолжаем создание
          now = DateTime.utc_now() |> DateTime.to_iso8601()

          link =
            Map.merge(link_params, %{
              "created_at" => now,
              "updated_at" => now
            })

          query = """
          INSERT INTO links (id, name, url, description, group_id, user_id, is_public, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          """

          # Преобразуем boolean в integer для SQLite
          is_public = if link["is_public"] == true or link["is_public"] == 1, do: 1, else: 0

          params = [
            link["id"],
            link["name"],
            link["url"],
            link["description"] || "",
            link["group_id"] || "",
            link["user_id"] || "guest",
            is_public,
            link["created_at"],
            link["updated_at"]
          ]

          case GenServer.call(__MODULE__, {:execute, query, params}) do
            {:ok, _} ->
              {:ok, link}

            {:error, reason} when is_binary(reason) ->
              if String.contains?(reason, "UNIQUE constraint") do
                {:error, :name_already_exists}
              else
                {:error, reason}
              end

            error ->
              error
          end

        error ->
          error
      end
    else
      {:error, :name_required}
    end
  end

  # API для обновления ссылки
  @impl true
  def update_link(id, link_params) do
    # Получаем существующую ссылку
    case get_link(id) do
      {:ok, existing_link} ->
        # Проверяем уникальность name, если он изменяется
        if link_params["name"] && link_params["name"] != existing_link["name"] do
          case get_link_by_name(link_params["name"]) do
            {:ok, _existing_link} ->
              {:error, :name_already_exists}

            {:error, :not_found} ->
              # name уникален, продолжаем обновление
              update_link_internal(id, existing_link, link_params)

            error ->
              error
          end
        else
          # name не изменяется или не указан, продолжаем обновление
          update_link_internal(id, existing_link, link_params)
        end

      error ->
        error
    end
  end

  # Внутренняя функция для обновления ссылки
  defp update_link_internal(id, existing_link, link_params) do
    # Обновляем только указанные поля
    updated_link = Map.merge(existing_link, link_params)
    updated_link = Map.put(updated_link, "updated_at", DateTime.utc_now() |> DateTime.to_iso8601())

    query = """
    UPDATE links
    SET name = ?, url = ?, description = ?, group_id = ?, user_id = ?, is_public = ?, updated_at = ?
    WHERE id = ?
    """

    # Преобразуем boolean в integer для SQLite
    is_public = if updated_link["is_public"] == true or updated_link["is_public"] == 1, do: 1, else: 0

    # Если is_public не указан, используем значение из существующей ссылки
    is_public =
      if Map.has_key?(updated_link, "is_public"),
        do: is_public,
        else: if(existing_link["is_public"] == 1, do: 1, else: 0)

    params = [
      updated_link["name"],
      updated_link["url"],
      updated_link["description"] || "",
      updated_link["group_id"] || "",
      updated_link["user_id"] || existing_link["user_id"] || "guest",
      is_public,
      updated_link["updated_at"],
      id
    ]

    case GenServer.call(__MODULE__, {:execute, query, params}) do
      {:ok, _} ->
        {:ok, updated_link}

      {:error, reason} when is_binary(reason) ->
        if String.contains?(reason, "UNIQUE constraint") do
          {:error, :name_already_exists}
        else
          {:error, reason}
        end

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

  # API для получения ссылки по name (для коротких ссылок)
  def get_link_by_name(name) do
    query = "SELECT * FROM links WHERE name = ? LIMIT 1"
    params = [name]

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

      error ->
        error
    end
  end

  # API для получения всех ссылок пользователя
  def get_all_links_by_user(user_id) do
    query = "SELECT * FROM links WHERE user_id = ?"
    params = [user_id]

    case GenServer.call(__MODULE__, {:query, query, params}) do
      {:ok, rows} ->
        links = Enum.map(rows, &row_to_map/1)
        {:ok, links}

      error ->
        error
    end
  end

  # API для получения публичной ссылки по имени (доступна всем)
  def get_public_link_by_name(name) do
    query = "SELECT * FROM links WHERE name = ? AND is_public = 1 LIMIT 1"
    params = [name]

    case GenServer.call(__MODULE__, {:query, query, params}) do
      {:ok, []} -> {:error, :not_found}
      {:ok, [row]} -> {:ok, row_to_map(row)}
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

      error ->
        error
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
    result =
      case Exqlite.Sqlite3.prepare(conn, query) do
        {:ok, statement} ->
          case bind_params(conn, statement, params) do
            :ok ->
              case Exqlite.Sqlite3.step(conn, statement) do
                :done -> {:ok, []}
                error -> error
              end

            error ->
              error
          end

        error ->
          error
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:query, query, params}, _from, %{conn: conn} = state) do
    result =
      case Exqlite.Sqlite3.prepare(conn, query) do
        {:ok, statement} ->
          case bind_params(conn, statement, params) do
            :ok ->
              fetch_all_rows(conn, statement, [])

            error ->
              error
          end

        error ->
          error
      end

    {:reply, result, state}
  end

  # Привязка параметров к запросу
  defp bind_params(_conn, _statement, []) do
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

    # Преобразуем is_public из integer в boolean
    row =
      Map.update(row, "is_public", false, fn
        1 -> true
        0 -> false
        val -> val
      end)

    # Преобразуем ISO8601 строки в DateTime
    row =
      if row["created_at"] do
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
