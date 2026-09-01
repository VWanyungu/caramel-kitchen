defmodule CaramelKitchen.TasteEngine.VectorUpdater do
  @moduledoc """
  GenServer that buffers taste vector update events and applies them
  in micro-batches to avoid thundering herd on PostgreSQL.
  Events are flushed every 2 seconds or when buffer hits 100 items.
  """
  use GenServer
  require Logger

  alias CaramelKitchen.{Accounts, Recipes, Repo}
  alias CaramelKitchen.Accounts.User

  @flush_interval_ms 2_000
  @max_buffer_size 100

  defstruct buffer: [], flush_timer: nil

  # ── Client API ────────────────────────────────────────────────

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc """
  Enqueue a taste vector update.
  action: :saved | :cooked | :skipped | :rated_5 | :rated_1
  """
  def enqueue(user_id, recipe_id, action) do
    GenServer.cast(__MODULE__, {:update, user_id, recipe_id, action})
  end

  # ── Callbacks ─────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    timer = schedule_flush()
    {:ok, %__MODULE__{flush_timer: timer}}
  end

  @impl true
  def handle_cast({:update, user_id, recipe_id, action}, state) do
    new_buffer = [{user_id, recipe_id, action} | state.buffer]

    if length(new_buffer) >= @max_buffer_size do
      Process.cancel_timer(state.flush_timer)
      flush_buffer(new_buffer)
      {:noreply, %{state | buffer: [], flush_timer: schedule_flush()}}
    else
      {:noreply, %{state | buffer: new_buffer}}
    end
  end

  @impl true
  def handle_info(:flush, state) do
    flush_buffer(state.buffer)
    {:noreply, %{state | buffer: [], flush_timer: schedule_flush()}}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    Logger.error("VectorUpdater monitored process died: #{inspect(reason)}")
    {:noreply, state}
  end

  # ── Private ───────────────────────────────────────────────────

  defp flush_buffer([]), do: :ok

  defp flush_buffer(events) do
    # Group by user to minimise DB reads
    grouped = Enum.group_by(events, fn {user_id, _, _} -> user_id end)

    Enum.each(grouped, fn {user_id, user_events} ->
      try do
        apply_user_events(user_id, user_events)
      rescue
        e ->
          Logger.error("VectorUpdater failed for user #{user_id}: #{inspect(e)}")
      end
    end)
  end

  defp apply_user_events(user_id, events) do
    with {:ok, user} <- Accounts.get_user(user_id) do
      # Aggregate all recipe profiles for this user's events
      aggregated_deltas =
        events
        |> Enum.reduce(List.duplicate(0.0, 8), fn {_uid, recipe_id, action}, acc ->
          recipe = Recipes.get_recipe!(recipe_id)
          profile = CaramelKitchen.Recipes.Recipe.taste_profile_list(recipe)
          delta = taste_delta(action)

          Enum.zip_with(acc, profile, fn a, p -> a + delta * p end)
        end)

      # Apply single aggregated update
      current = User.taste_vector_list(user)

      updated =
        Enum.zip_with(current, aggregated_deltas, fn c, d ->
          Float.round(clamp(c + d, 0.0, 1.0), 4)
        end)

      user
      |> User.taste_update_changeset(updated)
      |> Repo.update!()

      CaramelKitchen.Cache.invalidate_user_feed(user)
      Logger.debug("Updated taste vector for user #{user_id}")
    end
  end

  defp taste_delta(:cooked), do: 0.10
  defp taste_delta(:saved), do: 0.07
  defp taste_delta(:skipped), do: -0.05
  defp taste_delta(:rated_5), do: 0.15
  defp taste_delta(:rated_1), do: -0.10
  defp taste_delta(_), do: 0.0

  defp clamp(val, min, max), do: val |> max(min) |> min(max)
  defp schedule_flush, do: Process.send_after(self(), :flush, @flush_interval_ms)
end
