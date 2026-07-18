defmodule CaramelKitchenWeb.SuperAdminController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.{Accounts, Analytics}

  # GET /api/v1/superadmin/users
  def list_users(conn, params) do
    role = params["role"]
    tier = params["tier"]
    active = params["active"]

    opts =
      []
      |> then(fn o -> if role, do: [{:role, role} | o], else: o end)
      |> then(fn o -> if tier, do: [{:tier, tier} | o], else: o end)
      |> then(fn o -> if active == "true", do: [{:active, true} | o], else: o end)

    users = Accounts.list_users(opts)

    json(conn, %{
      data:
        Enum.map(users, fn u ->
          %{
            id: u.id,
            email: u.email,
            name: u.name,
            role: u.role,
            subscription_tier: u.subscription_tier,
            inserted_at: u.inserted_at,
            last_sign_in_at: u.last_sign_in_at,
            sign_in_count: u.sign_in_count,
            deactivated_at: u.deactivated_at
          }
        end)
    })
  end

  # PUT /api/v1/superadmin/users/:id/role
  def update_role(conn, %{"id" => id, "role" => role}) do
    with {:ok, user} <- Accounts.get_user(id),
         {:ok, updated} <- Accounts.update_user_role(user, role) do
      json(conn, %{data: %{id: updated.id, role: updated.role}})
    end
  end

  # DELETE /api/v1/superadmin/users/:id
  def deactivate_user(conn, %{"id" => id} = params) do
    with {:ok, user} <- Accounts.get_user(id),
         {:ok, _} <- Accounts.deactivate_user(user, params["reason"]) do
      json(conn, %{message: "User deactivated"})
    end
  end

  # GET /api/v1/superadmin/system/stats
  def system_stats(conn, _params) do
    json(conn, %{
      data: %{
        users: Analytics.user_growth_stats(),
        taste_dist: Analytics.taste_distribution(),
        oban_queues: oban_stats(),
        cache_stats: cache_stats(),
        node_info: node_info()
      }
    })
  end

  defp oban_stats do
    try do
      Enum.map([:default, :content, :email, :analytics, :maintenance, :ai], fn q ->
        {q, Oban.check_queue(queue: q)}
      end)
      |> Map.new()
    rescue
      _ -> %{error: "unavailable"}
    end
  end

  defp cache_stats do
    try do
      case Redix.command(:redix, ["INFO", "stats"]) do
        {:ok, info} ->
          info
          |> String.split("\r\n")
          |> Enum.filter(&String.contains?(&1, ":"))
          |> Map.new(fn line ->
            [k, v] = String.split(line, ":", parts: 2)
            {k, v}
          end)
          |> Map.take([
            "keyspace_hits",
            "keyspace_misses",
            "connected_clients",
            "used_memory_human"
          ])

        _ ->
          %{}
      end
    rescue
      _ -> %{error: "unavailable"}
    end
  end

  defp node_info do
    %{
      node: node(),
      erlang_version: :erlang.system_info(:version) |> to_string(),
      elixir_version: System.version(),
      uptime_secs: :erlang.statistics(:wall_clock) |> elem(0) |> div(1000),
      process_count: :erlang.system_info(:process_count),
      memory_mb: :erlang.memory(:total) |> div(1_048_576)
    }
  end
end
