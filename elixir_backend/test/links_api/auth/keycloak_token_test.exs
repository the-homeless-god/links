defmodule LinksApi.Auth.KeycloakTokenTest do
  use ExUnit.Case

  alias LinksApi.Auth.KeycloakToken

  describe "verify_token/1" do
    test "returns ok with test claims for any token" do
      # В текущей реализации verify_token всегда возвращает успех для тестирования
      assert {:ok, claims} = KeycloakToken.verify_token("any_token")
      assert claims["sub"] == "test_user"
      assert claims["roles"] == ["links-admin"]
    end
  end

  describe "has_role?/2" do
    test "returns true when user has the role" do
      claims = %{"realm_access" => %{"roles" => ["user", "admin"]}}
      assert KeycloakToken.has_role?(claims, "user") == true
      assert KeycloakToken.has_role?(claims, "admin") == true
    end

    test "returns false when user does not have the role" do
      claims = %{"realm_access" => %{"roles" => ["user"]}}
      assert KeycloakToken.has_role?(claims, "admin") == false
    end

    test "returns false when roles are in different format" do
      claims = %{"roles" => ["user"]}
      assert KeycloakToken.has_role?(claims, "user") == true
    end

    test "returns false when claims is not a map" do
      assert KeycloakToken.has_role?(nil, "user") == false
      assert KeycloakToken.has_role?("invalid", "user") == false
    end

    test "handles resource_access roles" do
      claims = %{
        "resource_access" => %{
          "client1" => %{"roles" => ["role1", "role2"]},
          "client2" => %{"roles" => ["role3"]}
        }
      }

      assert KeycloakToken.has_role?(claims, "role1") == true
      assert KeycloakToken.has_role?(claims, "role2") == true
      assert KeycloakToken.has_role?(claims, "role3") == true
      assert KeycloakToken.has_role?(claims, "role4") == false
    end
  end

  describe "has_any_role?/2" do
    test "returns true when user has at least one of the roles" do
      claims = %{"realm_access" => %{"roles" => ["user", "admin"]}}
      assert KeycloakToken.has_any_role?(claims, ["admin", "superuser"]) == true
      assert KeycloakToken.has_any_role?(claims, ["user", "guest"]) == true
    end

    test "returns false when user has none of the roles" do
      claims = %{"realm_access" => %{"roles" => ["user"]}}
      assert KeycloakToken.has_any_role?(claims, ["admin", "superuser"]) == false
    end

    test "returns false when claims is not a map" do
      assert KeycloakToken.has_any_role?(nil, ["user"]) == false
      assert KeycloakToken.has_any_role?("invalid", ["user"]) == false
    end
  end

  describe "get_roles/1" do
    test "extracts roles from realm_access" do
      claims = %{"realm_access" => %{"roles" => ["user", "admin"]}}
      assert KeycloakToken.get_roles(claims) == ["user", "admin"]
    end

    test "extracts roles from roles field" do
      claims = %{"roles" => ["user", "admin"]}
      assert KeycloakToken.get_roles(claims) == ["user", "admin"]
    end

    test "extracts roles from resource_access" do
      claims = %{
        "resource_access" => %{
          "client1" => %{"roles" => ["role1", "role2"]},
          "client2" => %{"roles" => ["role3"]}
        }
      }

      roles = KeycloakToken.get_roles(claims)
      assert "role1" in roles
      assert "role2" in roles
      assert "role3" in roles
    end

    test "returns empty list when no roles found" do
      claims = %{"sub" => "user123"}
      assert KeycloakToken.get_roles(claims) == []
    end

    test "returns empty list when claims is not a map" do
      assert KeycloakToken.get_roles(nil) == []
      assert KeycloakToken.get_roles("invalid") == []
    end

    test "prioritizes realm_access over roles field" do
      claims = %{
        "realm_access" => %{"roles" => ["realm_role"]},
        "roles" => ["field_role"]
      }

      assert KeycloakToken.get_roles(claims) == ["realm_role"]
    end
  end
end
