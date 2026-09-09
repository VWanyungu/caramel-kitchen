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
      |> order_by([r],
        desc:
          fragment(
            "0.6 * (1 - (taste_profile <=> ?::vector)) + 0.4 * engagement_score",
            ^taste_vec
          ),
        desc: r.published_at
      )
      |> select([r], %{
        recipe: r,
        taste_score: fragment("1 - (taste_profile <=> ?::vector)", ^taste_vec),
        combined_score:
          fragment(
            "0.6 * (1 - (taste_profile <=> ?::vector)) + 0.4 * engagement_score",
            ^taste_vec
          )
      })
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
        "(search_vector @@ plainto_tsquery('english', ?) OR title ILIKE ?)",
        ^sanitised,
        ^"%#{sanitised}%"
      )
    )
    |> order_by([r],
      desc:
        fragment(
          "ts_rank(search_vector, plainto_tsquery('english', ?)) + similarity(title, ?)",
          ^sanitised,
          ^sanitised
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

  def list_by_category(category, opts \\ [])

  def list_by_category("all", opts) do
    limit = Keyword.get(opts, :limit, 20)
    filters = Keyword.get(opts, :filters, %{})
    sort = Keyword.get(opts, :sort, Map.get(filters, :sort))

    from(r in Recipe, where: r.status == "live")
    |> apply_filters(filters)
    |> apply_recipe_ordering(sort)
    |> limit(^limit)
    |> Repo.all()
  end

  def list_by_category(category, opts) when is_binary(category) do
    list_by_category([category], opts)
  end

  def list_by_category(categories, opts) when is_list(categories) do
    limit = Keyword.get(opts, :limit, 20)
    filters = Keyword.get(opts, :filters, %{})
    sort = Keyword.get(opts, :sort, Map.get(filters, :sort))

    from(r in Recipe,
      where: r.status == "live" and fragment("? && ?", r.dish_categories, ^categories)
    )
    |> apply_filters(filters)
    |> apply_recipe_ordering(sort)
    |> limit(^limit)
    |> Repo.all()
  end

  def list_by_category(category, opts) when is_nil(category) or category == "" do
    list_by_category("all", opts)
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

  @doc "Checks whether a user has access to view a recipe's full details"
  def has_recipe_access?(%Recipe{} = recipe, user) do
    if recipe.is_special || recipe.is_premium || recipe.access_level == "premium" do
      cond do
        is_nil(user) -> false
        user.id == recipe.creator_id -> true
        CaramelKitchen.Accounts.User.admin?(user) -> true
        CaramelKitchen.Accounts.User.premium?(user) -> true
        true -> false
      end
    else
      true
    end
  end

  def has_recipe_access?(_, _), do: false

  # ── Category counts ───────────────────────────────────────────

  def category_counts do
    fetch_counts = fn ->
      from(r in Recipe,
        where: r.status == "live",
        cross_join: cat in fragment("unnest(?)", r.dish_categories),
        group_by: fragment("?", cat),
        select: {fragment("?", cat), count(r.id)}
      )
      |> Repo.all()
      |> Map.new()
    end

    if Mix.env() == :test do
      fetch_counts.()
    else
      Cache.get_or_store("category_counts", :timer.minutes(10), fetch_counts)
    end
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
    filters = Keyword.get(opts, :filters, %{})

    q = from r in Recipe, where: r.creator_id == ^creator_id

    q
    |> then(fn q -> if status, do: where(q, [r], r.status == ^status), else: q end)
    |> apply_filters(filters)
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

      {:dietary_requirements, flags}, q when is_list(flags) and length(flags) > 0 ->
        where(q, [r], fragment("? @> ?", r.dietary_flags, ^flags))

      {:taste, tags}, q when is_list(tags) and length(tags) > 0 ->
        where(q, [r], fragment("? && ?", r.taste_tags, ^tags))

      {:max_time, minutes}, q when is_integer(minutes) ->
        where(q, [r], r.total_time_mins <= ^minutes)

      {:min_time, minutes}, q when is_integer(minutes) ->
        where(q, [r], r.total_time_mins >= ^minutes)

      {:cooking_time, minutes}, q when is_integer(minutes) ->
        where(q, [r], r.cook_time_mins <= ^minutes)

      {:max_cooking_time, minutes}, q when is_integer(minutes) ->
        where(q, [r], r.cook_time_mins <= ^minutes)

      {:min_cooking_time, minutes}, q when is_integer(minutes) ->
        where(q, [r], r.cook_time_mins >= ^minutes)

      {:cost, max_cost}, q when not is_nil(max_cost) ->
        where(q, [r], r.cost <= ^max_cost)

      {:max_cost, max_cost}, q when not is_nil(max_cost) ->
        where(q, [r], r.cost <= ^max_cost)

      {:min_cost, min_cost}, q when not is_nil(min_cost) ->
        where(q, [r], r.cost >= ^min_cost)

      {:budget, max_cost}, q when not is_nil(max_cost) ->
        where(q, [r], r.cost <= ^max_cost)

      {:servings, n}, q when is_integer(n) ->
        where(q, [r], r.serving_size == ^n)

      {:serving_size, n}, q when is_integer(n) ->
        where(q, [r], r.serving_size == ^n)

      {:min_servings, n}, q when is_integer(n) ->
        where(q, [r], r.serving_size >= ^n)

      {:max_servings, n}, q when is_integer(n) ->
        where(q, [r], r.serving_size <= ^n)

      {:ingredient, ing}, q when is_binary(ing) and ing != "" ->
        pattern = "%#{ing}%"

        where(
          q,
          [r],
          fragment(
            "EXISTS (SELECT 1 FROM unnest(?) AS elem WHERE elem->>'name' ILIKE ?)",
            r.ingredients,
            ^pattern
          )
        )

      {:ingredients, ings}, q when is_list(ings) and length(ings) > 0 ->
        Enum.reduce(ings, q, fn ing, sub_q ->
          pattern = "%#{ing}%"

          where(
            sub_q,
            [r],
            fragment(
              "EXISTS (SELECT 1 FROM unnest(?) AS elem WHERE elem->>'name' ILIKE ?)",
              r.ingredients,
              ^pattern
            )
          )
        end)

      {:exclude_ingredients, ings}, q when is_list(ings) and length(ings) > 0 ->
        Enum.reduce(ings, q, fn ing, sub_q ->
          pattern = "%#{ing}%"

          where(
            sub_q,
            [r],
            not fragment(
              "EXISTS (SELECT 1 FROM unnest(?) AS elem WHERE elem->>'name' ILIKE ?)",
              r.ingredients,
              ^pattern
            )
          )
        end)

      {:difficulty, level}, q when is_binary(level) ->
        where(q, [r], r.difficulty == ^level)

      {:cuisine, origins}, q when is_list(origins) and length(origins) > 0 ->
        where(q, [r], fragment("? && ?", r.cuisine_origin, ^origins))

      {:cuisine, origin}, q when is_binary(origin) and origin != "" ->
        where(q, [r], fragment("? && ?", r.cuisine_origin, ^[origin]))

      {:course, course}, q when is_binary(course) ->
        where(q, [r], r.course == ^course)

      {:meal, meal}, q when is_binary(meal) ->
        where(q, [r], r.meal == ^meal)

      {:category, cat}, q when is_binary(cat) ->
        if cat == "all" do
          q
        else
          where(q, [r], fragment("? && ?", r.dish_categories, ^[cat]))
        end

      {:category, cats}, q when is_list(cats) and length(cats) > 0 ->
        where(q, [r], fragment("? && ?", r.dish_categories, ^cats))

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

      {:access_level, level}, q when is_binary(level) ->
        where(q, [r], r.access_level == ^level)

      {:is_special, val}, q when val in [true, "true"] ->
        where(q, [r], r.is_special == true or r.is_premium == true or r.access_level == "premium")

      {:is_special, val}, q when val in [false, "false"] ->
        where(
          q,
          [r],
          r.is_special == false and r.is_premium == false and r.access_level == "free"
        )

      {:is_premium, val}, q when val in [true, "true"] ->
        where(q, [r], r.is_premium == true or r.is_special == true or r.access_level == "premium")

      {:is_premium, val}, q when val in [false, "false"] ->
        where(
          q,
          [r],
          r.is_premium == false and r.is_special == false and r.access_level == "free"
        )

      {:created_after, dt}, q when not is_nil(dt) ->
        where(q, [r], r.inserted_at >= ^dt)

      {:created_before, dt}, q when not is_nil(dt) ->
        where(q, [r], r.inserted_at <= ^dt)

      {:created_from, dt}, q when not is_nil(dt) ->
        where(q, [r], r.inserted_at >= ^dt)

      {:created_to, dt}, q when not is_nil(dt) ->
        where(q, [r], r.inserted_at <= ^dt)

      {:creation_date, {start_dt, end_dt}}, q when not is_nil(start_dt) and not is_nil(end_dt) ->
        where(q, [r], r.inserted_at >= ^start_dt and r.inserted_at <= ^end_dt)

      {:creation_date, dt}, q when not is_nil(dt) ->
        where(q, [r], r.inserted_at >= ^dt)

      _, q ->
        q
    end)
  end

  defp apply_filters(query, _), do: query

  defp apply_recipe_ordering(query, sort)
       when sort in [:newest, "newest", :created_at_desc, "created_at_desc"] do
    order_by(query, [r], desc: r.inserted_at)
  end

  defp apply_recipe_ordering(query, sort)
       when sort in [:oldest, "oldest", :created_at_asc, "created_at_asc"] do
    order_by(query, [r], asc: r.inserted_at)
  end

  defp apply_recipe_ordering(query, _) do
    order_by(query, [r], desc: r.engagement_score)
  end

  defp apply_dietary_filter(query, []), do: query

  defp apply_dietary_filter(query, flags) do
    # Exclude recipes that conflict with user's dietary preferences
    where(query, [r], fragment("? && ?", r.dietary_flags, ^flags))
  end

  defp apply_after_cursor(query, nil), do: query

  defp apply_after_cursor(query, after_id) do
    where(query, [r], r.id < ^after_id)
  end

  defp format_vector(list) when is_list(list), do: Pgvector.new(list)
  defp format_vector(%Pgvector{} = vec), do: vec

  defp sanitise_search_query(q) do
    q
    |> String.trim()
    |> String.replace(Regex.compile!("[^\\w\\s-]"), "")
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
