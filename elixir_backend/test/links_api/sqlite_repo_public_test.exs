defmodule LinksApi.SqliteRepoPublicTest do
  use ExUnit.Case

  alias LinksApi.SqliteRepo

  setup do
    # Запускаем репозиторий для тестов
    start_supervised!({LinksApi.SqliteRepo, []})
    :ok
  end

  @public_link_params %{
    "name" => "public-link",
    "url" => "https://public.example.com",
    "description" => "Public link",
    "group_id" => "",
    "user_id" => "user1",
    "is_public" => true
  }

  @private_link_params %{
    "name" => "private-link",
    "url" => "https://private.example.com",
    "description" => "Private link",
    "group_id" => "",
    "user_id" => "user1",
    "is_public" => false
  }

  describe "get_public_link_by_name/1" do
    test "returns public link by name" do
      {:ok, created_link} = SqliteRepo.create_link(@public_link_params)

      assert {:ok, link} = SqliteRepo.get_public_link_by_name(@public_link_params["name"])
      assert link["name"] == @public_link_params["name"]
      assert link["is_public"] == true
      assert link["url"] == @public_link_params["url"]
    end

    test "returns error for private link" do
      {:ok, _link} = SqliteRepo.create_link(@private_link_params)

      assert {:error, :not_found} = SqliteRepo.get_public_link_by_name(@private_link_params["name"])
    end

    test "returns error for non-existent link" do
      assert {:error, :not_found} = SqliteRepo.get_public_link_by_name("non-existent")
    end

    test "only returns links with is_public = 1" do
      # Создаем публичную ссылку
      {:ok, _public_link} = SqliteRepo.create_link(@public_link_params)

      # Создаем приватную ссылку с тем же именем (но это невозможно из-за уникальности name)
      # Вместо этого создадим приватную ссылку с другим именем
      {:ok, _private_link} = SqliteRepo.create_link(Map.put(@private_link_params, "name" => "different-name"))

      # Публичная ссылка должна быть найдена
      assert {:ok, link} = SqliteRepo.get_public_link_by_name(@public_link_params["name"])
      assert link["is_public"] == true

      # Приватная ссылка не должна быть найдена через get_public_link_by_name
      assert {:error, :not_found} = SqliteRepo.get_public_link_by_name("different-name")
    end
  end

  describe "create_link/1 with is_public" do
    test "creates public link with is_public = true" do
      assert {:ok, link} = SqliteRepo.create_link(@public_link_params)
      assert link["is_public"] == true
    end

    test "creates private link with is_public = false" do
      assert {:ok, link} = SqliteRepo.create_link(@private_link_params)
      assert link["is_public"] == false
    end

    test "defaults to false when is_public not specified" do
      params = Map.drop(@public_link_params, ["is_public"])
      assert {:ok, link} = SqliteRepo.create_link(params)
      assert link["is_public"] == false
    end

    test "handles is_public as integer 1" do
      params = Map.put(@public_link_params, "is_public", 1)
      assert {:ok, link} = SqliteRepo.create_link(params)
      assert link["is_public"] == true
    end

    test "handles is_public as integer 0" do
      params = Map.put(@private_link_params, "is_public", 0)
      assert {:ok, link} = SqliteRepo.create_link(params)
      assert link["is_public"] == false
    end
  end

  describe "update_link/2 with is_public" do
    test "updates is_public field" do
      {:ok, link} = SqliteRepo.create_link(@private_link_params)

      update_params = %{"is_public" => true}

      assert {:ok, updated_link} = SqliteRepo.update_link(link["id"], update_params)
      assert updated_link["is_public"] == true
    end

    test "can change from public to private" do
      {:ok, link} = SqliteRepo.create_link(@public_link_params)

      update_params = %{"is_public" => false}

      assert {:ok, updated_link} = SqliteRepo.update_link(link["id"], update_params)
      assert updated_link["is_public"] == false
    end

    test "preserves is_public when not specified in update" do
      {:ok, link} = SqliteRepo.create_link(@public_link_params)

      update_params = %{"description" => "Updated description"}

      assert {:ok, updated_link} = SqliteRepo.update_link(link["id"], update_params)
      assert updated_link["is_public"] == true
      assert updated_link["description"] == "Updated description"
    end
  end

  describe "row_to_map converts is_public correctly" do
    test "converts integer 1 to boolean true" do
      {:ok, link} = SqliteRepo.create_link(@public_link_params)
      # Проверяем, что is_public правильно преобразован
      assert link["is_public"] == true
    end

    test "converts integer 0 to boolean false" do
      {:ok, link} = SqliteRepo.create_link(@private_link_params)
      # Проверяем, что is_public правильно преобразован
      assert link["is_public"] == false
    end
  end
end
