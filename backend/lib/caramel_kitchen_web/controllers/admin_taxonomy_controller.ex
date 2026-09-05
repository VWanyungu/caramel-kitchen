defmodule CaramelKitchenWeb.AdminTaxonomyController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.Taxonomies

  # ── Categories ────────────────────────────────────────────────

  def index_categories(conn, params) do
    list_items("category", conn, params, false)
  end

  def show_category(conn, %{"id" => id}) do
    show_item("category", conn, id)
  end

  def create_category(conn, params) do
    create_item("category", conn, params)
  end

  def update_category(conn, %{"id" => id} = params) do
    update_item("category", conn, id, params)
  end

  def delete_category(conn, %{"id" => id}) do
    delete_item("category", conn, id)
  end

  # ── Cuisines ──────────────────────────────────────────────────

  def index_cuisines(conn, params) do
    list_items("cuisine", conn, params, false)
  end

  def show_cuisine(conn, %{"id" => id}) do
    show_item("cuisine", conn, id)
  end

  def create_cuisine(conn, params) do
    create_item("cuisine", conn, params)
  end

  def update_cuisine(conn, %{"id" => id} = params) do
    update_item("cuisine", conn, id, params)
  end

  def delete_cuisine(conn, %{"id" => id}) do
    delete_item("cuisine", conn, id)
  end

  # ── Dietary Tags ──────────────────────────────────────────────

  def index_dietary_tags(conn, params) do
    list_items("dietary_tag", conn, params, false)
  end

  def show_dietary_tag(conn, %{"id" => id}) do
    show_item("dietary_tag", conn, id)
  end

  def create_dietary_tag(conn, params) do
    create_item("dietary_tag", conn, params)
  end

  def update_dietary_tag(conn, %{"id" => id} = params) do
    update_item("dietary_tag", conn, id, params)
  end

  def delete_dietary_tag(conn, %{"id" => id}) do
    delete_item("dietary_tag", conn, id)
  end

  # ── Difficulties ──────────────────────────────────────────────

  def index_difficulties(conn, params) do
    list_items("difficulty", conn, params, false)
  end

  def show_difficulty(conn, %{"id" => id}) do
    show_item("difficulty", conn, id)
  end

  def create_difficulty(conn, params) do
    create_item("difficulty", conn, params)
  end

  def update_difficulty(conn, %{"id" => id} = params) do
    update_item("difficulty", conn, id, params)
  end

  def delete_difficulty(conn, %{"id" => id}) do
    delete_item("difficulty", conn, id)
  end

  # ── Public Discovery Actions ─────────────────────────────────

  def public_cuisines(conn, params) do
    list_items("cuisine", conn, params, true)
  end

  def public_dietary_tags(conn, params) do
    list_items("dietary_tag", conn, params, true)
  end

  def public_difficulties(conn, params) do
    list_items("difficulty", conn, params, true)
  end

  # ── Internal Helpers ──────────────────────────────────────────

  defp list_items(type, conn, params, default_active) do
    active_only =
      case Map.get(params, "active_only") do
        "true" -> true
        "false" -> false
        _ -> default_active
      end

    search = Map.get(params, "search")

    taxonomies =
      Taxonomies.list_taxonomies(type,
        active_only: active_only,
        search: search
      )

    render(conn, :index, taxonomies: taxonomies)
  end

  defp show_item(type, conn, id) do
    case Taxonomies.get_taxonomy(id) do
      {:ok, %{type: ^type} = taxonomy} ->
        render(conn, :show, taxonomy: taxonomy)

      _ ->
        {:error, :not_found}
    end
  end

  defp create_item(type, conn, params) do
    with {:ok, taxonomy} <- Taxonomies.create_taxonomy(type, params) do
      conn
      |> put_status(:created)
      |> render(:show, taxonomy: taxonomy)
    end
  end

  defp update_item(type, conn, id, params) do
    with {:ok, %{type: ^type} = taxonomy} <- Taxonomies.get_taxonomy(id),
         attrs = Map.drop(params, ["id", "type"]),
         {:ok, updated} <- Taxonomies.update_taxonomy(taxonomy, attrs) do
      render(conn, :show, taxonomy: updated)
    else
      {:ok, _other_type_taxonomy} -> {:error, :not_found}
      {:error, :not_found} -> {:error, :not_found}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
    end
  end

  defp delete_item(type, conn, id) do
    with {:ok, %{type: ^type} = taxonomy} <- Taxonomies.get_taxonomy(id),
         {:ok, _deleted} <- Taxonomies.delete_taxonomy(taxonomy) do
      send_resp(conn, :no_content, "")
    else
      {:ok, _other_type_taxonomy} -> {:error, :not_found}
      {:error, :not_found} -> {:error, :not_found}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
    end
  end
end
