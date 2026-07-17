defmodule CaramelKitchen.Seeds do
  @moduledoc "Seeds the database with initial data for Phase 0."
  alias CaramelKitchen.{Repo, Accounts, Recipes}

  def run do
    IO.puts("🌱 Seeding Caramel Kitchen database...")

    # ── Admin / Creator user ──────────────────────────────────
    creator = case Accounts.register_user(%{
      "email"                 => "creator@caramelkitchen.app",
      "password"              => System.get_env("SEED_CREATOR_PASSWORD", "ChangeMeInProd1"),
      "password_confirmation" => System.get_env("SEED_CREATOR_PASSWORD", "ChangeMeInProd1"),
      "name"                  => "Caramel Kitchen"
    }) do
      {:ok, user} -> user
      {:error, _changeset} -> CaramelKitchen.Repo.get_by!(CaramelKitchen.Accounts.User, email: "creator@caramelkitchen.app")
    end

    Repo.update!(Ecto.Changeset.change(creator, %{
      role:              "creator",
      subscription_tier: "creator_pro",
      email_verified:    true
    }))

    IO.puts("✅ Creator account: #{creator.email}")

    # ── Sample Recipes ────────────────────────────────────────
    recipes = [
      %{
        title:          "Classic Jollof Rice",
        description:    "The iconic West African one-pot rice dish, smoky and richly spiced.",
        ingredients:    [
          %{name: "long grain rice",     quantity: 400, unit: "g"},
          %{name: "plum tomatoes",       quantity: 4,   unit: "whole"},
          %{name: "scotch bonnet",       quantity: 2,   unit: "whole"},
          %{name: "tomato puree",        quantity: 3,   unit: "tbsp"},
          %{name: "chicken stock",       quantity: 500, unit: "ml"},
          %{name: "onion",               quantity: 1,   unit: "large"},
          %{name: "vegetable oil",       quantity: 4,   unit: "tbsp"},
          %{name: "bay leaves",          quantity: 2,   unit: "whole"},
          %{name: "curry powder",        quantity: 1,   unit: "tsp"},
          %{name: "salt",                quantity: 1,   unit: "tsp"}
        ],
        steps: [
          %{order: 1, instruction: "Blend tomatoes, scotch bonnet and half the onion until smooth."},
          %{order: 2, instruction: "Heat oil in a heavy-based pot. Fry remaining diced onion for 5 minutes."},
          %{order: 3, instruction: "Add tomato puree and fry for 3 minutes, stirring constantly."},
          %{order: 4, instruction: "Add blended tomato mixture. Cook on medium heat for 20 minutes, stirring often."},
          %{order: 5, instruction: "Add stock, bay leaves, curry powder and salt. Bring to a boil."},
          %{order: 6, instruction: "Wash rice and add to pot. Stir once, reduce to low heat."},
          %{order: 7, instruction: "Cover tightly with foil then lid. Cook for 30 minutes without lifting lid."},
          %{order: 8, instruction: "Remove foil, fluff rice gently and serve hot."}
        ],
        dish_category:  "rice_dishes",
        course:         "main",
        primary_method: "boiling",
        difficulty:     "intermediate",
        cuisine_origin: ["west_african", "nigerian"],
        prep_time_mins: 20,
        cook_time_mins: 55,
        taste_tags:     ["savory", "spicy", "tangy"],
        dietary_flags:  ["halal", "dairy_free", "gluten_free"],
        allergens:      [],
        calories:       380,
        macros:         %{protein_g: 8, carbs_g: 72, fat_g: 9, fibre_g: 3},
        serving_size:   4,
        status:         "live"
      },
      %{
        title:          "Shakshuka with Feta",
        description:    "Eggs poached in a spiced tomato and pepper sauce, topped with creamy feta.",
        ingredients:    [
          %{name: "eggs",               quantity: 4,   unit: "whole"},
          %{name: "canned tomatoes",    quantity: 400, unit: "g"},
          %{name: "red pepper",         quantity: 1,   unit: "whole"},
          %{name: "onion",              quantity: 1,   unit: "medium"},
          %{name: "garlic cloves",      quantity: 3,   unit: "whole"},
          %{name: "cumin",              quantity: 1,   unit: "tsp"},
          %{name: "paprika",            quantity: 1,   unit: "tsp"},
          %{name: "chilli flakes",      quantity: 0.5, unit: "tsp"},
          %{name: "feta cheese",        quantity: 80,  unit: "g"},
          %{name: "olive oil",          quantity: 2,   unit: "tbsp"},
          %{name: "fresh coriander",    quantity: 1,   unit: "handful"}
        ],
        steps: [
          %{order: 1, instruction: "Dice onion and pepper. Mince garlic."},
          %{order: 2, instruction: "Heat olive oil in a wide pan. Sauté onion and pepper for 8 minutes."},
          %{order: 3, instruction: "Add garlic, cumin, paprika and chilli flakes. Cook 1 minute."},
          %{order: 4, instruction: "Pour in tomatoes. Season and simmer 10 minutes until thickened."},
          %{order: 5, instruction: "Make 4 wells in the sauce. Crack an egg into each well."},
          %{order: 6, instruction: "Cover and cook 5-7 minutes until whites are set but yolks remain runny."},
          %{order: 7, instruction: "Crumble feta over the top. Garnish with fresh coriander. Serve immediately."}
        ],
        dish_category:  "egg_dishes",
        course:         "main",
        primary_method: "sauteing",
        difficulty:     "beginner",
        cuisine_origin: ["middle_eastern", "mediterranean"],
        prep_time_mins: 10,
        cook_time_mins: 25,
        taste_tags:     ["spicy", "savory", "tangy"],
        dietary_flags:  ["vegetarian", "gluten_free", "halal"],
        allergens:      ["eggs", "dairy"],
        calories:       310,
        macros:         %{protein_g: 18, carbs_g: 14, fat_g: 20, fibre_g: 4},
        serving_size:   2,
        status:         "live"
      }
    ]

    generated_recipes = Enum.map(3..30, fn i ->
      %{
        title:          "Generated Recipe #{i}",
        description:    "A delicious auto-generated recipe to fill the database.",
        ingredients:    [
          %{name: "Ingredient 1", quantity: Enum.random(100..500), unit: "g"},
          %{name: "Ingredient 2", quantity: Enum.random(1..3), unit: "tbsp"}
        ],
        steps: [
          %{order: 1, instruction: "Prepare the ingredients."},
          %{order: 2, instruction: "Cook them using the primary method."},
          %{order: 3, instruction: "Serve hot and enjoy."}
        ],
        dish_category:  Enum.random(["rice_dishes", "egg_dishes", "soups_stews", "meat_dishes", "baked_goods", "fish_seafood", "salads", "pasta_noodles", "breakfast", "snacks", "vegetarian"]),
        course:         Enum.random(["main", "starter", "dessert", "soup", "salad", "pre_starter", "after_meal"]),
        primary_method: Enum.random(["boiling", "sauteing", "baking", "frying", "roasting", "grilling", "steaming", "braising", "stir_frying"]),
        difficulty:     Enum.random(["beginner", "intermediate", "advanced"]),
        cuisine_origin: ["global"],
        prep_time_mins: Enum.random(5..30),
        cook_time_mins: Enum.random(10..90),
        taste_tags:     Enum.take_random(["savory", "spicy", "tangy", "sweet", "umami", "mild", "bitter", "sour"], 3),
        dietary_flags:  Enum.take_random(["halal", "dairy_free", "gluten_free", "vegetarian", "vegan", "keto"], 2),
        allergens:      [],
        calories:       Enum.random(200..800),
        macros:         %{
          protein_g: Enum.random(5..50),
          carbs_g: Enum.random(10..80),
          fat_g: Enum.random(5..30),
          fibre_g: Enum.random(1..15)
        },
        serving_size:   Enum.random(1..6),
        status:         "live"
      }
    end)

    all_recipes = recipes ++ generated_recipes

    Enum.each(all_recipes, fn attrs ->
      str_attrs = Map.new(attrs, fn {k, v} ->
        str_key = to_string(k)
        str_val = cond do
          is_list(v) and length(v) > 0 and is_map(hd(v)) ->
            Enum.map(v, &Map.new(&1, fn {ik, iv} -> {to_string(ik), iv} end))
          true ->
            v
        end
        {str_key, str_val}
      end)

      try do
        case Recipes.create_recipe(creator, str_attrs) do
          {:ok, recipe} ->
            Recipes.publish_recipe(recipe)
            IO.puts("✅ Seeded recipe: #{recipe.title}")
          {:error, cs} ->
            IO.puts("⏭️  Skipped: #{str_attrs["title"]} — #{inspect(cs.errors)}")
        end
      rescue
        e ->
          IO.puts("⏭️  Skipped: #{str_attrs["title"]} — #{Exception.message(e)}")
      end
    end)

    IO.puts("\n🎉 Seeding complete!")
    IO.puts("   Creator login: creator@caramelkitchen.app")
    IO.puts("   Remember to change the password in production!")
  end
end

CaramelKitchen.Seeds.run()
