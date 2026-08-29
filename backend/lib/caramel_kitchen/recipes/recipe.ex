defmodule CaramelKitchen.Recipes.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_taste_tags ~w(sour sweet tangy spicy savory bitter umami mild)
  @valid_dietary_flags ~w(vegetarian vegan gluten_free dairy_free low_fat low_carb keto
                          high_protein low_sodium diabetic_friendly nut_free halal kosher
                          paleo whole30)
  @valid_statuses ~w(draft scheduled live archived)
  @valid_meals ~w(breakfast lunch dinner snack brunch dessert beverage)
  @valid_courses ~w(breakfast lunch dinner main side snack dessert desert beverage brunch appetizer)
  @valid_cooking_methods ~w(roasting boiling frying baking grilling steaming sauteing braising slow_cooking pressure_cooking smoking air_frying raw no_cook) ++ ["slow cooking", "pressure cooking", "air frying"]

  schema "recipes" do
    belongs_to :creator, CaramelKitchen.Accounts.User

    field :slug, :string
    field :title, :string
    field :description, :string
    field :ingredients, {:array, :map}, default: []
    field :steps, {:array, :map}, default: []
    field :serving_size, :integer, default: 2
    field :thumbnail_url, :string
    field :video_url, :string
    field :video_key, :string
    field :video_duration_secs, :integer

    # Classification
    field :dish_category, :string
    field :dish_categories, {:array, :string}, default: []
    field :course, :string
    field :meal, :string
    field :primary_method, :string
    field :secondary_method, :string
    field :difficulty, :string, default: "beginner"
    field :cuisine_origin, {:array, :string}, default: []

    # Time
    field :prep_time_mins, :integer, default: 0
    field :cook_time_mins, :integer, default: 0
    field :total_time_mins, :integer, default: 0

    # Taste
    field :taste_tags, {:array, :string}, default: []
    field :taste_profile, Pgvector.Ecto.Vector

    # Dietary
    field :dietary_flags, {:array, :string}, default: []
    field :allergens, {:array, :string}, default: []

    # Nutrition
    field :calories, :integer
    field :macros, :map, default: %{}

    # Engagement
    field :view_count, :integer, default: 0
    field :save_count, :integer, default: 0
    field :cook_count, :integer, default: 0
    field :avg_rating, :decimal
    field :rating_count, :integer, default: 0
    field :engagement_score, :float, default: 0.0

    # Publishing
    field :status, :string, default: "draft"
    field :published_at, :utc_datetime
    field :scheduled_at, :utc_datetime
    field :featured_until, :utc_datetime

    # tsvector, read-only
    field :search_vector, :string, load_in_query: false

    timestamps(type: :utc_datetime)
  end

  # ── Changesets ────────────────────────────────────────────────

  def creation_changeset(recipe, attrs) do
    attrs = normalize_category_attrs(attrs)

    recipe
    |> cast(attrs, [
      :title,
      :description,
      :ingredients,
      :steps,
      :serving_size,
      :dish_category,
      :dish_categories,
      :course,
      :meal,
      :primary_method,
      :secondary_method,
      :difficulty,
      :cuisine_origin,
      :prep_time_mins,
      :cook_time_mins,
      :taste_tags,
      :dietary_flags,
      :allergens,
      :calories,
      :macros,
      :status,
      :scheduled_at,
      :creator_id
    ])
    |> validate_required([:title, :ingredients, :steps, :primary_method, :creator_id])
    |> validate_length(:title, min: 3, max: 255)
    |> validate_length(:description, max: 2000)
    |> validate_number(:serving_size, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:prep_time_mins, greater_than_or_equal_to: 0)
    |> validate_number(:cook_time_mins, greater_than_or_equal_to: 0)
    |> validate_subset(:taste_tags, @valid_taste_tags)
    |> validate_length(:taste_tags, min: 1, max: 4, message: "must have 1-4 taste tags")
    |> validate_subset(:dietary_flags, @valid_dietary_flags)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_inclusion(:meal, @valid_meals)
    |> validate_inclusion(:course, @valid_courses)
    |> validate_inclusion(:primary_method, @valid_cooking_methods)
    |> validate_ingredients()
    |> validate_steps()
    |> put_slug()
    |> put_total_time()
    |> compute_taste_profile()
    |> foreign_key_constraint(:creator_id)
    |> unique_constraint(:slug)
  end

  def update_changeset(recipe, attrs) do
    attrs = normalize_category_attrs(attrs)

    recipe
    |> cast(attrs, [
      :title,
      :description,
      :ingredients,
      :steps,
      :serving_size,
      :dish_category,
      :dish_categories,
      :course,
      :meal,
      :primary_method,
      :secondary_method,
      :difficulty,
      :cuisine_origin,
      :prep_time_mins,
      :cook_time_mins,
      :taste_tags,
      :dietary_flags,
      :allergens,
      :calories,
      :macros,
      :thumbnail_url,
      :video_url,
      :video_key,
      :video_duration_secs,
      :status,
      :scheduled_at,
      :featured_until
    ])
    |> validate_required([:title, :ingredients, :steps])
    |> validate_subset(:taste_tags, @valid_taste_tags)
    |> validate_subset(:dietary_flags, @valid_dietary_flags)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_inclusion(:meal, @valid_meals)
    |> validate_inclusion(:course, @valid_courses)
    |> validate_inclusion(:primary_method, @valid_cooking_methods)
    |> validate_ingredients()
    |> validate_steps()
    |> put_total_time()
    |> compute_taste_profile()
    |> unique_constraint(:slug)
  end

  def publish_changeset(recipe) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(recipe, %{status: "live", published_at: now})
  end

  def video_changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [:video_url, :video_key, :video_duration_secs, :thumbnail_url])
    |> validate_required([:video_url, :video_key])
  end

  def engagement_changeset(recipe, field, increment \\ 1) do
    current = Map.get(recipe, field, 0) || 0
    change(recipe, %{field => current + increment})
  end

  # ── Computed ──────────────────────────────────────────────────

  def total_time(%__MODULE__{prep_time_mins: p, cook_time_mins: c}), do: (p || 0) + (c || 0)

  def live?(%__MODULE__{status: "live"}), do: true
  def live?(_), do: false

  def taste_profile_list(%__MODULE__{taste_profile: nil}), do: List.duplicate(0.5, 8)
  def taste_profile_list(%__MODULE__{taste_profile: vec}), do: Pgvector.to_list(vec)

  # ── Private ───────────────────────────────────────────────────

  defp put_slug(%Ecto.Changeset{valid?: true} = cs) do
    case get_field(cs, :title) do
      nil ->
        cs

      title ->
        slug =
          title
          |> String.downcase()
          |> String.replace(Regex.compile!("[^a-z0-9]+"), "-")
          |> String.trim("-")

        put_change(
          cs,
          :slug,
          "#{slug}-#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
        )
    end
  end

  defp put_slug(cs), do: cs

  defp put_total_time(cs) do
    prep = get_field(cs, :prep_time_mins) || 0
    cook = get_field(cs, :cook_time_mins) || 0
    put_change(cs, :total_time_mins, prep + cook)
  end

  # Map taste tags to a float vector for similarity search
  defp compute_taste_profile(%Ecto.Changeset{valid?: true} = cs) do
    tags = get_field(cs, :taste_tags) || []
    dimensions = ~w(sour sweet tangy spicy savory bitter umami mild)
    vector = Enum.map(dimensions, fn dim -> if dim in tags, do: 1.0, else: 0.0 end)
    put_change(cs, :taste_profile, vector)
  end

  defp compute_taste_profile(cs), do: cs

  defp validate_ingredients(cs) do
    case get_field(cs, :ingredients) do
      [] ->
        add_error(cs, :ingredients, "must have at least one ingredient")

      ingredients when is_list(ingredients) ->
        if Enum.all?(ingredients, &valid_ingredient?/1),
          do: cs,
          else: add_error(cs, :ingredients, "each ingredient must have name and quantity")

      _ ->
        cs
    end
  end

  defp validate_steps(cs) do
    case get_field(cs, :steps) do
      [] ->
        add_error(cs, :steps, "must have at least one step")

      steps when is_list(steps) ->
        if Enum.all?(steps, &valid_step?/1),
          do: cs,
          else: add_error(cs, :steps, "each step must have order and instruction")

      _ ->
        cs
    end
  end

  defp valid_ingredient?(%{"name" => n, "quantity" => q}) when is_binary(n) and not is_nil(q),
    do: true

  defp valid_ingredient?(_), do: false

  defp valid_step?(%{"order" => o, "instruction" => i}) when is_integer(o) and is_binary(i),
    do: true

  defp valid_step?(_), do: false

  @valid_legacy_categories ~w(egg_dishes rice_dishes soups_stews meat_dishes fish_seafood salads pasta_noodles breakfast baked_goods drinks_juices snacks vegetarian)

  defp map_legacy_category(cat) when cat in @valid_legacy_categories, do: cat
  defp map_legacy_category(cat) when cat in ~w(chicken_dishes beef_dishes), do: "meat_dishes"
  defp map_legacy_category(cat) when cat in ~w(vegetable_dishes legume_dishes), do: "vegetarian"
  defp map_legacy_category(_), do: nil

  defp normalize_category_attrs(attrs) when is_map(attrs) do
    string_keys? = Enum.any?(Map.keys(attrs), &is_binary/1)

    dish_categories =
      cond do
        Map.has_key?(attrs, "dish_categories") -> Map.get(attrs, "dish_categories")
        Map.has_key?(attrs, :dish_categories) -> Map.get(attrs, :dish_categories)
        Map.has_key?(attrs, "categories") -> Map.get(attrs, "categories")
        Map.has_key?(attrs, :categories) -> Map.get(attrs, :categories)
        Map.has_key?(attrs, "dish_category") -> wrap_in_list(Map.get(attrs, "dish_category"))
        Map.has_key?(attrs, :dish_category) -> wrap_in_list(Map.get(attrs, :dish_category))
        Map.has_key?(attrs, "category") -> wrap_in_list(Map.get(attrs, "category"))
        Map.has_key?(attrs, :category) -> wrap_in_list(Map.get(attrs, :category))
        true -> nil
      end

    case dish_categories do
      nil ->
        attrs

      cats when is_list(cats) ->
        first_cat = List.first(cats)
        legacy_cat = map_legacy_category(first_cat)

        if string_keys? do
          attrs
          |> Map.put("dish_categories", cats)
          |> Map.put("dish_category", legacy_cat)
        else
          attrs
          |> Map.put(:dish_categories, cats)
          |> Map.put(:dish_category, legacy_cat)
        end

      cat when is_binary(cat) ->
        legacy_cat = map_legacy_category(cat)

        if string_keys? do
          attrs
          |> Map.put("dish_categories", [cat])
          |> Map.put("dish_category", legacy_cat)
        else
          attrs
          |> Map.put(:dish_categories, [cat])
          |> Map.put(:dish_category, legacy_cat)
        end

      _ ->
        attrs
    end
  end

  defp normalize_category_attrs(attrs), do: attrs

  defp wrap_in_list(nil), do: []
  defp wrap_in_list(val) when is_list(val), do: val
  defp wrap_in_list(val) when is_binary(val), do: [val]
  defp wrap_in_list(_), do: []
end
