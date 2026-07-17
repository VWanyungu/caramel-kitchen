defmodule CaramelKitchenWeb.AIController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.AI.Orchestrator

  # POST /api/v1/ai/chat
  def chat(conn, %{"message" => message} = params) do
    user       = conn.assigns.current_user
    session_id = params["session_id"] || generate_session_id(user.id)

    case Orchestrator.chat(user, session_id, message) do
      {:ok, response} ->
        decoded = parse_ai_response(response)
        json(conn, %{
          data: %{
            session_id:   session_id,
            reply:        decoded["reply"] || response,
            recipe_ids:   decoded["recipe_ids"] || [],
            tip:          decoded["tip"],
            stream:       false
          }
        })

      {:error, reason} ->
        conn |> put_status(503) |> json(%{error: "ai_unavailable", detail: inspect(reason)})
    end
  end

  # POST /api/v1/ai/voice
  def voice(conn, params) do
    user = conn.assigns.current_user

    with {:ok, audio, conn} <- read_audio(conn, params),
         {:ok, transcript}  <- Orchestrator.transcribe_voice(audio),
         session_id          = params["session_id"] || generate_session_id(user.id),
         {:ok, ai_response} <- Orchestrator.chat(user, session_id, transcript) do

      decoded = parse_ai_response(ai_response)
      json(conn, %{
        data: %{
          session_id: session_id,
          transcript: transcript,
          reply:      decoded["reply"] || ai_response,
          recipe_ids: decoded["recipe_ids"] || []
        }
      })
    end
  end

  # GET /api/v1/ai/history/:session_id
  def history(conn, %{"session_id" => session_id}) do
    history = Orchestrator.get_history(session_id)
    json(conn, %{data: %{session_id: session_id, messages: history}})
  end

  # DELETE /api/v1/ai/session/:session_id
  def clear_session(conn, %{"session_id" => session_id}) do
    Orchestrator.clear_session(session_id)
    json(conn, %{message: "Session cleared"})
  end

  defp parse_ai_response(text) do
    clean = text |> String.replace(Regex.compile!("```json|```"), "") |> String.trim()
    case Jason.decode(clean) do
      {:ok, map} -> map
      _          -> %{"reply" => text}
    end
  end

  defp generate_session_id(user_id) do
    rand = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
    "#{user_id}-#{rand}"
  end

  defp read_audio(conn, params) do
    case params["audio"] do
      %Plug.Upload{path: path, content_type: _ct} ->
        audio = File.read!(path)
        {:ok, audio, conn}
      _ ->
        with {:ok, body, conn} <- Plug.Conn.read_body(conn, length: 25_000_000) do
          {:ok, body, conn}
        end
    end
  end
end

# ── Interaction Controller ─────────────────────────────────────

defmodule CaramelKitchenWeb.InteractionController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.Recipes
  alias CaramelKitchen.TasteEngine.VectorUpdater

  # POST /api/v1/recipes/:id/save
  def save(conn, %{"id" => recipe_id}) do
    record_interaction(conn, recipe_id, :saved)
  end

  # POST /api/v1/recipes/:id/cook
  def cook(conn, %{"id" => recipe_id}) do
    record_interaction(conn, recipe_id, :cooked)
  end

  # POST /api/v1/recipes/:id/skip
  def skip(conn, %{"id" => recipe_id}) do
    record_interaction(conn, recipe_id, :skipped)
  end

  # POST /api/v1/recipes/:id/rate
  def rate(conn, %{"id" => recipe_id, "rating" => rating_str}) do
    user   = conn.assigns.current_user
    rating = String.to_integer(to_string(rating_str))

    if rating in 1..5 do
      action = if rating >= 4, do: :rated_5, else: :rated_1
      VectorUpdater.enqueue(user.id, recipe_id, action)
      Recipes.increment_engagement(recipe_id, "view_count")
      json(conn, %{data: %{rated: true, rating: rating}})
    else
      conn |> put_status(422) |> json(%{error: "invalid_rating", message: "Rating must be 1-5"})
    end
  end

  # GET /api/v1/me/saved
  def saved_recipes(conn, params) do
    user   = conn.assigns.current_user
    limit  = min(String.to_integer(params["limit"] || "20"), 50)

    import Ecto.Query
    interactions =
      CaramelKitchen.Repo.all(
        from i in CaramelKitchen.UserRecipeInteraction,
        where: i.user_id == ^user.id and i.action == "saved",
        order_by: [desc: i.inserted_at],
        limit: ^limit,
        preload: [:recipe]
      )

    json(conn, %{data: Enum.map(interactions, fn i ->
      %{saved_at: i.inserted_at, recipe: %{id: i.recipe.id, title: i.recipe.title,
        thumbnail_url: i.recipe.thumbnail_url, taste_tags: i.recipe.taste_tags}}
    end)})
  end

  defp record_interaction(conn, recipe_id, action) do
    user = conn.assigns.current_user

    with {:ok, _recipe} <- Recipes.get_recipe(recipe_id) do
      VectorUpdater.enqueue(user.id, recipe_id, action)

      field = case action do
        :saved   -> "save_count"
        :cooked  -> "cook_count"
        :skipped -> nil
      end
      if field, do: Recipes.increment_engagement(recipe_id, field)

      json(conn, %{data: %{action: action, recipe_id: recipe_id}})
    end
  end
end

# ── MealPlan Controller ───────────────────────────────────────

defmodule CaramelKitchenWeb.MealPlanController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.MealPlans

  # GET /api/v1/meal-plans
  def index(conn, _params) do
    user  = conn.assigns.current_user
    plans = MealPlans.list_plans(user.id)
    json(conn, %{data: Enum.map(plans, &render_plan_summary/1)})
  end

  # GET /api/v1/meal-plans/active
  def active(conn, _params) do
    user = conn.assigns.current_user
    with {:ok, plan} <- MealPlans.get_active_plan(user.id) do
      json(conn, %{data: render_plan_full(plan)})
    end
  end

  # POST /api/v1/meal-plans/generate
  def generate(conn, %{"goal_type" => goal_type}) do
    user = conn.assigns.current_user
    with {:ok, plan} <- MealPlans.generate_plan(user, goal_type) do
      conn |> put_status(:created) |> json(%{data: render_plan_full(plan)})
    else
      {:error, :insufficient_recipes} ->
        conn |> put_status(422) |> json(%{error: "insufficient_recipes",
          message: "Not enough recipes available for this goal type yet"})
    end
  end

  # GET /api/v1/meal-plans/:id
  def show(conn, %{"id" => id}) do
    plan = MealPlans.get_plan!(id)
    json(conn, %{data: render_plan_full(plan)})
  end

  # PATCH /api/v1/meal-plans/:id/swap
  def swap_meal(conn, %{"id" => id, "day_offset" => day, "slot" => slot}) do
    user = conn.assigns.current_user
    plan = MealPlans.get_plan!(id)

    with {:ok, updated} <- MealPlans.swap_meal(plan, String.to_integer(day), slot, user) do
      json(conn, %{data: render_plan_full(updated)})
    end
  end

  # GET /api/v1/meal-plans/:id/macros/:day
  def daily_macros(conn, %{"id" => id, "day" => day_offset}) do
    plan = MealPlans.get_plan!(id)
    with {:ok, day} <- MealPlans.daily_summary(plan, String.to_integer(day_offset)) do
      json(conn, %{data: day})
    end
  end

  # DELETE /api/v1/meal-plans/:id
  def delete(conn, %{"id" => id}) do
    plan = MealPlans.get_plan!(id)
    CaramelKitchen.Repo.delete(plan)
    send_resp(conn, :no_content, "")
  end

  # GET /api/v1/meal-plans/:id/shopping
  def shopping_list(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    with {:ok, list} <- CaramelKitchen.Shopping.auto_generate_from_plan(id, user.id) do
      json(conn, %{data: %{id: list.id, items: list.items, share_token: list.share_token}})
    end
  end

  defp render_plan_summary(plan) do
    %{
      id:             plan.id,
      goal_type:      plan.goal_type,
      name:           plan.name,
      week_start:     plan.week_start,
      week_end:       plan.week_end,
      calorie_target: plan.calorie_target,
      is_active:      plan.is_active,
      inserted_at:    plan.inserted_at
    }
  end

  defp render_plan_full(plan) do
    Map.merge(render_plan_summary(plan), %{
      macro_split:    plan.macro_split,
      days:           plan.days,
      is_ai_generated: plan.is_ai_generated
    })
  end
end
