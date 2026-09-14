defmodule CaramelKitchen.AI.PromptBuilder do
  @moduledoc "Builds personalised system prompts from user taste + goal context."

  alias CaramelKitchen.Accounts.User

  @taste_dimensions ~w(sour sweet tangy spicy savory bitter umami mild)

  @doc """
  Build a full system prompt incorporating the user's:
  - Taste profile (top 3 dimensions)
  - Dietary restrictions
  - Active health goal
  - Known allergens
  """
  def build_system_prompt(%User{} = user) do
    top_tastes = top_taste_dims(user)
    dietary_str = format_dietary(user.dietary_flags)
    allergen_str = format_allergens(user.allergy_flags)
    goal_str = format_goal(user.goal_type)

    """
    You are a personal chef assistant for Caramel Kitchen, a smart recipe discovery app.

    USER TASTE PROFILE:
    - Top taste preferences: #{top_tastes}
    - Dietary lifestyle: #{dietary_str}
    - Allergens to avoid: #{allergen_str}
    - Health goal: #{goal_str}

    INSTRUCTIONS:
    1. Always recommend recipes that match the user's taste profile.
    2. Never suggest recipes containing the user's allergens.
    3. When recommending recipes, always respond with valid JSON in this format:
       {"reply": "<conversational response>", "recipe_ids": ["<uuid>", ...], "tip": "<cooking tip>"}
    4. If the user asks a general question, still include an empty recipe_ids array.
    5. Keep responses concise — max 3 sentences for the reply field.
    6. If recommending recipes from a specific goal plan, factor in the calorie targets.
    7. You may suggest 1-3 recipes per response.
    8. Voice cooking mode: if context includes [VOICE_COOKING], keep responses under 2 sentences
       and always end with "Say 'next step' to continue."
    """
  end

  @doc "Build a meal plan generation prompt."
  def build_meal_plan_prompt(user, goal_config, available_recipes, opts \\ %{}) do
    budget_str = format_budget(opts)
    servings_str = format_servings(opts)
    cuisine_pref = format_cuisine_preference(opts)

    recipe_summaries =
      available_recipes
      |> Enum.take(40)
      |> Enum.map(fn r ->
        cat = r.dish_category || List.first(r.dish_categories || []) || "general"
        cuisines = (r.cuisine_origin || []) |> Enum.join(",")
        cost_str = if r.cost, do: "$#{r.cost}", else: "N/A"
        dietary_str = (r.dietary_flags || []) |> Enum.join(",")
        access = r.access_level || if r.is_special || r.is_premium, do: "premium", else: "free"

        "- ID:#{r.id} | Title:#{r.title} | Meal:#{r.meal || "any"} | Course:#{r.course || "main"} | Cat:#{cat} | Cuisine:#{cuisines} | Cost:#{cost_str} | Servings:#{r.serving_size || 1} | Time:#{r.cook_time_mins || 0}m | Diff:#{r.difficulty || "intermediate"} | Cal:#{r.calories || 0} | Dietary:#{dietary_str} | Access:#{access}"
      end)
      |> Enum.join("\n")

    """
    Generate a 7-day meal plan for a user with the following profile:

    GOAL: #{goal_config.goal_type}
    DAILY CALORIE TARGET: #{goal_config.calorie_target} kcal
    MACRO SPLIT: #{format_macros(goal_config.macro_split)}
    DIETARY FLAGS: #{format_dietary(user.dietary_flags)}
    TASTE PREFERENCES: #{top_taste_dims(user)}
    #{budget_str}#{servings_str}#{cuisine_pref}
    AVAILABLE RECIPES (STRICTLY RESTRICTED TO THIS DATABASE LIST):
    #{recipe_summaries}

    CRITICAL INSTRUCTIONS & RESTRICTIONS:
    1. STRICT DATABASE RESTRICTION: You MUST ONLY select recipes from the AVAILABLE RECIPES list above using their EXACT "ID".
       UNDER NO CIRCUMSTANCES should you fabricate, hallucinate, or use any ID that does not appear in the AVAILABLE RECIPES list.
    2. MEAL SLOT MATCHING: Match the recipe's Meal tag (breakfast, lunch, dinner, snack) to the corresponding meal slot whenever possible.
    3. BUDGET & COST RESPECT: If a budget is specified, select recipes whose costs align with the target.
    4. VARIETY: No recipe may be repeated within 3 consecutive days.
    5. CALORIE ACCURACY: Plan 3 meals per day (breakfast, lunch, dinner) + 1-2 snacks where needed. Each day must hit the daily calorie target ±10%.
    6. Respond ONLY with valid JSON, no preamble, code fences, or explanations:

    {
      "days": [
        {
          "date_offset": 0,
          "meals": [
            {"slot": "breakfast", "recipe_id": "<exact_id_from_available_recipes>", "servings": 2},
            {"slot": "lunch",     "recipe_id": "<exact_id_from_available_recipes>", "servings": 1},
            {"slot": "dinner",    "recipe_id": "<exact_id_from_available_recipes>", "servings": 2},
            {"slot": "snack",     "recipe_id": "<exact_id_from_available_recipes>", "servings": 1}
          ],
          "estimated_calories": 2100
        }
      ],
      "weekly_summary": "Brief summary of the plan"
    }
    """
  end

  # ── Private ───────────────────────────────────────────────────

  defp top_taste_dims(%User{taste_vector: nil}), do: "no preference set yet"

  defp top_taste_dims(%User{taste_vector: vec}) do
    vec
    |> Pgvector.to_list()
    |> Enum.zip(@taste_dimensions)
    |> Enum.sort_by(fn {score, _dim} -> score end, :desc)
    |> Enum.take(3)
    |> Enum.map(fn {score, dim} -> "#{dim} (#{Float.round(score, 2)})" end)
    |> Enum.join(", ")
  end

  defp format_dietary([]), do: "no specific restrictions"
  defp format_dietary(flags), do: Enum.join(flags, ", ")

  defp format_allergens([]), do: "none"
  defp format_allergens(allergens), do: Enum.join(allergens, ", ")

  defp format_goal(nil), do: "general healthy eating"
  defp format_goal("gym_muscle"), do: "Gym & Muscle Gain (high protein, 2800-3500 kcal)"
  defp format_goal("weight_loss"), do: "Weight Loss (calorie deficit, 1200-1600 kcal)"
  defp format_goal("weight_gain"), do: "Weight Gain (calorie surplus, 3000-4000 kcal)"
  defp format_goal("balanced"), do: "Balanced & Healthy (maintenance, 1800-2200 kcal)"
  defp format_goal("keto"), do: "Keto / Low Carb (under 50g carbs/day)"
  defp format_goal(other), do: other

  defp format_macros(%{protein_pct: p, carbs_pct: c, fat_pct: f}) do
    "Protein #{p}% / Carbs #{c}% / Fat #{f}%"
  end

  defp format_macros(_), do: "balanced"

  defp format_budget(opts) do
    budget =
      Map.get(opts, :budget) || Map.get(opts, "budget") || Map.get(opts, :max_cost) ||
        Map.get(opts, "max_cost")

    if budget, do: "    BUDGET TARGET: $#{budget}\n", else: ""
  end

  defp format_servings(opts) do
    servings = Map.get(opts, :servings) || Map.get(opts, "servings")
    if servings, do: "    TARGET SERVING SIZE: #{servings}\n", else: ""
  end

  defp format_cuisine_preference(opts) do
    cuisine =
      Map.get(opts, :cuisine) || Map.get(opts, "cuisine") || Map.get(opts, :cuisines) ||
        Map.get(opts, "cuisines")

    case cuisine do
      list when is_list(list) and list != [] ->
        "    PREFERRED CUISINE: #{Enum.join(list, ", ")}\n"

      str when is_binary(str) and str != "" ->
        "    PREFERRED CUISINE: #{str}\n"

      _ ->
        ""
    end
  end
end
