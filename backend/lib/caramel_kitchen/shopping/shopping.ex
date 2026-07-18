defmodule CaramelKitchen.Shopping do
  @moduledoc "Shopping list context — auto-generation from meal plans and course menus."

  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Shopping.ShoppingList
  alias CaramelKitchen.Recipes
  alias CaramelKitchen.MealPlans

  @grocery_categories %{
    "produce" => ~w(vegetable fruit herb lettuce tomato onion garlic pepper),
    "protein" => ~w(chicken beef lamb fish prawn egg tofu legume bean lentil),
    "dairy" => ~w(milk cheese butter yoghurt cream),
    "grains" => ~w(rice pasta flour bread oat noodle),
    "pantry" => ~w(oil salt sugar spice sauce stock vinegar),
    "frozen" => ~w(frozen),
    "drinks" => ~w(water juice milk tea coffee)
  }

  # ── Auto-generate from meal plan ──────────────────────────────

  def auto_generate_from_plan(meal_plan_id, user_id, opts \\ []) do
    meal_plan = MealPlans.get_plan!(meal_plan_id)
    servings_mul = Keyword.get(opts, :servings_multiplier, 1.0)

    recipe_ids =
      meal_plan.days
      |> Enum.flat_map(fn day -> Enum.map(day["meals"], & &1["recipe_id"]) end)
      |> Enum.uniq()
      |> Enum.reject(&is_nil/1)

    recipes = Enum.map(recipe_ids, &Recipes.get_recipe!/1)

    items = aggregate_ingredients(recipes, servings_mul, meal_plan.days)

    %ShoppingList{}
    |> Ecto.Changeset.cast(
      %{
        user_id: user_id,
        meal_plan_id: meal_plan_id,
        name: "Shopping — #{meal_plan.name}",
        items: items,
        servings_multiplier: servings_mul,
        share_token: generate_share_token()
      },
      [:user_id, :meal_plan_id, :name, :items, :servings_multiplier, :share_token]
    )
    |> Repo.insert()
  end

  # ── CRUD ──────────────────────────────────────────────────────

  def get_list(id), do: Repo.fetch(from l in ShoppingList, where: l.id == ^id)

  def get_list_by_token(token) do
    Repo.fetch(from l in ShoppingList, where: l.share_token == ^token)
  end

  def list_user_lists(user_id) do
    from(l in ShoppingList,
      where: l.user_id == ^user_id,
      order_by: [desc: l.inserted_at],
      limit: 20
    )
    |> Repo.all()
  end

  def create_list(user_id, attrs) do
    %ShoppingList{}
    |> Ecto.Changeset.cast(
      Map.put(attrs, :user_id, user_id),
      [:user_id, :name, :items, :meal_plan_id]
    )
    |> Ecto.Changeset.validate_required([:user_id, :items])
    |> Ecto.Changeset.put_change(:share_token, generate_share_token())
    |> Repo.insert()
  end

  def check_item(list_id, item_index, user_id) do
    with {:ok, list} <- get_list(list_id),
         true <- list.user_id == user_id do
      checked = list.checked_ids |> List.insert_at(-1, item_index) |> Enum.uniq()

      list
      |> Ecto.Changeset.change(%{checked_ids: checked})
      |> Repo.update()
    else
      false -> {:error, :unauthorized}
    end
  end

  def uncheck_item(list_id, item_index, user_id) do
    with {:ok, list} <- get_list(list_id),
         true <- list.user_id == user_id do
      checked = Enum.reject(list.checked_ids, &(&1 == item_index))

      list
      |> Ecto.Changeset.change(%{checked_ids: checked})
      |> Repo.update()
    else
      false -> {:error, :unauthorized}
    end
  end

  def whatsapp_share_url(%ShoppingList{} = list) do
    base_url = Application.get_env(:caramel_kitchen, :app_url, "https://caramelkitchen.app")
    link = "#{base_url}/shopping/shared/#{list.share_token}"

    items_text =
      list.items
      |> Enum.take(10)
      |> Enum.map(fn i -> "• #{i["quantity"]} #{i["unit"]} #{i["name"]}" end)
      |> Enum.join("\n")

    text = URI.encode("🍳 My Caramel Kitchen Shopping List\n\n#{items_text}\n\nFull list: #{link}")
    "https://wa.me/?text=#{text}"
  end

  # ── Private ───────────────────────────────────────────────────

  defp aggregate_ingredients(recipes, servings_multiplier, days) do
    serving_map = build_serving_map(days)

    recipes
    |> Enum.flat_map(fn recipe ->
      multiplier =
        Map.get(serving_map, recipe.id, 1) * servings_multiplier / max(recipe.serving_size, 1)

      Enum.map(recipe.ingredients, fn ing ->
        %{
          "name" => ing["name"],
          "quantity" => round_qty(ing["quantity"] * multiplier),
          "unit" => ing["unit"] || "",
          "category" => classify_ingredient(ing["name"]),
          "recipe_ids" => [recipe.id],
          "notes" => ing["notes"],
          "checked" => false
        }
      end)
    end)
    |> merge_duplicates()
    |> Enum.sort_by(& &1["category"])
  end

  defp build_serving_map(days) do
    days
    |> Enum.flat_map(fn d -> d["meals"] end)
    |> Enum.group_by(& &1["recipe_id"])
    |> Map.new(fn {recipe_id, meals} ->
      {recipe_id, Enum.sum(Enum.map(meals, &(&1["servings"] || 1)))}
    end)
  end

  defp merge_duplicates(items) do
    items
    |> Enum.group_by(fn i -> {String.downcase(i["name"]), i["unit"]} end)
    |> Map.values()
    |> Enum.map(fn [first | rest] ->
      merged_qty = Enum.reduce(rest, first["quantity"], fn i, acc -> acc + i["quantity"] end)
      merged_recipes = Enum.flat_map([first | rest], & &1["recipe_ids"]) |> Enum.uniq()
      Map.merge(first, %{"quantity" => merged_qty, "recipe_ids" => merged_recipes})
    end)
  end

  defp classify_ingredient(name) do
    lower = String.downcase(name)

    Enum.find_value(@grocery_categories, "other", fn {category, keywords} ->
      if Enum.any?(keywords, &String.contains?(lower, &1)), do: category
    end)
  end

  defp round_qty(qty) when is_number(qty), do: Float.round(qty / 1, 1)

  defp generate_share_token do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end
