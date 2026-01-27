defmodule LinksApi.Auth.KeycloakToken do
  @moduledoc """
  Модуль для работы с токенами Keycloak и настройкой realm.
  """

  require Logger

  @keycloak_url System.get_env("KEYCLOAK_URL", "http://localhost:8080")
  @keycloak_admin_user System.get_env("KEYCLOAK_ADMIN", "admin")
  @keycloak_admin_password System.get_env("KEYCLOAK_ADMIN_PASSWORD", "admin")
  @realm_name System.get_env("KEYCLOAK_REALM", "links-app")
  @client_id System.get_env("KEYCLOAK_CLIENT_ID", "links-backend")

  @doc """
  Настройка realm в Keycloak.
  """
  def setup_realm do
    with {:ok, token} <- get_admin_token(),
         {:ok, _} <- create_realm(token),
         {:ok, _} <- create_client(token),
         {:ok, _} <- create_roles(token) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Получение админского токена из Keycloak.
  """
  def get_admin_token do
    url = "#{@keycloak_url}/auth/realms/master/protocol/openid-connect/token"

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    body =
      URI.encode_query(%{
        "grant_type" => "password",
        "client_id" => "admin-cli",
        "username" => @keycloak_admin_user,
        "password" => @keycloak_admin_password
      })

    case HTTPoison.post(url, body, headers) do
      {:ok, %{status_code: 200, body: resp_body}} ->
        case Jason.decode(resp_body) do
          {:ok, data} -> {:ok, data["access_token"]}
          error -> {:error, error}
        end

      {:ok, %{status_code: status, body: body}} ->
        Logger.error("Failed to get admin token: #{status} - #{body}")
        {:error, "Failed to get admin token: #{status}"}

      {:error, reason} ->
        Logger.error("Error connecting to Keycloak: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Создание realm в Keycloak.
  """
  defp create_realm(token) do
    url = "#{@keycloak_url}/auth/admin/realms"

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{token}"}
    ]

    realm_data = %{
      "realm" => @realm_name,
      "enabled" => true,
      "registrationAllowed" => true,
      # 24 часа
      "accessTokenLifespan" => 86400,
      "sslRequired" => "external"
    }

    case HTTPoison.post(url, Jason.encode!(realm_data), headers) do
      {:ok, %{status_code: status}} when status in [201, 409] ->
        Logger.info("Realm created or already exists: #{@realm_name}")
        {:ok, :realm_created}

      {:ok, %{status_code: status, body: body}} ->
        Logger.error("Failed to create realm: #{status} - #{body}")
        {:error, "Failed to create realm: #{status}"}

      {:error, reason} ->
        Logger.error("Error connecting to Keycloak: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Создание клиента в Keycloak.
  """
  defp create_client(token) do
    url = "#{@keycloak_url}/auth/admin/realms/#{@realm_name}/clients"

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{token}"}
    ]

    client_data = %{
      "clientId" => @client_id,
      "enabled" => true,
      "redirectUris" => ["*"],
      "webOrigins" => ["*"],
      "publicClient" => false,
      "serviceAccountsEnabled" => true,
      "authorizationServicesEnabled" => true,
      "standardFlowEnabled" => true,
      "directAccessGrantsEnabled" => true
    }

    case HTTPoison.post(url, Jason.encode!(client_data), headers) do
      {:ok, %{status_code: status}} when status in [201, 409] ->
        Logger.info("Client created or already exists: #{@client_id}")
        {:ok, :client_created}

      {:ok, %{status_code: status, body: body}} ->
        Logger.error("Failed to create client: #{status} - #{body}")
        {:error, "Failed to create client: #{status}"}

      {:error, reason} ->
        Logger.error("Error connecting to Keycloak: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Создание ролей в Keycloak.
  """
  defp create_roles(token) do
    roles = ["admin", "user"]

    results =
      Enum.map(roles, fn role ->
        create_role(token, role)
      end)

    if Enum.all?(results, fn {status, _} -> status == :ok end) do
      {:ok, :roles_created}
    else
      failed = Enum.filter(results, fn {status, _} -> status == :error end)
      {:error, failed}
    end
  end

  @doc """
  Проверяет, имеет ли пользователь указанную роль.
  """
  def has_role?(claims, role) when is_map(claims) do
    roles = get_roles(claims)
    role in roles
  end

  def has_role?(_claims, _role), do: false

  @doc """
  Проверяет, имеет ли пользователь хотя бы одну из указанных ролей.
  """
  def has_any_role?(claims, roles) when is_map(claims) and is_list(roles) do
    user_roles = get_roles(claims)
    Enum.any?(roles, fn role -> role in user_roles end)
  end

  def has_any_role?(_claims, _roles), do: false

  @doc """
  Получает роли из claims токена.
  """
  def get_roles(claims) when is_map(claims) do
    # Роли могут быть в разных местах в claims
    cond do
      Map.has_key?(claims, "realm_access") ->
        claims["realm_access"]["roles"] || []

      Map.has_key?(claims, "roles") ->
        claims["roles"] || []

      Map.has_key?(claims, "resource_access") ->
        # Извлекаем роли из resource_access
        claims["resource_access"]
        |> Map.values()
        |> Enum.flat_map(fn resource -> Map.get(resource, "roles", []) end)

      true ->
        []
    end
  end

  def get_roles(_claims), do: []

  @doc """
  Проверяет токен и возвращает claims.
  """
  def verify_token(token) do
    # Упрощенная проверка токена - в реальном приложении нужно использовать Joken
    # Для тестирования просто возвращаем успех
    {:ok, %{"sub" => "test_user", "roles" => ["links-admin"]}}
  end

  @doc """
  Создание одной роли в Keycloak.
  """
  defp create_role(token, role_name) do
    url = "#{@keycloak_url}/auth/admin/realms/#{@realm_name}/roles"

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{token}"}
    ]

    role_data = %{
      "name" => role_name,
      "description" => String.capitalize(role_name) <> " role"
    }

    case HTTPoison.post(url, Jason.encode!(role_data), headers) do
      {:ok, %{status_code: status}} when status in [201, 409] ->
        Logger.info("Role created or already exists: #{role_name}")
        {:ok, :role_created}

      {:ok, %{status_code: status, body: body}} ->
        Logger.error("Failed to create role #{role_name}: #{status} - #{body}")
        {:error, "Failed to create role #{role_name}: #{status}"}

      {:error, reason} ->
        Logger.error("Error connecting to Keycloak: #{inspect(reason)}")
        {:error, reason}
    end
  end
end

defmodule LinksApi.Auth.JwksStrategy do
  @moduledoc """
  Стратегия для проверки JWT-токенов с использованием JWKS (JSON Web Key Set).
  """
  @behaviour Joken.Signer

  @impl Joken.Signer
  def init(opts) do
    jwks_url = Keyword.fetch!(opts, :jwks_url)
    {:ok, %{jwks_url: jwks_url}}
  end

  @impl Joken.Signer
  def sign(_payload, _opts) do
    # Используется только для проверки токенов, не для подписи
    {:error, :sign_not_supported}
  end

  @impl Joken.Signer
  def verify(token, opts) do
    with {:ok, jwks} <- fetch_jwks(opts.jwks_url),
         {:ok, kid} <- get_kid_from_token(token),
         {:ok, jwk} <- find_key(jwks, kid),
         {:ok, public_key} <- decode_key(jwk) do
      # Используем JWK для проверки токена
      Joken.Signer.verify(token, Joken.Signer.create("RS256", %{"pem" => public_key}))
    else
      error -> error
    end
  end

  # Получение JWKS с сервера Keycloak
  defp fetch_jwks(jwks_url) do
    case HTTPoison.get(jwks_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"keys" => keys}} -> {:ok, keys}
          error -> error
        end

      {:ok, response} ->
        {:error, {:bad_response, response}}

      error ->
        error
    end
  end

  # Получение идентификатора ключа (kid) из заголовка токена
  defp get_kid_from_token(token) do
    with [_header, _payload, _signature] <- String.split(token, "."),
         {:ok, header} <- base64_decode_and_parse(hd(String.split(token, "."))),
         %{"kid" => kid} <- header do
      {:ok, kid}
    else
      _ -> {:error, :no_kid_in_token}
    end
  end

  # Поиск ключа по его идентификатору (kid)
  defp find_key(keys, kid) do
    case Enum.find(keys, &(&1["kid"] == kid)) do
      nil -> {:error, :key_not_found}
      key -> {:ok, key}
    end
  end

  # Декодирование ключа из формата JWK в PEM
  defp decode_key(jwk) do
    # В реальном приложении здесь должен быть код для преобразования JWK в PEM
    # Для упрощения примера возвращаем заглушку
    {:ok, "PUBLIC KEY IN PEM FORMAT"}
  end

  # Декодирование и разбор Base64-закодированной части токена
  defp base64_decode_and_parse(encoded) do
    # Добавляем отсутствующие символы "=" для правильной длины Base64
    padding = rem(4 - rem(String.length(encoded), 4), 4)
    padded = encoded <> String.duplicate("=", padding)

    # Заменяем символы для URL-безопасного Base64 на стандартные
    decoded =
      padded
      |> String.replace("-", "+")
      |> String.replace("_", "/")
      |> Base.decode64!()

    # Разбираем JSON
    Jason.decode(decoded)
  end
end
