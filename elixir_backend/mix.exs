defmodule LinksApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :links_api,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp releases do
    [
      links_api: [
        include_executables_for: [:unix, :windows],
        steps: [:assemble, :tar],
        cookie: "links_api_cookie"
      ]
    ]
  end

  # Приложения для разных окружений
  def application do
    [
      mod: {LinksApi.Application, []},
      # Добавляем :os_mon для LiveDashboard (требуется для некоторых страниц)
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Пути для компиляции в зависимости от окружения
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Зависимости проекта
  defp deps do
    [
      {:phoenix, "~> 1.7.7"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:esbuild, "~> 0.7"},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:elixir_uuid, "~> 1.2"},
      {:joken, "~> 2.5"},
      {:httpoison, "~> 2.0"},
      {:xandra, "~> 0.14"},
      {:ecto_sqlite3, "~> 0.10.2"},
      {:cors_plug, "~> 3.0"},
      {:backpex, "~> 0.12.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      # Зависимости для логирования
      {:logger_json, "~> 5.1"},
      {:lager, "~> 3.9"},
      {:logger_file_backend, "~> 0.0.13"},
      {:telemetry_metrics_prometheus, "~> 1.1"},
      # Инструменты разработчика и качество кода
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      # Тестирование
      {:excoveralls, "~> 0.16", only: :test},
      {:wallaby, "~> 0.30", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:ex_machina, "~> 2.7", only: :test},
      {:faker, "~> 0.17", only: [:dev, :test]},
      {:hammox, "~> 0.7", only: :test}
    ]
  end

  # Алиасы для миграций и других задач
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "cassandra.setup": ["run priv/repo/setup_cassandra.exs"],
      "sqlite.setup": ["run priv/repo/setup_sqlite.exs"],
      "db.setup": ["run priv/repo/setup_initial.exs"],
      "run.dev": ["db.setup", "phx.server"],
      "test.all": ["test", "test.integration", "test.load"],
      "test.integration": ["run test/integration/run_tests.exs"],
      "test.load": ["run test/load/run_load_tests.exs"]
    ]
  end
end
