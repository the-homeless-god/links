ExUnit.start()

# Запускаем SqliteRepo для тестов, которые используют реальный репозиторий
case LinksApi.SqliteRepo.start_link([]) do
  {:ok, _} -> :ok
  {:error, {:already_started, _}} -> :ok
end

# Определяем моки для тестирования
Mox.defmock(LinksApi.MockRepo, for: LinksApi.Repo.Behaviour)
Application.put_env(:links_api, :repo, LinksApi.MockRepo)
