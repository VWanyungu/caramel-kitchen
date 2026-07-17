# config/config.exs — Base configuration

import Config

config :caramel_kitchen,
  ecto_repos: [CaramelKitchen.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

config :caramel_kitchen, CaramelKitchenWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: CaramelKitchenWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: CaramelKitchen.PubSub,
  live_view: [signing_salt: "caramel_lv_salt"]

# Guardian JWT
config :caramel_kitchen, CaramelKitchen.Auth.Guardian,
  issuer: "caramel_kitchen",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY", "dev_secret_change_in_prod"),
  token_module: Guardian.Token.Jwt,
  allowed_drift: 2_000,
  verify_issuer: true

# Oban background jobs
config :caramel_kitchen, Oban,
  repo: CaramelKitchen.Repo,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.PG,
  queues: [
    default:     10,
    content:     5,
    email:       10,
    analytics:   20,
    maintenance: 2,
    ai:          5
  ],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},  # 7 days
    {Oban.Plugins.Cron,
     crontab: [
       {"0 2 * * *", CaramelKitchen.Workers.TasteVectorCleanupWorker},
       {"0 * * * *", CaramelKitchen.Workers.EngagementWorker, args: %{mode: "flush"}}
     ]}
  ]

# Stripe
config :stripity_stripe,
  api_key: System.get_env("STRIPE_SECRET_KEY", "sk_test_placeholder"),
  public_key: System.get_env("STRIPE_PUBLIC_KEY", "pk_test_placeholder"),
  webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_placeholder")

# FunWithFlags (feature flags backed by Redis)
config :fun_with_flags, :cache,
  enabled: true,
  ttl: 900

config :fun_with_flags, :persistence,
  adapter: FunWithFlags.Store.Persistent.Redis,
  database: 1

# Hammer Rate Limiter
config :hammer,
  backend: {Hammer.Backend.ETS, [
    expiry_ms: 60_000 * 60 * 4,
    cleanup_interval_ms: 60_000 * 10
  ]}

# Sentry error tracking
config :sentry,
  environment_name: Mix.env(),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!()

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :trace_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
