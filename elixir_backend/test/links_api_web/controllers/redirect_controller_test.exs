defmodule LinksApiWeb.RedirectControllerTest do
  use LinksApiWeb.ConnCase, async: true

  import Mox
  import LinksApiWeb.Layouts, only: [sigil_p: 2]

  # Настройка mock для Repo
  setup do
    # Убедитесь, что все ожидания выполнены после теста
    verify_on_exit!()
    :ok
  end

  describe "redirect_by_id/2" do
    test "redirects to the target URL when link exists", %{conn: conn} do
      # Имитируем Repo.get_link для тестового ID
      mock_link = %{
        "id" => "test-link",
        "url" => "https://example.com",
        "name" => "Test Link",
        "group_id" => "test-group"
      }

      # Настраиваем мок для Repo
      expect(LinksApi.MockRepo, :get_link, fn "test-link" ->
        {:ok, mock_link}
      end)

      # Выполняем запрос на редирект
      conn = get(conn, ~p"/r/test-link")

      # Проверяем, что произошел редирект на правильный URL
      assert redirected_to(conn, 302) == "https://example.com"
    end

    test "returns 404 when link doesn't exist", %{conn: conn} do
      # Настраиваем мок для несуществующей ссылки
      expect(LinksApi.MockRepo, :get_link, fn "nonexistent" ->
        {:error, :not_found}
      end)

      # Выполняем запрос на редирект
      conn = get(conn, ~p"/r/nonexistent")

      # Проверяем, что получен статус 404
      assert conn.status == 404
      assert conn.resp_body =~ "Not Found"
    end

    test "returns 500 on database error", %{conn: conn} do
      # Настраиваем мок для имитации ошибки БД
      expect(LinksApi.MockRepo, :get_link, fn "error-link" ->
        {:error, :database_error}
      end)

      # Выполняем запрос на редирект
      conn = get(conn, ~p"/r/error-link")

      # Проверяем, что получен статус 500
      assert conn.status == 500
      assert conn.resp_body =~ "Internal Server Error"
    end
  end

  # Тест для admin_redirect удален, так как маршрут /admin не определен в router
  # Админка отключена согласно router.ex
end
