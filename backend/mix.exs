defmodule CaramelKitchen.MixProject do
  use Mix.Project

  def project do
    [
      app: :caramel_kitchen,
      version: "2.0.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ],
      consolidate_protocols: false
    ]
  end

  def application do
    [
      mod: {CaramelKitchen.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix & Web
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:plug_cowboy, "~> 2.7"},
      {:cors_plug, "~> 3.0"},

      # Database
      {:ecto_sql, "~> 3.11"},
      {:postgrex, "~> 0.18"},
      {:ecto_psql_extras, "~> 0.7"},

      # Vector search (pgvector)
      {:pgvector, "~> 0.3"},

      # Auth
      {:guardian, "~> 2.3"},
      {:guardian_db, "~> 3.0"},
      {:bcrypt_elixir, "~> 3.1"},
      {:comeonin, "~> 5.4"},

      # Background Jobs
      {:oban, "~> 2.17"},

      # Redis / Cache
      {:redix, "~> 1.3"},
      {:con_cache, "~> 1.1"},

      # HTTP Client (for OpenAI / external APIs)
      {:req, "~> 0.5"},
      {:finch, "~> 0.18"},

      # JSON
      {:jason, "~> 1.4"},
      {:jose, "~> 1.11.10"},

      # Email
      {:swoosh, "~> 1.16"},
      {:gen_smtp, "~> 1.2"},

      # AWS S3
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:sweet_xml, "~> 0.7"},
      {:hackney, "~> 1.20"},

      # Rate Limiting
      {:hammer, "~> 6.2"},
      {:hammer_backend_redis, "~> 6.1"},

      # Telemetry & Observability
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:prom_ex, "~> 1.9"},

      # Validation
      {:tarams, "~> 1.7"},

      # Stripe
      {:stripity_stripe, "~> 3.1"},

      # Pagination
      {:paginator, "~> 1.2"},

      # Feature Flags
      {:fun_with_flags, "~> 1.12"},
      {:fun_with_flags_ui, "~> 0.8"},

      # Cron
      {:quantum, "~> 3.5"},

      # Error tracking
      {:sentry, "~> 10.2"},

      # Dev / Test
      {:excoveralls, "~> 0.18", only: :test},
      {:ex_machina, "~> 2.8", only: :test},
      {:faker, "~> 0.18", only: :test},
      {:mox, "~> 1.1", only: :test},
      {:bypass, "~> 2.1", only: :test}
      # {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      # {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      # {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["cmd --cd assets npm install"]
    ]
  end
end
