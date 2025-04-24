ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(LinksApi.Repo, :manual)

# Определяем моки для тестирования
Mox.defmock(LinksApi.MockRepo, for: LinksApi.Repo.Behaviour)
Application.put_env(:links_api, :repo, LinksApi.MockRepo)
