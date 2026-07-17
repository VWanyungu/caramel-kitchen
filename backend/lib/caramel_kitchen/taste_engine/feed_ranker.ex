defmodule CaramelKitchen.TasteEngine.FeedRanker do
  @moduledoc """
  GenServer that maintains a hot-cache of pre-ranked feed IDs per user.
  Invalidated whenever the user's taste vector changes or new recipes are published.
  Uses ETS for nanosecond-speed lookups with a 5-minute TTL.
  """
  use GenServer
  require Logger

  @table     :feed_rank_cache
  @ttl_ms    :timer.minutes(5)

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # ── Client API ────────────────────────────────────────────────

  def get_ranked_ids(user_id) do
    case :ets.lookup(@table, user_id) do
      [{^user_id, ids, inserted_at}] ->
        if System.monotonic_time(:millisecond) - inserted_at < @ttl_ms do
          {:ok, ids}
        else
          :miss
        end
      [] -> :miss
    end
  end

  def put_ranked_ids(user_id, ids) do
    :ets.insert(@table, {user_id, ids, System.monotonic_time(:millisecond)})
    :ok
  end

  def invalidate_cache(user_id) do
    :ets.delete(@table, user_id)
    Logger.debug("Invalidated feed cache for user #{user_id}")
    :ok
  end

  def invalidate_all do
    :ets.delete_all_objects(@table)
    Logger.info("Invalidated all feed caches")
    :ok
  end

  # ── Callbacks ─────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    :ets.new(@table, [
      :named_table,
      :public,
      :set,
      read_concurrency:  true,
      write_concurrency: true
    ])

    # Subscribe to feed update events
    Phoenix.PubSub.subscribe(CaramelKitchen.PubSub, "feed:updates")

    # Periodic cleanup of expired entries
    Process.send_after(self(), :cleanup, :timer.minutes(10))

    {:ok, %{}}
  end

  @impl true
  def handle_info({:new_recipe, _recipe}, state) do
    # New recipe published — invalidate all caches
    invalidate_all()
    {:noreply, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    now   = System.monotonic_time(:millisecond)
    count = :ets.select_delete(@table,
      [{{:_, :_, :"$1"}, [{:<, {:-, now, :"$1"}, @ttl_ms}], [true]}]
    )
    Logger.debug("Feed rank cache cleanup: removed #{count} stale entries")
    Process.send_after(self(), :cleanup, :timer.minutes(10))
    {:noreply, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}
end
