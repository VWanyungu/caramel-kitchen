defmodule CaramelKitchenWeb.MealPlanGenerationControllerTest do
  use CaramelKitchenWeb.ConnCase, async: false

  describe "POST /api/v1/meal-plans/generate" do
    test "requires authentication", %{conn: conn} do
      conn = post(conn, "/api/v1/meal-plans/generate", %{"goal_type" => "balanced"})
      assert json_response(conn, 401)
    end

    test "returns 402 premium_required for free users", %{conn: conn} do
      free_user = insert(:user, subscription_tier: "free")

      conn =
        conn
        |> authenticate_conn(free_user)
        |> post("/api/v1/meal-plans/generate", %{"goal_type" => "balanced"})

      assert json_response(conn, 402)["error"] == "premium_required"
    end

    test "returns 422 if goal_type is missing", %{conn: conn} do
      user = insert(:premium_user)
      conn = conn |> authenticate_conn(user) |> post("/api/v1/meal-plans/generate", %{})
      assert json_response(conn, 422)["error"] == "invalid_request"
    end

    test "generates meal plan restricted to database recipes and enriches meals with structured data",
         %{conn: conn} do
      user = insert(:premium_user, dietary_flags: ["halal"])

      recipes =
        for i <- 1..8 do
          meal_type = Enum.at(["breakfast", "lunch", "dinner", "snack"], rem(i, 4))

          insert(:recipe,
            title: "Controller Recipe #{i}",
            meal: meal_type,
            course: "main",
            dietary_flags: ["halal"],
            cost: Decimal.new("#{i}.25"),
            cook_time_mins: 25,
            calories: 450,
            is_special: false,
            is_premium: false,
            access_level: "free"
          )
        end

      r_ids = Enum.map(recipes, & &1.id)

      # Configure mock AI completion
      Application.put_env(:caramel_kitchen, :ai_completion_fn, fn _prompt ->
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
              "estimated_calories" => 1800
            }
          end)

        {:ok, Jason.encode!(%{"days" => days, "weekly_summary" => "Test plan"})}
      end)

      on_exit(fn ->
        Application.delete_env(:caramel_kitchen, :ai_completion_fn)
      end)

      payload = %{
        "goal_type" => "balanced",
        "budget" => 50.00,
        "servings" => 2
      }

      conn = conn |> authenticate_conn(user) |> post("/api/v1/meal-plans/generate", payload)
      body = json_response(conn, 201)

      assert %{"data" => data} = body
      assert data["goal_type"] == "balanced"
      assert data["budget"] == "50.0" or data["budget"] == "50.00"
      assert data["total_cost"] != nil
      assert data["is_active"] == true
      assert length(data["days"]) == 7

      day0 = List.first(data["days"])
      assert length(day0["meals"]) == 4

      # Verify enriched structured recipe attributes
      first_meal = List.first(day0["meals"])
      assert first_meal["recipe_title"] =~ "Controller Recipe"
      assert first_meal["cost"] != nil
      assert first_meal["calories"] == 450
      assert first_meal["cook_time_mins"] == 25
      assert first_meal["access_level"] == "free"
    end
  end

  describe "GET /api/v1/meal-plans/:id and swap" do
    test "retrieves meal plan and swaps a meal slot with available recipe", %{conn: conn} do
      user = insert(:premium_user)

      orig_lunch =
        insert(:recipe,
          title: "Initial Lunch Dish",
          meal: "lunch",
          cost: Decimal.new("3.00"),
          calories: 500,
          is_special: false,
          access_level: "free"
        )

      new_lunch =
        insert(:recipe,
          title: "Fresh Swap Dish",
          meal: "lunch",
          cost: Decimal.new("3.50"),
          calories: 550,
          is_special: false,
          access_level: "free"
        )

      plan =
        insert(:meal_plan,
          user_id: user.id,
          total_cost: Decimal.new("3.00"),
          days: [
            %{
              "date_offset" => 0,
              "meals" => [
                %{"slot" => "lunch", "recipe_id" => orig_lunch.id, "servings" => 1}
              ]
            }
          ]
        )

      # Show plan
      conn_show = conn |> authenticate_conn(user) |> get("/api/v1/meal-plans/#{plan.id}")
      show_data = json_response(conn_show, 200)["data"]
      assert show_data["id"] == plan.id
      first_meal = List.first(List.first(show_data["days"])["meals"])
      assert first_meal["recipe_title"] == "Initial Lunch Dish"

      # Swap meal
      swap_payload = %{
        "day_offset" => 0,
        "slot" => "lunch"
      }

      conn_swap =
        conn
        |> authenticate_conn(user)
        |> patch("/api/v1/meal-plans/#{plan.id}/swap", swap_payload)

      swap_data = json_response(conn_swap, 200)["data"]

      swapped_meal = List.first(List.first(swap_data["days"])["meals"])
      assert swapped_meal["recipe_id"] == new_lunch.id
      assert swapped_meal["recipe_title"] == "Fresh Swap Dish"
    end
  end
end
