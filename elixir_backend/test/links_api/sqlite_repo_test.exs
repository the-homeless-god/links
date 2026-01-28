defmodule LinksApi.SqliteRepoTest do
  use ExUnit.Case

  alias LinksApi.SqliteRepo

  defp valid_link_params(name \\ nil) do
    unique_name = name || "test-link-#{System.unique_integer([:positive])}"
    %{
      "name" => unique_name,
      "url" => "https://example.com",
      "description" => "Test description",
      "group_id" => "test-group"
    }
  end

  @user1_id "user1"
  @user2_id "user2"
  @guest_id "guest"

  setup do
    # SqliteRepo уже запущен в test_helper.exs
    :ok
  end

  describe "create_link/1" do
    test "creates link with user_id" do
      params = Map.put(valid_link_params(), "user_id", @user1_id)

      assert {:ok, link} = SqliteRepo.create_link(params)
      assert link["user_id"] == @user1_id
    end

    test "uses guest as default user_id when not provided" do
      params = valid_link_params()
      assert {:ok, link} = SqliteRepo.create_link(params)
      assert link["user_id"] == @guest_id
    end

    test "returns error when name already exists for same user" do
      name = "duplicate-test-#{System.unique_integer([:positive])}"
      params = Map.put(valid_link_params(name), "user_id", @user1_id)
      assert {:ok, _link} = SqliteRepo.create_link(params)

      # Пытаемся создать ссылку с тем же именем для того же пользователя
      assert {:error, :name_already_exists} = SqliteRepo.create_link(params)
    end

    test "allows same name for different users" do
      name = "shared-name-#{System.unique_integer([:positive])}"
      params1 = Map.put(valid_link_params(name), "user_id", @user1_id)
      params2 = Map.put(valid_link_params(name), "user_id", @user2_id)

      assert {:ok, link1} = SqliteRepo.create_link(params1)
      assert {:ok, link2} = SqliteRepo.create_link(params2)

      assert link1["name"] == link2["name"]
      assert link1["user_id"] == @user1_id
      assert link2["user_id"] == @user2_id
    end

    test "returns error when name is required but not provided" do
      params = valid_link_params() |> Map.drop(["name"])
      assert {:error, :name_required} = SqliteRepo.create_link(params)
    end
  end

  describe "get_all_links_by_user/1" do
    test "returns only links for specified user" do
      # Создаем ссылки для разных пользователей
      {:ok, _link1} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      {:ok, _link2} =
        SqliteRepo.create_link(valid_link_params() |> Map.put("user_id", @user1_id))

      {:ok, _link3} =
        SqliteRepo.create_link(valid_link_params() |> Map.put("user_id", @user2_id))

      assert {:ok, links} = SqliteRepo.get_all_links_by_user(@user1_id)
      assert length(links) == 2
      assert Enum.all?(links, fn link -> link["user_id"] == @user1_id end)
    end

    test "returns empty list when user has no links" do
      # Создаем ссылку для другого пользователя
      {:ok, _link} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user2_id))

      assert {:ok, links} = SqliteRepo.get_all_links_by_user(@user1_id)
      assert links == []
    end

    test "returns guest links for guest user" do
      {:ok, _link1} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @guest_id))

      {:ok, _link2} =
        SqliteRepo.create_link(valid_link_params() |> Map.put("user_id", @user1_id))

      assert {:ok, links} = SqliteRepo.get_all_links_by_user(@guest_id)
      assert length(links) == 1
      assert hd(links)["user_id"] == @guest_id
    end
  end

  describe "update_link/2" do
    test "updates link and preserves user_id" do
      {:ok, link} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      update_params = %{
        "name" => "updated-name-#{System.unique_integer([:positive])}",
        "url" => "https://updated.com",
        "user_id" => @user1_id
      }

      assert {:ok, updated_link} = SqliteRepo.update_link(link["id"], update_params)
      assert updated_link["url"] == "https://updated.com"
      assert updated_link["user_id"] == @user1_id
    end

    test "preserves existing user_id when not provided in update" do
      {:ok, link} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      update_params = %{
        "name" => "updated-name-#{System.unique_integer([:positive])}"
      }

      assert {:ok, updated_link} = SqliteRepo.update_link(link["id"], update_params)
      assert updated_link["user_id"] == @user1_id
    end

    test "returns error when trying to update with duplicate name for same user" do
      name1 = "duplicate-update-#{System.unique_integer([:positive])}"
      name2 = "duplicate-update-2-#{System.unique_integer([:positive])}"
      {:ok, _link1} = SqliteRepo.create_link(Map.put(valid_link_params(name1), "user_id", @user1_id))

      {:ok, link2} =
        SqliteRepo.create_link(valid_link_params(name2) |> Map.put("user_id", @user1_id))

      # Пытаемся переименовать link2 в имя link1
      update_params = %{"name" => name1}

      assert {:error, :name_already_exists} = SqliteRepo.update_link(link2["id"], update_params)
    end

    test "allows updating to same name if it's the same link" do
      name = "same-name-#{System.unique_integer([:positive])}"
      {:ok, link} = SqliteRepo.create_link(Map.put(valid_link_params(name), "user_id", @user1_id))

      update_params = %{
        "name" => name,
        "url" => "https://updated.com"
      }

      assert {:ok, updated_link} = SqliteRepo.update_link(link["id"], update_params)
      assert updated_link["name"] == name
    end
  end

  describe "get_link/1" do
    test "returns link by id" do
      {:ok, created_link} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      assert {:ok, link} = SqliteRepo.get_link(created_link["id"])
      assert link["id"] == created_link["id"]
      assert link["name"] == created_link["name"]
      assert link["user_id"] == @user1_id
    end

    test "returns error when link does not exist" do
      assert {:error, :not_found} = SqliteRepo.get_link("non-existent-id")
    end
  end

  describe "get_link_by_name/1" do
    test "returns link by name" do
      name = "get-by-name-#{System.unique_integer([:positive])}"
      {:ok, created_link} = SqliteRepo.create_link(Map.put(valid_link_params(name), "user_id", @user1_id))

      assert {:ok, link} = SqliteRepo.get_link_by_name(name)
      assert link["name"] == name
      assert link["user_id"] == @user1_id
    end

    test "returns error when link with name does not exist" do
      assert {:error, :not_found} = SqliteRepo.get_link_by_name("non-existent-name")
    end
  end

  describe "delete_link/1" do
    test "deletes link by id" do
      {:ok, link} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      assert :ok = SqliteRepo.delete_link(link["id"])
      assert {:error, :not_found} = SqliteRepo.get_link(link["id"])
    end

    test "returns ok even when link does not exist" do
      assert :ok = SqliteRepo.delete_link("non-existent-id")
    end
  end

  describe "get_links_by_group/1" do
    test "returns links filtered by group_id and user_id" do
      # Создаем ссылки для разных групп и пользователей
      {:ok, _link1} =
        SqliteRepo.create_link(valid_link_params() |> Map.put("user_id", @user1_id) |> Map.put("group_id", "group1"))

      {:ok, _link2} =
        SqliteRepo.create_link(
          valid_link_params()
          |> Map.put("user_id", @user1_id)
          |> Map.put("group_id", "group1")
        )

      {:ok, _link3} =
        SqliteRepo.create_link(
          valid_link_params()
          |> Map.put("user_id", @user1_id)
          |> Map.put("group_id", "group2")
        )

      {:ok, _link4} =
        SqliteRepo.create_link(
          valid_link_params()
          |> Map.put("user_id", @user2_id)
          |> Map.put("group_id", "group1")
        )

      assert {:ok, links} = SqliteRepo.get_links_by_group("group1")
      # Должны вернуться все ссылки группы group1 (независимо от user_id)
      assert length(links) == 3
      assert Enum.all?(links, fn link -> link["group_id"] == "group1" end)
    end

    test "returns empty list when no links in group" do
      assert {:ok, links} = SqliteRepo.get_links_by_group("non-existent-group")
      assert links == []
    end
  end

  describe "user isolation" do
    test "users cannot see each other's links" do
      {:ok, link1} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      {:ok, link2} =
        SqliteRepo.create_link(valid_link_params() |> Map.put("user_id", @user2_id))

      assert {:ok, user1_links} = SqliteRepo.get_all_links_by_user(@user1_id)
      assert {:ok, user2_links} = SqliteRepo.get_all_links_by_user(@user2_id)

      assert length(user1_links) == 1
      assert length(user2_links) == 1
      assert hd(user1_links)["id"] == link1["id"]
      assert hd(user2_links)["id"] == link2["id"]
    end

    test "guest users are isolated from regular users" do
      {:ok, _guest_link} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @guest_id))

      {:ok, _user_link} =
        SqliteRepo.create_link(valid_link_params() |> Map.put("user_id", @user1_id))

      assert {:ok, guest_links} = SqliteRepo.get_all_links_by_user(@guest_id)
      assert {:ok, user_links} = SqliteRepo.get_all_links_by_user(@user1_id)

      assert length(guest_links) == 1
      assert length(user_links) == 1
      assert hd(guest_links)["user_id"] == @guest_id
      assert hd(user_links)["user_id"] == @user1_id
    end
  end
end
