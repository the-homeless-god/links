defmodule LinksApi.Schemas.LinkTest do
  use ExUnit.Case, async: true
  alias LinksApi.Schemas.Link

  describe "changeset/2" do
    test "valid attributes" do
      attrs = %{
        id: "test-link-1",
        name: "Test Link",
        url: "https://example.com",
        description: "Test description",
        group_id: "test-group"
      }

      changeset = Link.changeset(%Link{}, attrs)
      assert changeset.valid?
    end

    test "required fields" do
      attrs = %{
        id: "test-link-1",
        description: "Test description",
        group_id: "test-group"
      }

      changeset = Link.changeset(%Link{}, attrs)
      refute changeset.valid?

      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).url
    end

    test "validates URL format" do
      # Некорректный URL без схемы
      attrs = %{
        id: "test-link-1",
        name: "Test Link",
        url: "example.com",
        description: "Test description"
      }

      changeset = Link.changeset(%Link{}, attrs)
      refute changeset.valid?
      assert "URL must have a scheme (http, https, etc.)" in errors_on(changeset).url

      # Некорректный URL без хоста
      attrs = %{
        id: "test-link-1",
        name: "Test Link",
        url: "http://"
      }
      changeset = Link.changeset(%Link{}, attrs)
      refute changeset.valid?
      assert "URL must have a host" in errors_on(changeset).url

      # Корректный URL
      attrs = %{
        id: "test-link-1",
        name: "Test Link",
        url: "https://example.com",
        description: "Test description"
      }

      changeset = Link.changeset(%Link{}, attrs)
      assert changeset.valid?
    end
  end

  # Вспомогательная функция для извлечения ошибок из changeset
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
