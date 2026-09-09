defmodule CaramelKitchen.Collections do
  @moduledoc """
  Context for managing curated Collections of recipes and videos.
  Provides CRUD operations, item management, and multi-dimensional filtering.
  """
  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Accounts.User
  alias CaramelKitchen.Collections.{Collection, CollectionItem, UserCollectionInteraction}

  # Suppress Dialyzer false positive with Ecto.Multi opaque types
  @dialyzer {:nowarn_function, create_collection: 2}

  # ── Collections Querying ──────────────────────────────────────

  @doc """
  Lists collections with multi-dimensional filtering.
  Supported filters in opts:
  - :viewer — User attempting to view (for privacy gating)
  - :user_id / :creator_id — filter by collection author
  - :mine — boolean (filters to current user's collections if viewer present)
  - :recipe_id — filter collections containing this recipe
  - :video_id — filter collections containing this video
  - :is_curated — boolean
  - :is_public — boolean
  - :is_premium — boolean
  - :is_seasonal — boolean
  - :season_name — string
  - :active_seasonal_only — boolean (defaults to true for public/users, false for admin)
  - :current_date — Date (default Date.utc_today())
  - :search / :q — string to match name or description
  - :sort — "newest" | "oldest" | "name" | "items_count"
  - :limit — integer (default 20, max 100)
  - :offset — integer (default 0)
  """
  def list_collections(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20) |> min(100)
    offset = Keyword.get(opts, :offset, 0)
    viewer = Keyword.get(opts, :viewer)

    base_query()
    |> apply_privacy_filter(viewer, opts)
    |> apply_author_filter(opts)
    |> apply_recipe_filter(Keyword.get(opts, :recipe_id))
    |> apply_video_filter(Keyword.get(opts, :video_id))
    |> apply_curated_filter(Keyword.get(opts, :is_curated))
    |> apply_public_filter(Keyword.get(opts, :is_public))
    |> apply_premium_filter(Keyword.get(opts, :is_premium))
    |> apply_seasonal_filter(viewer, opts)
    |> apply_season_name_filter(Keyword.get(opts, :season_name))
    |> apply_search_filter(Keyword.get(opts, :search) || Keyword.get(opts, :q))
    |> apply_sorting(Keyword.get(opts, :sort, "newest"))
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc "Count collections matching given filters"
  def count_collections(opts \\ []) do
    viewer = Keyword.get(opts, :viewer)

    from(c in Collection)
    |> apply_privacy_filter(viewer, opts)
    |> apply_author_filter(opts)
    |> apply_recipe_filter(Keyword.get(opts, :recipe_id))
    |> apply_video_filter(Keyword.get(opts, :video_id))
    |> apply_curated_filter(Keyword.get(opts, :is_curated))
    |> apply_public_filter(Keyword.get(opts, :is_public))
    |> apply_premium_filter(Keyword.get(opts, :is_premium))
    |> apply_seasonal_filter(viewer, opts)
    |> apply_season_name_filter(Keyword.get(opts, :season_name))
    |> apply_search_filter(Keyword.get(opts, :search) || Keyword.get(opts, :q))
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a single collection by ID with preloaded items.
  Optionally checks privacy against :viewer and enforces seasonal date range.
  """
  def get_collection(id, opts \\ []) do
    viewer = Keyword.get(opts, :viewer)
    check_season = Keyword.get(opts, :check_season, true)
    today = Keyword.get(opts, :current_date, Date.utc_today())

    case Repo.get(base_query(), id) do
      nil ->
        {:error, :not_found}

      %Collection{is_public: false} = collection ->
        if can_view_private?(collection, viewer) do
          maybe_check_season(collection, viewer, check_season, today)
        else
          {:error, :not_found}
        end

      %Collection{} = collection ->
        maybe_check_season(collection, viewer, check_season, today)
    end
  end

  defp maybe_check_season(collection, viewer, true, today) do
    if collection.is_seasonal and not Collection.in_season?(collection, today) and
         not can_manage?(collection, viewer) do
      {:error, :not_found}
    else
      {:ok, collection}
    end
  end

  defp maybe_check_season(collection, _viewer, false, _today), do: {:ok, collection}

  @doc "Lists active seasonal collections (under Premium by default)"
  def list_seasonal_collections(opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:is_seasonal, true)
      |> Keyword.put_new(:is_premium, true)

    list_collections(opts)
  end

  @doc "Lists distinct season names"
  def list_seasons do
    from(c in Collection,
      where: c.is_seasonal == true and not is_nil(c.season_name),
      distinct: true,
      select: c.season_name
    )
    |> Repo.all()
  end

  @doc "Returns active seasonal collections grouped by season_name"
  def grouped_seasonal_collections(opts \\ []) do
    collections = list_seasonal_collections(opts)
    Enum.group_by(collections, & &1.season_name)
  end

  @doc "Gets a collection by ID, raising if not found"
  def get_collection!(id) do
    Repo.get!(base_query(), id)
  end

  # ── CRUD Operations ───────────────────────────────────────────

  @doc "Creates a new collection for the given user, optionally attaching initial items"
  def create_collection(user, attrs) when is_map(attrs) do
    attrs = Map.put(attrs, "user_id", user.id)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:collection, Collection.changeset(%Collection{}, attrs))
    |> Ecto.Multi.run(:attach_items, fn repo, %{collection: collection} ->
      attach_initial_items(repo, collection, attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{collection: collection}} ->
        {:ok, get_collection!(collection.id)}

      {:error, :collection, changeset, _} ->
        {:error, changeset}

      {:error, :attach_items, reason, _} ->
        {:error, reason}
    end
  end

  @doc "Updates an existing collection"
  def update_collection(%Collection{} = collection, attrs) when is_map(attrs) do
    collection
    |> Collection.update_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, get_collection!(updated.id)}
      error -> error
    end
  end

  @doc "Deletes a collection and its items"
  def delete_collection(%Collection{} = collection) do
    Repo.delete(collection)
  end

  # ── Collection Item Management ────────────────────────────────

  @doc "Adds an item (recipe or video) to a collection"
  def add_item(%Collection{} = collection, attrs) when is_map(attrs) do
    next_pos = next_item_position(collection.id)

    attrs =
      attrs
      |> Map.put("collection_id", collection.id)
      |> Map.put_new("position", next_pos)
      |> normalize_item_attrs()

    %CollectionItem{}
    |> CollectionItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Removes an item from a collection by item ID"
  def remove_item(%Collection{} = collection, item_id) do
    case Repo.get_by(CollectionItem, id: item_id, collection_id: collection.id) do
      nil -> {:error, :not_found}
      item -> Repo.delete(item)
    end
  end

  @doc "Removes an item by recipe_id or video_id reference"
  def remove_item_by_ref(%Collection{} = collection, %{"recipe_id" => recipe_id}) do
    case Repo.get_by(CollectionItem, collection_id: collection.id, recipe_id: recipe_id) do
      nil -> {:error, :not_found}
      item -> Repo.delete(item)
    end
  end

  def remove_item_by_ref(%Collection{} = collection, %{"video_id" => video_id}) do
    case Repo.get_by(CollectionItem, collection_id: collection.id, video_id: video_id) do
      nil -> {:error, :not_found}
      item -> Repo.delete(item)
    end
  end

  # ── User Interaction (Save / Unsave) ─────────────────────────

  @doc """
  Saves a collection for a user. Idempotent.
  Increments collection.save_count on initial save.
  """
  def save_collection(%User{} = user, collection_id, metadata \\ %{}) do
    with {:ok, collection} <- get_collection(collection_id, viewer: user) do
      case Repo.get_by(UserCollectionInteraction,
             user_id: user.id,
             collection_id: collection.id,
             action: "saved"
           ) do
        nil ->
          %UserCollectionInteraction{}
          |> UserCollectionInteraction.changeset(%{
            user_id: user.id,
            collection_id: collection.id,
            action: "saved",
            metadata: metadata
          })
          |> Repo.insert()
          |> case do
            {:ok, interaction} ->
              from(c in Collection, where: c.id == ^collection.id)
              |> Repo.update_all(inc: [save_count: 1])

              updated = get_collection!(collection.id)

              {:ok,
               %{
                 collection_id: collection.id,
                 action: "saved",
                 status: "saved",
                 is_saved: true,
                 save_count: updated.save_count,
                 saved_at: interaction.inserted_at
               }}

            {:error, changeset} ->
              {:error, changeset}
          end

        existing ->
          {:ok,
           %{
             collection_id: collection.id,
             action: "saved",
             status: "already_saved",
             is_saved: true,
             save_count: collection.save_count,
             saved_at: existing.inserted_at
           }}
      end
    end
  end

  @doc """
  Unsaves a collection for a user.
  Decrements collection.save_count safely.
  """
  def unsave_collection(%User{} = user, collection_id) do
    with {:ok, collection} <- get_collection(collection_id, viewer: user) do
      case Repo.get_by(UserCollectionInteraction,
             user_id: user.id,
             collection_id: collection.id,
             action: "saved"
           ) do
        nil ->
          {:ok,
           %{
             collection_id: collection.id,
             action: "saved",
             status: "not_saved",
             is_saved: false,
             save_count: collection.save_count
           }}

        interaction ->
          case Repo.delete(interaction) do
            {:ok, _} ->
              from(c in Collection, where: c.id == ^collection.id and c.save_count > 0)
              |> Repo.update_all(inc: [save_count: -1])

              updated = get_collection!(collection.id)

              {:ok,
               %{
                 collection_id: collection.id,
                 action: "saved",
                 status: "unsaved",
                 is_saved: false,
                 save_count: updated.save_count
               }}

            error ->
              error
          end
      end
    end
  end

  @doc "Checks if a user has saved a collection"
  def is_saved?(nil, _collection_id), do: false

  def is_saved?(%User{id: user_id}, collection_id) do
    Repo.exists?(
      from i in UserCollectionInteraction,
        where: i.user_id == ^user_id and i.collection_id == ^collection_id and i.action == "saved"
    )
  end

  def is_saved?(%{id: user_id}, collection_id) do
    Repo.exists?(
      from i in UserCollectionInteraction,
        where: i.user_id == ^user_id and i.collection_id == ^collection_id and i.action == "saved"
    )
  end

  @doc "Get user collection interaction status and count"
  def get_user_collection_status(user, collection_id) do
    with {:ok, collection} <- get_collection(collection_id, viewer: user) do
      is_sav = is_saved?(user, collection.id)

      {:ok,
       %{
         collection_id: collection.id,
         is_saved: is_sav,
         save_count: collection.save_count
       }}
    end
  end

  @doc "List collections saved by a user with pagination"
  def list_saved_collections(%User{id: user_id}, opts \\ []) do
    limit = (Keyword.get(opts, :limit) || 20) |> min(100)
    offset = Keyword.get(opts, :offset) || 0

    from(c in base_query(),
      join: i in UserCollectionInteraction,
      on: i.collection_id == c.id,
      where: i.user_id == ^user_id and i.action == "saved",
      order_by: [desc: i.inserted_at],
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
  end

  @doc "Count collections saved by a user"
  def count_saved_collections(%User{id: user_id}, _opts \\ []) do
    Repo.one(
      from i in UserCollectionInteraction,
        where: i.user_id == ^user_id and i.action == "saved",
        select: count(i.id)
    ) || 0
  end

  # ── Access Control Helper ─────────────────────────────────────

  @doc "Checks if a user has management permissions (owner or admin) over a collection"
  def can_manage?(%Collection{user_id: user_id}, %{id: user_id}), do: true
  def can_manage?(_collection, %{role: "admin"}), do: true
  def can_manage?(_collection, _user), do: false

  @doc "Checks if a user has access to view a collection's content"
  def has_access?(%Collection{is_premium: false}, _user), do: true
  def has_access?(%Collection{is_premium: true}, nil), do: false
  def has_access?(%Collection{is_premium: true, user_id: user_id}, %{id: user_id}), do: true

  def has_access?(%Collection{is_premium: true}, %CaramelKitchen.Accounts.User{} = user) do
    CaramelKitchen.Accounts.User.admin?(user) || CaramelKitchen.Accounts.User.premium?(user)
  end

  def has_access?(%Collection{is_premium: true}, %{role: "admin"}), do: true
  def has_access?(%Collection{is_premium: true}, _), do: false

  defp can_view_private?(%Collection{user_id: user_id}, %{id: user_id}), do: true
  defp can_view_private?(_collection, %{role: "admin"}), do: true
  defp can_view_private?(_collection, _), do: false

  # ── Query Helpers ─────────────────────────────────────────────

  defp base_query do
    from c in Collection,
      preload: [
        :user,
        items:
          ^from(i in CollectionItem,
            order_by: [asc: i.position, asc: i.inserted_at],
            preload: [:recipe, :video]
          )
      ]
  end

  defp apply_privacy_filter(query, %{role: "admin"}, _opts), do: query

  defp apply_privacy_filter(query, %{id: user_id}, opts) do
    if Keyword.get(opts, :mine) == true or Keyword.get(opts, :user_id) == user_id do
      # User looking at their own collections: show both public and private
      query
    else
      # Otherwise show public collections OR user's own private collections
      from c in query, where: c.is_public == true or c.user_id == ^user_id
    end
  end

  defp apply_privacy_filter(query, nil, _opts) do
    # Unauthenticated visitor: only public collections
    from c in query, where: c.is_public == true
  end

  defp apply_author_filter(query, opts) do
    cond do
      Keyword.get(opts, :mine) == true and not is_nil(Keyword.get(opts, :viewer)) ->
        viewer_id = opts[:viewer].id
        from c in query, where: c.user_id == ^viewer_id

      author_id = Keyword.get(opts, :user_id) || Keyword.get(opts, :creator_id) ->
        from c in query, where: c.user_id == ^author_id

      true ->
        query
    end
  end

  defp apply_recipe_filter(query, nil), do: query
  defp apply_recipe_filter(query, ""), do: query

  defp apply_recipe_filter(query, recipe_id) do
    from c in query,
      join: i in assoc(c, :items),
      where: i.recipe_id == ^recipe_id,
      distinct: true
  end

  defp apply_video_filter(query, nil), do: query
  defp apply_video_filter(query, ""), do: query

  defp apply_video_filter(query, video_id) do
    from c in query,
      join: i in assoc(c, :items),
      where: i.video_id == ^video_id,
      distinct: true
  end

  defp apply_curated_filter(query, nil), do: query

  defp apply_curated_filter(query, val) when val in [true, "true", "1"],
    do: from(c in query, where: c.is_curated == true)

  defp apply_curated_filter(query, val) when val in [false, "false", "0"],
    do: from(c in query, where: c.is_curated == false)

  defp apply_curated_filter(query, _), do: query

  defp apply_public_filter(query, nil), do: query

  defp apply_public_filter(query, val) when val in [true, "true", "1"],
    do: from(c in query, where: c.is_public == true)

  defp apply_public_filter(query, val) when val in [false, "false", "0"],
    do: from(c in query, where: c.is_public == false)

  defp apply_public_filter(query, _), do: query

  defp apply_premium_filter(query, nil), do: query

  defp apply_premium_filter(query, val) when val in [true, "true", "1"],
    do: from(c in query, where: c.is_premium == true)

  defp apply_premium_filter(query, val) when val in [false, "false", "0"],
    do: from(c in query, where: c.is_premium == false)

  defp apply_premium_filter(query, _), do: query

  defp apply_seasonal_filter(query, viewer, opts) do
    is_seasonal_opt = Keyword.get(opts, :is_seasonal)
    today = Keyword.get(opts, :current_date) || Date.utc_today()

    active_only =
      case Keyword.fetch(opts, :active_seasonal_only) do
        {:ok, bool} -> bool
        :error -> not is_admin_or_owner?(viewer, opts)
      end

    cond do
      is_seasonal_opt in [true, "true", "1"] and active_only ->
        from c in query,
          where:
            c.is_seasonal == true and
              (is_nil(c.start_date) or c.start_date <= ^today) and
              (is_nil(c.end_date) or c.end_date >= ^today)

      is_seasonal_opt in [true, "true", "1"] and not active_only ->
        from c in query, where: c.is_seasonal == true

      is_seasonal_opt in [false, "false", "0"] ->
        from c in query, where: c.is_seasonal == false

      active_only ->
        from c in query,
          where:
            c.is_seasonal == false or
              ((is_nil(c.start_date) or c.start_date <= ^today) and
                 (is_nil(c.end_date) or c.end_date >= ^today))

      true ->
        query
    end
  end

  defp apply_season_name_filter(query, nil), do: query
  defp apply_season_name_filter(query, ""), do: query

  defp apply_season_name_filter(query, season_name) do
    from c in query, where: ilike(c.season_name, ^season_name)
  end

  defp is_admin_or_owner?(%{role: "admin"}, _opts), do: true

  defp is_admin_or_owner?(viewer, opts) do
    Keyword.get(opts, :mine) == true and not is_nil(viewer)
  end

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, search) do
    term = "%#{String.trim(search)}%"
    from c in query, where: ilike(c.name, ^term) or ilike(c.description, ^term)
  end

  defp apply_sorting(query, sort) when sort in ["oldest", :oldest],
    do: order_by(query, [c], asc: c.inserted_at)

  defp apply_sorting(query, sort) when sort in ["name", "alphabetical", :name],
    do: order_by(query, [c], asc: c.name)

  defp apply_sorting(query, _), do: order_by(query, [c], desc: c.inserted_at)

  # ── Batch Item Helpers ────────────────────────────────────────

  defp attach_initial_items(repo, collection, attrs) do
    recipe_ids = Map.get(attrs, "recipe_ids") || Map.get(attrs, :recipe_ids) || []
    video_ids = Map.get(attrs, "video_ids") || Map.get(attrs, :video_ids) || []
    items = Map.get(attrs, "items") || Map.get(attrs, :items) || []

    # 1. Insert explicit recipe_ids
    Enum.with_index(recipe_ids, 1)
    |> Enum.each(fn {recipe_id, idx} ->
      %CollectionItem{}
      |> CollectionItem.changeset(%{
        collection_id: collection.id,
        item_type: "recipe",
        recipe_id: recipe_id,
        position: idx
      })
      |> repo.insert()
    end)

    # 2. Insert explicit video_ids
    start_video_pos = length(recipe_ids) + 1

    Enum.with_index(video_ids, start_video_pos)
    |> Enum.each(fn {video_id, idx} ->
      %CollectionItem{}
      |> CollectionItem.changeset(%{
        collection_id: collection.id,
        item_type: "video",
        video_id: video_id,
        position: idx
      })
      |> repo.insert()
    end)

    # 3. Insert structured items
    start_struct_pos = length(recipe_ids) + length(video_ids) + 1

    Enum.with_index(items, start_struct_pos)
    |> Enum.each(fn {item_attr, idx} ->
      item_map =
        item_attr
        |> Map.put("collection_id", collection.id)
        |> Map.put_new("position", idx)
        |> normalize_item_attrs()

      %CollectionItem{}
      |> CollectionItem.changeset(item_map)
      |> repo.insert()
    end)

    {:ok, collection}
  end

  defp next_item_position(collection_id) do
    case Repo.one(
           from i in CollectionItem,
             where: i.collection_id == ^collection_id,
             select: max(i.position)
         ) do
      nil -> 1
      max_pos -> max_pos + 1
    end
  end

  defp normalize_item_attrs(attrs) when is_map(attrs) do
    cond do
      Map.has_key?(attrs, "recipe_id") or Map.has_key?(attrs, :recipe_id) ->
        Map.put_new(attrs, "item_type", "recipe")

      Map.has_key?(attrs, "video_id") or Map.has_key?(attrs, :video_id) ->
        Map.put_new(attrs, "item_type", "video")

      true ->
        attrs
    end
  end
end
