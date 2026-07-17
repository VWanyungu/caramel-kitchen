defmodule CaramelKitchenWeb.Router do
  use CaramelKitchenWeb, :router

  alias CaramelKitchenWeb.Plugs.{
    AuthenticateUser,
    RequirePremium,
    RequireCreator,
    RequireAdmin,
    RateLimit,
    VerifyStripeSignature,
    TrackRequest
  }

  # ── Pipelines ─────────────────────────────────────────────────

  pipeline :api do
    plug :accepts, ["json"]
    plug TrackRequest
    plug Plug.RequestId
  end

  pipeline :authenticated do
    plug AuthenticateUser
  end

  pipeline :premium do
    plug AuthenticateUser
    plug RequirePremium
  end

  pipeline :creator do
    plug AuthenticateUser
    plug RequireCreator
  end

  pipeline :admin do
    plug AuthenticateUser
    plug RequireAdmin
  end

  pipeline :rate_limit_auth do
    plug RateLimit, scale: 60_000, limit: 10, bucket: "auth"
  end

  pipeline :rate_limit_api do
    plug RateLimit, scale: 60_000, limit: 100, bucket: "api"
  end

  pipeline :rate_limit_ai do
    plug RateLimit, scale: 60_000, limit: 20, bucket: "ai"
  end

  pipeline :stripe_webhook do
    plug VerifyStripeSignature
  end

  # ── Health check ──────────────────────────────────────────────
  scope "/", CaramelKitchenWeb do
    pipe_through :api
    get "/health", HealthController, :index
    get "/ready",  HealthController, :ready
  end

  # ── Public Auth ───────────────────────────────────────────────
  scope "/api/v1", CaramelKitchenWeb do
    pipe_through [:api, :rate_limit_auth]

    post "/auth/register",       AuthController, :register
    post "/auth/login",          AuthController, :login
    post "/auth/refresh",        AuthController, :refresh
    post "/auth/google",         AuthController, :google_oauth
    post "/auth/forgot-password", AuthController, :forgot_password
    post "/auth/reset-password", AuthController, :reset_password
    get  "/auth/verify-email/:token", AuthController, :verify_email
  end

  # ── Public Recipe browsing (no auth required) ─────────────────
  scope "/api/v1", CaramelKitchenWeb do
    pipe_through [:api, :rate_limit_api]

    get  "/recipes",             RecipeController, :index
    get  "/recipes/trending",    RecipeController, :trending
    get  "/recipes/search",      RecipeController, :search
    get  "/recipes/:id",         RecipeController, :show
    get  "/recipes/slug/:slug",  RecipeController, :show_by_slug
    get  "/categories",          RecipeController, :categories
    get  "/shopping/shared/:token", ShoppingController, :show_shared
  end

  # ── Authenticated ─────────────────────────────────────────────
  scope "/api/v1", CaramelKitchenWeb do
    pipe_through [:api, :rate_limit_api, :authenticated]

    # Profile
    get    "/me",               ProfileController, :show
    put    "/me",               ProfileController, :update
    delete "/me",               ProfileController, :deactivate

    # Taste
    post   "/taste/survey",     TasteController, :submit_survey
    get    "/taste/vector",     TasteController, :get_vector

    # Feed
    get    "/feed",             FeedController, :personalised
    get    "/feed/for-you",     FeedController, :for_you

    # Interactions
    post   "/recipes/:id/save",   InteractionController, :save
    post   "/recipes/:id/cook",   InteractionController, :cook
    post   "/recipes/:id/skip",   InteractionController, :skip
    post   "/recipes/:id/rate",   InteractionController, :rate
    get    "/me/saved",           InteractionController, :saved_recipes

    # Shopping (basic — from single recipe)
    get    "/shopping",          ShoppingController, :index
    post   "/shopping",          ShoppingController, :create
    get    "/shopping/:id",      ShoppingController, :show
    patch  "/shopping/:id/check/:item_index",   ShoppingController, :check_item
    patch  "/shopping/:id/uncheck/:item_index", ShoppingController, :uncheck_item
    delete "/shopping/:id",      ShoppingController, :delete

    # Course builder (free tier)
    resources "/courses", CourseController, only: [:index, :create, :show, :update, :delete]

    # Subscription
    get    "/subscription",             SubscriptionController, :show
    post   "/subscription/checkout",    SubscriptionController, :create_checkout
    get    "/subscription/portal",      SubscriptionController, :billing_portal
  end

  # ── Premium features ──────────────────────────────────────────
  scope "/api/v1", CaramelKitchenWeb do
    pipe_through [:api, :premium]

    # AI (rate-limited separately)
    pipe_through [:rate_limit_ai]
    post   "/ai/chat",           AIController, :chat
    post   "/ai/voice",          AIController, :voice
    get    "/ai/history/:session_id", AIController, :history
    delete "/ai/session/:session_id", AIController, :clear_session

    # Meal plans
    get    "/meal-plans",                 MealPlanController, :index
    get    "/meal-plans/active",          MealPlanController, :active
    post   "/meal-plans/generate",        MealPlanController, :generate
    get    "/meal-plans/:id",             MealPlanController, :show
    patch  "/meal-plans/:id/swap",        MealPlanController, :swap_meal
    get    "/meal-plans/:id/shopping",    MealPlanController, :shopping_list
    get    "/meal-plans/:id/macros/:day", MealPlanController, :daily_macros
    delete "/meal-plans/:id",             MealPlanController, :delete
  end

  # ── Creator / Admin ───────────────────────────────────────────
  scope "/api/v1/admin", CaramelKitchenWeb do
    pipe_through [:api, :creator]

    # Recipe management
    get    "/recipes",                   AdminRecipeController, :index
    post   "/recipes",                   AdminRecipeController, :create
    get    "/recipes/:id",               AdminRecipeController, :show
    put    "/recipes/:id",               AdminRecipeController, :update
    post   "/recipes/:id/publish",       AdminRecipeController, :publish
    post   "/recipes/:id/archive",       AdminRecipeController, :archive
    delete "/recipes/:id",               AdminRecipeController, :delete

    # Video upload
    post   "/videos/presigned-url",      AdminVideoController, :presigned_url
    post   "/videos/processed",          AdminVideoController, :on_processed

    # Analytics
    get    "/analytics",                 AdminAnalyticsController, :index
    get    "/analytics/recipes",         AdminAnalyticsController, :recipes
    get    "/analytics/taste",           AdminAnalyticsController, :taste_distribution
    get    "/analytics/ai",              AdminAnalyticsController, :ai_queries
  end

  # ── Super Admin ───────────────────────────────────────────────
  scope "/api/v1/superadmin", CaramelKitchenWeb do
    pipe_through [:api, :admin]

    get    "/users",             SuperAdminController, :list_users
    put    "/users/:id/role",    SuperAdminController, :update_role
    delete "/users/:id",         SuperAdminController, :deactivate_user
    get    "/system/stats",      SuperAdminController, :system_stats
  end

  # ── Stripe Webhooks ───────────────────────────────────────────
  scope "/webhooks", CaramelKitchenWeb do
    pipe_through [:api, :stripe_webhook]
    post "/stripe", WebhookController, :stripe
  end

  # ── LiveDashboard (dev only) ──────────────────────────────────
  if Application.compile_env(:caramel_kitchen, :dev_routes) do
    import Phoenix.LiveDashboard.Router
    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: CaramelKitchen.Telemetry
    end
  end
end
