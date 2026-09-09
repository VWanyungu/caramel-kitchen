defmodule CaramelKitchenWeb.AdminRecipeController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.{Recipes, Content}

  # GET /api/v1/admin/recipes
  def index(conn, params) do
    creator = conn.assigns.current_user
    status = params["status"]
    filters = parse_admin_filters(params)

    recipes =
      Recipes.list_creator_recipes(creator.id,
        status: status,
        filters: filters,
        limit: 100
      )

    json(conn, %{data: Enum.map(recipes, &render_admin_recipe/1)})
  end

  # POST /api/v1/admin/recipes
  def create(conn, params) do
    creator = conn.assigns.current_user

    with {:ok, recipe} <- Recipes.create_recipe(creator, params) do
      conn |> put_status(:created) |> json(%{data: render_admin_recipe(recipe)})
    end
  end

  # GET /api/v1/admin/recipes/:id
  def show(conn, %{"id" => id}) do
    recipe = Recipes.get_recipe!(id)
    json(conn, %{data: render_admin_recipe(recipe)})
  end

  # PUT /api/v1/admin/recipes/:id
  def update(conn, %{"id" => id} = params) do
    recipe = Recipes.get_recipe!(id)

    with {:ok, updated} <- Recipes.update_recipe(recipe, Map.delete(params, "id")) do
      json(conn, %{data: render_admin_recipe(updated)})
    end
  end

  # POST /api/v1/admin/recipes/:id/publish
  def publish(conn, %{"id" => id}) do
    recipe = Recipes.get_recipe!(id)

    cond do
      is_nil(recipe.video_url) ->
        conn
        |> put_status(422)
        |> json(%{error: "video_required", message: "Recipe must have a video before publishing"})

      length(recipe.taste_tags) == 0 ->
        conn
        |> put_status(422)
        |> json(%{
          error: "taste_tags_required",
          message: "Recipe must have at least one taste tag"
        })

      true ->
        with {:ok, _} <- Content.schedule_publish(recipe) do
          json(conn, %{data: %{status: "live", published_at: DateTime.utc_now()}})
        end
    end
  end

  # POST /api/v1/admin/recipes/:id/archive
  def archive(conn, %{"id" => id}) do
    recipe = Recipes.get_recipe!(id)

    with {:ok, updated} <- Recipes.update_recipe(recipe, %{status: "archived"}) do
      if recipe.video_key, do: Content.archive_video(recipe.video_key)
      json(conn, %{data: render_admin_recipe(updated)})
    end
  end

  # DELETE /api/v1/admin/recipes/:id
  def delete(conn, %{"id" => id}) do
    recipe = Recipes.get_recipe!(id)
    CaramelKitchen.Repo.delete(recipe)
    send_resp(conn, :no_content, "")
  end

  defp render_admin_recipe(recipe) do
    categories = recipe.dish_categories || []
    cuisine_list = recipe.cuisine_origin || []
    primary_cuisine = List.first(cuisine_list)
    primary_category = recipe.dish_category || List.first(categories)
    dietary_list = recipe.dietary_flags || []

    is_premium =
      Map.get(recipe, :is_premium, false) || Map.get(recipe, :is_special, false) || false

    access_level = Map.get(recipe, :access_level) || if is_premium, do: "premium", else: "free"
    yt = CaramelKitchen.Recipes.Recipe.parse_youtube_video(recipe.video_url || "")

    %{
      id: recipe.id,
      slug: recipe.slug,
      title: recipe.title,
      description: recipe.description,
      status: recipe.status,
      # Access & Tier
      access_level: access_level,
      is_special: is_premium,
      is_premium: is_premium,
      # Category
      category: primary_category,
      categories: categories,
      dish_category: primary_category,
      dish_categories: categories,
      # Classification
      course: recipe.course,
      meal: recipe.meal,
      primary_method: recipe.primary_method,
      secondary_method: recipe.secondary_method,
      difficulty: recipe.difficulty,
      # Cuisine
      cuisine: primary_cuisine,
      cuisines: cuisine_list,
      cuisine_origin: cuisine_list,
      # Cost / Economics
      cost: recipe.cost,
      estimated_cost: recipe.cost,
      # Servings
      servings: recipe.serving_size,
      serving_size: recipe.serving_size,
      # Timing
      cooking_time: recipe.cook_time_mins,
      cooking_time_mins: recipe.cook_time_mins,
      prep_time_mins: recipe.prep_time_mins,
      cook_time_mins: recipe.cook_time_mins,
      total_time_mins: recipe.total_time_mins,
      # Content
      ingredients: recipe.ingredients,
      steps: recipe.steps,
      # Dietary & Taste
      taste_tags: recipe.taste_tags,
      dietary: dietary_list,
      dietary_requirements: dietary_list,
      dietary_flags: dietary_list,
      allergens: recipe.allergens,
      # Nutrition
      calories: recipe.calories,
      macros: recipe.macros,
      # Video & Media
      thumbnail_url: recipe.thumbnail_url,
      video_url: recipe.video_url || yt.video_url,
      video_embed_url: yt.video_embed_url,
      video_iframe_html: yt.iframe_html,
      youtube_video_id: yt.youtube_id,
      video_key: recipe.video_key,
      video_duration_secs: recipe.video_duration_secs,
      # Engagement
      view_count: recipe.view_count,
      save_count: recipe.save_count,
      cook_count: recipe.cook_count,
      avg_rating: recipe.avg_rating,
      # Timestamps
      published_at: recipe.published_at,
      scheduled_at: recipe.scheduled_at,
      created_at: recipe.inserted_at,
      inserted_at: recipe.inserted_at,
      updated_at: recipe.updated_at
    }
  end

  defp parse_admin_filters(params) do
    %{}
    |> maybe_add_date(:created_after, params["created_after"] || params["created_from"])
    |> maybe_add_date(:created_before, params["created_before"] || params["created_to"])
    |> maybe_add_exact_date(params["creation_date"] || params["created_at"])
  end

  defp maybe_add_date(map, _key, nil), do: map
  defp maybe_add_date(map, _key, ""), do: map

  defp maybe_add_date(map, key, str) when is_binary(str) do
    case DateTime.from_iso8601(String.trim(str)) do
      {:ok, dt, _} ->
        Map.put(map, key, dt)

      {:error, _} ->
        case Date.from_iso8601(String.trim(str)) do
          {:ok, date} ->
            time = if key == :created_before, do: ~T[23:59:59], else: ~T[00:00:00]
            Map.put(map, key, DateTime.new!(date, time, "Etc/UTC"))

          _ ->
            map
        end
    end
  end

  defp maybe_add_exact_date(map, nil), do: map
  defp maybe_add_exact_date(map, ""), do: map

  defp maybe_add_exact_date(map, str) when is_binary(str) do
    case Date.from_iso8601(String.trim(str)) do
      {:ok, date} ->
        start_dt = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
        end_dt = DateTime.new!(date, ~T[23:59:59], "Etc/UTC")
        Map.put(map, :creation_date, {start_dt, end_dt})

      _ ->
        map
    end
  end
end

# ── Admin Video Controller ─────────────────────────────────────

defmodule CaramelKitchenWeb.AdminVideoController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.Content

  @allowed_video_types ~w(video/mp4 video/quicktime video/webm video/mpeg)
  # 500 MB
  @max_video_bytes 500 * 1024 * 1024

  # POST /api/v1/admin/videos/presigned-url
  def presigned_url(conn, %{"filename" => filename, "content_type" => ct, "size_bytes" => size}) do
    creator = conn.assigns.current_user

    cond do
      ct not in @allowed_video_types ->
        conn
        |> put_status(422)
        |> json(%{
          error: "invalid_content_type",
          message: "Allowed types: #{Enum.join(@allowed_video_types, ", ")}"
        })

      String.to_integer(to_string(size)) > @max_video_bytes ->
        conn |> put_status(422) |> json(%{error: "file_too_large", message: "Max 500MB"})

      true ->
        with {:ok, result} <- Content.presigned_upload_url(creator.id, filename, ct) do
          json(conn, %{data: result})
        end
    end
  end

  # POST /api/v1/admin/videos/processed (called by Lambda/transcoder webhook)
  def on_processed(conn, %{
        "recipe_id" => rid,
        "video_key" => key,
        "duration_secs" => dur,
        "thumbnail_key" => thumb
      }) do
    with {:ok, recipe} <- Content.on_video_processed(rid, key, dur, thumb) do
      json(conn, %{data: %{recipe_id: recipe.id, video_url: recipe.video_url, status: "ready"}})
    end
  end
end
