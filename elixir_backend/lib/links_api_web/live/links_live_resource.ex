defmodule LinksApiWeb.LinksLiveResource do
  use Backpex.LiveResource,
    adapter: LinksApi.RepoAdapter,
    adapter_config: [schema: LinksApi.Schemas.Link],
    primary_key: :id,
    full_text_search: true,
    layout: {LinksApiWeb.Layouts, :app},
    pubsub: [name: LinksApi.PubSub, topic: "links", event_prefix: "link"]

  alias LinksApi.Auth.KeycloakToken
  alias LinksApi.Schemas.Link
  alias LinksApiWeb.Router.Helpers, as: Routes
  import Phoenix.Component
  import PhoenixHTMLHelpers.Link

  @impl true
  def display_name, do: "Links"

  @impl true
  def menu, do: :main

  @impl true
  def menu_icon, do: :link

  @impl true
  def singular_name, do: "Link"

  @impl true
  def plural_name, do: "Links"

  @impl true
  def form_fields(socket, _resource, _changeset) do
    [
      name: %{
        module: Backpex.Fields.Text,
        label: "Name",
        required: true
      },
      url: %{
        module: Backpex.Fields.Text,
        label: "URL",
        required: true
      },
      description: %{
        module: Backpex.Fields.Textarea,
        label: "Description"
      },
      group_id: %{
        module: Backpex.Fields.Select,
        label: "Group",
        options: get_group_options(socket)
      }
    ]
  end

  @impl true
  def list_fields(_socket) do
    [
      name: %{
        module: Backpex.Fields.Text,
        label: "Name",
        sortable: true
      },
      url: %{
        module: Backpex.Fields.Text,
        label: "URL",
        sortable: true,
        render: fn url, _resource, _socket ->
          link(url, to: url, target: "_blank")
        end
      },
      description: %{
        module: Backpex.Fields.Text,
        label: "Description"
      },
      group_id: %{
        module: Backpex.Fields.Text,
        label: "Group"
      },
      created_at: %{
        module: Backpex.Fields.DateTime,
        label: "Created At",
        sortable: true
      },
      updated_at: %{
        module: Backpex.Fields.DateTime,
        label: "Updated At",
        sortable: true
      },
      short_link: %{
        module: Backpex.Fields.Custom,
        label: "Short Link",
        render: fn _value, resource, socket ->
          short_url = Routes.redirect_url(socket, :redirect_by_id, resource.id)
          link(short_url, to: short_url, target: "_blank")
        end
      }
    ]
  end

  @impl true
  def filters(socket) do
    [
      name: %{
        module: Backpex.Filter.Text,
        label: "Name"
      },
      url: %{
        module: Backpex.Filter.Text,
        label: "URL"
      },
      group_id: %{
        module: Backpex.Filter.Select,
        label: "Group",
        options: get_group_options(socket)
      }
    ]
  end

  @impl true
  def search_fields do
    [:name, :url, :description]
  end

  @impl true
  def resource_actions(socket, resource) do
    [
      view_public: %{
        module: Backpex.Action.Link,
        label: "Open link",
        icon: :external_link,
        to: Routes.redirect_url(socket, :redirect_by_id, resource.id),
        target: "_blank"
      }
    ]
  end

  @impl true
  def global_actions(_socket) do
    [
      import: %{
        module: Backpex.Action.Link,
        label: "Import links",
        icon: :document_add,
        to: "#",
        class: "btn-secondary"
      },
      export: %{
        module: Backpex.Action.Link,
        label: "Export links",
        icon: :document_download,
        to: "#",
        class: "btn-secondary"
      }
    ]
  end

  # Авторизация - проверяет имеет ли пользователь право на операцию
  @impl true
  def authorize(_socket, :index, current_user) do
    KeycloakToken.has_any_role?(current_user, ["links-admin", "links-editor", "links-viewer"])
  end

  @impl true
  def authorize(_socket, :show, current_user) do
    KeycloakToken.has_any_role?(current_user, ["links-admin", "links-editor", "links-viewer"])
  end

  @impl true
  def authorize(_socket, :new, current_user) do
    KeycloakToken.has_any_role?(current_user, ["links-admin", "links-editor"])
  end

  @impl true
  def authorize(_socket, :create, current_user) do
    KeycloakToken.has_any_role?(current_user, ["links-admin", "links-editor"])
  end

  @impl true
  def authorize(_socket, :edit, current_user) do
    KeycloakToken.has_any_role?(current_user, ["links-admin", "links-editor"])
  end

  @impl true
  def authorize(_socket, :update, current_user) do
    KeycloakToken.has_any_role?(current_user, ["links-admin", "links-editor"])
  end

  @impl true
  def authorize(_socket, :delete, current_user) do
    KeycloakToken.has_role?(current_user, "links-admin")
  end

  # Helper для получения списка групп для выбора
  defp get_group_options(socket) do
    current_user = socket.assigns[:current_user]

    if current_user && KeycloakToken.has_role?(current_user, "links-admin") do
      # Администраторы видят все группы + возможность создать ссылку без группы
      groups = current_user["groups"] || []
      [{"No group", ""}] ++ Enum.map(groups, fn group -> {group, group} end)
    else
      # Обычные пользователи видят только свои группы
      groups = current_user["groups"] || []
      Enum.map(groups, fn group -> {group, group} end)
    end
  end

  # Кастомная обработка создания записи
  @impl true
  def create(socket, params) do
    # Если ID не был указан, генерируем случайный UUID
    params_with_id = Map.put_new(params, "id", UUID.uuid4())

    # Добавляем группу пользователя, если группа не выбрана и пользователь не админ
    params_with_group =
      if is_nil(params_with_id["group_id"]) || params_with_id["group_id"] == "" do
        current_user = socket.assigns[:current_user]

        if current_user && !KeycloakToken.has_role?(current_user, "links-admin") do
          # Берем первую группу пользователя или пустую строку
          user_groups = current_user["groups"] || []
          group_id = if Enum.empty?(user_groups), do: "", else: List.first(user_groups)
          Map.put(params_with_id, "group_id", group_id)
        else
          params_with_id
        end
      else
        params_with_id
      end

    # Создаем и валидируем changeset
    changeset = Link.changeset(%Link{}, params_with_group)

    if changeset.valid? do
      case LinksApi.RepoAdapter.insert(changeset) do
        {:ok, resource} -> {:ok, resource}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error, changeset}
    end
  end
end
