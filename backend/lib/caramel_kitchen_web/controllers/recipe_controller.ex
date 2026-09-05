defmodule CaramelKitchenWeb.RecipeController do
  use CaramelKitchenWeb, :controller
  use OpenApiSpex.ControllerSpecs
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.Recipes

  tags(["Recipes"])

  operation(:index,
    summary: "List recipes",
    description:
      "Returns a list of recipes. If authenticated, returns a personalised feed based on taste vectors.",
    parameters: [
      limit: [in: :query, type: :integer, description: "Max number of items", example: 20],
      after_id: [in: :query, type: :string, description: "Pagination cursor", required: false],
      category: [in: :query, type: :string, description: "Filter by category", required: false]
    ],
    responses: %{
      200 =>
        {"Success", "application/json",
         %OpenApiSpex.Schema{
           type: :object,
           properties: %{
             data: %OpenApiSpex.Schema{type: :array, items: CaramelKitchenWeb.Schemas.RecipeCard},
             meta: %OpenApiSpex.Schema{type: :object}
           }
         }}
    }
  )

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
          render_recipe_card(r, %{taste_score: ts, combined_score: cs, current_user: user})
        end)
      else
        Recipes.list_by_category(filters[:category] || "all",
          limit: limit,
          filters: filters
        )
        |> Enum.map(&render_recipe_card(&1, %{current_user: nil}))
      end

    json(conn, %{data: recipes, meta: %{count: length(recipes), after_id: after_id}})
  end

  # GET /api/v1/recipes/trending
  operation(:trending,
    summary: "Get trending recipes",
    description: "Returns a list of trending recipes.",
    parameters: [
      limit: [in: :query, type: :integer, description: "Max number of items", example: 10]
    ],
    responses: %{
      200 =>
        {"Success", "application/json",
         %OpenApiSpex.Schema{
           type: :object,
           properties: %{
             data: %OpenApiSpex.Schema{type: :array, items: CaramelKitchenWeb.Schemas.RecipeCard}
           }
         }}
    }
  )

  def trending(conn, params) do
    limit = parse_int(params["limit"], 10) |> min(30)
    user = conn.assigns[:current_user]
    recipes = Recipes.trending(limit: limit)
    json(conn, %{data: Enum.map(recipes, &render_recipe_card(&1, %{current_user: user}))})
  end

  # GET /api/v1/recipes/search?q=...
  operation(:search,
    summary: "Search recipes",
    description: "Search for recipes by query and filters.",
    parameters: [
      q: [in: :query, type: :string, description: "Search query", required: true],
      limit: [in: :query, type: :integer, description: "Max number of items", example: 20],
      offset: [in: :query, type: :integer, description: "Pagination offset", example: 0]
    ],
    responses: %{
      200 =>
        {"Success", "application/json",
         %OpenApiSpex.Schema{
           type: :object,
           properties: %{
             data: %OpenApiSpex.Schema{type: :array, items: CaramelKitchenWeb.Schemas.RecipeCard},
             meta: %OpenApiSpex.Schema{type: :object}
           }
         }}
    }
  )

  def search(conn, params) do
    q = params["q"] || ""
    filters = parse_filters(params)
    limit = parse_int(params["limit"], 20)
    offset = parse_int(params["offset"], 0)
    user = conn.assigns[:current_user]

    results = Recipes.search(q, filters: filters, limit: limit, offset: offset)

    json(conn, %{
      data:
        Enum.map(results, fn %{recipe: r, rank: rank} ->
          render_recipe_card(r, %{search_rank: rank, current_user: user})
        end),
      meta: %{query: q, limit: limit, offset: offset}
    })
  end

  operation(:show,
    summary: "Get a recipe",
    description: "Returns full details for a single recipe.",
    parameters: [
      id: [in: :path, type: :string, description: "Recipe UUID", required: true]
    ],
    responses: %{
      200 =>
        {"Success", "application/json",
         %OpenApiSpex.Schema{
           type: :object,
           properties: %{data: CaramelKitchenWeb.Schemas.RecipeDetail}
         }},
      404 => "NotFound"
    }
  )

  # GET /api/v1/recipes/:id
  def show(conn, %{"id" => id}) do
    user = conn.assigns[:current_user]

    with {:ok, recipe} <- Recipes.get_recipe(id) do
      if (recipe.is_special || false) && not Recipes.has_recipe_access?(recipe, user) do
        conn
        |> put_status(:payment_required)
        |> json(%{
          error: "premium_required",
          message: "This special recipe requires a Premium subscription",
          upgrade_url: "/subscription/checkout"
        })
      else
        if user, do: Recipes.track_view(id, user.id)
        json(conn, %{data: render_recipe_detail(recipe, user)})
      end
    end
  end

  operation(:show_by_slug,
    summary: "Get a recipe by slug",
    description: "Returns full details for a single recipe using its URL slug.",
    parameters: [
      slug: [in: :path, type: :string, description: "Recipe Slug", required: true]
    ],
    responses: %{
      200 =>
        {"Success", "application/json",
         %OpenApiSpex.Schema{
           type: :object,
           properties: %{data: CaramelKitchenWeb.Schemas.RecipeDetail}
         }},
      404 => "NotFound"
    }
  )

  # GET /api/v1/recipes/slug/:slug
  def show_by_slug(conn, %{"slug" => slug}) do
    user = conn.assigns[:current_user]

    with {:ok, recipe} <- Recipes.get_recipe_by_slug(slug) do
      if (recipe.is_special || false) && not Recipes.has_recipe_access?(recipe, user) do
        conn
        |> put_status(:payment_required)
        |> json(%{
          error: "premium_required",
          message: "This special recipe requires a Premium subscription",
          upgrade_url: "/subscription/checkout"
        })
      else
        json(conn, %{data: render_recipe_detail(recipe, user)})
      end
    end
  end

  operation(:categories,
    summary: "Get recipe categories",
    description: "Returns an aggregation of recipe categories and their counts.",
    responses: %{
      200 =>
        {"Success", "application/json",
         %OpenApiSpex.Schema{
           type: :object,
           properties: %{
             data: %OpenApiSpex.Schema{type: :object}
           }
         }}
    }
  )

  # GET /api/v1/categories
  def categories(conn, _params) do
    counts = Recipes.category_counts()
    json(conn, %{data: counts})
  end

  operation(:dish_types,
    summary: "Get recipe dish types",
    description: "Returns an aggregation of recipe dish types (courses) and their counts.",
    responses: %{
      200 =>
        {"Success", "application/json",
         %OpenApiSpex.Schema{
           type: :object,
           properties: %{
             data: %OpenApiSpex.Schema{type: :object}
           }
         }}
    }
  )

  # GET /api/v1/dish-types
  def dish_types(conn, _params) do
    counts = Recipes.dish_type_counts()
    json(conn, %{data: counts})
  end

  # ── Rendering ─────────────────────────────────────────────────

  defp render_recipe_card(recipe, meta) do
    categories = recipe.dish_categories || []
    user = meta[:current_user]
    is_special = Map.get(recipe, :is_special, false) || false
    is_locked = is_special and not Recipes.has_recipe_access?(recipe, user)

    %{
      id: recipe.id,
      slug: recipe.slug,
      title: recipe.title,
      thumbnail_url: recipe.thumbnail_url,
      dish_category: recipe.dish_category || List.first(categories),
      dish_categories: categories,
      categories: categories,
      course: recipe.course,
      meal: recipe.meal,
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
      search_rank: meta[:search_rank],
      is_special: is_special,
      is_premium: is_special,
      is_locked: is_locked,
      created_at: recipe.inserted_at
    }
  end

  defp render_recipe_detail(recipe, user) do
    base = render_recipe_card(recipe, %{current_user: user})
    yt = CaramelKitchen.Recipes.Recipe.parse_youtube_video(recipe.video_url || "")

    Map.merge(base, %{
      description: recipe.description,
      ingredients: recipe.ingredients,
      steps: recipe.steps,
      serving_size: recipe.serving_size,
      prep_time_mins: recipe.prep_time_mins,
      cook_time_mins: recipe.cook_time_mins,
      video_url: recipe.video_url || yt.video_url,
      video_embed_url: yt.video_embed_url,
      video_iframe_html: yt.iframe_html,
      youtube_video_id: yt.youtube_id,
      video_duration_secs: recipe.video_duration_secs,
      secondary_method: recipe.secondary_method,
      allergens: recipe.allergens,
      macros: recipe.macros,
      save_count: recipe.save_count,
      cook_count: recipe.cook_count,
      view_count: recipe.view_count,
      featured_until: recipe.featured_until,
      published_at: recipe.published_at,
      created_at: recipe.inserted_at,
      allergy_alerts: compute_allergy_alerts(recipe, user),
      creator_id: recipe.creator_id
    })
  end

  defp compute_allergy_alerts(_recipe, nil), do: []

  defp compute_allergy_alerts(recipe, user) do
    user_allergens = user.allergy_flags || []

    # 1. Exact match against explicitly defined recipe allergens
    explicit_alerts = Enum.filter(recipe.allergens, &(&1 in user_allergens))

    # 2. Case-insensitive substring match against actual ingredients
    ingredient_alerts =
      Enum.reduce(user_allergens, [], fn allergy, acc ->
        allergy_down = String.downcase(allergy)

        found? =
          Enum.any?(recipe.ingredients, fn
            %{"name" => name} when is_binary(name) ->
              String.contains?(String.downcase(name), allergy_down)

            _ ->
              false
          end)

        if found?, do: [allergy | acc], else: acc
      end)

    Enum.uniq(explicit_alerts ++ ingredient_alerts)
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
    |> maybe_add(:meal, params["meal"])
    |> maybe_add(:category, params["category"])
    |> maybe_add(:max_calories, parse_int(params["max_calories"]))
    |> maybe_add(:serving_context, params["context"])
    |> maybe_add(:exclude_allergens, parse_list(params["exclude_allergens"]))
    |> maybe_add(:is_special, parse_boolean(params["is_special"] || params["is_premium"]))
    |> maybe_add(
      :created_after,
      parse_datetime_boundary(
        params["created_after"] || params["created_from"] || params["from_date"] ||
          params["start_date"],
        :start_of_day
      )
    )
    |> maybe_add(
      :created_before,
      parse_datetime_boundary(
        params["created_before"] || params["created_to"] || params["to_date"] ||
          params["end_date"],
        :end_of_day
      )
    )
    |> maybe_add(
      :creation_date,
      parse_exact_date_filter(
        params["creation_date"] || params["created_at"] || params["created_date"] ||
          params["date"]
      )
    )
    |> maybe_apply_preset_filter(params["created_within"] || params["date_range"])
    |> maybe_add(:sort, params["sort"])
  end

  defp maybe_add(map, _key, nil), do: map
  defp maybe_add(map, _key, []), do: map
  defp maybe_add(map, key, val), do: Map.put(map, key, val)

  defp parse_list(nil), do: []
  defp parse_list(str) when is_binary(str), do: String.split(str, ",", trim: true)
  defp parse_list(list) when is_list(list), do: list

  defp parse_boolean(nil), do: nil
  defp parse_boolean(val) when val in [true, "true", "1"], do: true
  defp parse_boolean(val) when val in [false, "false", "0"], do: false
  defp parse_boolean(_), do: nil

  defp parse_int(val, default \\ nil)
  defp parse_int(nil, default), do: default

  defp parse_int(str, default) when is_binary(str) do
    case Integer.parse(str) do
      {val, _} -> val
      :error -> default
    end
  end

  defp parse_int(val, _default) when is_integer(val), do: val
  defp parse_int(_, default), do: default

  defp parse_datetime_boundary(nil, _), do: nil
  defp parse_datetime_boundary("", _), do: nil
  defp parse_datetime_boundary(%DateTime{} = dt, _), do: dt

  defp parse_datetime_boundary(str, boundary) when is_binary(str) do
    str = String.trim(str)

    case DateTime.from_iso8601(str) do
      {:ok, dt, _offset} ->
        dt

      {:error, _} ->
        case Date.from_iso8601(str) do
          {:ok, date} ->
            time = if boundary == :end_of_day, do: ~T[23:59:59], else: ~T[00:00:00]
            DateTime.new!(date, time, "Etc/UTC")

          {:error, _} ->
            case Integer.parse(str) do
              {epoch, ""} ->
                case DateTime.from_unix(epoch) do
                  {:ok, dt} -> dt
                  _ -> nil
                end

              _ ->
                nil
            end
        end
    end
  end

  defp parse_datetime_boundary(_, _), do: nil

  defp parse_exact_date_filter(nil), do: nil
  defp parse_exact_date_filter(""), do: nil

  defp parse_exact_date_filter(str) when is_binary(str) do
    str = String.trim(str)

    case Date.from_iso8601(str) do
      {:ok, date} ->
        start_dt = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
        end_dt = DateTime.new!(date, ~T[23:59:59], "Etc/UTC")
        {start_dt, end_dt}

      {:error, _} ->
        case DateTime.from_iso8601(str) do
          {:ok, dt, _offset} ->
            date = DateTime.to_date(dt)
            start_dt = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
            end_dt = DateTime.new!(date, ~T[23:59:59], "Etc/UTC")
            {start_dt, end_dt}

          _ ->
            nil
        end
    end
  end

  defp parse_exact_date_filter(_), do: nil

  defp maybe_apply_preset_filter(map, nil), do: map
  defp maybe_apply_preset_filter(map, ""), do: map

  defp maybe_apply_preset_filter(map, preset) when is_binary(preset) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    today = Date.utc_today()

    case String.downcase(String.trim(preset)) do
      "today" ->
        start_dt = DateTime.new!(today, ~T[00:00:00], "Etc/UTC")
        Map.put(map, :created_after, start_dt)

      "yesterday" ->
        yesterday = Date.add(today, -1)
        start_dt = DateTime.new!(yesterday, ~T[00:00:00], "Etc/UTC")
        end_dt = DateTime.new!(yesterday, ~T[23:59:59], "Etc/UTC")

        map
        |> Map.put(:created_after, start_dt)
        |> Map.put(:created_before, end_dt)

      p when p in ["this_week", "last_7_days", "week"] ->
        start_dt = DateTime.add(now, -7, :day)
        Map.put(map, :created_after, start_dt)

      p when p in ["this_month", "last_30_days", "month"] ->
        start_dt = DateTime.add(now, -30, :day)
        Map.put(map, :created_after, start_dt)

      p when p in ["this_year", "year"] ->
        start_dt = DateTime.new!(Date.new!(today.year, 1, 1), ~T[00:00:00], "Etc/UTC")
        Map.put(map, :created_after, start_dt)

      _ ->
        map
    end
  end

  defp maybe_apply_preset_filter(map, _), do: map
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

    atomized_responses =
      Enum.map(responses, fn %{"taste" => t, "score" => s} ->
        %{taste: t, score: s}
      end)

    with {:ok, updated_user} <- Accounts.submit_taste_survey(user, atomized_responses) do
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
