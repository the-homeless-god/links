defmodule LinksApiWeb.AuthPlug do
  @moduledoc """
  Плагин для проверки аутентификации через Keycloak.
  """
  import Plug.Conn
  alias LinksApi.Auth.KeycloakToken

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_token(conn) do
      nil ->
        conn
        |> put_status(401)
        |> Phoenix.Controller.json(%{error: "Unauthorized"})
        |> halt()

      token ->
        case KeycloakToken.verify_token(token) do
          {:ok, claims} ->
            # Сохраняем информацию о пользователе в контексте запроса
            conn
            |> assign(:current_user, claims)
            |> assign(:user_roles, KeycloakToken.get_roles(claims))

          {:error, _reason} ->
            conn
            |> put_status(401)
            |> Phoenix.Controller.json(%{error: "Invalid token"})
            |> halt()
        end
    end
  end

  @doc """
  Извлекает токен из заголовка Authorization.
  """
  def get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end

  @doc """
  Проверяет, имеет ли пользователь требуемую роль.
  Используется как плагин для конкретных маршрутов.
  """
  def require_role(conn, role) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> put_status(401)
        |> Phoenix.Controller.json(%{error: "Unauthorized"})
        |> halt()

      claims ->
        if KeycloakToken.has_role?(claims, role) do
          conn
        else
          conn
          |> put_status(403)
          |> Phoenix.Controller.json(%{error: "Forbidden"})
          |> halt()
        end
    end
  end

  @doc """
  Проверяет, имеет ли пользователь хотя бы одну из требуемых ролей.
  Используется как плагин для конкретных маршрутов.
  """
  def require_any_role(conn, roles) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> put_status(401)
        |> Phoenix.Controller.json(%{error: "Unauthorized"})
        |> halt()

      claims ->
        if KeycloakToken.has_any_role?(claims, roles) do
          conn
        else
          conn
          |> put_status(403)
          |> Phoenix.Controller.json(%{error: "Forbidden"})
          |> halt()
        end
    end
  end

  @doc """
  Проверяет доступ к ссылке на основе группы.
  Пользователь должен принадлежать к той же группе, что и ссылка,
  или иметь роль links-admin.
  """
  def check_link_access(conn, link) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> put_status(401)
        |> Phoenix.Controller.json(%{error: "Unauthorized"})
        |> halt()

      claims ->
        # Администраторы имеют доступ ко всем ссылкам
        if KeycloakToken.has_role?(claims, "links-admin") do
          conn
        else
          # Если у ссылки нет группы, доступ разрешен всем аутентифицированным пользователям
          if link["group_id"] == nil || link["group_id"] == "" do
            conn
          else
            # Проверяем группы пользователя
            user_groups = claims["groups"] || []

            if Enum.member?(user_groups, link["group_id"]) do
              conn
            else
              conn
              |> put_status(403)
              |> Phoenix.Controller.json(%{error: "Forbidden"})
              |> halt()
            end
          end
        end
    end
  end
end
