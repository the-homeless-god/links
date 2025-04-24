defmodule LinksApiWeb.LiveSessionGuard do
  @moduledoc """
  Модуль для проверки аутентификации в LiveView сессиях.
  """
  import Phoenix.Component
  import Phoenix.LiveView
  alias LinksApi.Auth.KeycloakToken

  # Проверка аутентификации для LiveView
  def on_mount(:auth, _params, session, socket) do
    token = session["access_token"]

    if token do
      # Проверяем токен
      case KeycloakToken.verify_token(token) do
        {:ok, claims} ->
          # Проверяем наличие необходимых ролей
          roles = KeycloakToken.get_roles(claims)
          has_access = Enum.any?(["links-admin", "links-editor", "links-viewer"], &Enum.member?(roles, &1))

          if has_access do
            # Сохраняем информацию о пользователе в сокете
            socket =
              socket
              |> assign(:current_user, claims)
              |> assign(:user_roles, roles)
              |> assign(:user_groups, claims["groups"] || [])

            {:cont, socket}
          else
            # У пользователя нет необходимых ролей
            {:halt, redirect(socket, to: "/auth/login")}
          end

        {:error, _} ->
          # Токен недействителен
          {:halt, redirect(socket, to: "/auth/login")}
      end
    else
      # Токен отсутствует
      {:halt, redirect(socket, to: "/auth/login")}
    end
  end
end
