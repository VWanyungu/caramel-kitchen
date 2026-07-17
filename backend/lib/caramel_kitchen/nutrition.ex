defmodule CaramelKitchen.Nutrition do
  @moduledoc """
  Macro and calorie data from Nutritionix API.
  Used to auto-calculate nutrition per recipe from ingredient list.
  Falls back to Edamam if Nutritionix is unavailable.
  Results are cached in Redis for 30 days (ingredient data rarely changes).
  """

  alias CaramelKitchen.Cache
  require Logger

  @nutritionix_url "https://trackapi.nutritionix.com/v2/natural/nutrients"
  @cache_ttl       :timer.hours(24 * 30)  # 30 days

  # ── Public API ────────────────────────────────────────────────

  @doc """
  Calculate nutrition for a full recipe from its ingredient list.
  Returns {:ok, %{calories, protein_g, carbs_g, fat_g, fibre_g, sodium_mg}} per serving.
  """
  def calculate_recipe_nutrition(ingredients, serving_size) when is_list(ingredients) do
    query = ingredients_to_query(ingredients)
    cache_key = "nutrition:#{:erlang.phash2(query)}"

    result = Cache.get_or_store(cache_key, @cache_ttl, fn ->
      fetch_nutrition(query)
    end)

    case result do
      {:ok, totals} ->
        per_serving = divide_by_servings(totals, serving_size)
        {:ok, per_serving}

      {:error, _} = err ->
        err
    end
  end

  @doc "Look up a single ingredient's nutrition data."
  def ingredient_nutrition(ingredient_name, quantity, unit) do
    query     = "#{quantity} #{unit} #{ingredient_name}"
    cache_key = "nutrition:single:#{:erlang.phash2(query)}"

    Cache.get_or_store(cache_key, @cache_ttl, fn ->
      fetch_nutrition(query)
    end)
  end

  # ── Private ───────────────────────────────────────────────────

  defp fetch_nutrition(query) do
    app_id  = Application.get_env(:caramel_kitchen, :nutritionix_app_id)
    app_key = Application.get_env(:caramel_kitchen, :nutritionix_app_key)

    if app_id && app_key do
      fetch_from_nutritionix(query, app_id, app_key)
    else
      Logger.warning("Nutritionix credentials not set — returning estimated nutrition")
      {:ok, estimate_nutrition(query)}
    end
  end

  defp fetch_from_nutritionix(query, app_id, app_key) do
    case Req.post(@nutritionix_url,
      headers: [
        {"x-app-id",  app_id},
        {"x-app-key", app_key},
        {"Content-Type", "application/json"}
      ],
      json: %{query: query},
      receive_timeout: 10_000
    ) do
      {:ok, %{status: 200, body: %{"foods" => foods}}} ->
        totals = aggregate_foods(foods)
        {:ok, totals}

      {:ok, %{status: 404}} ->
        {:ok, %{calories: 0, protein_g: 0, carbs_g: 0, fat_g: 0, fibre_g: 0, sodium_mg: 0}}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Nutritionix error #{status}: #{inspect(body)}")
        {:error, "nutritionix_error_#{status}"}

      {:error, reason} ->
        Logger.error("Nutritionix request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp aggregate_foods(foods) do
    Enum.reduce(foods, %{calories: 0, protein_g: 0, carbs_g: 0, fat_g: 0, fibre_g: 0, sodium_mg: 0},
      fn food, acc ->
        %{
          calories:  acc.calories  + round(food["nf_calories"]         || 0),
          protein_g: acc.protein_g + Float.round((food["nf_protein"]   || 0) * 1.0, 1),
          carbs_g:   acc.carbs_g   + Float.round((food["nf_total_carbohydrate"] || 0) * 1.0, 1),
          fat_g:     acc.fat_g     + Float.round((food["nf_total_fat"] || 0) * 1.0, 1),
          fibre_g:   acc.fibre_g   + Float.round((food["nf_dietary_fiber"] || 0) * 1.0, 1),
          sodium_mg: acc.sodium_mg + round(food["nf_sodium"]           || 0)
        }
      end
    )
  end

  defp divide_by_servings(totals, serving_size) when serving_size > 0 do
    %{
      calories:  round(totals.calories  / serving_size),
      protein_g: Float.round(totals.protein_g / serving_size, 1),
      carbs_g:   Float.round(totals.carbs_g   / serving_size, 1),
      fat_g:     Float.round(totals.fat_g     / serving_size, 1),
      fibre_g:   Float.round(totals.fibre_g   / serving_size, 1),
      sodium_mg: round(totals.sodium_mg / serving_size)
    }
  end
  defp divide_by_servings(totals, _), do: totals

  defp ingredients_to_query(ingredients) do
    ingredients
    |> Enum.map(fn ing ->
      qty  = ing["quantity"] || ing[:quantity] || 1
      unit = ing["unit"]     || ing[:unit]     || ""
      name = ing["name"]     || ing[:name]     || ""
      "#{qty} #{unit} #{name}"
    end)
    |> Enum.join(", ")
  end

  # Rough estimate when API not available (used in dev/test)
  defp estimate_nutrition(_query) do
    %{calories: 350, protein_g: 20.0, carbs_g: 35.0, fat_g: 12.0, fibre_g: 4.0, sodium_mg: 400}
  end
end
