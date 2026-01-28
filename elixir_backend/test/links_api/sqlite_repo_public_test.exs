defmodule LinksApi.SqliteRepoPublicTest do
  use ExUnit.Case

  alias LinksApi.SqliteRepo

  setup do
    # SqliteRepo уже запущен в test_helper.exs
    # Очищаем базу данных перед каждым тестом
    SqliteRepo.clear_all_links()
    :ok
  end

  defp public_link_params(name \\ nil) do
    unique_name = name || "public-link-#{System.unique_integer([:positive])}-#{:erlang.system_time(:microsecond)}"
    %{
      "name" => unique_name,
      "url" => "https://public.example.com",
      "description" => "Public link",
      "group_id" => "",
      "user_id" => "user1",
      "is_public" => true
    }
  end

  defp private_link_params(name \\ nil) do
    unique_name = name || "private-link-#{System.unique_integer([:positive])}-#{:erlang.system_time(:microsecond)}"
    %{
      "name" => unique_name,
      "url" => "https://private.example.com",
      "description" => "Private link",
      "group_id" => "",
      "user_id" => "user1",
      "is_public" => false
    }
  end

  describe "get_public_link_by_name/1" do
    test "returns public link by name" do
      params = public_link_params()
      {:ok, _created_link} = SqliteRepo.create_link(params)

      assert {:ok, link} = SqliteRepo.get_public_link_by_name(params["name"])
      assert link["name"] == params["name"]
      assert link["is_public"] == true
      assert link["url"] == params["url"]
    end

    test "returns error for private link" do
      params = private_link_params()
      {:ok, _link} = SqliteRepo.create_link(params)

      assert {:error, :not_found} = SqliteRepo.get_public_link_by_name(params["name"])
    end

    test "returns error for non-existent link" do
      assert {:error, :not_found} = SqliteRepo.get_public_link_by_name("non-existent")
    end

    test "only returns links with is_public = 1" do
      # Создаем публичную ссылку
      public_params = public_link_params()
      {:ok, _public_link} = SqliteRepo.create_link(public_params)

      # Создаем приватную ссылку с другим именем
      private_params = private_link_params()
      {:ok, _private_link} = SqliteRepo.create_link(private_params)

      # Публичная ссылка должна быть найдена
      assert {:ok, link} = SqliteRepo.get_public_link_by_name(public_params["name"])
      assert link["is_public"] == true

      # Приватная ссылка не должна быть найдена через get_public_link_by_name
      assert {:error, :not_found} = SqliteRepo.get_public_link_by_name(private_params["name"])
    end
  end

  describe "create_link/1 with is_public" do
    test "creates public link with is_public = true" do
      params = public_link_params()
      assert {:ok, link} = SqliteRepo.create_link(params)
      assert link["is_public"] == true
    end

    test "creates private link with is_public = false" do
      params = private_link_params()
      assert {:ok, link} = SqliteRepo.create_link(params)
      assert link["is_public"] == false
    end

    test "defaults to false when is_public not specified" do
      params = public_link_params() |> Map.drop(["is_public"])
      assert {:ok, link} = SqliteRepo.create_link(params)
      assert link["is_public"] == false
    end

    test "handles is_public as integer 1" do
      params = public_link_params() |> Map.put("is_public", 1)
      assert {:ok, link} = SqliteRepo.create_link(params)
      assert link["is_public"] == true
    end

    test "handles is_public as integer 0" do
      params = private_link_params() |> Map.put("is_public", 0)
      assert {:ok, link} = SqliteRepo.create_link(params)
      assert link["is_public"] == false
    end
  end

  describe "update_link/2 with is_public" do
    test "updates is_public field" do
      params = private_link_params()
      {:ok, link} = SqliteRepo.create_link(params)

      update_params = %{"is_public" => true}

      assert {:ok, updated_link} = SqliteRepo.update_link(link["id"], update_params)
      assert updated_link["is_public"] == true
    end

    test "can change from public to private" do
      params = public_link_params()
      {:ok, link} = SqliteRepo.create_link(params)

      update_params = %{"is_public" => false}

      assert {:ok, updated_link} = SqliteRepo.update_link(link["id"], update_params)
      assert updated_link["is_public"] == false
    end

    test "preserves is_public when not specified in update" do
      params = public_link_params()
      {:ok, link} = SqliteRepo.create_link(params)

      update_params = %{"description" => "Updated description"}

      assert {:ok, updated_link} = SqliteRepo.update_link(link["id"], update_params)
      assert updated_link["is_public"] == true
      assert updated_link["description"] == "Updated description"
    end
  end

  describe "row_to_map converts is_public correctly" do
    test "converts integer 1 to boolean true" do
      params = public_link_params()
      {:ok, link} = SqliteRepo.create_link(params)
      # Проверяем, что is_public правильно преобразован
      assert link["is_public"] == true
    end

    test "converts integer 0 to boolean false" do
      params = private_link_params()
      {:ok, link} = SqliteRepo.create_link(params)
      # Проверяем, что is_public правильно преобразован
      assert link["is_public"] == false
    end
  end
end
