defmodule LinksApiWeb.ConnCase do
  @moduledoc """
  Этот модуль определяет тестовый case для тестирования
  контроллеров, требующих рабочего соединения.

  Он включает в себя все необходимое для тестирования,
  включая подключение mock Repo.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Импортируем необходимые модули
      import Plug.Conn
      import Phoenix.ConnTest
      import LinksApiWeb.ConnCase
      import Mox

      # Конфигурируем эндпоинт для тестирования
      @endpoint LinksApiWeb.Endpoint

      # Используем Mock Repo для тестирования
      setup do
        Mox.stub_with(LinksApi.MockRepo, LinksApi.MockRepo)
        :ok
      end
    end
  end

  setup _tags do
    # Создаем тестовое соединение
    conn = Phoenix.ConnTest.build_conn()
    {:ok, conn: conn}
  end
end
