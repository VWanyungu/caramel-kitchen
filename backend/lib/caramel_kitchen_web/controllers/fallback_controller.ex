defmodule CaramelKitchenWeb.FallbackController do
  use Phoenix.Controller

  def call(conn, {:error, :not_found}) do
    conn |> put_status(:not_found) |> json(%{error: "not_found", message: "Resource not found"})
  end

  def call(conn, {:error, :unauthorized}) do
    conn |> put_status(:unauthorized) |> json(%{error: "unauthorized"})
  end

  def call(conn, {:error, :forbidden}) do
    conn |> put_status(:forbidden) |> json(%{error: "forbidden"})
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "validation_error", errors: errors})
  end

  def call(conn, {:error, reason}) when is_atom(reason) do
    conn |> put_status(422) |> json(%{error: to_string(reason)})
  end

  def call(conn, {:error, reason}) do
    conn |> put_status(500) |> json(%{error: "internal_server_error", detail: inspect(reason)})
  end
end

# ── Health Controller ──────────────────────────────────────────

defmodule CaramelKitchenWeb.HealthController do
  use CaramelKitchenWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok", version: "2.0.0"})
  end

  def ready(conn, _params) do
    checks = %{
      database: check_database(),
      redis: check_redis()
    }

    all_ok = Enum.all?(checks, fn {_, v} -> v == :ok end)
    status = if all_ok, do: :ok, else: :service_unavailable

    conn
    |> put_status(status)
    |> json(%{status: if(all_ok, do: "ready", else: "not_ready"), checks: checks})
  end

  defp check_database do
    case CaramelKitchen.Repo.query("SELECT 1", []) do
      {:ok, _} -> :ok
      _ -> :error
    end
  rescue
    _ -> :error
  end

  defp check_redis do
    case Redix.command(:redix, ["PING"]) do
      {:ok, "PONG"} -> :ok
      _ -> :error
    end
  rescue
    _ -> :error
  end
end

# ── Webhook Controller ─────────────────────────────────────────

defmodule CaramelKitchenWeb.WebhookController do
  use CaramelKitchenWeb, :controller
  require Logger

  alias CaramelKitchen.Monetisation

  def stripe(conn, _params) do
    payload = conn.assigns.stripe_payload

    case Monetisation.handle_webhook(payload) do
      :ok ->
        json(conn, %{received: true})

      {:ok, _} ->
        json(conn, %{received: true})

      {:error, reason} ->
        Logger.error("Stripe webhook error: #{inspect(reason)}")
        conn |> put_status(422) |> json(%{error: "webhook_processing_failed"})
    end
  end
end

# ── Shopping Controller ────────────────────────────────────────

defmodule CaramelKitchenWeb.ShoppingController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.Shopping

  def index(conn, _params) do
    user = conn.assigns.current_user
    lists = Shopping.list_user_lists(user.id)
    json(conn, %{data: Enum.map(lists, &render_list_summary/1)})
  end

  def create(conn, params) do
    user = conn.assigns.current_user

    with {:ok, list} <- Shopping.create_list(user.id, params) do
      conn |> put_status(:created) |> json(%{data: render_list_full(list)})
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, list} <- Shopping.get_list(id) do
      json(conn, %{data: render_list_full(list)})
    end
  end

  def show_shared(conn, %{"token" => token}) do
    with {:ok, list} <- Shopping.get_list_by_token(token) do
      json(conn, %{data: render_list_full(list)})
    end
  end

  def check_item(conn, %{"id" => id, "item_index" => idx}) do
    user = conn.assigns.current_user

    with {:ok, list} <- Shopping.check_item(id, String.to_integer(idx), user.id) do
      json(conn, %{data: %{checked_ids: list.checked_ids}})
    end
  end

  def uncheck_item(conn, %{"id" => id, "item_index" => idx}) do
    user = conn.assigns.current_user

    with {:ok, list} <- Shopping.uncheck_item(id, String.to_integer(idx), user.id) do
      json(conn, %{data: %{checked_ids: list.checked_ids}})
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, list} <- Shopping.get_list(id) do
      CaramelKitchen.Repo.delete(list)
      send_resp(conn, :no_content, "")
    end
  end

  defp render_list_summary(list) do
    %{
      id: list.id,
      name: list.name,
      item_count: length(list.items),
      share_token: list.share_token,
      inserted_at: list.inserted_at
    }
  end

  defp render_list_full(list) do
    Map.merge(render_list_summary(list), %{
      items: list.items,
      checked_ids: list.checked_ids,
      servings_multiplier: list.servings_multiplier,
      meal_plan_id: list.meal_plan_id,
      whatsapp_url: Shopping.whatsapp_share_url(list)
    })
  end
end
