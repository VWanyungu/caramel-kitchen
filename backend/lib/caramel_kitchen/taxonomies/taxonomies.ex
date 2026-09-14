defmodule CaramelKitchen.Taxonomies do
  @moduledoc """
  Context module for managing taxonomy metadata (categories, cuisines, dietary tags, and difficulty levels).
  Provides CRUD operations for admin and read operations for client discovery.
  """
  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Taxonomies.Taxonomy

  @doc "Lists taxonomies of a specific type with optional active_only filter"
  def list_taxonomies(type, opts \\ []) do
    active_only = Keyword.get(opts, :active_only, true)
    search = Keyword.get(opts, :search)

    from(t in Taxonomy, where: t.type == ^to_string(type))
    |> apply_active_filter(active_only)
    |> apply_search_filter(search)
    |> order_by([t], asc: t.display_order, asc: t.name)
    |> Repo.all()
  end

  @doc "Get a single taxonomy by ID"
  def get_taxonomy(id) do
    case Repo.get(Taxonomy, id) do
      nil -> {:error, :not_found}
      taxonomy -> {:ok, taxonomy}
    end
  end

  @doc "Get a single taxonomy by ID, raising if not found"
  def get_taxonomy!(id), do: Repo.get!(Taxonomy, id)

  @doc "Get a taxonomy by type and slug"
  def get_taxonomy_by_slug(type, slug) do
    case Repo.get_by(Taxonomy, type: to_string(type), slug: to_string(slug)) do
      nil -> {:error, :not_found}
      taxonomy -> {:ok, taxonomy}
    end
  end

  @doc "Create a new taxonomy of given type"
  def create_taxonomy(type, attrs) when is_map(attrs) do
    attrs = Map.put(attrs, "type", to_string(type))

    %Taxonomy{}
    |> Taxonomy.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Update an existing taxonomy"
  def update_taxonomy(%Taxonomy{} = taxonomy, attrs) when is_map(attrs) do
    taxonomy
    |> Taxonomy.update_changeset(attrs)
    |> Repo.update()
  end

  @doc "Delete a taxonomy"
  def delete_taxonomy(%Taxonomy{} = taxonomy) do
    Repo.delete(taxonomy)
  end

  # ── Convenience helpers ───────────────────────────────────────

  def list_categories(opts \\ []), do: list_taxonomies("category", opts)
  def list_cuisines(opts \\ []), do: list_taxonomies("cuisine", opts)
  def list_dietary_tags(opts \\ []), do: list_taxonomies("dietary_tag", opts)
  def list_difficulties(opts \\ []), do: list_taxonomies("difficulty", opts)

  # ── Filter helpers ────────────────────────────────────────────

  defp apply_active_filter(query, true), do: from(t in query, where: t.is_active == true)
  defp apply_active_filter(query, false), do: query
  defp apply_active_filter(query, nil), do: query

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, search) do
    term = "%#{String.trim(search)}%"
    from(t in query, where: ilike(t.name, ^term) or ilike(t.slug, ^term))
  end
end
