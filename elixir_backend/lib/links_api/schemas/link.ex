defmodule LinksApi.Schemas.Link do
  @moduledoc """
  Схема Ecto для работы с ссылками.
  Используется для Backpex админки, но не для сохранения в БД (там используется Cassandra).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "links" do
    field :name, :string
    field :url, :string
    field :description, :string
    field :group_id, :string
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
  end

  def changeset(link, attrs) do
    link
    |> cast(attrs, [:id, :name, :url, :description, :group_id, :created_at, :updated_at])
    |> validate_required([:name, :url])
    |> validate_url(:url)
  end

  # Валидация URL формата
  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      case URI.parse(url) do
        %URI{scheme: nil} -> [{field, "URL must have a scheme (http, https, etc.)"}]
        %URI{host: nil} -> [{field, "URL must have a host"}]
        _ -> []
      end
    end)
  end
end
