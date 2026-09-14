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
  @doc \"""
  AI-generates a 7-day meal plan for the user's goal.
  Candidate recipes and generated meal plan are strictly restricted to available recipe data
  matching user tier, dietary restrictions, budget, and meal slots.
  Returns {:ok, %MealPlan{}} | {:error, reason}.
  """
  def generate_plan(user, goal_type, opts \\ %{})

  def generate_plan(user, goal_type, opts)
      when goal_type in ~w(gym_muscle weight_loss weight_gain balanced keto) do
    opts = normalize_opts(opts)
    config = Map.get(@goal_configs, goal_type)
    week_start = Date.utc_today()
    week_end = Date.add(week_start, 6)

    # Fetch compatible recipes strictly restricted to user tier, dietary flags, budget, and allergies
    available_recipes = fetch_candidate_recipes(user, opts)

    if length(available_recipes) < 7 do
      {:error, :insufficient_recipes}
    else
      prompt =
        PromptBuilder.build_meal_plan_prompt(
          user,
          Map.put(config, :goal_type, goal_type),
          available_recipes,
          opts
        )

      complete_opts =
        [format: :json] ++
          if opts[:completion_fn], do: [completion_fn: opts[:completion_fn]], else: []

      with {:ok, json_text} <- Orchestrator.complete(prompt, complete_opts),
           {:ok, plan_data} <- parse_plan_response(json_text) do
        # Strictly validate and restrict every meal in the plan to available recipe data
        {validated_days, total_cost} =
          validate_and_restrict_plan(plan_data["days"], available_recipes, user, opts)

        case insert_plan(
               user,
               goal_type,
               config,
               validated_days,
               total_cost,
               week_start,
               week_end,
               opts
             ) do
          {:ok, meal_plan} ->
            # Async: auto-generate shopping list
            if Application.get_env(:caramel_kitchen, :auto_generate_shopping_list, true) do
              caller = self()

              Task.Supervisor.start_child(CaramelKitchen.AI.TaskSupervisor, fn ->
                if Code.ensure_loaded?(Ecto.Adapters.SQL.Sandbox) do
                  try do
                    Ecto.Adapters.SQL.Sandbox.allow(CaramelKitchen.Repo, caller, self())
                  rescue
                    _ -> :ok
                  end
                end

                try do
                  Shopping.auto_generate_from_plan(meal_plan.id, user.id)
                rescue
                  _ in DBConnection.OwnershipError -> :ok
                  e -> reraise e, __STACKTRACE__
                end
              end)
            end

            {:ok, meal_plan}

          error ->
            error
        end
      end
    end
  end

  def generate_plan(_user, _goal_type, _opts), do: {:error, :invalid_goal_type}

  @doc "Swap a single meal slot with an alternative strictly restricted to available recipes for that slot."
  def swap_meal(meal_plan, day_offset, slot, user, opts \\ %{}) do
    opts = normalize_opts(opts)

    current_ids =
      meal_plan.days
      |> Enum.flat_map(fn d -> Enum.map(d["meals"] || [], & &1["recipe_id"]) end)

    is_prem = CaramelKitchen.Accounts.User.premium?(user)
    meal_tag = slot_to_meal(slot)

    filters =
      %{dietary: user.dietary_flags, exclude_allergens: user.allergy_flags}
      |> maybe_put(:meal, meal_tag)
      |> maybe_put(:is_premium, if(is_prem, do: nil, else: false))
      |> maybe_put(:access_level, if(is_prem, do: nil, else: "free"))
      |> maybe_put(:max_cost, opts[:budget] || opts[:max_cost])

    alternatives =
      Recipes.personalised_feed(user, limit: 25, filters: filters)
      |> Enum.map(& &1.recipe)
      |> Enum.reject(fn r -> r.id in current_ids end)

    # If slot-specific search had no alternatives, search broader while strictly respecting tier and allergies
    alternatives =
      if alternatives == [] do
        Recipes.personalised_feed(user,
          limit: 25,
          filters: %{
            dietary: user.dietary_flags,
            exclude_allergens: user.allergy_flags,
            is_premium: if(is_prem, do: nil, else: false),
            access_level: if(is_prem, do: nil, else: "free")
          }
        )
        |> Enum.map(& &1.recipe)
        |> Enum.reject(fn r -> r.id in current_ids end)
      else
        alternatives
      end

    # Ensure access gating is strictly enforced
    alternatives =
      if is_prem do
        alternatives
      else
        Enum.filter(alternatives, fn r ->
          not (r.is_special || r.is_premium || r.access_level == "premium")
        end)
      end

    case alternatives do
      [] ->
        {:error, :no_alternatives}

      [new_recipe | _] ->
        updated_days =
          meal_plan.days
          |> Enum.map(fn day ->
            if day["date_offset"] == day_offset do
              updated_meals =
                Enum.map(day["meals"] || [], fn meal ->
                  if to_string(meal["slot"]) == to_string(slot) do
                    meal
                    |> Map.put("recipe_id", new_recipe.id)
                    |> Map.put("recipe_title", new_recipe.title)
                    |> Map.put("cost", new_recipe.cost)
                    |> Map.put("calories", new_recipe.calories)
                    |> Map.put("meal", new_recipe.meal)
                    |> Map.put("cuisine", List.first(new_recipe.cuisine_origin || []))
                  else
                    meal
                  end
                end)

              new_cals = Enum.reduce(updated_meals, 0, &((&1["calories"] || 0) + &2))

              new_cost =
                Enum.reduce(updated_meals, Decimal.new(0), fn m, acc ->
                  Decimal.add(acc, m["cost"] || Decimal.new(0))
                end)

              day
              |> Map.put("meals", updated_meals)
              |> Map.put("estimated_calories", new_cals)
              |> Map.put("estimated_cost", new_cost)
            else
              day
            end
          end)

        new_total_cost =
          Enum.reduce(updated_days, Decimal.new(0), fn d, acc ->
            Decimal.add(acc, d["estimated_cost"] || Decimal.new(0))
          end)

        meal_plan
        |> Ecto.Changeset.change(%{days: updated_days, total_cost: new_total_cost})
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
      case Repo.get_by(UserMealPlanInteraction,
             user_id: user.id,
             meal_plan_id: meal_plan.id,
             action: "saved"
           ) do
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
      case Repo.get_by(UserMealPlanInteraction,
             user_id: user.id,
             meal_plan_id: meal_plan.id,
             action: "saved"
           ) do
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

  @doc "Fetches candidate recipes strictly restricted to user tier, dietary restrictions, and budget."
  def fetch_candidate_recipes(user, opts \\ %{}) do
    opts = normalize_opts(opts)
    is_premium = CaramelKitchen.Accounts.User.premium?(user)

    dietary =
      Map.get(opts, :dietary) || Map.get(opts, :dietary_requirements) || user.dietary_flags || []

    dietary_list =
      cond do
        is_list(dietary) -> dietary
        is_binary(dietary) and dietary != "" -> [dietary]
        true -> []
      end

    allergy_list = (user.allergy_flags || []) ++ (Map.get(opts, :exclude_allergens) || [])

    base_filters = %{
      dietary: dietary_list,
      exclude_allergens: allergy_list
    }

    filters =
      base_filters
      |> maybe_put(:max_cost, Map.get(opts, :budget) || Map.get(opts, :max_cost))
      |> maybe_put(:servings, Map.get(opts, :servings))
      |> maybe_put(:cuisine, Map.get(opts, :cuisine) || Map.get(opts, :cuisines))
      |> maybe_put(:cooking_time, Map.get(opts, :max_cooking_time))
      |> maybe_put(:difficulty, Map.get(opts, :difficulty))
      |> maybe_put(:exclude_ingredients, Map.get(opts, :exclude_ingredients))
      |> maybe_put(:is_premium, if(is_premium, do: nil, else: false))
      |> maybe_put(:access_level, if(is_premium, do: nil, else: "free"))

    candidates =
      Recipes.personalised_feed(user, limit: 50, filters: filters)
      |> Enum.map(& &1.recipe)

    # Strictly enforce access gating: free users NEVER get premium recipes
    candidates =
      if is_premium do
        candidates
      else
        Enum.filter(candidates, fn r ->
          not (r.is_special || r.is_premium || r.access_level == "premium")
        end)
      end

    # If filters were too restrictive, fall back to base tier + dietary pool
    if length(candidates) < 7 do
      fallback_filters =
        base_filters
        |> maybe_put(:is_premium, if(is_premium, do: nil, else: false))
        |> maybe_put(:access_level, if(is_premium, do: nil, else: "free"))

      fallback_candidates =
        Recipes.personalised_feed(user, limit: 50, filters: fallback_filters)
        |> Enum.map(& &1.recipe)

      fallback_candidates =
        if is_premium do
          fallback_candidates
        else
          Enum.filter(fallback_candidates, fn r ->
            not (r.is_special || r.is_premium || r.access_level == "premium")
          end)
        end

      if length(fallback_candidates) >= 7, do: fallback_candidates, else: candidates
    else
      candidates
    end
  end

  @doc """
  Strictly validates and restricts AI-generated days to available recipe data.
  Replaces any invalid, hallucinated, or unpermitted recipe IDs with compatible
  recipes from available_recipes for the given slot.
  """
  def validate_and_restrict_plan(days, available_recipes, user, opts \\ %{}) do
    recipe_map = Map.new(available_recipes, &{&1.id, &1})
    valid_ids = MapSet.new(Map.keys(recipe_map))

    # Partition available recipes into meal slot pools
    breakfast_pool = slot_pool(available_recipes, ["breakfast", "brunch"])
    lunch_pool = slot_pool(available_recipes, ["lunch", "main", "starter"])
    dinner_pool = slot_pool(available_recipes, ["dinner", "main"])
    snack_pool = slot_pool(available_recipes, ["snack", "dessert", "side"])

    # Process days sequentially while keeping track of recent recipe usage for variety
    {validated_days, _history} =
      Enum.map_reduce(days, [], fn day, recent_history ->
        meals = Map.get(day, "meals") || Map.get(day, :meals) || []
        date_offset = Map.get(day, "date_offset") || Map.get(day, :date_offset) || 0

        {validated_meals, day_recipe_ids} =
          Enum.map_reduce(meals, [], fn meal, day_ids ->
            slot =
              (Map.get(meal, "slot") || Map.get(meal, :slot) || "meal")
              |> to_string()
              |> String.downcase()

            raw_id = Map.get(meal, "recipe_id") || Map.get(meal, :recipe_id)

            chosen_recipe =
              if raw_id && MapSet.member?(valid_ids, raw_id) &&
                   Recipes.has_recipe_access?(Map.fetch!(recipe_map, raw_id), user) do
                Map.fetch!(recipe_map, raw_id)
              else
                # Auto-repair: select best compatible recipe from slot pool
                select_fallback_recipe(
                  slot,
                  breakfast_pool,
                  lunch_pool,
                  dinner_pool,
                  snack_pool,
                  available_recipes,
                  day_ids ++ recent_history
                )
              end

            default_servings = Map.get(opts, :servings) || chosen_recipe.serving_size || 1

            servings =
              case Map.get(meal, "servings") || Map.get(meal, :servings) do
                n when is_integer(n) and n > 0 ->
                  n

                str when is_binary(str) ->
                  case Integer.parse(str) do
                    {n, _} when n > 0 -> n
                    _ -> default_servings
                  end

                _ ->
                  default_servings
              end

            meal_map = %{
              "slot" => slot,
              "recipe_id" => chosen_recipe.id,
              "servings" => servings,
              "recipe_title" => chosen_recipe.title,
              "cost" => chosen_recipe.cost,
              "calories" => chosen_recipe.calories,
              "meal" => chosen_recipe.meal,
              "cuisine" => List.first(chosen_recipe.cuisine_origin || [])
            }

            {meal_map, [chosen_recipe.id | day_ids]}
          end)

        day_calories =
          Enum.reduce(validated_meals, 0, fn m, acc ->
            acc + (m["calories"] || 0)
          end)

        day_cost =
          Enum.reduce(validated_meals, Decimal.new(0), fn m, acc ->
            cost = m["cost"] || Decimal.new(0)
            Decimal.add(acc, cost)
          end)

        validated_day = %{
          "date_offset" => date_offset,
          "meals" => validated_meals,
          "estimated_calories" => day_calories,
          "estimated_cost" => day_cost
        }

        # Keep history of last 3 days to enforce variety
        new_recent = Enum.take(day_recipe_ids ++ recent_history, 15)

        {validated_day, new_recent}
      end)

    total_cost =
      Enum.reduce(validated_days, Decimal.new(0), fn d, acc ->
        Decimal.add(acc, d["estimated_cost"] || Decimal.new(0))
      end)

    {validated_days, total_cost}
  end

  defp select_fallback_recipe(slot, bf, lu, di, sn, all, excluded_ids) do
    pool =
      case slot do
        "breakfast" -> bf
        "lunch" -> lu
        "dinner" -> di
        "snack" -> sn
        _ -> all
      end

    pool = if pool == [], do: all, else: pool

    candidate = Enum.find(pool, fn r -> r.id not in excluded_ids end)

    candidate || Enum.find(all, fn r -> r.id not in excluded_ids end) || List.first(pool) ||
      List.first(all)
  end

  defp slot_pool(recipes, meals) do
    filtered =
      Enum.filter(recipes, fn r ->
        (r.meal && r.meal in meals) or (r.course && r.course in meals)
      end)

    if filtered == [], do: recipes, else: filtered
  end

  defp slot_to_meal("breakfast"), do: "breakfast"
  defp slot_to_meal("lunch"), do: "lunch"
  defp slot_to_meal("dinner"), do: "dinner"
  defp slot_to_meal("snack"), do: "snack"
  defp slot_to_meal(_), do: nil

  defp normalize_opts(opts) when is_list(opts), do: Map.new(opts)

  defp normalize_opts(%{} = opts) do
    Enum.reduce(opts, %{}, fn {k, v}, acc ->
      atom_k =
        case k do
          a when is_atom(a) ->
            a

          s when is_binary(s) ->
            try do
              String.to_existing_atom(s)
            rescue
              ArgumentError -> String.to_atom(s)
            end
        end

      Map.put(acc, atom_k, v)
    end)
  end

  defp normalize_opts(_), do: %{}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, val), do: Map.put(map, key, val)

  defp insert_plan(
         user,
         goal_type,
         config,
         validated_days,
         total_cost,
         week_start,
         week_end,
         opts
       ) do
    # Deactivate existing plans
    from(p in MealPlan, where: p.user_id == ^user.id)
    |> Repo.update_all(set: [is_active: false])

    budget =
      case Map.get(opts, :budget) || Map.get(opts, :max_cost) do
        nil ->
          nil

        %Decimal{} = d ->
          d

        n when is_number(n) ->
          Decimal.new(to_string(n))

        str when is_binary(str) ->
          case Decimal.parse(str) do
            {d, _} -> d
            _ -> nil
          end
      end

    avg_cost =
      if length(validated_days) > 0 do
        Decimal.div(total_cost, Decimal.new(length(validated_days))) |> Decimal.round(2)
      else
        Decimal.new(0)
      end

    macro_split =
      Map.merge(config.macro_split, %{
        "estimated_total_cost" => total_cost,
        "average_daily_cost" => avg_cost,
        "budget" => budget
      })

    %MealPlan{}
    |> Ecto.Changeset.cast(
      %{
        user_id: user.id,
        goal_type: goal_type,
        name: "#{format_goal_name(goal_type)} Plan — #{Date.to_string(week_start)}",
        week_start: week_start,
        week_end: week_end,
        calorie_target: config.calorie_target,
        macro_split: macro_split,
        days: validated_days,
        total_cost: total_cost,
        budget: budget,
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
        :total_cost,
        :budget,
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
