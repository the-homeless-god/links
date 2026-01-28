defmodule LinksApi.Integration.LinksApiTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Интеграционный тест для проверки взаимодействия с API.
  Требует запущенную Cassandra и систему.
  """

  alias LinksApi.SqliteRepo

  setup do
    # Создаем тестовые данные с уникальными именами
    unique_name = "test-link-#{System.unique_integer([:positive])}"
    test_link = %{
      "id" => "test-link-#{System.unique_integer([:positive])}",
      "name" => unique_name,
      "url" => "https://example.com",
      "description" => "Test link for integration testing",
      "group_id" => "test-group"
    }

    {:ok, %{test_link: test_link}}
  end

  describe "Link API" do
    test "create and retrieve a link", %{test_link: link} do
      # Создаем ссылку
      {:ok, created_link} = SqliteRepo.create_link(link)

      # Проверяем, что ссылка создана с правильными данными
      assert created_link["id"] == link["id"]
      assert created_link["name"] == link["name"]
      assert created_link["url"] == link["url"]

      # Получаем ссылку и проверяем данные
      {:ok, retrieved_link} = SqliteRepo.get_link(link["id"])
      assert retrieved_link["id"] == link["id"]
      assert retrieved_link["name"] == link["name"]
      assert retrieved_link["url"] == link["url"]
      assert retrieved_link["description"] == link["description"]
      assert retrieved_link["group_id"] == link["group_id"]

      # Проверяем, что created_at и updated_at установлены
      assert retrieved_link["created_at"] != nil
      assert retrieved_link["updated_at"] != nil
    end

    test "update a link", %{test_link: link} do
      # Создаем ссылку
      {:ok, _created_link} = SqliteRepo.create_link(link)

      # Обновляем ссылку
      updated_name = "updated-name-#{System.unique_integer([:positive])}"
      updated_data = %{
        "name" => updated_name,
        "description" => "Updated description"
      }

      {:ok, updated_link} = SqliteRepo.update_link(link["id"], updated_data)

      # Проверяем, что изменения сохранены
      assert updated_link["id"] == link["id"]
      assert updated_link["name"] == updated_name
      assert updated_link["description"] == "Updated description"
      # Не изменилось
      assert updated_link["url"] == link["url"]

      # Получаем ссылку и проверяем обновленные данные
      {:ok, retrieved_link} = SqliteRepo.get_link(link["id"])
      assert retrieved_link["name"] == updated_name
      assert retrieved_link["description"] == "Updated description"
    end

    test "delete a link", %{test_link: link} do
      # Создаем ссылку
      {:ok, _created_link} = SqliteRepo.create_link(link)

      # Удаляем ссылку
      :ok = SqliteRepo.delete_link(link["id"])

      # Проверяем, что ссылка удалена
      assert {:error, :not_found} = SqliteRepo.get_link(link["id"])
    end

    test "get links by group", %{test_link: link} do
      # Создаем ссылку
      {:ok, _created_link} = SqliteRepo.create_link(link)

      # Создаем ещё одну ссылку в той же группе
      second_link = %{
        "id" => "test-link-#{System.unique_integer([:positive])}",
        "name" => "second-test-link-#{System.unique_integer([:positive])}",
        "url" => "https://example.org",
        "description" => "Another test link",
        "group_id" => link["group_id"]
      }

      {:ok, _second_created} = SqliteRepo.create_link(second_link)

      # Получаем ссылки по группе
      {:ok, links_by_group} = SqliteRepo.get_links_by_group(link["group_id"])

      # Проверяем, что обе ссылки найдены
      assert Enum.count(links_by_group) >= 2

      # Проверяем, что обе наши ссылки есть в результате
      link_ids = Enum.map(links_by_group, & &1["id"])
      assert link["id"] in link_ids
      assert second_link["id"] in link_ids

      # Очистка
      SqliteRepo.delete_link(second_link["id"])
    end
  end
end
