defmodule LinksApiWeb.CoreComponents do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders a flash notice.
  """
  attr(:flash, :map, required: true)
  attr(:kind, :atom, values: [:info, :error], doc: "used for styling")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")

  def flash(%{kind: _kind} = assigns) do
    ~H"""
    <div
      :if={msg = @flash[@kind]}
      id={"flash-#{@kind}"}
      role="alert"
      class={[
        "fixed top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-emerald-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= msg %>
      </p>
      <button
        type="button"
        class="group absolute top-1 right-1 p-2"
        aria-label="close"
        phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide_flash()}
      >
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Renders a set of flash notices.
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")

  def flash_group(assigns) do
    ~H"""
    <.flash flash={@flash} kind={:info} />
    <.flash flash={@flash} kind={:error} />
    """
  end

  @doc """
  Renders an icon.
  """
  attr(:name, :string, required: true)
  attr(:class, :string, default: nil)

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  defp hide_flash(js) do
    js
    |> JS.hide(to: "#flash", transition: "fade-out")
    |> JS.hide(to: "#flash-info", transition: "fade-out-scale")
    |> JS.hide(to: "#flash-error", transition: "fade-out-scale")
  end
end
