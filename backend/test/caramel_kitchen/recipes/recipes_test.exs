defmodule CaramelKitchen.RecipesTest do
  use CaramelKitchen.DataCase, async: false

  alias CaramelKitchen.Recipes
  alias CaramelKitchen.Recipes.Recipe

  describe "create_recipe/2" do
    setup do
      {:ok, creator: insert(:creator)}
    end

    test "creates recipe with valid attributes", %{creator: creator} do
      attrs = %{
        "title" => "Jollof Rice",
        "description" => "Classic West African Jollof Rice",
        "ingredients" => [
          %{"name" => "rice", "quantity" => 400, "unit" => "g"},
          %{"name" => "tomato", "quantity" => 3, "unit" => "whole"}
        ],
        "steps" => [
          %{"order" => 1, "instruction" => "Blend tomatoes"},
          %{"order" => 2, "instruction" => "Fry tomato base"},
          %{"order" => 3, "instruction" => "Add rice and stock"}
        ],
        "dish_category" => "rice_dishes",
        "course" => "main",
        "primary_method" => "boiling",
        "taste_tags" => ["savory", "spicy"],
        "dietary_flags" => ["halal", "gluten_free"],
        "calories" => 380,
        "prep_time_mins" => 15,
        "cook_time_mins" => 45
      }

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(creator, attrs)
      assert recipe.title == "Jollof Rice"
      assert recipe.status == "draft"
      assert recipe.creator_id == creator.id
      assert recipe.taste_tags == ["savory", "spicy"]
      assert recipe.total_time_mins == 60
      # taste_profile should be computed
      assert not is_nil(recipe.taste_profile)
    end

    test "creates recipe with updated course, cooking_method, and taste_tags (issue #52)", %{
      creator: creator
    } do
      attrs = %{
        "title" => "Air Fried Wings",
        "description" => "Crispy air fried chicken wings",
        "ingredients" => [%{"name" => "chicken wings", "quantity" => 500, "unit" => "g"}],
        "steps" => [%{"order" => 1, "instruction" => "Air fry at 200C"}],
        "course" => "appetizer",
        "primary_method" => "air_frying",
        "taste_tags" => ["savory", "tangy", "umami"],
        "meal" => "snack"
      }

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(creator, attrs)
      assert recipe.course == "appetizer"
      assert recipe.primary_method == "air_frying"
      assert recipe.taste_tags == ["savory", "tangy", "umami"]
      assert recipe.meal == "snack"
    end

    test "rejects recipe without ingredients", %{creator: creator} do
      attrs = %{
        "title" => "Empty Recipe",
        "ingredients" => [],
        "steps" => [%{"order" => 1, "instruction" => "Do something"}],
        "primary_method" => "boiling",
        "taste_tags" => ["mild"]
      }

      assert {:error, changeset} = Recipes.create_recipe(creator, attrs)
      assert errors_on(changeset).ingredients != []
    end

    test "rejects recipe with invalid taste tags", %{creator: creator} do
      attrs = %{
        "title" => "Bad Tags Recipe",
        "ingredients" => [%{"name" => "salt", "quantity" => 1, "unit" => "tsp"}],
        "steps" => [%{"order" => 1, "instruction" => "Add salt"}],
        "primary_method" => "raw",
        "taste_tags" => ["not_a_valid_taste", "also_invalid"]
      }

      assert {:error, changeset} = Recipes.create_recipe(creator, attrs)
      assert errors_on(changeset).taste_tags != []
    end

    test "generates unique slug from title", %{creator: creator} do
      attrs = base_recipe_attrs()

      assert {:ok, recipe1} =
               Recipes.create_recipe(creator, Map.put(attrs, "title", "Pepper Soup"))

      assert {:ok, recipe2} =
               Recipes.create_recipe(creator, Map.put(attrs, "title", "Pepper Soup"))

      assert recipe1.slug != recipe2.slug
      assert String.starts_with?(recipe1.slug, "pepper-soup")
    end

    test "parses YouTube iframe snippet and normalizes video_url", %{creator: creator} do
      iframe_input =
        ~s(<iframe width="1337" height="752" src="https://www.youtube.com/embed/t4NSPbreDgE" title="Top Generals" frameborder="0" allowfullscreen></iframe>)

      attrs = Map.merge(base_recipe_attrs(), %{"video_url" => iframe_input})

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(creator, attrs)
      assert recipe.video_url == "https://www.youtube.com/watch?v=t4NSPbreDgE"

      parsed = Recipe.parse_youtube_video(recipe.video_url)
      assert parsed.youtube_id == "t4NSPbreDgE"
      assert parsed.video_embed_url == "https://www.youtube.com/embed/t4NSPbreDgE"
      assert String.contains?(parsed.iframe_html, "https://www.youtube.com/embed/t4NSPbreDgE")
    end
  end

  describe "update_recipe/2" do
    setup do
      recipe = insert(:recipe)
      {:ok, recipe: recipe}
    end

    test "updates recipe attributes", %{recipe: recipe} do
      assert {:ok, updated} = Recipes.update_recipe(recipe, %{"title" => "Updated Title"})
      assert updated.title == "Updated Title"
    end

    test "cannot update with empty steps", %{recipe: recipe} do
      assert {:error, changeset} = Recipes.update_recipe(recipe, %{"steps" => []})
      assert errors_on(changeset).steps != []
    end
  end

  describe "publish_recipe/1" do
    test "publishes a draft recipe" do
      recipe = insert(:draft_recipe)
      assert {:ok, published} = Recipes.publish_recipe(recipe)
      assert published.status == "live"
      assert not is_nil(published.published_at)
    end
  end

  describe "category_counts/0" do
    test "returns counts per dish category including multi-category recipes" do
      insert(:recipe, dish_categories: ["meat_dishes", "rice_dishes"])
      insert(:recipe, dish_categories: ["meat_dishes"])
      insert(:recipe, dish_categories: ["rice_dishes"])

      counts = Recipes.category_counts()
      assert is_map(counts)
      assert Map.get(counts, "meat_dishes") >= 2
      assert Map.get(counts, "rice_dishes") >= 2
    end
  end

  describe "list_by_category/2" do
    test "returns recipes matching a category in multi-category list" do
      insert(:recipe, status: "live", dish_categories: ["breakfast", "egg_dishes"])
      insert(:recipe, status: "live", dish_categories: ["dinner", "meat_dishes"])

      results = Recipes.list_by_category("breakfast")
      assert Enum.all?(results, fn r -> "breakfast" in r.dish_categories end)
    end
  end

  describe "search/2" do
    test "finds recipes by title" do
      insert(:recipe, title: "Egusi Soup Special", status: "live")
      insert(:recipe, title: "Jollof Rice Deluxe", status: "live")

      results = Recipes.search("Egusi")
      titles = Enum.map(results, fn %{recipe: r} -> r.title end)
      assert Enum.any?(titles, &String.contains?(&1, "Egusi"))
    end
  end

  describe "filter system" do
    setup do
      insert(:recipe,
        primary_method: "grilling",
        dietary_flags: ["halal"],
        taste_tags: ["savory"],
        total_time_mins: 20,
        status: "live"
      )

      insert(:recipe,
        primary_method: "boiling",
        dietary_flags: ["vegan"],
        taste_tags: ["mild"],
        total_time_mins: 60,
        status: "live"
      )

      insert(:recipe,
        primary_method: "frying",
        dietary_flags: ["halal", "gluten_free"],
        taste_tags: ["spicy"],
        total_time_mins: 15,
        status: "live"
      )

      :ok
    end

    test "filters by cooking method" do
      user = insert(:premium_user)
      results = Recipes.personalised_feed(user, filters: %{cooking_method: "grilling"})
      methods = Enum.map(results, fn %{recipe: r} -> r.primary_method end)
      assert Enum.all?(methods, &(&1 == "grilling"))
    end

    test "filters by dietary flags" do
      user = insert(:premium_user)
      results = Recipes.personalised_feed(user, filters: %{dietary: ["vegan"]})
      flags = Enum.map(results, fn %{recipe: r} -> r.dietary_flags end)
      assert Enum.all?(flags, &("vegan" in &1))
    end

    test "filters by max time" do
      user = insert(:premium_user)
      results = Recipes.personalised_feed(user, filters: %{max_time: 25}, limit: 50)
      times = Enum.map(results, fn %{recipe: r} -> r.total_time_mins end)
      assert Enum.all?(times, &(&1 <= 25))
    end

    test "filters by creation date: created_after and created_before" do
      old_recipe = insert(:recipe, status: "live", title: "Ancient Recipe")
      new_recipe = insert(:recipe, status: "live", title: "Modern Recipe")

      from(r in Recipe, where: r.id == ^old_recipe.id)
      |> Repo.update_all(set: [inserted_at: ~U[2026-08-01 00:00:00Z]])

      from(r in Recipe, where: r.id == ^new_recipe.id)
      |> Repo.update_all(set: [inserted_at: ~U[2026-09-05 12:00:00Z]])

      after_results =
        Recipes.list_by_category("all",
          filters: %{created_after: ~U[2026-09-01 00:00:00Z]}
        )

      after_ids = Enum.map(after_results, & &1.id)
      assert new_recipe.id in after_ids
      refute old_recipe.id in after_ids

      before_results =
        Recipes.list_by_category("all",
          filters: %{created_before: ~U[2026-08-15 23:59:59Z]}
        )

      before_ids = Enum.map(before_results, & &1.id)
      assert old_recipe.id in before_ids
      refute new_recipe.id in before_ids
    end

    test "filters by exact creation date range" do
      target_recipe = insert(:recipe, status: "live", title: "Exact Day Recipe")
      other_recipe = insert(:recipe, status: "live", title: "Other Day Recipe")

      from(r in Recipe, where: r.id == ^target_recipe.id)
      |> Repo.update_all(set: [inserted_at: ~U[2026-08-20 14:30:00Z]])

      from(r in Recipe, where: r.id == ^other_recipe.id)
      |> Repo.update_all(set: [inserted_at: ~U[2026-08-21 01:00:00Z]])

      results =
        Recipes.list_by_category("all",
          filters: %{
            creation_date: {~U[2026-08-20 00:00:00Z], ~U[2026-08-20 23:59:59Z]}
          }
        )

      ids = Enum.map(results, & &1.id)
      assert target_recipe.id in ids
      refute other_recipe.id in ids
    end

    test "orders by creation date newest and oldest" do
      r1 = insert(:recipe, status: "live")
      r2 = insert(:recipe, status: "live")

      from(r in Recipe, where: r.id == ^r1.id)
      |> Repo.update_all(set: [inserted_at: ~U[2026-07-01 00:00:00Z]])

      from(r in Recipe, where: r.id == ^r2.id)
      |> Repo.update_all(set: [inserted_at: ~U[2026-09-01 00:00:00Z]])

      newest = Recipes.list_by_category("all", sort: "newest")
      oldest = Recipes.list_by_category("all", sort: "oldest")

      newest_idx_r2 = Enum.find_index(newest, &(&1.id == r2.id))
      newest_idx_r1 = Enum.find_index(newest, &(&1.id == r1.id))
      assert newest_idx_r2 < newest_idx_r1

      oldest_idx_r1 = Enum.find_index(oldest, &(&1.id == r1.id))
      oldest_idx_r2 = Enum.find_index(oldest, &(&1.id == r2.id))
      assert oldest_idx_r1 < oldest_idx_r2
    end

    test "list_creator_recipes filters by creation date" do
      creator = insert(:creator)
      old_r = insert(:recipe, creator_id: creator.id, status: "live")
      new_r = insert(:recipe, creator_id: creator.id, status: "live")

      from(r in Recipe, where: r.id == ^old_r.id)
      |> Repo.update_all(set: [inserted_at: ~U[2026-08-01 00:00:00Z]])

      from(r in Recipe, where: r.id == ^new_r.id)
      |> Repo.update_all(set: [inserted_at: ~U[2026-09-05 00:00:00Z]])

      filtered =
        Recipes.list_creator_recipes(creator.id,
          filters: %{created_after: ~U[2026-09-01 00:00:00Z]}
        )

      ids = Enum.map(filtered, & &1.id)
      assert new_r.id in ids
      refute old_r.id in ids
    end
  end

  describe "structured fields for smart meal planner (Issue #124 & #97)" do
    setup do
      {:ok, creator: insert(:creator)}
    end

    test "creates recipe with all 11 structured fields and alias normalization", %{
      creator: creator
    } do
      attrs = %{
        "title" => "Budget Pasta Bowl",
        "description" => "Cheap, nutritious, and delicious",
        "cost" => "8.50",
        "servings" => 4,
        "ingredients" => [
          %{"name" => "penne pasta", "quantity" => 300, "unit" => "g"},
          %{"name" => "garlic", "quantity" => 2, "unit" => "cloves"}
        ],
        "steps" => [
          %{"order" => 1, "instruction" => "Boil pasta"},
          %{"order" => 2, "instruction" => "Saute garlic and toss"}
        ],
        "meal" => "dinner",
        "course" => "main",
        "cuisine" => "italian",
        "dietary_requirements" => ["vegetarian"],
        "cooking_time" => 20,
        "prep_time" => 10,
        "difficulty" => "intermediate",
        "category" => "pasta_noodles",
        "access_level" => "premium",
        "primary_method" => "boiling",
        "taste_tags" => ["savory", "mild"]
      }

      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(creator, attrs)
      assert Decimal.equal?(recipe.cost, Decimal.new("8.50"))
      assert recipe.serving_size == 4
      assert recipe.meal == "dinner"
      assert recipe.course == "main"
      assert recipe.cuisine_origin == ["italian"]
      assert "vegetarian" in recipe.dietary_flags
      assert recipe.cook_time_mins == 20
      assert recipe.prep_time_mins == 10
      assert recipe.total_time_mins == 30
      assert recipe.difficulty == "intermediate"
      assert "pasta_noodles" in recipe.dish_categories
      assert recipe.access_level == "premium"
      assert recipe.is_premium == true
      assert recipe.is_special == true
    end

    test "syncs access_level, is_premium, and is_special in updates", %{creator: creator} do
      recipe =
        insert(:recipe,
          creator_id: creator.id,
          access_level: "free",
          is_premium: false,
          is_special: false
        )

      assert {:ok, updated} = Recipes.update_recipe(recipe, %{"access_level" => "premium"})
      assert updated.access_level == "premium"
      assert updated.is_premium == true
      assert updated.is_special == true

      assert {:ok, demoted} = Recipes.update_recipe(updated, %{"is_premium" => false})
      assert demoted.access_level == "free"
      assert demoted.is_premium == false
      assert demoted.is_special == false
    end

    test "filters recipes by budget / max_cost and min_cost" do
      cheap = insert(:recipe, status: "live", cost: Decimal.new("5.00"))
      expensive = insert(:recipe, status: "live", cost: Decimal.new("25.00"))

      filtered_budget = Recipes.list_by_category("all", filters: %{budget: Decimal.new("10.00")})
      ids_budget = Enum.map(filtered_budget, & &1.id)
      assert cheap.id in ids_budget
      refute expensive.id in ids_budget

      filtered_min = Recipes.list_by_category("all", filters: %{min_cost: Decimal.new("15.00")})
      ids_min = Enum.map(filtered_min, & &1.id)
      assert expensive.id in ids_min
      refute cheap.id in ids_min
    end

    test "filters recipes by servings / serving_size" do
      single = insert(:recipe, status: "live", serving_size: 1)
      family = insert(:recipe, status: "live", serving_size: 6)

      res_exact = Recipes.list_by_category("all", filters: %{servings: 6})
      ids_exact = Enum.map(res_exact, & &1.id)
      assert family.id in ids_exact
      refute single.id in ids_exact

      res_min = Recipes.list_by_category("all", filters: %{min_servings: 4})
      ids_min = Enum.map(res_min, & &1.id)
      assert family.id in ids_min
      refute single.id in ids_min
    end

    test "filters recipes by ingredient and exclude_ingredients" do
      with_chicken =
        insert(:recipe,
          status: "live",
          ingredients: [%{"name" => "chicken breast", "quantity" => 200, "unit" => "g"}]
        )

      with_tofu =
        insert(:recipe,
          status: "live",
          ingredients: [%{"name" => "firm tofu", "quantity" => 250, "unit" => "g"}]
        )

      res_inc = Recipes.list_by_category("all", filters: %{ingredient: "chicken"})
      ids_inc = Enum.map(res_inc, & &1.id)
      assert with_chicken.id in ids_inc
      refute with_tofu.id in ids_inc

      res_exc = Recipes.list_by_category("all", filters: %{exclude_ingredients: ["chicken"]})
      ids_exc = Enum.map(res_exc, & &1.id)
      assert with_tofu.id in ids_exc
      refute with_chicken.id in ids_exc
    end

    test "filters recipes by cooking_time / cook_time_mins" do
      fast = insert(:recipe, status: "live", cook_time_mins: 15)
      slow = insert(:recipe, status: "live", cook_time_mins: 60)

      res = Recipes.list_by_category("all", filters: %{cooking_time: 30})
      ids = Enum.map(res, & &1.id)
      assert fast.id in ids
      refute slow.id in ids
    end

    test "filters recipes by access_level" do
      free_r =
        insert(:recipe,
          status: "live",
          access_level: "free",
          is_premium: false,
          is_special: false
        )

      prem_r =
        insert(:recipe,
          status: "live",
          access_level: "premium",
          is_premium: true,
          is_special: true
        )

      res_free = Recipes.list_by_category("all", filters: %{access_level: "free"})
      ids_free = Enum.map(res_free, & &1.id)
      assert free_r.id in ids_free
      refute prem_r.id in ids_free

      res_prem = Recipes.list_by_category("all", filters: %{access_level: "premium"})
      ids_prem = Enum.map(res_prem, & &1.id)
      assert prem_r.id in ids_prem
      refute free_r.id in ids_prem
    end

    test "has_recipe_access?/2 respects free vs premium access" do
      creator = insert(:creator)
      user = insert(:user, role: "user")
      premium_user = insert(:user, role: "user", subscription_tier: "premium")
      admin_user = insert(:admin)

      free_recipe = insert(:recipe, access_level: "free", is_premium: false, is_special: false)

      prem_recipe =
        insert(:recipe,
          creator_id: creator.id,
          access_level: "premium",
          is_premium: true,
          is_special: true
        )

      assert Recipes.has_recipe_access?(free_recipe, nil) == true
      assert Recipes.has_recipe_access?(free_recipe, user) == true

      assert Recipes.has_recipe_access?(prem_recipe, nil) == false
      assert Recipes.has_recipe_access?(prem_recipe, user) == false
      assert Recipes.has_recipe_access?(prem_recipe, premium_user) == true
      assert Recipes.has_recipe_access?(prem_recipe, admin_user) == true
      assert Recipes.has_recipe_access?(prem_recipe, creator) == true
    end
  end

  # ── Helpers ───────────────────────────────────────────────────

  defp base_recipe_attrs do
    %{
      "title" => "Test Recipe",
      "ingredients" => [%{"name" => "egg", "quantity" => 2, "unit" => "whole"}],
      "steps" => [%{"order" => 1, "instruction" => "Boil eggs"}],
      "primary_method" => "boiling",
      "taste_tags" => ["mild"]
    }
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(Regex.compile!("%{(\\w+)}"), msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
