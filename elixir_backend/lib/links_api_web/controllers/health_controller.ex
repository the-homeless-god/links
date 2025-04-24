defmodule LinksApiWeb.HealthController do
  use Phoenix.Controller

  def health(conn, _params) do
    json(conn, %{status: "ok", version: "1.0.0"})
  end
end
