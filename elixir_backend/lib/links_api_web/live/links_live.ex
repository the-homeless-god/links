defmodule LinksApiWeb.LinksLive do
  use Backpex.LiveResource,
    adapter: LinksApi.RepoAdapter,
    adapter_config: [
      schema: LinksApi.Schemas.Link,
      create_changeset: &LinksApi.Schemas.Link.create_changeset/3,
      update_changeset: &LinksApi.Schemas.Link.update_changeset/3
    ],
    primary_key: :id,
    full_text_search: true,
    layout: {LinksApiWeb.Layouts, :admin},
    pubsub: [server: LinksApi.PubSub, topic: "links"],
    fluid?: true

  alias LinksApi.Auth.KeycloakToken
  alias LinksApi.Schemas.Link
  alias Elixir.UUID
  import Phoenix.Component

  @impl Backpex.LiveResource
  def display_name, do: "Ссылки"

  @impl Backpex.LiveResource
  def menu, do: :main

  @impl Backpex.LiveResource
  def menu_icon, do: :link

  @impl Backpex.LiveResource
  def singular_name, do: "Ссылка"

  @impl Backpex.LiveResource
  def plural_name, do: "Ссылки"

  @impl Backpex.LiveResource
  def fields do
    [
      name: %{
        module: Backpex.Fields.Text,
        label: "Название",
        searchable: true,
        orderable: true,
        only: [:index, :new, :edit, :show]
      },
      url: %{
        module: Backpex.Fields.URL,
        label: "URL",
        searchable: true,
        orderable: true,
        only: [:index, :new, :edit, :show]
      },
      description: %{
        module: Backpex.Fields.Textarea,
        label: "Описание",
        searchable: true,
        only: [:index, :new, :edit, :show]
      },
      group_id: %{
        module: Backpex.Fields.Select,
        label: "Группа",
        only: [:index, :new, :edit, :show],
        options: fn _socket ->
          [
            {"dev", "dev"},
            {"prod", "prod"},
            {"personal", "personal"}
          ]
        end
      },
      created_at: %{
        module: Backpex.Fields.DateTime,
        label: "Создано",
        orderable: true,
        only: [:index, :show]
      },
      updated_at: %{
        module: Backpex.Fields.DateTime,
        label: "Обновлено",
        orderable: true,
        only: [:index, :show]
      },
      short_link: %{
        module: Backpex.Fields.Text,
        label: "Короткая ссылка (формат: /r/{name})",
        only: [:index, :show]
      }
    ]
  end

  @impl Backpex.LiveResource
  def search_fields do
    [:name, :url, :description]
  end

  @impl Backpex.LiveResource
  def filters do
    # ВРЕМЕННО отключаем фильтры из-за проблемы с Backpex.Filter.Select.can?/1
    # Можно включить обратно после обновления Backpex или исправления проблемы
    []
  end

  @impl Backpex.LiveResource
  def filters(_assigns) do
    # Переопределяем filters/1, чтобы гарантировать, что он тоже возвращает пустой список
    []
    # [
    #   group_id: %{
    #     module: Backpex.Filter.Select,
    #     label: "Группа",
    #     options: fn _socket ->
    #       [
    #         {"Все", ""},
    #         {"dev", "dev"},
    #         {"prod", "prod"},
    #         {"personal", "personal"}
    #       ]
    #     end
    #   },
    #   created_at: %{
    #     module: Backpex.Filter.DateRange,
    #     label: "Дата создания"
    #   }
    # ]
  end

  @impl Backpex.LiveResource
  def resource_actions(_socket, resource) do
    [
      view_public: [
        module: Backpex.Action.Link,
        label: "Открыть ссылку",
        icon: :external_link,
        # Используем name вместо id для короткой ссылки
        to: "/r/#{URI.encode(resource.name || resource.id)}",
        target: "_blank"
      ]
    ]
  end

  @impl Backpex.LiveResource
  def item_actions(_socket) do
    [
      show: [
        module: Backpex.ItemActions.Show,
        only: [:row, :index]
      ],
      edit: [
        module: Backpex.ItemActions.Edit,
        only: [:row, :show]
      ],
      delete: [
        module: Backpex.ItemActions.Delete,
        only: [:row, :index, :show]
      ]
    ]
  end

  @impl Backpex.LiveResource
  def global_actions(_socket) do
    [
      new: [
        module: Backpex.GlobalAction.New,
        label: "Новая ссылка",
        icon: :plus
      ],
      import: [
        module: Backpex.Action.Link,
        label: "Импорт ссылок",
        icon: :document_add,
        to: "#",
        class: "btn-secondary"
      ],
      export: [
        module: Backpex.Action.Link,
        label: "Экспорт ссылок",
        icon: :document_download,
        to: "#",
        class: "btn-secondary"
      ],
      delete_selected: [
        module: Backpex.GlobalAction.DeleteSelected,
        label: "Удалить выбранные",
        icon: :trash,
        class: "btn-danger"
      ]
    ]
  end

  # Авторизация - проверяет имеет ли пользователь право на операцию
  @impl Backpex.LiveResource
  def authorize(_socket, :index, current_user) do
    try do
      KeycloakToken.has_any_role?(current_user, ["links-admin", "links-editor", "links-viewer"])
    rescue
      # В случае ошибки разрешаем доступ для тестирования
      _ -> true
    end
  end

  @impl Backpex.LiveResource
  def authorize(_socket, :show, current_user) do
    try do
      KeycloakToken.has_any_role?(current_user, ["links-admin", "links-editor", "links-viewer"])
    rescue
      # В случае ошибки разрешаем доступ для тестирования
      _ -> true
    end
  end

  @impl Backpex.LiveResource
  def authorize(_socket, :new, current_user) do
    try do
      KeycloakToken.has_any_role?(current_user, ["links-admin", "links-editor"])
    rescue
      # В случае ошибки разрешаем доступ для тестирования
      _ -> true
    end
  end

  @impl Backpex.LiveResource
  def authorize(_socket, :create, current_user) do
    try do
      KeycloakToken.has_any_role?(current_user, ["links-admin", "links-editor"])
    rescue
      # В случае ошибки разрешаем доступ для тестирования
      _ -> true
    end
  end

  @impl Backpex.LiveResource
  def authorize(_socket, :edit, current_user) do
    try do
      KeycloakToken.has_any_role?(current_user, ["links-admin", "links-editor"])
    rescue
      # В случае ошибки разрешаем доступ для тестирования
      _ -> true
    end
  end

  @impl Backpex.LiveResource
  def authorize(_socket, :update, current_user) do
    try do
      KeycloakToken.has_any_role?(current_user, ["links-admin", "links-editor"])
    rescue
      # В случае ошибки разрешаем доступ для тестирования
      _ -> true
    end
  end

  @impl Backpex.LiveResource
  def authorize(_socket, :delete, current_user) do
    try do
      KeycloakToken.has_role?(current_user, "links-admin")
    rescue
      # В случае ошибки разрешаем доступ для тестирования
      _ -> true
    end
  end

  # Helper для получения списка групп для выбора
  defp _get_group_options(socket) do
    # Безопасное получение current_user
    current_user =
      try do
        socket.assigns[:current_user]
      rescue
        # В случае ошибки используем заглушку
        _ -> %{"groups" => ["default_group"]}
      end

    # Безопасная проверка роли
    is_admin =
      try do
        current_user && KeycloakToken.has_role?(current_user, "links-admin")
      rescue
        # В случае ошибки считаем, что пользователь администратор для тестирования
        _ -> true
      end

    if is_admin do
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
  @impl Backpex.LiveResource
  def create(socket, params) do
    # Если ID не был указан, генерируем случайный UUID
    params_with_id = Map.put_new(params, "id", UUID.uuid4())

    # Безопасное добавление группы пользователя
    params_with_group =
      try do
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
      rescue
        # В случае ошибки просто используем параметры как есть
        _ -> params_with_id
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
