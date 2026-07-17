defmodule CaramelKitchen.MealPlans do
  @moduledoc """
  Meal planning context — goal-driven AI plan generation,
  macro tracking, and meal swapping.
  """

  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.MealPlans.MealPlan
  alias CaramelKitchen.AI.{Orchestrator, PromptBuilder}
  alias CaramelKitchen.Recipes
  alias CaramelKitchen.Shopping

  require Logger

  @goal_configs %{
    "gym_muscle"    => %{calorie_target: 3200, macro_split: %{protein_pct: 40, carbs_pct: 35, fat_pct: 25}},
    "weight_loss"   => %{calorie_target: 1400, macro_split: %{protein_pct: 30, carbs_pct: 45, fat_pct: 25}},
    "weight_gain"   => %{calorie_target: 3500, macro_split: %{protein_pct: 35, carbs_pct: 40, fat_pct: 25}},
    "balanced"      => %{calorie_target: 2000, macro_split: %{protein_pct: 30, carbs_pct: 40, fat_pct: 30}},
    "keto"          => %{calorie_target: 1800, macro_split: %{protein_pct: 25, carbs_pct: 5,  fat_pct: 70}}
  }

  # ── Generation ────────────────────────────────────────────────

  @doc """
  AI-generates a 7-day meal plan for the user's goal.
  Returns {:ok, %MealPlan{}} | {:error, reason}.
  """
  def generate_plan(user, goal_type) when goal_type in ~w(gym_muscle weight_loss weight_gain balanced keto) do
    config = Map.get(@goal_configs, goal_type)
    week_start = Date.utc_today()
    week_end   = Date.add(week_start, 6)

    # Fetch compatible recipes (respects dietary flags + taste)
    available_recipes = Recipes.personalised_feed(user,
      limit: 50,
      filters: %{
        dietary: user.dietary_flags,
        exclude_allergens: user.allergy_flags
      }
    )
    |> Enum.map(& &1.recipe)

    if length(available_recipes) < 7 do
      {:error, :insufficient_recipes}
    else
      prompt = PromptBuilder.build_meal_plan_prompt(user, Map.put(config, :goal_type, goal_type), available_recipes)

      with {:ok, json_text}    <- Orchestrator.complete(prompt, format: :json),
           {:ok, plan_data}    <- parse_plan_response(json_text),
           {:ok, meal_plan}    <- insert_plan(user, goal_type, config, plan_data, week_start, week_end) do

        # Async: auto-generate shopping list
        Task.Supervisor.start_child(CaramelKitchen.AI.TaskSupervisor, fn ->
          Shopping.auto_generate_from_plan(meal_plan.id, user.id)
        end)

        {:ok, meal_plan}
      end
    end
  end

  @doc "Swap a single meal slot with an AI-suggested alternative."
  def swap_meal(meal_plan, day_offset, slot, user) do
    current_ids =
      meal_plan.days
      |> Enum.flat_map(fn d -> Enum.map(d["meals"], & &1["recipe_id"]) end)

    alternatives = Recipes.personalised_feed(user,
      limit: 10,
      filters: %{dietary: user.dietary_flags}
    )
    |> Enum.map(& &1.recipe)
    |> Enum.reject(fn r -> r.id in current_ids end)

    case alternatives do
      [] -> {:error, :no_alternatives}
      [new_recipe | _] ->
        updated_days =
          meal_plan.days
          |> Enum.map(fn day ->
            if day["date_offset"] == day_offset do
              updated_meals =
                Enum.map(day["meals"], fn meal ->
                  if meal["slot"] == slot, do: Map.put(meal, "recipe_id", new_recipe.id), else: meal
                end)
              Map.put(day, "meals", updated_meals)
            else
              day
            end
          end)

        meal_plan
        |> Ecto.Changeset.change(%{days: updated_days})
        |> Repo.update()
    end
  end

  # ── Queries ───────────────────────────────────────────────────

  def get_active_plan(user_id) do
    Repo.fetch(
      from p in MealPlan,
      where: p.user_id == ^user_id and p.is_active == true,
      order_by: [desc: p.inserted_at],
      limit: 1
    )
  end

  def list_plans(user_id) do
    from(p in MealPlan, where: p.user_id == ^user_id, order_by: [desc: p.inserted_at])
    |> Repo.all()
  end

  def get_plan!(id), do: Repo.get!(MealPlan, id)

  def daily_summary(meal_plan, day_offset) do
    day = Enum.find(meal_plan.days, &(&1["date_offset"] == day_offset))
    if is_nil(day), do: {:error, :day_not_found}, else: {:ok, day}
  end

  def goal_configs, do: @goal_configs

  # ── Private ───────────────────────────────────────────────────

  defp insert_plan(user, goal_type, config, plan_data, week_start, week_end) do
    # Deactivate existing plans
    from(p in MealPlan, where: p.user_id == ^user.id)
    |> Repo.update_all(set: [is_active: false])

    %MealPlan{}
    |> Ecto.Changeset.cast(%{
      user_id:        user.id,
      goal_type:      goal_type,
      name:           "#{format_goal_name(goal_type)} Plan — #{Date.to_string(week_start)}",
      week_start:     week_start,
      week_end:       week_end,
      calorie_target: config.calorie_target,
      macro_split:    config.macro_split,
      days:           plan_data["days"],
      is_ai_generated: true,
      ai_model:       "gpt-4o",
      is_active:      true
    }, [:user_id, :goal_type, :name, :week_start, :week_end, :calorie_target,
        :macro_split, :days, :is_ai_generated, :ai_model, :is_active])
    |> Ecto.Changeset.validate_required([:user_id, :goal_type, :week_start, :week_end])
    |> Repo.insert()
  end

  defp parse_plan_response(json_text) do
    clean = json_text |> String.replace(Regex.compile!("```json|```"), "") |> String.trim()
    case Jason.decode(clean) do
      {:ok, %{"days" => days} = data} when is_list(days) -> {:ok, data}
      {:ok, _}    -> {:error, :invalid_plan_format}
      {:error, _} -> {:error, :json_parse_error}
    end
  end

  defp format_goal_name("gym_muscle"),  do: "Gym & Muscle"
  defp format_goal_name("weight_loss"), do: "Weight Loss"
  defp format_goal_name("weight_gain"), do: "Weight Gain"
  defp format_goal_name("balanced"),    do: "Balanced"
  defp format_goal_name("keto"),        do: "Keto"
  defp format_goal_name(other),         do: String.capitalize(other)
end
