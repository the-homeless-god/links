defmodule LinksApiWeb.LinkControllerTest do
  use LinksApiWeb.ConnCase
  import Mox

  alias LinksApi.SqliteRepo

  setup do
    # SqliteRepo уже запущен в test_helper.exs
    :ok
  end

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

  describe "index/2" do
    test "returns only links for authenticated user" do
      # Создаем ссылки для разных пользователей
      {:ok, _link1} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      {:ok, _link2} =
        SqliteRepo.create_link(valid_link_params() |> Map.put("name", "test-link-2") |> Map.put("user_id", @user1_id))

      {:ok, _link3} =
        SqliteRepo.create_link(valid_link_params() |> Map.put("name", "test-link-3") |> Map.put("user_id", @user2_id))

      # Создаем conn с assigns
      conn =
        Plug.Test.conn(:get, "/api/links")
        |> Plug.Conn.assign(:user_id, @user1_id)
        |> Plug.Conn.assign(:current_user, %{"sub" => @user1_id})

      # Вызываем контроллер напрямую
      result = LinkController.index(conn, %{})

      # Проверяем, что вернулись только ссылки user1
      assert result.status == 200
      links = Jason.decode!(result.resp_body)
      assert length(links) == 2
      assert Enum.all?(links, fn link -> link["user_id"] == @user1_id end)
    end

    test "returns empty list when user has no links" do
      # Создаем ссылку для другого пользователя
      {:ok, _link} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user2_id))

      conn =
        Plug.Test.conn(:get, "/api/links")
        |> Plug.Conn.assign(:user_id, @user1_id)
        |> Plug.Conn.assign(:current_user, %{"sub" => @user1_id})

      result = LinkController.index(conn, %{})

      assert result.status == 200
      links = Jason.decode!(result.resp_body)
      assert links == []
    end

    test "guest user sees only guest links" do
      # Создаем ссылки для guest и обычного пользователя
      {:ok, _link1} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @guest_id))

      {:ok, _link2} =
        SqliteRepo.create_link(valid_link_params() |> Map.put("name", "test-link-2") |> Map.put("user_id", @user1_id))

      conn =
        Plug.Test.conn(:get, "/api/links")
        |> Plug.Conn.assign(:user_id, @guest_id)
        |> Plug.Conn.assign(:current_user, %{"sub" => @guest_id})

      result = LinkController.index(conn, %{})

      assert result.status == 200
      links = Jason.decode!(result.resp_body)
      assert length(links) == 1
      assert hd(links)["user_id"] == @guest_id
    end
  end

  describe "create/2" do
    test "creates link with user_id from assigns" do
      conn =
        Plug.Test.conn(:post, "/api/links")
        |> Plug.Conn.assign(:user_id, @user1_id)
        |> Plug.Conn.assign(:current_user, %{"sub" => @user1_id})
        |> Map.put(:body_params, valid_link_params())

      result = LinksApiWeb.LinkController.create(conn, %{})

      assert result.status == 201
      link = Jason.decode!(result.resp_body)
      assert link["name"] == valid_link_params()["name"]
      assert link["user_id"] == @user1_id
    end

    test "uses guest as default user_id when not set" do
      conn =
        Plug.Test.conn(:post, "/api/links")
        |> Plug.Conn.assign(:user_id, @guest_id)
        |> Plug.Conn.assign(:current_user, %{"sub" => @guest_id})
        |> Map.put(:body_params, valid_link_params())

      result = LinksApiWeb.LinkController.create(conn, %{})

      assert result.status == 201
      link = Jason.decode!(result.resp_body)
      assert link["user_id"] == @guest_id
    end

    test "returns error when name already exists for same user" do
      # Создаем ссылку с именем
      {:ok, _existing} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      conn =
        Plug.Test.conn(:post, "/api/links")
        |> Plug.Conn.assign(:user_id, @user1_id)
        |> Plug.Conn.assign(:current_user, %{"sub" => @user1_id})
        |> Map.put(:body_params, valid_link_params())

      result = LinksApiWeb.LinkController.create(conn, %{})

      assert result.status == 422
      error = Jason.decode!(result.resp_body)
      assert error["error"] == "name_already_exists"
    end

    test "allows same name for different users" do
      # Создаем ссылку для user1
      {:ok, _link1} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      # Пытаемся создать ссылку с тем же именем для user2
      conn =
        Plug.Test.conn(:post, "/api/links")
        |> Plug.Conn.assign(:user_id, @user2_id)
        |> Plug.Conn.assign(:current_user, %{"sub" => @user2_id})
        |> Map.put(:body_params, valid_link_params())

      result = LinksApiWeb.LinkController.create(conn, %{})

      # Должно быть успешно, так как это другой пользователь
      assert result.status == 201
      link = Jason.decode!(result.resp_body)
      assert link["name"] == valid_link_params()["name"]
      assert link["user_id"] == @user2_id
    end
  end

  describe "update/2" do
    test "updates link belonging to user" do
      {:ok, link} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      update_params = %{"name" => "updated-name", "url" => "https://updated.com"}

      conn =
        Plug.Test.conn(:put, "/api/links/#{link["id"]}")
        |> Plug.Conn.assign(:user_id, @user1_id)
        |> Plug.Conn.assign(:current_user, %{"sub" => @user1_id})
        |> Map.put(:body_params, update_params)

      result = LinkController.update(conn, %{"id" => link["id"]})

      assert result.status == 200
      updated_link = Jason.decode!(result.resp_body)
      assert updated_link["name"] == "updated-name"
      assert updated_link["url"] == "https://updated.com"
      assert updated_link["user_id"] == @user1_id
    end

    test "returns 403 when trying to update another user's link" do
      {:ok, link} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      update_params = %{"name" => "updated-name"}

      conn =
        Plug.Test.conn(:put, "/api/links/#{link["id"]}")
        # Другой пользователь
        |> Plug.Conn.assign(:user_id, @user2_id)
        |> Plug.Conn.assign(:current_user, %{"sub" => @user2_id})
        |> Map.put(:body_params, update_params)

      result = LinkController.update(conn, %{"id" => link["id"]})

      assert result.status == 403
      error = Jason.decode!(result.resp_body)
      assert error["error"] =~ "Forbidden"
    end

    test "returns 404 when link does not exist" do
      conn =
        Plug.Test.conn(:put, "/api/links/non-existent-id")
        |> Plug.Conn.assign(:user_id, @user1_id)
        |> Plug.Conn.assign(:current_user, %{"sub" => @user1_id})
        |> Map.put(:body_params, %{"name" => "test"})

      result = LinkController.update(conn, %{"id" => "non-existent-id"})

      assert result.status == 404
    end
  end

  describe "delete/2" do
    test "deletes link belonging to user" do
      {:ok, link} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      conn =
        Plug.Test.conn(:delete, "/api/links/#{link["id"]}")
        |> Plug.Conn.assign(:user_id, @user1_id)
        |> Plug.Conn.assign(:current_user, %{"sub" => @user1_id})

      result = LinkController.delete(conn, %{"id" => link["id"]})

      assert result.status == 204

      # Проверяем, что ссылка удалена
      assert {:error, :not_found} = SqliteRepo.get_link(link["id"])
    end

    test "returns 403 when trying to delete another user's link" do
      {:ok, link} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      conn =
        Plug.Test.conn(:delete, "/api/links/#{link["id"]}")
        # Другой пользователь
        |> Plug.Conn.assign(:user_id, @user2_id)
        |> Plug.Conn.assign(:current_user, %{"sub" => @user2_id})

      result = LinkController.delete(conn, %{"id" => link["id"]})

      assert result.status == 403
      error = Jason.decode!(result.resp_body)
      assert error["error"] =~ "Forbidden"

      # Проверяем, что ссылка не удалена
      assert {:ok, _} = SqliteRepo.get_link(link["id"])
    end

    test "returns 404 when link does not exist" do
      conn =
        Plug.Test.conn(:delete, "/api/links/non-existent-id")
        |> Plug.Conn.assign(:user_id, @user1_id)
        |> Plug.Conn.assign(:current_user, %{"sub" => @user1_id})

      result = LinkController.delete(conn, %{"id" => "non-existent-id"})

      assert result.status == 404
    end
  end

  describe "show/2" do
    test "returns link by id" do
      {:ok, link} = SqliteRepo.create_link(Map.put(valid_link_params(), "user_id", @user1_id))

      conn = Plug.Test.conn(:get, "/api/links/#{link["id"]}")

      result = LinkController.show(conn, %{"id" => link["id"]})

      assert result.status == 200
      returned_link = Jason.decode!(result.resp_body)
      assert returned_link["id"] == link["id"]
      assert returned_link["name"] == link["name"]
    end

    test "returns 404 when link does not exist" do
      conn = Plug.Test.conn(:get, "/api/links/non-existent-id")

      result = LinkController.show(conn, %{"id" => "non-existent-id"})

      assert result.status == 404
    end
  end
end
