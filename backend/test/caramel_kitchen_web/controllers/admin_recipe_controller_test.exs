defmodule CaramelKitchenWeb.AdminRecipeControllerTest do
  use CaramelKitchenWeb.ConnCase, async: false

  describe "AdminRecipeController CRUD and structured fields (Issue #124 & #97)" do
    setup %{conn: conn} do
      admin = insert(:admin)
      authed_conn = authenticate_conn(conn, admin)
      {:ok, admin: admin, conn: authed_conn}
    end

    test "POST /api/v1/admin/recipes creates recipe with all 11 structured fields", %{conn: conn} do
      payload = %{
        "title" => "Chef Special Rice",
        "description" => "A high-end gourmet rice dish",
        "cost" => "19.99",
        "servings" => 4,
        "ingredients" => [
          %{"name" => "jasmine rice", "quantity" => 400, "unit" => "g"},
          %{"name" => "saffron", "quantity" => 1, "unit" => "pinch"}
        ],
        "steps" => [
          %{"order" => 1, "instruction" => "Soak saffron"},
          %{"order" => 2, "instruction" => "Cook rice with saffron water"}
        ],
        "meal" => "dinner",
        "course" => "main",
        "cuisine" => "persian",
        "dietary_requirements" => ["vegan", "gluten_free"],
        "cooking_time" => 35,
        "prep_time" => 15,
        "difficulty" => "advanced",
        "category" => "rice_dishes",
        "access_level" => "premium",
        "primary_method" => "steaming",
        "taste_tags" => ["savory", "mild"]
      }

      conn = post(conn, "/api/v1/admin/recipes", payload)
      assert %{"data" => recipe} = json_response(conn, 201)

      assert recipe["title"] == "Chef Special Rice"
      assert recipe["cost"] == "19.99" || recipe["cost"] == 19.99
      assert recipe["estimated_cost"] == "19.99" || recipe["estimated_cost"] == 19.99
      assert recipe["servings"] == 4
      assert recipe["serving_size"] == 4
      assert recipe["meal"] == "dinner"
      assert recipe["course"] == "main"
      assert recipe["cuisine"] == "persian"
      assert "persian" in recipe["cuisines"]
      assert "vegan" in recipe["dietary_requirements"]
      assert recipe["cooking_time"] == 35
      assert recipe["cooking_time_mins"] == 35
      assert recipe["prep_time_mins"] == 15
      assert recipe["total_time_mins"] == 50
      assert recipe["difficulty"] == "advanced"
      assert recipe["category"] == "rice_dishes"
      assert "rice_dishes" in recipe["categories"]
      assert recipe["access_level"] == "premium"
      assert recipe["is_premium"] == true
      assert recipe["is_special"] == true
      assert length(recipe["ingredients"]) == 2
      assert length(recipe["steps"]) == 2

      # Verify via GET /admin/recipes/:id
      conn_show = get(conn, "/api/v1/admin/recipes/#{recipe["id"]}")
      assert %{"data" => show_data} = json_response(conn_show, 200)
      assert show_data["cost"] == recipe["cost"]
      assert show_data["servings"] == 4
      assert show_data["meal"] == "dinner"
      assert show_data["access_level"] == "premium"
    end

    test "PUT /api/v1/admin/recipes/:id updates structured fields", %{conn: conn, admin: admin} do
      recipe =
        insert(:recipe,
          creator_id: admin.id,
          cost: Decimal.new("10.00"),
          serving_size: 2,
          access_level: "free",
          is_premium: false,
          is_special: false
        )

      update_payload = %{
        "cost" => "15.00",
        "servings" => 6,
        "access_level" => "premium",
        "meal" => "lunch"
      }

      conn_put = put(conn, "/api/v1/admin/recipes/#{recipe.id}", update_payload)
      assert %{"data" => updated} = json_response(conn_put, 200)

      assert updated["cost"] == "15.00" || updated["cost"] == 15.0
      assert updated["servings"] == 6
      assert updated["meal"] == "lunch"
      assert updated["access_level"] == "premium"
      assert updated["is_premium"] == true
      assert updated["is_special"] == true
    end

    test "GET /api/v1/admin/recipes returns list with structured fields", %{
      conn: conn,
      admin: admin
    } do
      insert(:recipe,
        creator_id: admin.id,
        cost: Decimal.new("8.00"),
        serving_size: 3,
        meal: "breakfast"
      )

      conn_list = get(conn, "/api/v1/admin/recipes")
      assert %{"data" => list} = json_response(conn_list, 200)
      assert length(list) >= 1
      first = List.first(list)
      assert Map.has_key?(first, "cost")
      assert Map.has_key?(first, "servings")
      assert Map.has_key?(first, "meal")
      assert Map.has_key?(first, "access_level")
    end
  end
end
