defmodule LinksApiWeb.LiveSessionGuard do
  @moduledoc """
  Модуль для проверки аутентификации в LiveView сессиях.
  """
  import Phoenix.Component
  import Phoenix.LiveView
  alias LinksApi.Auth.KeycloakToken

  # Проверка аутентификации для LiveView - временно отключена для тестирования
  def on_mount(:auth, _params, _session, socket) do
    # Создаем тестового пользователя с ролью админа
    current_user = %{"sub" => "test_user", "name" => "Test User"}
    user_roles = ["links-admin", "links-editor", "links-viewer"]
    user_groups = ["default_group"]

    # Проверяем, есть ли assigns в socket, если нет - инициализируем
    socket =
      if is_map_key(socket, :assigns) do
        socket
        |> assign(:current_user, current_user)
        |> assign(:user_roles, user_roles)
        |> assign(:user_groups, user_groups)
      else
        # Создаем структуру с assigns
        Map.put(socket, :assigns, %{
          current_user: current_user,
          user_roles: user_roles,
          user_groups: user_groups
        })
      end

    {:cont, nil}
  end
end
