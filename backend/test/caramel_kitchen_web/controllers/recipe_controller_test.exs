defmodule CaramelKitchenWeb.RecipeControllerTest do
  use CaramelKitchenWeb.ConnCase, async: false

  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Recipes.Recipe

  describe "GET /api/v1/recipes (public)" do
    setup do
      insert_list(5, :recipe, status: "live")
      # should not appear
      insert(:recipe, status: "draft")
      :ok
    end

    test "returns live recipes without auth", %{conn: conn} do
      conn = get(conn, "/api/v1/recipes")
      body = json_response(conn, 200)
      assert length(body["data"]) >= 5
    end

    test "filters by cooking method", %{conn: conn} do
      insert(:recipe, status: "live", primary_method: "grilling")
      conn = get(conn, "/api/v1/recipes?cooking_method=grilling")
      body = json_response(conn, 200)
      assert Enum.all?(body["data"], &(&1["primary_method"] == "grilling"))
      assert length(body["data"]) >= 1
    end

    test "filters by dietary flags", %{conn: conn} do
      insert(:recipe, status: "live", dietary_flags: ["vegan"])
      conn = get(conn, "/api/v1/recipes?dietary=vegan")
      body = json_response(conn, 200)
      assert Enum.all?(body["data"], &("vegan" in &1["dietary_flags"]))
      assert length(body["data"]) >= 1
    end

    test "6-dimensional filtering works together", %{conn: conn} do
      # Target recipe that matches all filters
      insert(:recipe,
        status: "live",
        dish_category: "salads",
        dish_categories: ["salads"],
        primary_method: "sauteing",
        dietary_flags: ["vegan", "gluten_free"],
        allergens: [],
        course: "starter",
        total_time_mins: 15
      )

      # Decoy recipes that fail one of the filters
      # Fails category
      insert(:recipe,
        status: "live",
        dish_category: "soups_stews",
        dish_categories: ["soups_stews"],
        primary_method: "sauteing",
        dietary_flags: ["vegan", "gluten_free"],
        allergens: [],
        course: "starter",
        total_time_mins: 15
      )

      # Fails method
      insert(:recipe,
        status: "live",
        dish_category: "salads",
        dish_categories: ["salads"],
        primary_method: "baking",
        dietary_flags: ["vegan", "gluten_free"],
        allergens: [],
        course: "starter",
        total_time_mins: 15
      )

      # Fails dietary
      insert(:recipe,
        status: "live",
        dish_category: "salads",
        dish_categories: ["salads"],
        primary_method: "sauteing",
        dietary_flags: ["gluten_free"],
        allergens: [],
        course: "starter",
        total_time_mins: 15
      )

      # Fails allergens
      insert(:recipe,
        status: "live",
        dish_category: "salads",
        dish_categories: ["salads"],
        primary_method: "sauteing",
        dietary_flags: ["vegan", "gluten_free"],
        allergens: ["nuts"],
        course: "starter",
        total_time_mins: 15
      )

      # Fails course
      insert(:recipe,
        status: "live",
        dish_category: "salads",
        dish_categories: ["salads"],
        primary_method: "sauteing",
        dietary_flags: ["vegan", "gluten_free"],
        allergens: [],
        course: "main",
        total_time_mins: 15
      )

      # Fails time limit
      insert(:recipe,
        status: "live",
        dish_category: "salads",
        dish_categories: ["salads"],
        primary_method: "sauteing",
        dietary_flags: ["vegan", "gluten_free"],
        allergens: [],
        course: "starter",
        prep_time_mins: 15,
        cook_time_mins: 30,
        total_time_mins: 45
      )

      query =
        URI.encode_query(%{
          category: "salads",
          cooking_method: "sauteing",
          dietary: "vegan,gluten_free",
          exclude_allergens: "nuts",
          course: "starter",
          max_time: 30
        })

      conn = get(conn, "/api/v1/recipes?#{query}")
      body = json_response(conn, 200)

      assert length(body["data"]) == 1
      recipe = hd(body["data"])
      assert recipe["dish_category"] == "salads"
      assert recipe["primary_method"] == "sauteing"
      assert "vegan" in recipe["dietary_flags"]
      assert recipe["course"] == "starter"
    end
  end

  describe "GET /api/v1/recipes/search" do
    test "combines search query with filters", %{conn: conn} do
      # Recipe matching both text and filters
      insert(:recipe,
        title: "Spicy Vegan Taco",
        status: "live",
        dish_category: "vegetarian",
        dish_categories: ["vegetarian"],
        dietary_flags: ["vegan"]
      )

      # Matches text, fails filter
      insert(:recipe,
        title: "Spicy Beef Taco",
        status: "live",
        dish_category: "vegetarian",
        dish_categories: ["vegetarian"],
        dietary_flags: []
      )

      # Matches filter, fails text
      insert(:recipe,
        title: "Mild Vegan Wrap",
        description: "Fresh vegetable wrap",
        ingredients: [%{"name" => "tofu", "quantity" => 100, "unit" => "g"}],
        taste_tags: ["mild"],
        status: "live",
        dish_category: "vegetarian",
        dish_categories: ["vegetarian"],
        dietary_flags: ["vegan"]
      )

      query = URI.encode_query(%{q: "Taco", dietary: "vegan", category: "vegetarian"})
      conn = get(conn, "/api/v1/recipes/search?#{query}")
      body = json_response(conn, 200)

      assert length(body["data"]) == 1
      assert hd(body["data"])["title"] == "Spicy Vegan Taco"
    end

    test "filters recipes by meal", %{conn: conn} do
      insert(:recipe, title: "Pancakes", meal: "breakfast", status: "live")
      insert(:recipe, title: "Steak", meal: "dinner", status: "live")

      conn = get(conn, "/api/v1/recipes/search?meal=breakfast")
      body = json_response(conn, 200)

      assert length(body["data"]) == 1
      assert hd(body["data"])["title"] == "Pancakes"
      assert hd(body["data"])["meal"] == "breakfast"
    end
  end

  describe "GET /api/v1/recipes/:id" do
    test "returns recipe detail", %{conn: conn} do
      recipe = insert(:recipe, status: "live")
      conn = get(conn, "/api/v1/recipes/#{recipe.id}")
      body = json_response(conn, 200)

      assert body["data"]["id"] == recipe.id
      assert body["data"]["title"] == recipe.title
      assert body["data"]["ingredients"]
      assert body["data"]["steps"]
      assert body["data"]["macros"]
      assert body["data"]["dish_categories"] == recipe.dish_categories
      assert body["data"]["categories"] == recipe.dish_categories
    end

    test "returns 404 for non-existent recipe", %{conn: conn} do
      conn = get(conn, "/api/v1/recipes/00000000-0000-0000-0000-000000000000")
      assert json_response(conn, 404)["error"] == "not_found"
    end
  end

  describe "GET /api/v1/recipes/trending" do
    test "returns trending recipes", %{conn: conn} do
      insert_list(3, :recipe, status: "live", engagement_score: 0.9)
      conn = get(conn, "/api/v1/recipes/trending")
      body = json_response(conn, 200)
      assert length(body["data"]) >= 1
    end
  end

  describe "GET /api/v1/categories" do
    test "returns category counts", %{conn: conn} do
      insert(:recipe, status: "live", dish_category: "meat_dishes")
      conn = get(conn, "/api/v1/categories")
      body = json_response(conn, 200)
      assert is_map(body["data"])
    end
  end

  describe "is_special access control (Issue #58)" do
    test "blocks unauthenticated user from accessing is_special recipe detail", %{conn: conn} do
      recipe = insert(:recipe, status: "live", is_special: true)

      conn_id = get(conn, "/api/v1/recipes/#{recipe.id}")
      assert json_response(conn_id, 402)["error"] == "premium_required"

      conn_slug = get(conn, "/api/v1/recipes/slug/#{recipe.slug}")
      assert json_response(conn_slug, 402)["error"] == "premium_required"
    end

    test "blocks free user from accessing is_special recipe detail", %{conn: conn} do
      recipe = insert(:recipe, status: "live", is_special: true)
      free_user = insert(:user, subscription_tier: "free")

      conn = authenticate_conn(conn, free_user)
      conn_id = get(conn, "/api/v1/recipes/#{recipe.id}")
      assert json_response(conn_id, 402)["error"] == "premium_required"

      conn_slug = get(conn, "/api/v1/recipes/slug/#{recipe.slug}")
      assert json_response(conn_slug, 402)["error"] == "premium_required"
    end

    test "allows premium user to access is_special recipe detail", %{conn: conn} do
      recipe = insert(:recipe, status: "live", is_special: true)
      prem_user = insert(:premium_user)

      conn = authenticate_conn(conn, prem_user)
      conn_id = get(conn, "/api/v1/recipes/#{recipe.id}")
      body = json_response(conn_id, 200)

      assert body["data"]["id"] == recipe.id
      assert body["data"]["is_special"] == true
      assert body["data"]["is_locked"] == false
      assert length(body["data"]["ingredients"]) > 0
      assert length(body["data"]["steps"]) > 0

      conn_slug = get(conn, "/api/v1/recipes/slug/#{recipe.slug}")
      assert json_response(conn_slug, 200)["data"]["id"] == recipe.id
    end

    test "allows admin user to access is_special recipe detail", %{conn: conn} do
      recipe = insert(:recipe, status: "live", is_special: true)
      admin = insert(:admin)

      conn = authenticate_conn(conn, admin)
      conn_id = get(conn, "/api/v1/recipes/#{recipe.id}")
      assert json_response(conn_id, 200)["data"]["id"] == recipe.id
    end

    test "marks is_locked on recipe cards according to user subscription", %{conn: conn} do
      insert(:recipe, status: "live", is_special: true, title: "VIP Truffle Pasta")
      insert(:recipe, status: "live", is_special: false, title: "Standard Pasta")

      # 1. Unauthenticated
      conn_anon = get(conn, "/api/v1/recipes")
      body_anon = json_response(conn_anon, 200)
      vip_card_anon = Enum.find(body_anon["data"], &(&1["title"] == "VIP Truffle Pasta"))
      std_card_anon = Enum.find(body_anon["data"], &(&1["title"] == "Standard Pasta"))

      assert vip_card_anon["is_special"] == true
      assert vip_card_anon["is_locked"] == true
      assert std_card_anon["is_special"] == false
      assert std_card_anon["is_locked"] == false

      # 2. Premium user
      prem_user = insert(:premium_user)
      conn_prem = conn |> authenticate_conn(prem_user) |> get("/api/v1/recipes")
      body_prem = json_response(conn_prem, 200)
      vip_card_prem = Enum.find(body_prem["data"], &(&1["title"] == "VIP Truffle Pasta"))

      assert vip_card_prem["is_special"] == true
      assert vip_card_prem["is_locked"] == false
    end

    test "filters recipes by is_special query parameter", %{conn: conn} do
      insert(:recipe, status: "live", is_special: true, title: "Only Special Recipe")
      insert(:recipe, status: "live", is_special: false, title: "Only Free Recipe")

      conn_spec = get(conn, "/api/v1/recipes?is_special=true")
      body_spec = json_response(conn_spec, 200)
      assert Enum.any?(body_spec["data"], &(&1["title"] == "Only Special Recipe"))
      refute Enum.any?(body_spec["data"], &(&1["title"] == "Only Free Recipe"))

      conn_free = get(conn, "/api/v1/recipes?is_special=false")
      body_free = json_response(conn_free, 200)
      assert Enum.any?(body_free["data"], &(&1["title"] == "Only Free Recipe"))
      refute Enum.any?(body_free["data"], &(&1["title"] == "Only Special Recipe"))
    end
  end

  describe "creation date filtering and metadata" do
    test "exposes created_at in recipe card and detail responses", %{conn: conn} do
      recipe = insert(:recipe, status: "live", title: "Dated Recipe")

      conn_list = get(conn, "/api/v1/recipes")
      card = Enum.find(json_response(conn_list, 200)["data"], &(&1["id"] == recipe.id))
      assert card["created_at"] != nil

      conn_detail = get(conn, "/api/v1/recipes/#{recipe.id}")
      detail = json_response(conn_detail, 200)["data"]
      assert detail["created_at"] != nil
    end

    test "filters recipes by created_after and created_before", %{conn: conn} do
      old_r = insert(:recipe, status: "live", title: "June Recipe")
      new_r = insert(:recipe, status: "live", title: "September Recipe")

      from(r in Recipe, where: r.id == ^old_r.id)
      |> Repo.update_all(set: [inserted_at: ~U[2026-06-01 10:00:00Z]])

      from(r in Recipe, where: r.id == ^new_r.id)
      |> Repo.update_all(set: [inserted_at: ~U[2026-09-05 12:00:00Z]])

      conn_after = get(conn, "/api/v1/recipes?created_after=2026-09-01")
      data_after = json_response(conn_after, 200)["data"]
      assert Enum.any?(data_after, &(&1["id"] == new_r.id))
      refute Enum.any?(data_after, &(&1["id"] == old_r.id))

      conn_before = get(conn, "/api/v1/recipes?created_before=2026-07-01")
      data_before = json_response(conn_before, 200)["data"]
      assert Enum.any?(data_before, &(&1["id"] == old_r.id))
      refute Enum.any?(data_before, &(&1["id"] == new_r.id))
    end

    test "filters recipes by creation_date (exact day)", %{conn: conn} do
      target_r = insert(:recipe, status: "live", title: "Target Day Recipe")
      other_r = insert(:recipe, status: "live", title: "Other Day Recipe")

      from(r in Recipe, where: r.id == ^target_r.id)
      |> Repo.update_all(set: [inserted_at: ~U[2026-08-15 14:00:00Z]])

      from(r in Recipe, where: r.id == ^other_r.id)
      |> Repo.update_all(set: [inserted_at: ~U[2026-08-16 09:00:00Z]])

      conn_exact = get(conn, "/api/v1/recipes?creation_date=2026-08-15")
      data_exact = json_response(conn_exact, 200)["data"]
      assert Enum.any?(data_exact, &(&1["id"] == target_r.id))
      refute Enum.any?(data_exact, &(&1["id"] == other_r.id))
    end

    test "filters recipes by created_within preset", %{conn: conn} do
      recent_r = insert(:recipe, status: "live", title: "Recent Recipe")
      ancient_r = insert(:recipe, status: "live", title: "Ancient Recipe")

      from(r in Recipe, where: r.id == ^ancient_r.id)
      |> Repo.update_all(set: [inserted_at: ~U[2025-01-01 00:00:00Z]])

      conn_preset = get(conn, "/api/v1/recipes?created_within=last_7_days")
      data_preset = json_response(conn_preset, 200)["data"]
      assert Enum.any?(data_preset, &(&1["id"] == recent_r.id))
      refute Enum.any?(data_preset, &(&1["id"] == ancient_r.id))
    end
  end

  describe "structured fields for smart meal planner (Issue #124 & #97)" do
    test "recipe card and detail return all 11 structured fields", %{conn: conn} do
      recipe =
        insert(:recipe,
          status: "live",
          title: "Complete Meal Planner Recipe",
          cost: Decimal.new("12.50"),
          serving_size: 4,
          cook_time_mins: 25,
          prep_time_mins: 15,
          dish_category: "rice_dishes",
          dish_categories: ["rice_dishes"],
          meal: "lunch",
          course: "main",
          difficulty: "intermediate",
          cuisine_origin: ["west_african"],
          dietary_flags: ["gluten_free", "halal"],
          access_level: "premium",
          is_premium: true,
          is_special: true,
          ingredients: [%{"name" => "basmati rice", "quantity" => 500, "unit" => "g"}]
        )

      creator = CaramelKitchen.Repo.get!(CaramelKitchen.Accounts.User, recipe.creator_id)
      authed_conn = authenticate_conn(conn, creator)

      # 1. Card listing
      conn_list = get(conn, "/api/v1/recipes")
      card = Enum.find(json_response(conn_list, 200)["data"], &(&1["id"] == recipe.id))

      assert card != nil
      assert card["cost"] == "12.50" || card["cost"] == 12.5
      assert card["estimated_cost"] == "12.50" || card["estimated_cost"] == 12.5
      assert card["servings"] == 4
      assert card["serving_size"] == 4
      assert card["cooking_time"] == 25
      assert card["cooking_time_mins"] == 25
      assert card["prep_time_mins"] == 15
      assert card["total_time_mins"] == 40
      assert card["meal"] == "lunch"
      assert card["course"] == "main"
      assert card["category"] == "rice_dishes"
      assert "rice_dishes" in card["categories"]
      assert card["cuisine"] == "west_african"
      assert "west_african" in card["cuisines"]
      assert "gluten_free" in card["dietary_requirements"]
      assert "gluten_free" in card["dietary"]
      assert card["difficulty"] == "intermediate"
      assert card["access_level"] == "premium"
      assert card["is_premium"] == true
      assert card["is_special"] == true

      # 2. Detail view
      conn_detail = get(authed_conn, "/api/v1/recipes/#{recipe.id}")
      detail = json_response(conn_detail, 200)["data"]

      assert detail["servings"] == 4
      assert detail["cooking_time"] == 25
      assert detail["meal"] == "lunch"
      assert detail["access_level"] == "premium"
      assert length(detail["ingredients"]) == 1
    end

    test "filters by cost / budget and servings", %{conn: conn} do
      r1 = insert(:recipe, status: "live", cost: Decimal.new("6.00"), serving_size: 2)
      r2 = insert(:recipe, status: "live", cost: Decimal.new("18.00"), serving_size: 6)

      # Budget filter
      conn_budget = get(conn, "/api/v1/recipes?cost=10.00")
      ids_budget = Enum.map(json_response(conn_budget, 200)["data"], & &1["id"])
      assert r1.id in ids_budget
      refute r2.id in ids_budget

      # Servings filter
      conn_serv = get(conn, "/api/v1/recipes?servings=6")
      ids_serv = Enum.map(json_response(conn_serv, 200)["data"], & &1["id"])
      assert r2.id in ids_serv
      refute r1.id in ids_serv
    end

    test "filters by cooking_time and access_level", %{conn: conn} do
      r_fast_free =
        insert(:recipe,
          status: "live",
          cook_time_mins: 15,
          access_level: "free",
          is_premium: false,
          is_special: false
        )

      r_slow_prem =
        insert(:recipe,
          status: "live",
          cook_time_mins: 60,
          access_level: "premium",
          is_premium: true,
          is_special: true
        )

      conn_time = get(conn, "/api/v1/recipes?cooking_time=30")
      ids_time = Enum.map(json_response(conn_time, 200)["data"], & &1["id"])
      assert r_fast_free.id in ids_time
      refute r_slow_prem.id in ids_time

      conn_prem = get(conn, "/api/v1/recipes?access_level=premium")
      ids_prem = Enum.map(json_response(conn_prem, 200)["data"], & &1["id"])
      assert r_slow_prem.id in ids_prem
      refute r_fast_free.id in ids_prem
    end

    test "filters by ingredient and exclude_ingredients", %{conn: conn} do
      r_spinach =
        insert(:recipe,
          status: "live",
          ingredients: [%{"name" => "fresh spinach", "quantity" => 100, "unit" => "g"}]
        )

      r_mushrooms =
        insert(:recipe,
          status: "live",
          ingredients: [%{"name" => "button mushrooms", "quantity" => 150, "unit" => "g"}]
        )

      conn_spinach = get(conn, "/api/v1/recipes?ingredient=spinach")
      ids_spinach = Enum.map(json_response(conn_spinach, 200)["data"], & &1["id"])
      assert r_spinach.id in ids_spinach
      refute r_mushrooms.id in ids_spinach

      conn_no_spinach = get(conn, "/api/v1/recipes?exclude_ingredients=spinach")
      ids_no_spinach = Enum.map(json_response(conn_no_spinach, 200)["data"], & &1["id"])
      assert r_mushrooms.id in ids_no_spinach
      refute r_spinach.id in ids_no_spinach
    end
  end
end
