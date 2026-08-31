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

    test "creates recipe with updated course, cooking_method, and taste_tags (issue #52)", %{creator: creator} do
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
