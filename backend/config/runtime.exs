# config/runtime.exs — Production secrets loaded at startup

import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "DATABASE_URL environment variable is missing."

  pool_size = String.to_integer(System.get_env("POOL_SIZE", "3"))

  socket_options = if System.get_env("ECTO_IPV6") == "true", do: [:inet6], else: []

  config :caramel_kitchen, CaramelKitchen.Repo,
    url: database_url,
    pool_size: pool_size,
    ssl: true,
    ssl_opts: [verify: :verify_none],
    socket_options: socket_options,
    queue_target: 5_000,
    queue_interval: 1_000,
    migration_timestamps: [type: :utc_datetime],
    parameters: [
      application_name: "caramel_kitchen"
    ]

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE environment variable is missing."

  host = System.get_env("PHX_HOST", "caramelkitchen.app")
  port = String.to_integer(System.get_env("PORT", "4000"))

  config :caramel_kitchen, CaramelKitchenWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    server: true

  prod_allowed_origins =
    case System.get_env("ALLOWED_ORIGINS") do
      nil -> [
        "https://caramelkitchen.app",
        "https://www.caramelkitchen.app",
        "https://admin.caramelkitchen.app"
      ]

      origins ->
        String.split(origins, ",") |> Enum.map(&String.trim/1)
    end

  config :caramel_kitchen,
    redis_url: System.get_env("REDIS_URL", "redis://localhost:6379"),
    redis_host: System.get_env("REDIS_HOST", "localhost"),
    openai_api_key: System.get_env("OPENAI_API_KEY", "sk-placeholder"),
    s3_bucket: System.get_env("S3_BUCKET", "caramel-kitchen-videos"),
    cdn_url: System.get_env("CDN_URL", "https://cdn.caramelkitchen.app"),
    app_url: "https://#{host}",
    allowed_origins: prod_allowed_origins,
    stripe_webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_placeholder"),
    stripe_premium_price_id: System.get_env("STRIPE_PREMIUM_PRICE_ID", "price_placeholder"),
    stripe_creator_price_id: System.get_env("STRIPE_CREATOR_PRICE_ID", "price_placeholder")

  config :caramel_kitchen, CaramelKitchen.Auth.Guardian,
    secret_key: System.get_env("GUARDIAN_SECRET_KEY") || secret_key_base

  config :stripity_stripe,
    api_key: System.get_env("STRIPE_SECRET_KEY", "sk_test_placeholder"),
    webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_placeholder")

  config :ex_aws,
    access_key_id: System.get_env("AWS_ACCESS_KEY_ID", "dummy_key"),
    secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY", "dummy_secret"),
    region: System.get_env("AWS_REGION", "eu-west-1")

  config :sentry,
    dsn: System.get_env("SENTRY_DSN"),
    included_environments: [:prod]
end

if config_env() == :dev do
  config :caramel_kitchen, CaramelKitchen.Repo,
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    database: "caramel_kitchen_dev",
    stacktrace: true,
    show_sensitive_data_on_connection_error: true,
    pool_size: 10

  config :caramel_kitchen, CaramelKitchenWeb.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: 4000],
    check_origin: false,
    code_reloader: true,
    debug_errors: true,
    secret_key_base: "dev_secret_key_base_caramel_kitchen_at_least_64_chars_long_ok",
    watchers: []

  dev_allowed_origins =
    case System.get_env("ALLOWED_ORIGINS") do
      nil -> ["http://localhost:3000", "http://localhost:4000", "http://localhost:5173", "http://127.0.0.1:3000", "http://127.0.0.1:4000", "http://127.0.0.1:5173"]
      origins -> String.split(origins, ",") |> Enum.map(&String.trim/1)
    end

  config :caramel_kitchen,
    redis_url: "redis://localhost:6379",
    openai_api_key: System.get_env("OPENAI_API_KEY", "sk-dev-placeholder"),
    s3_bucket: "caramel-kitchen-dev",
    cdn_url: "http://localhost:9000",
    app_url: "http://localhost:4000",
    allowed_origins: dev_allowed_origins,
    dev_routes: true

  config :logger, level: :debug
end

if config_env() == :test do
  config :caramel_kitchen, CaramelKitchen.Repo,
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    database: "caramel_kitchen_test#{System.get_env("MIX_TEST_PARTITION")}",
    pool: Ecto.Adapters.SQL.Sandbox,
    pool_size: 10

  config :caramel_kitchen, CaramelKitchenWeb.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: 4002],
    secret_key_base: "test_secret_key_base_caramel_kitchen_at_least_64_chars_long",
    server: false

  config :caramel_kitchen,
    openai_api_key: "sk-test-placeholder",
    s3_bucket: "caramel-kitchen-test",
    app_url: "http://localhost:4002"

  config :logger, level: :warning
end
