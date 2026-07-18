# config/test.exs
import Config

config :caramel_kitchen, CaramelKitchen.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "caramel_kitchen_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  types: CaramelKitchen.PostgresTypes

config :caramel_kitchen, CaramelKitchenWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_caramel_kitchen_at_least_64_chars_long_ok_here",
  server: false

config :caramel_kitchen,
  redis_url: "redis://localhost:6379",
  redis_host: "localhost",
  openai_api_key: "sk-test-placeholder",
  s3_bucket: "caramel-kitchen-test",
  cdn_url: "http://localhost:9000",
  app_url: "http://localhost:4002",
  nutritionix_app_id: nil,
  nutritionix_app_key: nil,
  fcm_server_key: nil,
  stripe_webhook_secret: "whsec_test",
  stripe_premium_price_id: "price_test",
  stripe_creator_price_id: "price_test_creator"

# Use test adapter — no real emails sent in tests
config :caramel_kitchen, CaramelKitchen.Mailer, adapter: Swoosh.Adapters.Test

# Disable Oban in tests (use inline testing)
config :caramel_kitchen, Oban, testing: :inline

config :logger, level: :warning

# Speed up bcrypt in tests
config :bcrypt_elixir, log_rounds: 4
