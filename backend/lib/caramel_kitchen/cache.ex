defmodule CaramelKitchen.Cache do
  @moduledoc """
  Two-tier cache:
  - L1: ConCache (ETS, in-process) — microsecond reads, node-local
  - L2: Redis (Redix) — shared across cluster nodes, survives restarts

  Strategy: read L1 → L2 → source. Write to both on miss.
  Invalidation: delete from both tiers.
  """

  require Logger

  @l1_ttl :timer.seconds(30)

  # ── Read ──────────────────────────────────────────────────────

  @doc "Get or compute a value. fun/0 is called on cache miss."
  def get_or_store(key, ttl_ms \\ :timer.minutes(5), fun) do
    case l1_get(key) do
      {:ok, val} ->
        val

      :miss ->
        case l2_get(key) do
          {:ok, val} ->
            l1_put(key, val)
            val

          :miss ->
            val = fun.()
            l1_put(key, val)
            l2_put(key, val, ttl_ms)
            val
        end
    end
  end

  def get(key) do
    case l1_get(key) do
      {:ok, val} -> {:ok, val}
      :miss -> l2_get(key)
    end
  end

  def put(key, val, ttl_ms \\ :timer.minutes(5)) do
    l1_put(key, val)
    l2_put(key, val, ttl_ms)
    :ok
  end

  # ── Invalidation ──────────────────────────────────────────────

  def invalidate(key) do
    l1_delete(key)
    l2_delete(key)
    :ok
  end

  def invalidate_user(%{id: user_id}), do: invalidate("user:#{user_id}")
  def invalidate_user_feed(%{id: user_id}) do
    # Pattern-delete all feed keys for this user
    l2_pattern_delete("feed:#{user_id}:*")
    :ok
  end
  def invalidate_recipe(recipe_id), do: invalidate("recipe:#{recipe_id}")
  def invalidate_category_counts, do: invalidate("category_counts")
  def invalidate_trending, do: invalidate("trending:global")

  # ── L1: ConCache (ETS) ────────────────────────────────────────

  defp l1_get(key) do
    case ConCache.get(:caramel_cache, key) do
      nil -> :miss
      val -> {:ok, val}
    end
  rescue
    _ -> :miss
  catch
    :exit, _ -> :miss
  end

  defp l1_put(key, val) do
    ConCache.put(:caramel_cache, key, %ConCache.Item{value: val, ttl: @l1_ttl})
  rescue
    e -> Logger.warning("L1 cache put failed for #{key}: #{inspect(e)}")
  catch
    :exit, _ -> Logger.warning("L1 cache put failed for #{key}: process not running")
  end

  defp l1_delete(key) do
    ConCache.delete(:caramel_cache, key)
  rescue
    _ -> :ok
  catch
    :exit, _ -> :ok
  end

  # ── L2: Redis ─────────────────────────────────────────────────

  defp l2_get(key) do
    case Redix.command(:redix, ["GET", prefixed(key)]) do
      {:ok, nil}   -> :miss
      {:ok, value} ->
        case :erlang.binary_to_term(value, [:safe]) do
          term -> {:ok, term}
        end
      {:error, reason} ->
        Logger.warning("Redis GET failed for #{key}: #{inspect(reason)}")
        :miss
    end
  rescue
    _ -> :miss
  catch
    :exit, _ -> :miss
  end

  defp l2_put(key, val, ttl_ms) do
    ttl_secs = max(div(ttl_ms, 1000), 1)
    binary   = :erlang.term_to_binary(val)

    case Redix.command(:redix, ["SET", prefixed(key), binary, "EX", ttl_secs]) do
      {:ok, _}         -> :ok
      {:error, reason} ->
        Logger.warning("Redis SET failed for #{key}: #{inspect(reason)}")
        :ok
    end
  rescue
    e ->
      Logger.warning("Redis SET exception for #{key}: #{inspect(e)}")
      :ok
  catch
    :exit, _ ->
      Logger.warning("Redis SET exit for #{key}: process not running")
      :ok
  end

  defp l2_delete(key) do
    Redix.command(:redix, ["DEL", prefixed(key)])
  rescue
    _ -> :ok
  catch
    :exit, _ -> :ok
  end

  defp l2_pattern_delete(pattern) do
    case Redix.command(:redix, ["SCAN", "0", "MATCH", prefixed(pattern), "COUNT", "100"]) do
      {:ok, [_cursor, keys]} when keys != [] ->
        Redix.command(:redix, ["DEL" | keys])
      _ -> :ok
    end
  rescue
    _ -> :ok
  catch
    :exit, _ -> :ok
  end

  defp prefixed(key), do: "ck:#{key}"
end
