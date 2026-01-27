defmodule LinksApiWeb.PublicLinkControllerTest do
  use ExUnit.Case

  alias LinksApi.SqliteRepo
  alias LinksApiWeb.RedirectController

  setup do
    # Запускаем репозиторий для тестов
    start_supervised!({LinksApi.SqliteRepo, []})
    :ok
  end

  @valid_link_params %{
    "name" => "public-link",
    "url" => "https://example.com",
    "description" => "Public link",
    "group_id" => "",
    "user_id" => "user1",
    "is_public" => true
  }

  @private_link_params %{
    "name" => "private-link",
    "url" => "https://private.com",
    "description" => "Private link",
    "group_id" => "",
    "user_id" => "user1",
    "is_public" => false
  }

  describe "redirect_public_by_name/2" do
    test "redirects to public link URL" do
      {:ok, link} = SqliteRepo.create_link(@valid_link_params)

      conn = Plug.Test.conn(:get, "/u/#{link["name"]}")

      result = RedirectController.redirect_public_by_name(conn, %{"name" => link["name"]})

      assert result.status == 302
      assert get_resp_header(result, "location") == [link["url"]]
    end

    test "returns 404 for private link" do
      {:ok, link} = SqliteRepo.create_link(@private_link_params)

      conn = Plug.Test.conn(:get, "/u/#{link["name"]}")

      result = RedirectController.redirect_public_by_name(conn, %{"name" => link["name"]})

      assert result.status == 404
    end

    test "returns 404 for non-existent link" do
      conn = Plug.Test.conn(:get, "/u/non-existent")

      result = RedirectController.redirect_public_by_name(conn, %{"name" => "non-existent"})

      assert result.status == 404
    end

    test "handles URL-encoded names" do
      {:ok, link} = SqliteRepo.create_link(Map.put(@valid_link_params, "name" => "test-link-123"))

      encoded_name = URI.encode("test-link-123")
      conn = Plug.Test.conn(:get, "/u/#{encoded_name}")

      result = RedirectController.redirect_public_by_name(conn, %{"name" => encoded_name})

      assert result.status == 302
      assert get_resp_header(result, "location") == [link["url"]]
    end

    test "allows access to public links without authentication" do
      {:ok, link} = SqliteRepo.create_link(@valid_link_params)

      # Создаем conn без авторизации
      conn = Plug.Test.conn(:get, "/u/#{link["name"]}")

      result = RedirectController.redirect_public_by_name(conn, %{"name" => link["name"]})

      # Должен работать без авторизации
      assert result.status == 302
    end
  end
end
