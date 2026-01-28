defmodule LinksApiWeb.RedirectControllerTest do
  use LinksApiWeb.ConnCase, async: true

  import LinksApiWeb.Layouts, only: [sigil_p: 2]
  alias LinksApi.SqliteRepo

  setup do
    # SqliteRepo уже запущен в test_helper.exs
    :ok
  end

  describe "redirect_by_name/2" do
    test "redirects to the target URL when link exists", %{conn: conn} do
      # Создаем тестовую ссылку
      name = "redirect-test-#{System.unique_integer([:positive])}"
      link_params = %{
        "id" => "test-link-#{System.unique_integer([:positive])}",
        "name" => name,
        "url" => "https://example.com",
        "description" => "Test Link",
        "group_id" => "test-group",
        "user_id" => "test-user"
      }

      {:ok, _link} = SqliteRepo.create_link(link_params)

      # Выполняем запрос на редирект
      conn = get(conn, ~p"/r/#{name}")

      # Проверяем, что произошел редирект на правильный URL
      assert redirected_to(conn, 302) == "https://example.com"
    end

    test "returns 404 when link doesn't exist", %{conn: conn} do
      # Выполняем запрос на редирект для несуществующей ссылки
      name = "nonexistent-#{System.unique_integer([:positive])}"
      conn = get(conn, ~p"/r/#{name}")

      # Проверяем, что получен статус 404
      assert conn.status == 404
      assert conn.resp_body =~ "Not Found"
    end
  end

  # Тест для admin_redirect удален, так как маршрут /admin не определен в router
  # Админка отключена согласно router.ex
end
