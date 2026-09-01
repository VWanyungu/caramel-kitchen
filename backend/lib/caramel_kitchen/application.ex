defmodule CaramelKitchen.Application do
  @moduledoc """
  OTP Application entry point.
  Supervision tree is ordered deliberately:
  infrastructure -> cache -> jobs -> business logic -> HTTP endpoint.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # 1. Telemetry (must be first)
      CaramelKitchen.Telemetry,

      # 2. PromEx metrics
      CaramelKitchen.PromEx,

      # 3. Database
      CaramelKitchen.Repo,

      # 4. PubSub (must be before Endpoint & Channels)
      {Phoenix.PubSub, name: CaramelKitchen.PubSub},

      # 5. L1 Cache (ETS via ConCache)
      {ConCache,
       [
         name: :caramel_cache,
         ttl_check_interval: :timer.seconds(30),
         global_ttl: :timer.seconds(60),
         ets_options: [:named_table, read_concurrency: true, write_concurrency: true]
       ]},

      # 8. Background jobs (Oban)
      {Oban, Application.fetch_env!(:caramel_kitchen, Oban)},

      # 9. Taste engine GenServers
      {CaramelKitchen.TasteEngine.Supervisor, []},

      # 10. AI orchestration
      {CaramelKitchen.AI.Supervisor, []},

      # 11. Meal plan engine
      {CaramelKitchen.MealPlans.Supervisor, []},

      # 12. Content pipeline
      {CaramelKitchen.Content.Supervisor, []},

      # 13. Daraja (M-Pesa)
      {Finch, name: Daraja.Finch},
      {Daraja.Supervisor, []},
      {Daraja.Callback.Guard, []},

      # 14. HTTP Endpoint (always last)
      CaramelKitchenWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: CaramelKitchen.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        attach_oban_telemetry()
        {:ok, pid}

      error ->
        error
    end
  end

  @impl true
  def config_change(changed, _new, removed) do
    CaramelKitchenWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp attach_oban_telemetry do
    :telemetry.attach_many(
      "oban-logger",
      [
        [:oban, :job, :start],
        [:oban, :job, :stop],
        [:oban, :job, :exception]
      ],
      &CaramelKitchen.ObanLogger.handle_event/4,
      nil
    )
  end


end

defmodule CaramelKitchen.ObanLogger do
  require Logger

  def handle_event([:oban, :job, :start], _measure, meta, _) do
    Logger.info("[Oban] started  worker=#{meta.worker} queue=#{meta.queue} id=#{meta.id}")
  end

  def handle_event([:oban, :job, :stop], %{duration: dur}, meta, _) do
    ms = System.convert_time_unit(dur, :native, :millisecond)

    Logger.info(
      "[Oban] complete worker=#{meta.worker} queue=#{meta.queue} id=#{meta.id} duration_ms=#{ms}"
    )
  end

  def handle_event([:oban, :job, :exception], _measure, meta, _) do
    Logger.error(
      "[Oban] failed   worker=#{meta.worker} queue=#{meta.queue} id=#{meta.id} error=#{inspect(meta.reason)}"
    )
  end
end
