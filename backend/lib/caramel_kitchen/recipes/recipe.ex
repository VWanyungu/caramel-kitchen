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

  schema "recipes" do
    belongs_to :creator, CaramelKitchen.Accounts.User

    field :slug,               :string
    field :title,              :string
    field :description,        :string
    field :ingredients,        {:array, :map}, default: []
    field :steps,              {:array, :map}, default: []
    field :serving_size,       :integer, default: 2
    field :thumbnail_url,      :string
    field :video_url,          :string
    field :video_key,          :string
    field :video_duration_secs, :integer

    # Classification
    field :dish_category,      :string
    field :course,             :string
    field :primary_method,     :string
    field :secondary_method,   :string
    field :difficulty,         :string, default: "beginner"
    field :cuisine_origin,     {:array, :string}, default: []

    # Time
    field :prep_time_mins,     :integer, default: 0
    field :cook_time_mins,     :integer, default: 0
    field :total_time_mins,    :integer, default: 0

    # Taste
    field :taste_tags,         {:array, :string}, default: []
    field :taste_profile,      Pgvector.Ecto.Vector

    # Dietary
    field :dietary_flags,      {:array, :string}, default: []
    field :allergens,          {:array, :string}, default: []

    # Nutrition
    field :calories,           :integer
    field :macros,             :map, default: %{}

    # Engagement
    field :view_count,         :integer, default: 0
    field :save_count,         :integer, default: 0
    field :cook_count,         :integer, default: 0
    field :avg_rating,         :decimal
    field :rating_count,       :integer, default: 0
    field :engagement_score,   :float, default: 0.0

    # Publishing
    field :status,             :string, default: "draft"
    field :published_at,       :utc_datetime
    field :scheduled_at,       :utc_datetime
    field :featured_until,     :utc_datetime

    field :search_vector,      :string  # tsvector, read-only

    timestamps(type: :utc_datetime)
  end

  # ── Changesets ────────────────────────────────────────────────

  def creation_changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [
      :title, :description, :ingredients, :steps, :serving_size,
      :dish_category, :course, :primary_method, :secondary_method,
      :difficulty, :cuisine_origin, :prep_time_mins, :cook_time_mins,
      :taste_tags, :dietary_flags, :allergens,
      :calories, :macros, :status, :scheduled_at, :creator_id
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
    |> validate_ingredients()
    |> validate_steps()
    |> put_slug()
    |> compute_taste_profile()
    |> foreign_key_constraint(:creator_id)
    |> unique_constraint(:slug)
  end

  def update_changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [
      :title, :description, :ingredients, :steps, :serving_size,
      :dish_category, :course, :primary_method, :secondary_method,
      :difficulty, :cuisine_origin, :prep_time_mins, :cook_time_mins,
      :taste_tags, :dietary_flags, :allergens, :calories, :macros,
      :thumbnail_url, :video_url, :video_key, :video_duration_secs,
      :status, :scheduled_at, :featured_until
    ])
    |> validate_required([:title, :ingredients, :steps])
    |> validate_subset(:taste_tags, @valid_taste_tags)
    |> validate_subset(:dietary_flags, @valid_dietary_flags)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_ingredients()
    |> validate_steps()
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
      nil -> cs
      title ->
        slug = title |> String.downcase() |> String.replace(Regex.compile!("[^a-z0-9]+"), "-") |> String.trim("-")
        put_change(cs, :slug, "#{slug}-#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}")
    end
  end
  defp put_slug(cs), do: cs

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
      [] -> add_error(cs, :ingredients, "must have at least one ingredient")
      ingredients when is_list(ingredients) ->
        if Enum.all?(ingredients, &valid_ingredient?/1), do: cs,
          else: add_error(cs, :ingredients, "each ingredient must have name and quantity")
      _ -> cs
    end
  end

  defp validate_steps(cs) do
    case get_field(cs, :steps) do
      [] -> add_error(cs, :steps, "must have at least one step")
      steps when is_list(steps) ->
        if Enum.all?(steps, &valid_step?/1), do: cs,
          else: add_error(cs, :steps, "each step must have order and instruction")
      _ -> cs
    end
  end

  defp valid_ingredient?(%{"name" => n, "quantity" => q}) when is_binary(n) and not is_nil(q), do: true
  defp valid_ingredient?(_), do: false

  defp valid_step?(%{"order" => o, "instruction" => i}) when is_integer(o) and is_binary(i), do: true
  defp valid_step?(_), do: false
end
