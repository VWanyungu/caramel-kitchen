defmodule CaramelKitchen.MealPlansTest do
  use ExUnit.Case, async: false

  import CaramelKitchen.Factory
  alias CaramelKitchen.MealPlans
  alias CaramelKitchen.MealPlans.MealPlan
  alias CaramelKitchen.AI.PromptBuilder
  alias CaramelKitchen.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "PromptBuilder.build_meal_plan_prompt/4" do
    test "includes structured recipe fields and strict database restriction rules" do
      user = insert(:user, dietary_flags: ["halal"])

      goal_config = %{
        goal_type: "balanced",
        calorie_target: 2000,
        macro_split: %{protein_pct: 30, carbs_pct: 40, fat_pct: 30}
      }

      r1 =
        insert(:recipe,
          title: "Jollof Rice with Chicken",
          meal: "dinner",
          course: "main",
          dish_categories: ["rice_dishes"],
          cuisine_origin: ["west_african"],
          cost: Decimal.new("3.50"),
          serving_size: 2,
          cook_time_mins: 35,
          difficulty: "intermediate",
          calories: 600,
          dietary_flags: ["halal"],
          is_special: false
        )

      opts = %{
        budget: 40.00,
        servings: 2,
        cuisine: "west_african"
      }

      prompt = PromptBuilder.build_meal_plan_prompt(user, goal_config, [r1], opts)

      # Check structured recipe data
      assert prompt =~ "ID:#{r1.id}"
      assert prompt =~ "Title:Jollof Rice with Chicken"
      assert prompt =~ "Meal:dinner"
      assert prompt =~ "Course:main"
      assert prompt =~ "Cuisine:west_african"
      assert prompt =~ "Cost:$3.50"
      assert prompt =~ "Servings:2"
      assert prompt =~ "Time:35m"
      assert prompt =~ "Diff:intermediate"
      assert prompt =~ "Cal:600"
      assert prompt =~ "Dietary:halal"
      assert prompt =~ "Access:free"

      # Check user preferences
      assert prompt =~ "BUDGET TARGET: $40"
      assert prompt =~ "TARGET SERVING SIZE: 2"
      assert prompt =~ "PREFERRED CUISINE: west_african"

      # Check strict restriction instructions
      assert prompt =~
               "STRICT DATABASE RESTRICTION: You MUST ONLY select recipes from the AVAILABLE RECIPES list"

      assert prompt =~ "UNDER NO CIRCUMSTANCES should you fabricate, hallucinate, or use any ID"
      assert prompt =~ "MEAL SLOT MATCHING"
    end
  end

  describe "Candidate recipe selection & tier access gating" do
    test "free users are strictly restricted to free recipes and excluded from premium recipes" do
      free_user = insert(:user, subscription_tier: "free", dietary_flags: [])

      free_recipes =
        for i <- 1..8 do
          insert(:recipe,
            title: "Free Recipe #{i}",
            meal: "lunch",
            cost: Decimal.new("2.00"),
            is_special: false,
            is_premium: false,
            access_level: "free"
          )
        end

      premium_recipe =
        insert(:recipe,
          title: "Chef Exclusive Steak",
          meal: "dinner",
          cost: Decimal.new("15.00"),
          is_special: true,
          is_premium: true,
          access_level: "premium"
        )

      candidates = MealPlans.fetch_candidate_recipes(free_user, %{})
      candidate_ids = Enum.map(candidates, & &1.id)

      Enum.each(free_recipes, fn fr ->
        assert fr.id in candidate_ids
      end)

      refute premium_recipe.id in candidate_ids
    end

    test "premium users have access to both free and premium recipes in candidate pool" do
      prem_user = insert(:premium_user, subscription_tier: "premium", dietary_flags: [])

      _free_recipes =
        for i <- 1..8 do
          insert(:recipe,
            title: "Free Recipe #{i}",
            meal: "lunch",
            is_special: false,
            is_premium: false,
            access_level: "free"
          )
        end

      premium_recipe =
        insert(:recipe,
          title: "VIP Truffle Pasta",
          meal: "dinner",
          is_special: true,
          is_premium: true,
          access_level: "premium"
        )

      candidates = MealPlans.fetch_candidate_recipes(prem_user, %{})
      candidate_ids = Enum.map(candidates, & &1.id)

      assert premium_recipe.id in candidate_ids
    end
  end

  describe "validate_and_restrict_plan/4 (Hallucination Guard & Auto-Repair)" do
    test "replaces hallucinated and invalid recipe IDs with valid available recipes for the slot" do
      user = insert(:user)

      breakfast =
        insert(:recipe,
          title: "Oat Porridge",
          meal: "breakfast",
          cost: Decimal.new("1.00"),
          calories: 350
        )

      lunch =
        insert(:recipe,
          title: "Chicken Salad",
          meal: "lunch",
          cost: Decimal.new("3.00"),
          calories: 500
        )

      dinner =
        insert(:recipe,
          title: "Grilled Tilapia",
          meal: "dinner",
          cost: Decimal.new("4.00"),
          calories: 600
        )

      snack =
        insert(:recipe,
          title: "Fruit Mix",
          meal: "snack",
          cost: Decimal.new("0.75"),
          calories: 150
        )

      available_recipes = [breakfast, lunch, dinner, snack]

      # Simulate an AI response containing a hallucinated UUID
      hallucinated_uuid = "00000000-0000-0000-0000-000000000000"

      raw_days = [
        %{
          "date_offset" => 0,
          "meals" => [
            %{"slot" => "breakfast", "recipe_id" => hallucinated_uuid, "servings" => 2},
            %{"slot" => "lunch", "recipe_id" => lunch.id, "servings" => 1},
            %{"slot" => "dinner", "recipe_id" => dinner.id, "servings" => 2},
            %{"slot" => "snack", "recipe_id" => snack.id, "servings" => 1}
          ]
        }
      ]

      {validated_days, total_cost} =
        MealPlans.validate_and_restrict_plan(raw_days, available_recipes, user, %{servings: 2})

      assert length(validated_days) == 1
      day0 = List.first(validated_days)

      bf_meal = Enum.find(day0["meals"], &(&1["slot"] == "breakfast"))
      # The hallucinated ID was repaired to the available breakfast recipe!
      assert bf_meal["recipe_id"] == breakfast.id
      assert bf_meal["recipe_title"] == "Oat Porridge"
      assert bf_meal["cost"] == Decimal.new("1.00")

      assert day0["estimated_calories"] > 0
      assert Decimal.gt?(total_cost, Decimal.new(0))
    end

    test "replaces premium recipes with free recipes when generated for a free user" do
      free_user = insert(:user, subscription_tier: "free")

      free_breakfast =
        insert(:recipe,
          title: "Pancake",
          meal: "breakfast",
          cost: Decimal.new("1.20"),
          calories: 400,
          is_special: false,
          is_premium: false,
          access_level: "free"
        )

      premium_dinner =
        insert(:recipe,
          title: "Gold Leaf Steak",
          meal: "dinner",
          cost: Decimal.new("50.00"),
          calories: 900,
          is_special: true,
          is_premium: true,
          access_level: "premium"
        )

      free_dinner =
        insert(:recipe,
          title: "Vegetable Stew",
          meal: "dinner",
          cost: Decimal.new("2.50"),
          calories: 550,
          is_special: false,
          is_premium: false,
          access_level: "free"
        )

      available_recipes = [free_breakfast, free_dinner]

      raw_days = [
        %{
          "date_offset" => 0,
          "meals" => [
            %{"slot" => "breakfast", "recipe_id" => free_breakfast.id},
            # AI unlawfully picked premium dinner
            %{"slot" => "dinner", "recipe_id" => premium_dinner.id}
          ]
        }
      ]

      {validated_days, _total} =
        MealPlans.validate_and_restrict_plan(raw_days, available_recipes, free_user)

      day0 = List.first(validated_days)
      dinner_meal = Enum.find(day0["meals"], &(&1["slot"] == "dinner"))

      # Premium recipe rejected and replaced by compatible free dinner recipe
      assert dinner_meal["recipe_id"] == free_dinner.id
      assert dinner_meal["recipe_title"] == "Vegetable Stew"
    end
  end

  describe "generate_plan/3 end-to-end with restriction and cost tracking" do
    test "successfully generates meal plan restricted to database recipes with budget and costs" do
      user = insert(:user, dietary_flags: ["halal"])

      recipes =
        for i <- 1..10 do
          meal_type = Enum.at(["breakfast", "lunch", "dinner", "snack"], rem(i, 4))

          insert(:recipe,
            title: "Plan Dish #{i}",
            meal: meal_type,
            course: "main",
            dietary_flags: ["halal"],
            cost: Decimal.new("#{i}.50"),
            calories: 400 + i * 20,
            is_special: false,
            is_premium: false,
            access_level: "free"
          )
        end

      r_ids = Enum.map(recipes, & &1.id)

      mock_ai_fn = fn _prompt ->
        # Returns simulated valid JSON with recipe IDs from the pool
        days =
          Enum.map(0..6, fn offset ->
            %{
              "date_offset" => offset,
              "meals" => [
                %{"slot" => "breakfast", "recipe_id" => Enum.at(r_ids, 0), "servings" => 2},
                %{"slot" => "lunch", "recipe_id" => Enum.at(r_ids, 1), "servings" => 2},
                %{"slot" => "dinner", "recipe_id" => Enum.at(r_ids, 2), "servings" => 2},
                %{"slot" => "snack", "recipe_id" => Enum.at(r_ids, 3), "servings" => 1}
              ],
              "estimated_calories" => 2000
            }
          end)

        {:ok, Jason.encode!(%{"days" => days, "weekly_summary" => "Delicious balanced week"})}
      end

      opts = %{
        budget: Decimal.new("60.00"),
        servings: 2,
        completion_fn: mock_ai_fn
      }

      assert {:ok, %MealPlan{} = plan} = MealPlans.generate_plan(user, "balanced", opts)

      assert plan.user_id == user.id
      assert plan.goal_type == "balanced"
      assert plan.is_active == true
      assert plan.budget == Decimal.new("60.00")
      assert Decimal.gt?(plan.total_cost, Decimal.new(0))
      assert length(plan.days) == 7

      # Verify that every single meal in every day points to a real recipe in the database
      all_meal_recipe_ids =
        plan.days
        |> Enum.flat_map(fn d -> Enum.map(d["meals"], & &1["recipe_id"]) end)

      Enum.each(all_meal_recipe_ids, fn id ->
        assert id in r_ids
      end)
    end
  end

  describe "swap_meal/5" do
    test "swaps meal slot with an alternative restricted to available recipes for that slot" do
      user = insert(:user)

      orig_lunch =
        insert(:recipe,
          title: "Old Lunch",
          meal: "lunch",
          cost: Decimal.new("2.50"),
          calories: 450,
          is_special: false,
          access_level: "free"
        )

      new_lunch =
        insert(:recipe,
          title: "New Fresh Lunch",
          meal: "lunch",
          cost: Decimal.new("3.50"),
          calories: 520,
          is_special: false,
          access_level: "free"
        )

      dinner =
        insert(:recipe,
          title: "Night Dinner",
          meal: "dinner",
          cost: Decimal.new("4.00"),
          calories: 600,
          is_special: false,
          access_level: "free"
        )

      days = [
        %{
          "date_offset" => 0,
          "estimated_calories" => 1050,
          "estimated_cost" => Decimal.new("6.50"),
          "meals" => [
            %{
              "slot" => "lunch",
              "recipe_id" => orig_lunch.id,
              "cost" => orig_lunch.cost,
              "calories" => orig_lunch.calories
            },
            %{
              "slot" => "dinner",
              "recipe_id" => dinner.id,
              "cost" => dinner.cost,
              "calories" => dinner.calories
            }
          ]
        }
      ]

      plan =
        insert(:meal_plan,
          user_id: user.id,
          days: days,
          total_cost: Decimal.new("6.50")
        )

      assert {:ok, updated_plan} = MealPlans.swap_meal(plan, 0, "lunch", user)

      day0 = List.first(updated_plan.days)
      lunch_meal = Enum.find(day0["meals"], &(&1["slot"] == "lunch"))

      assert lunch_meal["recipe_id"] == new_lunch.id
      assert lunch_meal["recipe_title"] == "New Fresh Lunch"
      assert lunch_meal["cost"] == new_lunch.cost
    end
  end
end
