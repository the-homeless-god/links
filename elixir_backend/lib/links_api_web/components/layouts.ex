defmodule LinksApiWeb.Layouts do
  use Phoenix.Component
  import Phoenix.HTML
  import Phoenix.Controller, only: [get_csrf_token: 0]
  import Phoenix.HTML.Form

  # Импорт Route хелперов
  import LinksApiWeb.Router.Helpers, only: [static_path: 2]
  alias LinksApiWeb.Router.Helpers, as: Routes

  # Импорт компонентов
  import LinksApiWeb.CoreComponents

  # Функция sigil_p для ~p сигила
  def sigil_p(path, _modifiers) do
    Path.join(["", path]) |> String.to_charlist() |> IO.iodata_to_binary()
  end

  embed_templates "layouts/*"
end
