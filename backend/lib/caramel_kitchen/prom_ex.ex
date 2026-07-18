defmodule CaramelKitchen.PromEx do
  @moduledoc """
  PromEx configuration for Prometheus + Grafana metrics.
  Exposes /metrics endpoint (protected in production).
  Includes plugins for Phoenix, Ecto, Oban, Beam VM, and custom business metrics.
  """
  use PromEx, otp_app: :caramel_kitchen

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      # Built-in plugins
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix, router: CaramelKitchenWeb.Router, endpoint: CaramelKitchenWeb.Endpoint},
      {Plugins.Ecto, repos: [CaramelKitchen.Repo]},
      {Plugins.Oban, queues: [:default, :content, :email, :analytics, :maintenance, :ai]},

      # Custom business metrics plugin
      CaramelKitchen.PromEx.CustomPlugin
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: "prometheus",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards do
    [
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "phoenix.json"},
      {:prom_ex, "ecto.json"},
      {:prom_ex, "oban.json"},
      {:caramel_kitchen, "priv/grafana/caramel_kitchen_business.json"}
    ]
  end
end

defmodule CaramelKitchen.PromEx.CustomPlugin do
  @moduledoc "Custom Prometheus metrics for Caramel Kitchen business events."
  use PromEx.Plugin

  @impl true
  def event_metrics(_opts) do
    Event.build(
      :caramel_kitchen_business_event_metrics,
      [
        counter("caramel_kitchen.ai.request.total",
          event_name: [:caramel_kitchen, :ai, :request],
          description: "Total AI requests",
          tags: [:query_type]
        ),
        distribution("caramel_kitchen.ai.request.duration_milliseconds",
          event_name: [:caramel_kitchen, :ai, :request, :stop],
          measurement: :duration,
          description: "AI request duration",
          tags: [:query_type],
          unit: {:native, :millisecond},
          reporter_options: [buckets: [100, 300, 500, 1000, 3000, 10000]]
        ),
        counter("caramel_kitchen.taste.update.total",
          event_name: [:caramel_kitchen, :taste, :update],
          description: "Total taste vector updates",
          tags: [:action]
        ),
        counter("caramel_kitchen.recipe.view.total",
          event_name: [:caramel_kitchen, :recipe, :view],
          description: "Total recipe views"
        ),
        counter("caramel_kitchen.subscription.created.total",
          event_name: [:caramel_kitchen, :subscription, :created],
          description: "New subscriptions",
          tags: [:plan]
        ),
        counter("caramel_kitchen.auth.login.total",
          event_name: [:caramel_kitchen, :auth, :login],
          description: "Login attempts",
          tags: [:result]
        )
      ]
    )
  end

  @impl true
  def polling_metrics(_opts) do
    Polling.build(
      :caramel_kitchen_business_polling_metrics,
      5_000,
      {__MODULE__, :execute_polling_metrics, []},
      [
        last_value("caramel_kitchen.users.total_count",
          event_name: [:caramel_kitchen, :users, :count],
          description: "Total registered users"
        ),
        last_value("caramel_kitchen.recipes.live_count",
          event_name: [:caramel_kitchen, :recipes, :count],
          description: "Total live recipes"
        ),
        last_value("caramel_kitchen.ai.session.active_count",
          event_name: [:caramel_kitchen, :ai, :sessions, :count],
          description: "Active AI sessions"
        )
      ]
    )
  end

  def execute_polling_metrics do
    import Ecto.Query

    user_count = CaramelKitchen.Repo.aggregate(CaramelKitchen.Accounts.User, :count, :id)

    recipe_count =
      CaramelKitchen.Repo.aggregate(
        from(r in CaramelKitchen.Recipes.Recipe, where: r.status == "live"),
        :count,
        :id
      )

    :telemetry.execute([:caramel_kitchen, :users, :count], %{count: user_count}, %{})
    :telemetry.execute([:caramel_kitchen, :recipes, :count], %{count: recipe_count}, %{})
  rescue
    _ -> :ok
  end
end
