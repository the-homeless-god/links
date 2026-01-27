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
    field :user_id, :string  # ID пользователя (из Keycloak или "guest")
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
    # Виртуальное поле для отображения короткой ссылки
    field :short_link, :string, virtual: true
  end

  def changeset(link, attrs) do
    link
    |> cast(attrs, [:id, :name, :url, :description, :group_id, :user_id, :created_at, :updated_at])
    |> validate_required([:name, :url])
    |> validate_url(:url)
  end

  def update_changeset(link, attrs, _params) do
    now = DateTime.utc_now()
    attrs = Map.put(attrs, :updated_at, now)

    link
    |> cast(attrs, [:name, :url, :description, :group_id, :user_id, :updated_at])
    |> validate_required([:name, :url])
    |> validate_url(:url)
  end

  def create_changeset(link, attrs, _params) do
    now = DateTime.utc_now()
    attrs = attrs
      |> Map.put(:created_at, now)
      |> Map.put(:updated_at, now)
      |> Map.put_new(:id, UUID.uuid4())

    link
    |> cast(attrs, [:id, :name, :url, :description, :group_id, :user_id, :created_at, :updated_at])
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
