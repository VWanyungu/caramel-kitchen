# config/dev.exs
import Config

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
  secret_key_base: "dev_secret_key_base_caramel_kitchen_at_least_64_chars_long_replace_me",
  watchers: []

config :caramel_kitchen,
  redis_url:      "redis://localhost:6379",
  redis_host:     "localhost",
  openai_api_key: System.get_env("OPENAI_API_KEY", "sk-dev-placeholder"),
  s3_bucket:      "caramel-kitchen-dev",
  cdn_url:        "http://localhost:9000/caramel-kitchen-dev",
  app_url:        "http://localhost:4000",
  allowed_origins: ["http://localhost:3000", "http://localhost:4000"],
  dev_routes:     true,
  nutritionix_app_id:  System.get_env("NUTRITIONIX_APP_ID"),
  nutritionix_app_key: System.get_env("NUTRITIONIX_APP_KEY"),
  fcm_server_key: System.get_env("FCM_SERVER_KEY"),
  stripe_webhook_secret:   "whsec_dev",
  stripe_premium_price_id: "price_dev_premium",
  stripe_creator_price_id: "price_dev_creator"

# Use Mailpit in dev (SMTP on localhost:1025)
config :caramel_kitchen, CaramelKitchen.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay:   "localhost",
  port:    1025,
  tls:     :never

config :logger, level: :debug

