defmodule CaramelKitchen.MealPlans do
  @moduledoc """
  Meal planning context — goal-driven AI plan generation,
  macro tracking, and meal swapping.
  """

  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Accounts.User
  alias CaramelKitchen.MealPlans.{MealPlan, UserMealPlanInteraction}
  alias CaramelKitchen.AI.{Orchestrator, PromptBuilder}
  alias CaramelKitchen.Recipes
  alias CaramelKitchen.Shopping

  require Logger

  @goal_configs %{
    "gym_muscle" => %{
      calorie_target: 3200,
      macro_split: %{protein_pct: 40, carbs_pct: 35, fat_pct: 25}
    },
    "weight_loss" => %{
      calorie_target: 1400,
      macro_split: %{protein_pct: 30, carbs_pct: 45, fat_pct: 25}
    },
    "weight_gain" => %{
      calorie_target: 3500,
      macro_split: %{protein_pct: 35, carbs_pct: 40, fat_pct: 25}
    },
    "balanced" => %{
      calorie_target: 2000,
      macro_split: %{protein_pct: 30, carbs_pct: 40, fat_pct: 30}
    },
    "keto" => %{calorie_target: 1800, macro_split: %{protein_pct: 25, carbs_pct: 5, fat_pct: 70}}
  }

  # ── Generation ────────────────────────────────────────────────

  @doc """
  AI-generates a 7-day meal plan for the user's goal.
  Returns {:ok, %MealPlan{}} | {:error, reason}.
  """
  def generate_plan(user, goal_type)
      when goal_type in ~w(gym_muscle weight_loss weight_gain balanced keto) do
    config = Map.get(@goal_configs, goal_type)
    week_start = Date.utc_today()
    week_end = Date.add(week_start, 6)

    # Fetch compatible recipes (respects dietary flags + taste)
    available_recipes =
      Recipes.personalised_feed(user,
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
      prompt =
        PromptBuilder.build_meal_plan_prompt(
          user,
          Map.put(config, :goal_type, goal_type),
          available_recipes
        )

      with {:ok, json_text} <- Orchestrator.complete(prompt, format: :json),
           {:ok, plan_data} <- parse_plan_response(json_text),
           {:ok, meal_plan} <-
             insert_plan(user, goal_type, config, plan_data, week_start, week_end) do
        # Async: auto-generate shopping list
        Task.Supervisor.start_child(CaramelKitchen.AI.TaskSupervisor, fn ->
          Shopping.auto_generate_from_plan(meal_plan.id, user.id)
        end)

        {:ok, meal_plan}
      end
    end
  end

  def generate_plan(_user, _goal_type), do: {:error, :invalid_goal_type}

  @doc "Swap a single meal slot with an AI-suggested alternative."
  def swap_meal(meal_plan, day_offset, slot, user) do
    current_ids =
      meal_plan.days
      |> Enum.flat_map(fn d -> Enum.map(d["meals"], & &1["recipe_id"]) end)

    alternatives =
      Recipes.personalised_feed(user,
        limit: 10,
        filters: %{dietary: user.dietary_flags}
      )
      |> Enum.map(& &1.recipe)
      |> Enum.reject(fn r -> r.id in current_ids end)

    case alternatives do
      [] ->
        {:error, :no_alternatives}

      [new_recipe | _] ->
        updated_days =
          meal_plan.days
          |> Enum.map(fn day ->
            if day["date_offset"] == day_offset do
              updated_meals =
                Enum.map(day["meals"], fn meal ->
                  if meal["slot"] == slot,
                    do: Map.put(meal, "recipe_id", new_recipe.id),
                    else: meal
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

  def list_plans(user_id, opts \\ []) do
    from(p in MealPlan, where: p.user_id == ^user_id, order_by: [desc: p.inserted_at])
    |> apply_meal_plan_premium_filter(Keyword.get(opts, :is_premium))
    |> Repo.all()
  end

  def get_plan!(id), do: Repo.get!(MealPlan, id)

  def get_plan(id) do
    case Repo.get(MealPlan, id) do
      nil -> {:error, :not_found}
      plan -> {:ok, plan}
    end
  end

  # ── User Interaction (Save / Unsave) ─────────────────────────

  @doc """
  Saves a meal plan for a user. Idempotent.
  Increments meal_plan.save_count on initial save.
  """
  def save_meal_plan(%User{} = user, meal_plan_id, metadata \\ %{}) do
    with {:ok, meal_plan} <- get_plan(meal_plan_id) do
      case Repo.get_by(UserMealPlanInteraction, user_id: user.id, meal_plan_id: meal_plan.id, action: "saved") do
        nil ->
          %UserMealPlanInteraction{}
          |> UserMealPlanInteraction.changeset(%{
            user_id: user.id,
            meal_plan_id: meal_plan.id,
            action: "saved",
            metadata: metadata
          })
          |> Repo.insert()
          |> case do
            {:ok, interaction} ->
              from(m in MealPlan, where: m.id == ^meal_plan.id)
              |> Repo.update_all(inc: [save_count: 1])

              updated = get_plan!(meal_plan.id)

              {:ok,
               %{
                 meal_plan_id: meal_plan.id,
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
             meal_plan_id: meal_plan.id,
             action: "saved",
             status: "already_saved",
             is_saved: true,
             save_count: meal_plan.save_count,
             saved_at: existing.inserted_at
           }}
      end
    end
  end

  @doc """
  Unsaves a meal plan for a user.
  Decrements meal_plan.save_count safely.
  """
  def unsave_meal_plan(%User{} = user, meal_plan_id) do
    with {:ok, meal_plan} <- get_plan(meal_plan_id) do
      case Repo.get_by(UserMealPlanInteraction, user_id: user.id, meal_plan_id: meal_plan.id, action: "saved") do
        nil ->
          {:ok,
           %{
             meal_plan_id: meal_plan.id,
             action: "saved",
             status: "not_saved",
             is_saved: false,
             save_count: meal_plan.save_count
           }}

        interaction ->
          case Repo.delete(interaction) do
            {:ok, _} ->
              from(m in MealPlan, where: m.id == ^meal_plan.id and m.save_count > 0)
              |> Repo.update_all(inc: [save_count: -1])

              updated = get_plan!(meal_plan.id)

              {:ok,
               %{
                 meal_plan_id: meal_plan.id,
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

  @doc "Checks if a user has saved a meal plan"
  def is_saved?(nil, _meal_plan_id), do: false

  def is_saved?(%User{id: user_id}, meal_plan_id) do
    Repo.exists?(
      from i in UserMealPlanInteraction,
        where: i.user_id == ^user_id and i.meal_plan_id == ^meal_plan_id and i.action == "saved"
    )
  end

  def is_saved?(%{id: user_id}, meal_plan_id) do
    Repo.exists?(
      from i in UserMealPlanInteraction,
        where: i.user_id == ^user_id and i.meal_plan_id == ^meal_plan_id and i.action == "saved"
    )
  end

  @doc "Get user meal plan interaction status and count"
  def get_user_meal_plan_status(user, meal_plan_id) do
    with {:ok, meal_plan} <- get_plan(meal_plan_id) do
      is_sav = is_saved?(user, meal_plan.id)

      {:ok,
       %{
         meal_plan_id: meal_plan.id,
         is_saved: is_sav,
         save_count: meal_plan.save_count
       }}
    end
  end

  @doc "List meal plans saved by user with pagination"
  def list_saved_meal_plans(%User{id: user_id}, opts \\ []) do
    limit = (Keyword.get(opts, :limit) || 20) |> min(100)
    offset = Keyword.get(opts, :offset) || 0

    from(m in MealPlan,
      join: i in UserMealPlanInteraction,
      on: i.meal_plan_id == m.id,
      where: i.user_id == ^user_id and i.action == "saved",
      order_by: [desc: i.inserted_at],
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
  end

  @doc "Count meal plans saved by user"
  def count_saved_meal_plans(%User{id: user_id}, _opts \\ []) do
    Repo.one(
      from i in UserMealPlanInteraction,
        where: i.user_id == ^user_id and i.action == "saved",
        select: count(i.id)
    ) || 0
  end

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
    |> Ecto.Changeset.cast(
      %{
        user_id: user.id,
        goal_type: goal_type,
        name: "#{format_goal_name(goal_type)} Plan — #{Date.to_string(week_start)}",
        week_start: week_start,
        week_end: week_end,
        calorie_target: config.calorie_target,
        macro_split: config.macro_split,
        days: plan_data["days"],
        is_ai_generated: true,
        ai_model: "gpt-4o",
        is_active: true,
        is_premium: CaramelKitchen.Accounts.User.premium?(user)
      },
      [
        :user_id,
        :goal_type,
        :name,
        :week_start,
        :week_end,
        :calorie_target,
        :macro_split,
        :days,
        :is_ai_generated,
        :ai_model,
        :is_active,
        :is_premium
      ]
    )
    |> Ecto.Changeset.validate_required([:user_id, :goal_type, :week_start, :week_end])
    |> Repo.insert()
  end

  defp apply_meal_plan_premium_filter(query, nil), do: query

  defp apply_meal_plan_premium_filter(query, val) when val in [true, "true", "1"],
    do: from(p in query, where: p.is_premium == true)

  defp apply_meal_plan_premium_filter(query, val) when val in [false, "false", "0"],
    do: from(p in query, where: p.is_premium == false)

  defp apply_meal_plan_premium_filter(query, _), do: query

  defp parse_plan_response(json_text) do
    clean = json_text |> String.replace(Regex.compile!("```json|```"), "") |> String.trim()

    case Jason.decode(clean) do
      {:ok, %{"days" => days} = data} when is_list(days) -> {:ok, data}
      {:ok, _} -> {:error, :invalid_plan_format}
      {:error, _} -> {:error, :json_parse_error}
    end
  end

  defp format_goal_name("gym_muscle"), do: "Gym & Muscle"
  defp format_goal_name("weight_loss"), do: "Weight Loss"
  defp format_goal_name("weight_gain"), do: "Weight Gain"
  defp format_goal_name("balanced"), do: "Balanced"
  defp format_goal_name("keto"), do: "Keto"
  defp format_goal_name(other), do: String.capitalize(other)
end
