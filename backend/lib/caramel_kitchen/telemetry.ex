defmodule CaramelKitchen.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg), do: Supervisor.start_link(__MODULE__, arg, name: __MODULE__)

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller,
       measurements: [
         {CaramelKitchen.Telemetry, :dispatch_node_stats, []},
         {CaramelKitchen.Telemetry, :dispatch_oban_stats, []}
       ],
       period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix
      summary("phoenix.endpoint.start.system_time", unit: {:native, :millisecond}),
      summary("phoenix.endpoint.stop.duration", unit: {:native, :millisecond}),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Ecto
      summary("caramel_kitchen.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "Total time for DB queries"
      ),
      summary("caramel_kitchen.repo.query.queue_time", unit: {:native, :millisecond}),

      # Custom
      counter("caramel_kitchen.ai.request.count"),
      summary("caramel_kitchen.ai.request.latency", unit: :millisecond),
      counter("caramel_kitchen.taste.update.count"),
      counter("caramel_kitchen.recipe.view.count"),
      counter("caramel_kitchen.subscription.created.count"),

      # Oban
      summary("oban.job.stop.duration", tags: [:worker], unit: {:native, :millisecond}),
      counter("oban.job.exception.count", tags: [:worker]),

      # VM
      last_value("vm.memory.total", unit: :byte),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu")
    ]
  end

  def dispatch_node_stats do
    :telemetry.execute([:vm, :memory], Map.new(:erlang.memory()), %{})
  end

  def dispatch_oban_stats do
    try do
      counts = Oban.check_queue(queue: :all) |> Map.new()
      :telemetry.execute([:oban, :queue, :stats], counts, %{})
    rescue
      _ -> :ok
    end
  end
end

# ── Analytics Context ─────────────────────────────────────────

defmodule CaramelKitchen.Analytics do
  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Recipes.Recipe

  alias CaramelKitchen.Accounts.User

  @doc "Top performing recipes for creator dashboard."
  def top_recipes(creator_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    period = Keyword.get(opts, :period, :last_30_days)
    since = period_to_datetime(period)

    from(r in Recipe,
      where: r.creator_id == ^creator_id and r.status == "live",
      where: is_nil(^since) or r.published_at >= ^since,
      order_by: [desc: r.engagement_score],
      limit: ^limit,
      select: %{
        id: r.id,
        title: r.title,
        view_count: r.view_count,
        save_count: r.save_count,
        cook_count: r.cook_count,
        avg_rating: r.avg_rating,
        engagement_score: r.engagement_score,
        published_at: r.published_at
      }
    )
    |> Repo.all()
  end

  @doc "Taste distribution across all active users."
  def taste_distribution do
    # Returns average of each taste dimension across all users with vectors
    from(u in User,
      where: not is_nil(u.taste_vector) and u.taste_survey_done == true,
      select: %{
        count: count(u.id)
      }
    )
    |> Repo.one()
    # Note: actual vector aggregation done via raw SQL for pgvector AVG
    |> then(fn base ->
      case Repo.query(
             "SELECT AVG(taste_vector) as avg_vector, COUNT(*) as total FROM users WHERE taste_vector IS NOT NULL",
             []
           ) do
        {:ok, %{rows: [[avg, total]]}} ->
          Map.merge(base || %{}, %{
            avg_vector: avg,
            total_users: total,
            dimensions: ~w(sour sweet tangy spicy savory bitter umami mild)
          })

        _ ->
          %{error: "unavailable"}
      end
    end)
  end

  @doc "AI query stats for a creator's audience."
  def ai_query_stats(_creator_id, period \\ :last_7_days) do
    since = period_to_datetime(period)

    total =
      Repo.aggregate(
        from(q in "ai_queries",
          where: is_nil(^since) or q.inserted_at >= ^since
        ),
        :count,
        :id
      )

    %{
      total_queries: total,
      period: to_string(period)
    }
  end

  @doc "User growth stats for admin dashboard."
  def user_growth_stats do
    now = DateTime.utc_now()
    last_7 = DateTime.add(now, -7 * 86_400, :second)
    last_30 = DateTime.add(now, -30 * 86_400, :second)

    %{
      total: Repo.aggregate(User, :count, :id),
      last_7_days: Repo.aggregate(from(u in User, where: u.inserted_at >= ^last_7), :count, :id),
      last_30_days:
        Repo.aggregate(from(u in User, where: u.inserted_at >= ^last_30), :count, :id),
      premium: Repo.aggregate(from(u in User, where: u.subscription_tier != "free"), :count, :id),
      creators: Repo.aggregate(from(u in User, where: u.role == "creator"), :count, :id)
    }
  end

  defp period_to_datetime(:last_7_days),
    do: DateTime.add(DateTime.utc_now(), -7 * 86_400, :second)

  defp period_to_datetime(:last_30_days),
    do: DateTime.add(DateTime.utc_now(), -30 * 86_400, :second)

  defp period_to_datetime(:all_time), do: nil
  defp period_to_datetime(_), do: nil
end
