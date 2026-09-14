defmodule CaramelKitchenWeb.CollectionController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.Collections
  alias CaramelKitchenWeb.CollectionJSON

  # GET /api/v1/collections
  def index(conn, params) do
    viewer = conn.assigns[:current_user]
    opts = build_query_opts(params, viewer)

    collections = Collections.list_collections(opts)
    total = Collections.count_collections(opts)

    render(conn, :index,
      collections: collections,
      current_user: viewer,
      meta: %{
        total_count: total,
        limit: Keyword.get(opts, :limit, 20),
        offset: Keyword.get(opts, :offset, 0)
      }
    )
  end

  # GET /api/v1/me/collections
  def my_collections(conn, params) do
    user = conn.assigns.current_user
    opts = [viewer: user, mine: true] ++ build_query_opts(params, user)

    collections = Collections.list_collections(opts)
    total = Collections.count_collections(opts)

    render(conn, :index,
      collections: collections,
      current_user: user,
      meta: %{
        total_count: total,
        limit: Keyword.get(opts, :limit, 20),
        offset: Keyword.get(opts, :offset, 0)
      }
    )
  end

  # GET /api/v1/collections/:id
  def show(conn, %{"id" => id}) do
    viewer = conn.assigns[:current_user]

    case Collections.get_collection(id, viewer: viewer) do
      {:ok, collection} ->
        if (collection.is_premium || false) && not Collections.has_access?(collection, viewer) do
          conn
          |> put_status(:payment_required)
          |> json(%{
            error: "premium_required",
            message: "This collection requires a Premium subscription",
            upgrade_url: "/subscription/checkout"
          })
        else
          render(conn, :show, collection: collection, current_user: viewer)
        end

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  # POST /api/v1/collections
  def create(conn, params) do
    user = conn.assigns.current_user

    with {:ok, collection} <- Collections.create_collection(user, params) do
      conn
      |> put_status(:created)
      |> render(:show, collection: collection)
    end
  end

  # PUT /api/v1/collections/:id
  def update(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user

    with {:ok, collection} <- Collections.get_collection(id, viewer: user) do
      if Collections.can_manage?(collection, user) do
        attrs = Map.delete(params, "id")

        with {:ok, updated} <- Collections.update_collection(collection, attrs) do
          render(conn, :show, collection: updated)
        end
      else
        {:error, :forbidden}
      end
    end
  end

  # DELETE /api/v1/collections/:id
  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    with {:ok, collection} <- Collections.get_collection(id, viewer: user) do
      if Collections.can_manage?(collection, user) do
        with {:ok, _deleted} <- Collections.delete_collection(collection) do
          send_resp(conn, :no_content, "")
        end
      else
        {:error, :forbidden}
      end
    end
  end

  # POST /api/v1/collections/:id/items
  def add_item(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user

    with {:ok, collection} <- Collections.get_collection(id, viewer: user) do
      if Collections.can_manage?(collection, user) do
        with {:ok, item} <- Collections.add_item(collection, params) do
          conn
          |> put_status(:created)
          |> render(:item, item: item)
        end
      else
        {:error, :forbidden}
      end
    end
  end

  # DELETE /api/v1/collections/:id/items/:item_id
  def remove_item(conn, %{"id" => id, "item_id" => item_id}) do
    user = conn.assigns.current_user

    with {:ok, collection} <- Collections.get_collection(id, viewer: user) do
      if Collections.can_manage?(collection, user) do
        with {:ok, _deleted} <- Collections.remove_item(collection, item_id) do
          send_resp(conn, :no_content, "")
        end
      else
        {:error, :forbidden}
      end
    end
  end

  # ── User Interaction (Save / Unsave) ─────────────────────────

  # POST /api/v1/collections/:id/save
  def save(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user
    metadata = Map.get(params, "metadata", %{})

    with {:ok, result} <- Collections.save_collection(user, id, metadata) do
      json(conn, CollectionJSON.action_result(%{result: result}))
    end
  end

  # DELETE /api/v1/collections/:id/save
  def unsave(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    with {:ok, result} <- Collections.unsave_collection(user, id) do
      json(conn, CollectionJSON.action_result(%{result: result}))
    end
  end

  # GET /api/v1/collections/:id/status
  def status(conn, %{"id" => id}) do
    user = conn.assigns[:current_user]

    with {:ok, status} <- Collections.get_user_collection_status(user, id) do
      json(conn, CollectionJSON.status(%{status: status}))
    end
  end

  # GET /api/v1/me/collections/saved
  def saved_collections(conn, params) do
    user = conn.assigns.current_user
    opts = build_query_opts(params, user)
    collections = Collections.list_saved_collections(user, opts)
    total = Collections.count_saved_collections(user, opts)

    render(conn, :index,
      collections: collections,
      current_user: user,
      meta: %{
        total_count: total,
        limit: Keyword.get(opts, :limit, 20),
        offset: Keyword.get(opts, :offset, 0)
      }
    )
  end

  # GET /api/v1/collections/seasonal
  # GET /api/v1/premium/collections/seasonal
  def seasonal(conn, params) do
    viewer = conn.assigns[:current_user]

    opts =
      build_query_opts(params, viewer)
      |> Keyword.put(:is_seasonal, true)
      |> Keyword.put_new(:is_premium, true)

    collections = Collections.list_collections(opts)
    total = Collections.count_collections(opts)

    render(conn, :seasonal,
      collections: collections,
      current_user: viewer,
      meta: %{
        total_count: total,
        limit: Keyword.get(opts, :limit, 20),
        offset: Keyword.get(opts, :offset, 0),
        current_date: Date.utc_today()
      }
    )
  end

  # ── Helpers ───────────────────────────────────────────────────

  defp build_query_opts(params, viewer) do
    []
    |> maybe_put(:viewer, viewer)
    |> maybe_put(:user_id, params["user_id"] || params["creator_id"])
    |> maybe_put(:recipe_id, params["recipe_id"])
    |> maybe_put(:video_id, params["video_id"])
    |> maybe_put(:is_curated, parse_boolean(params["is_curated"]))
    |> maybe_put(:is_public, parse_boolean(params["is_public"]))
    |> maybe_put(:is_premium, parse_boolean(params["is_premium"]))
    |> maybe_put(:is_seasonal, parse_boolean(params["is_seasonal"]))
    |> maybe_put(:season_name, params["season_name"])
    |> maybe_put(:active_seasonal_only, parse_boolean(params["active_seasonal_only"]))
    |> maybe_put(:search, params["search"] || params["q"])
    |> maybe_put(:sort, params["sort"])
    |> maybe_put(:limit, parse_int(params["limit"]))
    |> maybe_put(:offset, parse_int(params["offset"]))
    |> maybe_put(:mine, parse_boolean(params["mine"]))
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, _key, ""), do: opts
  defp maybe_put(opts, key, val), do: [{key, val} | opts]

  defp parse_boolean(nil), do: nil
  defp parse_boolean(val) when val in [true, "true", "1"], do: true
  defp parse_boolean(val) when val in [false, "false", "0"], do: false
  defp parse_boolean(_), do: nil

  defp parse_int(nil), do: nil

  defp parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {val, _} -> val
      :error -> nil
    end
  end

  defp parse_int(val) when is_integer(val), do: val
  defp parse_int(_), do: nil
end
