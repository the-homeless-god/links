defmodule LinksApi.Integration.LinksApiTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Интеграционный тест для проверки взаимодействия с API.
  Требует запущенную Cassandra и систему.
  """

  alias LinksApi.Repo

  setup do
    # Очистка таблицы ссылок перед каждым тестом
    # (В реальном проекте лучше использовать тестовую базу данных)
    # Repo.clear_links_for_test()

    # Создаем тестовые данные
    test_link = %{
      "id" => "test-link-#{System.unique_integer([:positive])}",
      "name" => "Test Link",
      "url" => "https://example.com",
      "description" => "Test link for integration testing",
      "group_id" => "test-group"
    }

    # Очищаем после теста
    on_exit(fn ->
      # Repo.delete_link(test_link["id"])
      :ok
    end)

    {:ok, %{test_link: test_link}}
  end

  describe "Link API" do
    test "create and retrieve a link", %{test_link: link} do
      # Создаем ссылку
      {:ok, created_link} = Repo.create_link(link)

      # Проверяем, что ссылка создана с правильными данными
      assert created_link["id"] == link["id"]
      assert created_link["name"] == link["name"]
      assert created_link["url"] == link["url"]

      # Получаем ссылку и проверяем данные
      {:ok, retrieved_link} = Repo.get_link(link["id"])
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
      {:ok, _created_link} = Repo.create_link(link)

      # Обновляем ссылку
      updated_data = %{
        "name" => "Updated Name",
        "description" => "Updated description"
      }

      {:ok, updated_link} = Repo.update_link(link["id"], updated_data)

      # Проверяем, что изменения сохранены
      assert updated_link["id"] == link["id"]
      assert updated_link["name"] == "Updated Name"
      assert updated_link["description"] == "Updated description"
      assert updated_link["url"] == link["url"] # Не изменилось

      # Получаем ссылку и проверяем обновленные данные
      {:ok, retrieved_link} = Repo.get_link(link["id"])
      assert retrieved_link["name"] == "Updated Name"
      assert retrieved_link["description"] == "Updated description"
    end

    test "delete a link", %{test_link: link} do
      # Создаем ссылку
      {:ok, _created_link} = Repo.create_link(link)

      # Удаляем ссылку
      :ok = Repo.delete_link(link["id"])

      # Проверяем, что ссылка удалена
      assert {:error, :not_found} = Repo.get_link(link["id"])
    end

    test "get links by group", %{test_link: link} do
      # Создаем ссылку
      {:ok, _created_link} = Repo.create_link(link)

      # Создаем ещё одну ссылку в той же группе
      second_link = %{
        "id" => "test-link-#{System.unique_integer([:positive])}",
        "name" => "Second Test Link",
        "url" => "https://example.org",
        "description" => "Another test link",
        "group_id" => link["group_id"]
      }

      {:ok, _second_created} = Repo.create_link(second_link)

      # Получаем ссылки по группе
      {:ok, links_by_group} = Repo.get_links_by_group(link["group_id"])

      # Проверяем, что обе ссылки найдены
      assert Enum.count(links_by_group) >= 2

      # Проверяем, что обе наши ссылки есть в результате
      link_ids = Enum.map(links_by_group, & &1["id"])
      assert link["id"] in link_ids
      assert second_link["id"] in link_ids

      # Очистка
      Repo.delete_link(second_link["id"])
    end
  end
end
