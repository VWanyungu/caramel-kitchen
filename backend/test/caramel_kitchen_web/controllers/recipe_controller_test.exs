defmodule CaramelKitchenWeb.RecipeControllerTest do
  use CaramelKitchenWeb.ConnCase, async: false

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
end
