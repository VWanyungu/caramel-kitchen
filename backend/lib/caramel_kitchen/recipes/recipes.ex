defmodule CaramelKitchen.Recipes do
  @moduledoc """
  Recipes context — CRUD, multi-dimensional filtering,
  full-text search, and engagement tracking.
  """

  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Recipes.Recipe
  alias CaramelKitchen.Cache
  alias CaramelKitchen.Workers.{PublishRecipeWorker, EngagementWorker}

  require Logger

  # ── Public API ────────────────────────────────────────────────

  @doc """
  Personalised feed: cosine similarity ranked, with trending boost.
  taste_vector: list of 8 floats from user profile.
  """
  def personalised_feed(user, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    after_id = Keyword.get(opts, :after_id)
    filters = Keyword.get(opts, :filters, %{})

    cache_key = "feed:#{user.id}:#{:erlang.phash2(filters)}"

    Cache.get_or_store(cache_key, :timer.minutes(5), fn ->
      taste_vec = user |> CaramelKitchen.Accounts.User.taste_vector_list() |> format_vector()

      base_query =
        from r in Recipe,
          where: r.status == "live",
          where: is_nil(r.featured_until) or r.featured_until > ^DateTime.utc_now()

      base_query
      |> apply_filters(filters)
      |> apply_dietary_filter(user.dietary_flags)
      |> apply_after_cursor(after_id)
      |> select([r], %{
        recipe: r,
        taste_score: fragment("1 - (taste_profile <=> ?::vector)", ^taste_vec),
        combined_score:
          fragment(
            "0.6 * (1 - (taste_profile <=> ?::vector)) + 0.4 * engagement_score",
            ^taste_vec
          )
      })
      |> order_by([r, ...],
        desc: fragment("combined_score"),
        desc: r.published_at
      )
      |> limit(^limit)
      |> Repo.all()
    end)
  end

  @doc """
  Full-text + trigram search with multi-dimensional filtering.
  """
  def search(query_string, opts \\ []) do
    filters = Keyword.get(opts, :filters, %{})
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    sanitised = sanitise_search_query(query_string)

    from(r in Recipe, where: r.status == "live")
    |> apply_filters(filters)
    |> where(
      [r],
      fragment(
        "search_vector @@ plainto_tsquery('english', ?) OR title ILIKE ?",
        ^sanitised,
        ^"%#{sanitised}%"
      )
    )
    |> select([r], %{
      recipe: r,
      rank:
        fragment(
          "ts_rank(search_vector, plainto_tsquery('english', ?)) + similarity(title, ?)",
          ^sanitised,
          ^sanitised
        )
    })
    |> order_by([r, ...], desc: fragment("rank"))
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc "Filter count — returns total matching recipes for a given filter set."
  def filter_count(filters) do
    from(r in Recipe, where: r.status == "live")
    |> apply_filters(filters)
    |> Repo.aggregate(:count, :id)
  end

  @doc "Trending recipes — last 7 days by engagement."
  def trending(opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    since = DateTime.add(DateTime.utc_now(), -7 * 86_400, :second)

    Cache.get_or_store("trending:global", :timer.hours(1), fn ->
      from(r in Recipe,
        where: r.status == "live" and r.published_at >= ^since,
        order_by: [desc: r.engagement_score],
        limit: ^limit
      )
      |> Repo.all()
    end)
  end

  def list_by_category(category, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    filters = Keyword.get(opts, :filters, %{})

    from(r in Recipe,
      where: r.status == "live" and r.dish_category == ^category
    )
    |> apply_filters(filters)
    |> order_by([r], desc: r.engagement_score)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_recipe!(id), do: Repo.get!(Recipe, id)

  def get_recipe(id) do
    case Repo.get(Recipe, id) do
      nil -> {:error, :not_found}
      recipe -> {:ok, recipe}
    end
  end

  def get_recipe_by_slug(slug) do
    Repo.fetch(from r in Recipe, where: r.slug == ^slug and r.status == "live")
  end

  # ── Category counts ───────────────────────────────────────────

  def category_counts do
    Cache.get_or_store("category_counts", :timer.minutes(10), fn ->
      from(r in Recipe,
        where: r.status == "live" and not is_nil(r.dish_category),
        group_by: r.dish_category,
        select: {r.dish_category, count(r.id)}
      )
      |> Repo.all()
      |> Map.new()
    end)
  end

  def dish_type_counts do
    Cache.get_or_store("dish_type_counts", :timer.minutes(10), fn ->
      from(r in Recipe,
        where: r.status == "live" and not is_nil(r.course),
        group_by: r.course,
        select: {r.course, count(r.id)}
      )
      |> Repo.all()
      |> Map.new()
    end)
  end

  # ── CMS / Admin ───────────────────────────────────────────────

  def create_recipe(creator, attrs) do
    %Recipe{creator_id: creator.id}
    |> Recipe.creation_changeset(attrs)
    |> Repo.insert()
    |> tap_ok(fn recipe ->
      if recipe.status == "scheduled" and recipe.scheduled_at do
        PublishRecipeWorker.new(%{recipe_id: recipe.id},
          scheduled_at: recipe.scheduled_at
        )
        |> Oban.insert()
      end

      Cache.invalidate_category_counts()
      Cache.invalidate_dish_type_counts()
    end)
  end

  def update_recipe(%Recipe{} = recipe, attrs) do
    recipe
    |> Recipe.update_changeset(attrs)
    |> Repo.update()
    |> tap_ok(fn r ->
      Cache.invalidate_recipe(r.id)
      Cache.invalidate_category_counts()
      Cache.invalidate_dish_type_counts()
    end)
  end

  def publish_recipe(%Recipe{} = recipe) do
    recipe
    |> Recipe.publish_changeset()
    |> Repo.update()
    |> tap_ok(fn r ->
      Cache.invalidate_recipe(r.id)
      Cache.invalidate_category_counts()
      Cache.invalidate_dish_type_counts()
      Phoenix.PubSub.broadcast(CaramelKitchen.PubSub, "feed:updates", {:new_recipe, r})
    end)
  end

  def set_video(%Recipe{} = recipe, video_attrs) do
    recipe
    |> Recipe.video_changeset(video_attrs)
    |> Repo.update()
    |> tap_ok(&Cache.invalidate_recipe(&1.id))
  end

  def list_creator_recipes(creator_id, opts \\ []) do
    status = Keyword.get(opts, :status)
    limit = Keyword.get(opts, :limit, 50)

    q = from r in Recipe, where: r.creator_id == ^creator_id

    q
    |> then(fn q -> if status, do: where(q, [r], r.status == ^status), else: q end)
    |> order_by([r], desc: r.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  # ── Engagement ────────────────────────────────────────────────

  def track_view(recipe_id, user_id) do
    EngagementWorker.new(%{recipe_id: recipe_id, user_id: user_id, action: "view"})
    |> Oban.insert()
  end

  def increment_engagement(recipe_id, field) when field in ~w(view_count save_count cook_count) do
    from(r in Recipe, where: r.id == ^recipe_id)
    |> Repo.update_all(inc: [{String.to_existing_atom(field), 1}])
  end

  # ── Filters ───────────────────────────────────────────────────

  defp apply_filters(query, filters) when is_map(filters) do
    Enum.reduce(filters, query, fn
      {:cooking_method, method}, q when is_binary(method) ->
        where(q, [r], r.primary_method == ^method or r.secondary_method == ^method)

      {:dietary, flags}, q when is_list(flags) and length(flags) > 0 ->
        where(q, [r], fragment("? @> ?", r.dietary_flags, ^flags))

      {:taste, tags}, q when is_list(tags) and length(tags) > 0 ->
        where(q, [r], fragment("? && ?", r.taste_tags, ^tags))

      {:max_time, minutes}, q when is_integer(minutes) ->
        where(q, [r], r.total_time_mins <= ^minutes)

      {:min_time, minutes}, q when is_integer(minutes) ->
        where(q, [r], r.total_time_mins >= ^minutes)

      {:difficulty, level}, q when is_binary(level) ->
        where(q, [r], r.difficulty == ^level)

      {:cuisine, origins}, q when is_list(origins) and length(origins) > 0 ->
        where(q, [r], fragment("? && ?", r.cuisine_origin, ^origins))

      {:course, course}, q when is_binary(course) ->
        where(q, [r], r.course == ^course)

      {:category, cat}, q when is_binary(cat) ->
        where(q, [r], r.dish_category == ^cat)

      {:serving_context, ctx}, q when is_binary(ctx) ->
        case ctx do
          "quick" -> where(q, [r], r.total_time_mins <= 30)
          "family" -> where(q, [r], r.serving_size >= 4)
          "meal_prep" -> where(q, [r], r.serving_size >= 4 and r.total_time_mins <= 60)
          "healthy" -> where(q, [r], r.calories <= 500)
          _ -> q
        end

      {:exclude_allergens, allergens}, q when is_list(allergens) ->
        where(q, [r], not fragment("? && ?", r.allergens, ^allergens))

      {:max_calories, cal}, q when is_integer(cal) ->
        where(q, [r], r.calories <= ^cal)

      _, q ->
        q
    end)
  end

  defp apply_filters(query, _), do: query

  defp apply_dietary_filter(query, []), do: query

  defp apply_dietary_filter(query, flags) do
    # Exclude recipes that conflict with user's dietary preferences
    where(query, [r], fragment("? && ?", r.dietary_flags, ^flags))
  end

  defp apply_after_cursor(query, nil), do: query

  defp apply_after_cursor(query, after_id) do
    where(query, [r], r.id < ^after_id)
  end

  defp format_vector(list), do: "[#{Enum.join(list, ",")}]"

  defp sanitise_search_query(q) do
    q
    |> String.trim()
    |> String.replace(Regex.compile!("[^\\\\w\\\\s-]"), "")
    |> String.slice(0, 200)
  end

  defp tap_ok({:ok, val} = result, fun),
    do:
      (
        fun.(val)
        result
      )

  defp tap_ok(result, _fun), do: result
end
