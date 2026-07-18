defmodule CaramelKitchenWeb.AdminRecipeController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.{Recipes, Content}

  # GET /api/v1/admin/recipes
  def index(conn, params) do
    creator = conn.assigns.current_user
    status = params["status"]

    recipes = Recipes.list_creator_recipes(creator.id, status: status, limit: 100)
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
    %{
      id: recipe.id,
      slug: recipe.slug,
      title: recipe.title,
      description: recipe.description,
      status: recipe.status,
      dish_category: recipe.dish_category,
      course: recipe.course,
      primary_method: recipe.primary_method,
      secondary_method: recipe.secondary_method,
      difficulty: recipe.difficulty,
      cuisine_origin: recipe.cuisine_origin,
      taste_tags: recipe.taste_tags,
      dietary_flags: recipe.dietary_flags,
      allergens: recipe.allergens,
      calories: recipe.calories,
      macros: recipe.macros,
      prep_time_mins: recipe.prep_time_mins,
      cook_time_mins: recipe.cook_time_mins,
      total_time_mins: recipe.total_time_mins,
      thumbnail_url: recipe.thumbnail_url,
      video_url: recipe.video_url,
      video_key: recipe.video_key,
      video_duration_secs: recipe.video_duration_secs,
      view_count: recipe.view_count,
      save_count: recipe.save_count,
      cook_count: recipe.cook_count,
      avg_rating: recipe.avg_rating,
      published_at: recipe.published_at,
      scheduled_at: recipe.scheduled_at,
      inserted_at: recipe.inserted_at,
      updated_at: recipe.updated_at
    }
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
