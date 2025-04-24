defmodule LinksApiWeb.ManualLinksLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-6">Ссылки</h1>

      <div class="bg-white rounded-lg shadow overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Название</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">URL</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Описание</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Группа</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Действия</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for link <- @links do %>
              <tr>
                <td class="px-6 py-4 whitespace-nowrap"><%= link["name"] %></td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <a href={link["url"]} target="_blank" class="text-indigo-600 hover:text-indigo-900"><%= link["url"] %></a>
                </td>
                <td class="px-6 py-4 whitespace-nowrap"><%= link["description"] %></td>
                <td class="px-6 py-4 whitespace-nowrap"><%= link["group_id"] %></td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <a href={"/r/#{link["id"]}"} target="_blank" class="text-indigo-600 hover:text-indigo-900 mr-2">Открыть</a>
                  <button phx-click="delete" phx-value-id={link["id"]} class="text-red-600 hover:text-red-900">Удалить</button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

      <div class="mt-8 bg-white rounded-lg shadow p-6">
        <h2 class="text-xl font-bold mb-4">Добавить ссылку</h2>
        <form phx-submit="create">
          <div class="grid grid-cols-1 gap-6">
            <div>
              <label for="name" class="block text-sm font-medium text-gray-700">Название</label>
              <input type="text" name="name" id="name" required class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md">
            </div>
            <div>
              <label for="url" class="block text-sm font-medium text-gray-700">URL</label>
              <input type="url" name="url" id="url" required class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md">
            </div>
            <div>
              <label for="description" class="block text-sm font-medium text-gray-700">Описание</label>
              <textarea name="description" id="description" rows="3" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"></textarea>
            </div>
            <div>
              <label for="group_id" class="block text-sm font-medium text-gray-700">Группа</label>
              <input type="text" name="group_id" id="group_id" class="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md">
            </div>
            <div>
              <button type="submit" class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                Добавить
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    # Просто загружаем все ссылки при монтировании компонента
    case LinksApi.SqliteRepo.get_all_links() do
      {:ok, links} ->
        {:ok, assign(socket, links: links)}
      _ ->
        {:ok, assign(socket, links: [])}
    end
  end

  # Обработка события удаления ссылки
  def handle_event("delete", %{"id" => id}, socket) do
    :ok = LinksApi.SqliteRepo.delete_link(id)
    # Обновляем список ссылок после удаления
    {:ok, links} = LinksApi.SqliteRepo.get_all_links()
    {:noreply, assign(socket, links: links)}
  end

  # Обработка события создания ссылки
  def handle_event("create", params, socket) do
    link_params = %{
      "id" => UUID.uuid4(),
      "name" => params["name"],
      "url" => params["url"],
      "description" => params["description"] || "",
      "group_id" => params["group_id"] || ""
    }

    case LinksApi.SqliteRepo.create_link(link_params) do
      {:ok, _} ->
        {:ok, links} = LinksApi.SqliteRepo.get_all_links()
        {:noreply, assign(socket, links: links)}
      _ ->
        {:noreply, socket}
    end
  end
end
