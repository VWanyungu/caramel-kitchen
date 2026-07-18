defmodule CaramelKitchenWeb.RecipeController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.Recipes

  # GET /api/v1/recipes
  def index(conn, params) do
    filters = parse_filters(params)
    limit = parse_int(params["limit"], 20) |> min(50)
    after_id = params["after_id"]

    user = conn.assigns[:current_user]

    recipes =
      if user do
        Recipes.personalised_feed(user,
          limit: limit,
          after_id: after_id,
          filters: filters
        )
        |> Enum.map(fn %{recipe: r, taste_score: ts, combined_score: cs} ->
          render_recipe_card(r, %{taste_score: ts, combined_score: cs})
        end)
      else
        Recipes.list_by_category(filters[:category] || "all",
          limit: limit,
          filters: filters
        )
        |> Enum.map(&render_recipe_card(&1, %{}))
      end

    json(conn, %{data: recipes, meta: %{count: length(recipes), after_id: after_id}})
  end

  # GET /api/v1/recipes/trending
  def trending(conn, params) do
    limit = parse_int(params["limit"], 10) |> min(30)
    recipes = Recipes.trending(limit: limit)
    json(conn, %{data: Enum.map(recipes, &render_recipe_card(&1, %{}))})
  end

  # GET /api/v1/recipes/search?q=...
  def search(conn, %{"q" => q} = params) do
    filters = parse_filters(params)
    limit = parse_int(params["limit"], 20)
    offset = parse_int(params["offset"], 0)

    results = Recipes.search(q, filters: filters, limit: limit, offset: offset)

    json(conn, %{
      data:
        Enum.map(results, fn %{recipe: r, rank: rank} ->
          render_recipe_card(r, %{search_rank: rank})
        end),
      meta: %{query: q, limit: limit, offset: offset}
    })
  end

  def search(conn, _), do: json(conn, %{data: [], meta: %{query: ""}})

  # GET /api/v1/recipes/:id
  def show(conn, %{"id" => id}) do
    with {:ok, recipe} <- Recipes.get_recipe(id) do
      user = conn.assigns[:current_user]
      if user, do: Recipes.track_view(id, user.id)
      json(conn, %{data: render_recipe_detail(recipe, user)})
    end
  end

  # GET /api/v1/recipes/slug/:slug
  def show_by_slug(conn, %{"slug" => slug}) do
    with {:ok, recipe} <- Recipes.get_recipe_by_slug(slug) do
      user = conn.assigns[:current_user]
      json(conn, %{data: render_recipe_detail(recipe, user)})
    end
  end

  # GET /api/v1/categories
  def categories(conn, _params) do
    counts = Recipes.category_counts()
    json(conn, %{data: counts})
  end

  # ── Rendering ─────────────────────────────────────────────────

  defp render_recipe_card(recipe, meta) do
    %{
      id: recipe.id,
      slug: recipe.slug,
      title: recipe.title,
      thumbnail_url: recipe.thumbnail_url,
      dish_category: recipe.dish_category,
      course: recipe.course,
      primary_method: recipe.primary_method,
      difficulty: recipe.difficulty,
      total_time_mins: recipe.total_time_mins,
      taste_tags: recipe.taste_tags,
      dietary_flags: recipe.dietary_flags,
      calories: recipe.calories,
      avg_rating: recipe.avg_rating,
      rating_count: recipe.rating_count,
      cuisine_origin: recipe.cuisine_origin,
      taste_score: meta[:taste_score],
      search_rank: meta[:search_rank]
    }
  end

  defp render_recipe_detail(recipe, user) do
    base = render_recipe_card(recipe, %{})

    Map.merge(base, %{
      description: recipe.description,
      ingredients: recipe.ingredients,
      steps: recipe.steps,
      serving_size: recipe.serving_size,
      prep_time_mins: recipe.prep_time_mins,
      cook_time_mins: recipe.cook_time_mins,
      video_url: recipe.video_url,
      video_duration_secs: recipe.video_duration_secs,
      secondary_method: recipe.secondary_method,
      allergens: recipe.allergens,
      macros: recipe.macros,
      save_count: recipe.save_count,
      cook_count: recipe.cook_count,
      view_count: recipe.view_count,
      featured_until: recipe.featured_until,
      published_at: recipe.published_at,
      allergy_alerts: compute_allergy_alerts(recipe, user),
      creator_id: recipe.creator_id
    })
  end

  defp compute_allergy_alerts(_recipe, nil), do: []

  defp compute_allergy_alerts(recipe, user) do
    user_allergens = user.allergy_flags || []
    Enum.filter(recipe.allergens, &(&1 in user_allergens))
  end

  defp parse_filters(params) do
    %{}
    |> maybe_add(:cooking_method, params["cooking_method"])
    |> maybe_add(:dietary, parse_list(params["dietary"]))
    |> maybe_add(:taste, parse_list(params["taste"]))
    |> maybe_add(:max_time, parse_int(params["max_time"]))
    |> maybe_add(:min_time, parse_int(params["min_time"]))
    |> maybe_add(:difficulty, params["difficulty"])
    |> maybe_add(:cuisine, parse_list(params["cuisine"]))
    |> maybe_add(:course, params["course"])
    |> maybe_add(:category, params["category"])
    |> maybe_add(:max_calories, parse_int(params["max_calories"]))
    |> maybe_add(:serving_context, params["context"])
  end

  defp maybe_add(map, _key, nil), do: map
  defp maybe_add(map, _key, []), do: map
  defp maybe_add(map, key, val), do: Map.put(map, key, val)

  defp parse_list(nil), do: []
  defp parse_list(str) when is_binary(str), do: String.split(str, ",", trim: true)
  defp parse_list(list) when is_list(list), do: list

  defp parse_int(val, default \\ nil)
  defp parse_int(nil, default), do: default

  defp parse_int(str, default) when is_binary(str) do
    case Integer.parse(str) do
      {val, _} -> val
      :error -> default
    end
  end

  defp parse_int(val, _) when is_integer(val), do: val
  defp parse_int(_, default), do: default
end

# ── Feed Controller ────────────────────────────────────────────

defmodule CaramelKitchenWeb.FeedController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.Recipes

  # GET /api/v1/feed
  def personalised(conn, params) do
    user = conn.assigns.current_user
    limit = min(String.to_integer(params["limit"] || "20"), 50)
    after_id = params["after_id"]

    results = Recipes.personalised_feed(user, limit: limit, after_id: after_id)
    trending = Recipes.trending(limit: 5)

    json(conn, %{
      data: %{
        for_you:
          Enum.map(results, fn %{recipe: r, taste_score: ts} ->
            %{
              id: r.id,
              title: r.title,
              thumbnail_url: r.thumbnail_url,
              taste_score: ts,
              taste_tags: r.taste_tags,
              total_time_mins: r.total_time_mins,
              calories: r.calories,
              dietary_flags: r.dietary_flags
            }
          end),
        trending:
          Enum.map(trending, fn r ->
            %{
              id: r.id,
              title: r.title,
              thumbnail_url: r.thumbnail_url,
              engagement_score: r.engagement_score
            }
          end)
      }
    })
  end

  def for_you(conn, params), do: personalised(conn, params)
end

# ── Taste Controller ───────────────────────────────────────────

defmodule CaramelKitchenWeb.TasteController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.Accounts
  alias CaramelKitchen.Accounts.User

  # POST /api/v1/taste/survey
  def submit_survey(conn, %{"responses" => responses}) do
    user = conn.assigns.current_user

    with {:ok, updated_user} <- Accounts.submit_taste_survey(user, responses) do
      json(conn, %{
        data: %{
          taste_vector: User.taste_vector_list(updated_user),
          survey_complete: true,
          dimensions: User.taste_dimensions()
        }
      })
    end
  end

  # GET /api/v1/taste/vector
  def get_vector(conn, _params) do
    user = conn.assigns.current_user

    json(conn, %{
      data: %{
        taste_vector: User.taste_vector_list(user),
        survey_complete: user.taste_survey_done,
        dimensions: User.taste_dimensions(),
        updated_at: user.taste_updated_at
      }
    })
  end
end
