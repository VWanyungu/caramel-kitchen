defmodule CaramelKitchen.TasteEngine.VectorUpdaterTest do
  use CaramelKitchen.DataCase, async: false

  alias CaramelKitchen.TasteEngine.VectorUpdater
  alias CaramelKitchen.{Accounts, Repo}
  alias CaramelKitchen.Accounts.User

  describe "enqueue/3 and flush" do
    test "buffers events and applies delta on flush" do
      user   = insert(:user, taste_vector: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5])
      recipe = insert(:recipe, taste_profile: [0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0])

      VectorUpdater.enqueue(user.id, recipe.id, :cooked)

      # Wait for flush (2s interval + buffer)
      Process.sleep(2_500)

      updated = Repo.get!(User, user.id)
      vec     = User.taste_vector_list(updated)

      # spicy (index 3) and savory (index 4) should increase
      assert Enum.at(vec, 3) > 0.5
      assert Enum.at(vec, 4) > 0.5
      # sour (index 0) should be unchanged
      assert Enum.at(vec, 0) == 0.5
    end

    test "clamps vector values to [0.0, 1.0]" do
      user   = insert(:user, taste_vector: [0.99, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5])
      recipe = insert(:recipe, taste_profile: [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])

      VectorUpdater.enqueue(user.id, recipe.id, :rated_5)
      Process.sleep(2_500)

      updated = Repo.get!(User, user.id)
      vec     = User.taste_vector_list(updated)
      assert Enum.at(vec, 0) == 1.0
    end
  end
end

defmodule CaramelKitchen.ShoppingTest do
  use CaramelKitchen.DataCase, async: true

  alias CaramelKitchen.Shopping

  describe "auto_generate_from_plan/2" do
    test "generates a list with merged ingredients" do
      user    = insert(:premium_user)
      recipe1 = insert(:recipe, ingredients: [
        %{"name" => "chicken", "quantity" => 500, "unit" => "g"},
        %{"name" => "garlic",  "quantity" => 3,   "unit" => "cloves"}
      ], serving_size: 2)
      recipe2 = insert(:recipe, ingredients: [
        %{"name" => "chicken", "quantity" => 300, "unit" => "g"},
        %{"name" => "onion",   "quantity" => 1,   "unit" => "whole"}
      ], serving_size: 2)

      plan = insert(:meal_plan,
        user_id: user.id,
        days: [
          %{"date_offset" => 0, "meals" => [
            %{"slot" => "lunch",  "recipe_id" => recipe1.id, "servings" => 2},
            %{"slot" => "dinner", "recipe_id" => recipe2.id, "servings" => 2}
          ]}
        ]
      )

      {:ok, list} = Shopping.auto_generate_from_plan(plan.id, user.id)

      assert is_list(list.items)
      assert length(list.items) >= 3

      # chicken should be merged: (500/2)*2 + (300/2)*2 = 800g
      chicken = Enum.find(list.items, &(String.downcase(&1["name"]) == "chicken"))
      assert chicken != nil
      assert chicken["quantity"] == 800.0 or chicken["quantity"] == 800
    end

    test "generates a share token" do
      user = insert(:premium_user)
      plan = insert(:meal_plan, user_id: user.id, days: [])

      {:ok, list} = Shopping.auto_generate_from_plan(plan.id, user.id)
      assert is_binary(list.share_token)
      assert String.length(list.share_token) > 0
    end
  end

  describe "whatsapp_share_url/1" do
    test "returns a valid WhatsApp URL" do
      user = insert(:user)
      plan = insert(:meal_plan, user_id: user.id, days: [])
      {:ok, list} = Shopping.create_list(user.id, %{
        name:  "Test List",
        items: [%{"name" => "eggs", "quantity" => 6, "unit" => "whole", "category" => "protein", "checked" => false}]
      })

      url = Shopping.whatsapp_share_url(list)
      assert String.starts_with?(url, "https://wa.me/")
      assert String.contains?(url, list.share_token)
    end
  end

  describe "check_item/3 and uncheck_item/3" do
    test "checks and unchecks items" do
      user = insert(:user)
      {:ok, list} = Shopping.create_list(user.id, %{
        name:  "Groceries",
        items: [%{"name" => "milk", "quantity" => 1, "unit" => "litre", "category" => "dairy", "checked" => false}]
      })

      {:ok, checked} = Shopping.check_item(list.id, 0, user.id)
      assert 0 in checked.checked_ids

      {:ok, unchecked} = Shopping.uncheck_item(list.id, 0, user.id)
      assert 0 not in unchecked.checked_ids
    end

    test "rejects check from wrong user" do
      user1 = insert(:user)
      user2 = insert(:user)
      {:ok, list} = Shopping.create_list(user1.id, %{
        name: "Private", items: []
      })

      assert {:error, :unauthorized} = Shopping.check_item(list.id, 0, user2.id)
    end
  end
end

defmodule CaramelKitchenWeb.AdminRecipeControllerTest do
  use CaramelKitchenWeb.ConnCase, async: true

  describe "POST /api/v1/admin/recipes" do
    setup %{conn: conn} do
      creator = insert(:creator)
      {:ok, conn: authenticate_conn(conn, creator), creator: creator}
    end

    test "creates a recipe successfully", %{conn: conn} do
      params = %{
        title:          "Pepper Soup",
        description:    "Spicy West African pepper soup",
        ingredients:    [
          %{name: "goat meat", quantity: 500, unit: "g"},
          %{name: "uziza leaves", quantity: 1, unit: "handful"}
        ],
        steps: [
          %{order: 1, instruction: "Season meat and set aside"},
          %{order: 2, instruction: "Cook meat with spices until tender"},
          %{order: 3, instruction: "Add pepper soup spice mix and simmer 15 minutes"}
        ],
        dish_category:  "soups_stews",
        course:         "soup",
        primary_method: "boiling",
        difficulty:     "beginner",
        taste_tags:     ["spicy", "savory", "umami"],
        dietary_flags:  ["halal", "gluten_free"],
        calories:       280,
        prep_time_mins: 15,
        cook_time_mins: 45
      }

      conn = post(conn, "/api/v1/admin/recipes", params)
      body = json_response(conn, 201)

      assert body["data"]["title"]    == "Pepper Soup"
      assert body["data"]["status"]   == "draft"
      assert body["data"]["taste_tags"] == ["spicy", "savory", "umami"]
    end

    test "returns 403 for non-creator user", %{conn: _} do
      regular_user = insert(:user)
      conn = build_conn() |> authenticate_conn(regular_user)
      conn = post(conn, "/api/v1/admin/recipes", %{title: "Test"})
      assert json_response(conn, 403)["error"] == "forbidden"
    end

    test "rejects recipe with too many taste tags", %{conn: conn} do
      params = %{
        title:          "Over-tagged Recipe",
        ingredients:    [%{name: "salt", quantity: 1, unit: "tsp"}],
        steps:          [%{order: 1, instruction: "Add salt"}],
        primary_method: "raw",
        taste_tags:     ["spicy", "savory", "sweet", "sour", "bitter"]  # 5 tags — max is 4
      }

      conn = post(conn, "/api/v1/admin/recipes", params)
      assert json_response(conn, 422)["error"] == "validation_error"
    end
  end

  describe "POST /api/v1/admin/recipes/:id/publish" do
    setup %{conn: conn} do
      creator = insert(:creator)
      {:ok, conn: authenticate_conn(conn, creator), creator: creator}
    end

    test "blocks publish when no video attached", %{conn: conn, creator: creator} do
      recipe = insert(:draft_recipe, creator_id: creator.id,
                      taste_tags: ["spicy"], video_url: nil)
      conn = post(conn, "/api/v1/admin/recipes/#{recipe.id}/publish")
      body = json_response(conn, 422)
      assert body["error"] == "video_required"
    end

    test "blocks publish when no taste tags", %{conn: conn, creator: creator} do
      recipe = insert(:draft_recipe, creator_id: creator.id,
                      taste_tags: [], video_url: "https://cdn.example.com/v.mp4")
      conn = post(conn, "/api/v1/admin/recipes/#{recipe.id}/publish")
      body = json_response(conn, 422)
      assert body["error"] == "taste_tags_required"
    end
  end
end

defmodule CaramelKitchenWeb.ShoppingControllerTest do
  use CaramelKitchenWeb.ConnCase, async: true

  describe "GET /api/v1/shopping/shared/:token" do
    test "returns shared list by token without auth", %{conn: conn} do
      user = insert(:user)
      {:ok, list} = CaramelKitchen.Shopping.create_list(user.id, %{
        name:  "Shared Groceries",
        items: [%{"name" => "bread", "quantity" => 1, "unit" => "loaf",
                  "category" => "grains", "checked" => false}]
      })

      conn = get(conn, "/api/v1/shopping/shared/#{list.share_token}")
      body = json_response(conn, 200)
      assert body["data"]["name"]    == "Shared Groceries"
      assert length(body["data"]["items"]) == 1
    end

    test "returns 404 for invalid token", %{conn: conn} do
      conn = get(conn, "/api/v1/shopping/shared/definitely_not_a_real_token")
      assert json_response(conn, 404)
    end
  end
end
