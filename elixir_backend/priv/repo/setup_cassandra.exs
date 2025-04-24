defmodule LinksApi.SetupCassandra do
  @moduledoc """
  Скрипт для настройки базы данных Cassandra.
  Создает keyspace и таблицу links.
  """

  require Logger

  def run do
    Logger.info("Настройка Cassandra...")

    # Параметры подключения к Cassandra
    nodes = Application.get_env(:links_api, LinksApi.Repo)[:nodes] || ["localhost:9042"]

    with {:ok, conn} <- connect(nodes) do
      # Создаем keyspace, если его еще нет
      create_keyspace(conn)

      # Используем keyspace
      {:ok, _} = Xandra.execute(conn, "USE links_keyspace;")

      # Создаем таблицу links, если ее еще нет
      create_links_table(conn)

      # Создаем индексы для таблицы links
      create_indices(conn)

      Logger.info("✅ Настройка Cassandra завершена успешно!")
    else
      {:error, %Xandra.Error{} = error} ->
        Logger.error("Ошибка Cassandra: #{inspect(error)}")
        System.halt(1)
      error ->
        Logger.error("Ошибка: #{inspect(error)}")
        System.halt(1)
    end
  end

  defp connect(nodes) do
    Logger.info("Подключение к Cassandra: #{inspect(nodes)}")
    Xandra.start_link(nodes: nodes)
  end

  defp create_keyspace(conn) do
    Logger.info("Создание keyspace links_keyspace...")

    # Создаем keyspace с простой стратегией репликации (для разработки)
    create_keyspace_query = """
    CREATE KEYSPACE IF NOT EXISTS links_keyspace
    WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
    """

    case Xandra.execute(conn, create_keyspace_query) do
      {:ok, %Xandra.SchemaChange{}} ->
        Logger.info("Keyspace links_keyspace создан.")
      {:ok, %Xandra.Void{}} ->
        Logger.info("Keyspace links_keyspace уже существует.")
      error ->
        Logger.error("Ошибка при создании keyspace: #{inspect(error)}")
        throw(error)
    end
  end

  defp create_links_table(conn) do
    Logger.info("Создание таблицы links...")

    # Создаем таблицу links с необходимыми полями
    create_table_query = """
    CREATE TABLE IF NOT EXISTS links (
      id text PRIMARY KEY,
      name text,
      url text,
      description text,
      group_id text,
      created_at timestamp,
      updated_at timestamp
    );
    """

    case Xandra.execute(conn, create_table_query) do
      {:ok, %Xandra.SchemaChange{}} ->
        Logger.info("Таблица links создана.")
      {:ok, %Xandra.Void{}} ->
        Logger.info("Таблица links уже существует.")
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

    case Xandra.execute(conn, create_index_query) do
      {:ok, %Xandra.SchemaChange{}} ->
        Logger.info("Индекс links_group_id_idx создан.")
      {:ok, %Xandra.Void{}} ->
        Logger.info("Индекс links_group_id_idx уже существует.")
      error ->
        Logger.error("Ошибка при создании индекса: #{inspect(error)}")
        throw(error)
    end
  end
end

# Запускаем настройку
LinksApi.SetupCassandra.run()
