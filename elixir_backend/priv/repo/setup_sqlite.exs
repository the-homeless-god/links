defmodule LinksApi.SetupSqlite do
  @moduledoc """
  Скрипт для настройки базы данных SQLite.
  Создает таблицу links.
  """

  require Logger

  @db_path Path.join([File.cwd!(), "priv/db/links.db"])

  def run do
    Logger.info("Настройка SQLite...")

    # Убедимся что директория существует
    db_dir = Path.dirname(@db_path)
    File.mkdir_p!(db_dir)

    # Открываем соединение с базой данных
    with {:ok, conn} <- Exqlite.Sqlite3.open(@db_path) do
      # Создаем таблицу links, если ее еще нет
      create_links_table(conn)

      # Создаем индексы для таблицы links
      create_indices(conn)

      Logger.info("✅ Настройка SQLite завершена успешно!")
    else
      {:error, error} ->
        Logger.error("Ошибка SQLite: #{inspect(error)}")
        System.halt(1)
    end
  end

  defp create_links_table(conn) do
    Logger.info("Создание таблицы links...")

    # Создаем таблицу links с необходимыми полями
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

    case Exqlite.Sqlite3.execute(conn, create_table_query) do
      :ok ->
        Logger.info("Таблица links создана или уже существует.")
      error ->
        Logger.error("Ошибка при создании таблицы: #{inspect(error)}")
        throw(error)
    end
  end

  defp create_indices(conn) do
    Logger.info("Создание индексов...")

    # Создаем индекс по group_id для оптимизации запросов по группам
    create_index_query = """
    CREATE INDEX IF NOT EXISTS links_group_id_idx ON links (group_id);
    """

    case Exqlite.Sqlite3.execute(conn, create_index_query) do
      :ok ->
        Logger.info("Индекс links_group_id_idx создан или уже существует.")
      error ->
        Logger.error("Ошибка при создании индекса: #{inspect(error)}")
        throw(error)
    end
  end
end

# Запускаем настройку
LinksApi.SetupSqlite.run()
