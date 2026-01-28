defmodule LinksApiWeb.PublicLinkControllerTest do
  use LinksApiWeb.ConnCase

  alias LinksApi.SqliteRepo
  alias LinksApiWeb.RedirectController

  setup %{conn: conn} do
    # SqliteRepo уже запущен в test_helper.exs
    # Очищаем базу данных перед каждым тестом
    SqliteRepo.clear_all_links()
    {:ok, conn: conn}
  end

  defp valid_link_params(name) do
    %{
      "name" => name,
      "url" => "https://example.com",
      "description" => "Public link",
      "group_id" => "",
      "user_id" => "user1",
      "is_public" => true
    }
  end

  defp private_link_params(name) do
    %{
      "name" => name,
      "url" => "https://private.com",
      "description" => "Private link",
      "group_id" => "",
      "user_id" => "user1",
      "is_public" => false
    }
  end

  describe "redirect_public_by_name/2" do
    test "redirects to public link URL", %{conn: _conn} do
      unique_name = "public-link-#{System.unique_integer([:positive])}"
      {:ok, link} = SqliteRepo.create_link(valid_link_params(unique_name))

      test_conn = Plug.Test.conn(:get, "/u/#{link["name"]}")
      result = RedirectController.redirect_public_by_name(test_conn, %{"name" => link["name"]})

      assert result.status == 302
      assert get_resp_header(result, "location") == [link["url"]]
    end

    test "returns 404 for private link", %{conn: _conn} do
      unique_name = "private-link-#{System.unique_integer([:positive])}"
      {:ok, link} = SqliteRepo.create_link(private_link_params(unique_name))

      test_conn = Plug.Test.conn(:get, "/u/#{link["name"]}")
      result = RedirectController.redirect_public_by_name(test_conn, %{"name" => link["name"]})

      assert result.status == 404
    end

    test "returns 404 for non-existent link", %{conn: _conn} do
      test_conn = Plug.Test.conn(:get, "/u/non-existent")
      result = RedirectController.redirect_public_by_name(test_conn, %{"name" => "non-existent"})

      assert result.status == 404
    end

    test "handles URL-encoded names", %{conn: _conn} do
      unique_name = "test-link-#{System.unique_integer([:positive])}"
      {:ok, link} = SqliteRepo.create_link(valid_link_params(unique_name))

      encoded_name = URI.encode(unique_name)
      test_conn = Plug.Test.conn(:get, "/u/#{encoded_name}")
      result = RedirectController.redirect_public_by_name(test_conn, %{"name" => encoded_name})

      assert result.status == 302
      assert get_resp_header(result, "location") == [link["url"]]
    end

    test "allows access to public links without authentication", %{conn: _conn} do
      unique_name = "public-link-#{System.unique_integer([:positive])}"
      {:ok, link} = SqliteRepo.create_link(valid_link_params(unique_name))

      # Создаем conn без авторизации
      test_conn = Plug.Test.conn(:get, "/u/#{link["name"]}")
      result = RedirectController.redirect_public_by_name(test_conn, %{"name" => link["name"]})

      # Должен работать без авторизации
      assert result.status == 302
    end
  end
end
