defmodule CaramelKitchen.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @taste_dimensions ~w(sour sweet tangy spicy savory bitter umami mild)
  @valid_dietary_flags ~w(vegetarian vegan gluten_free dairy_free low_fat low_carb keto
                          high_protein low_sodium diabetic_friendly nut_free halal kosher
                          paleo whole30)
  @valid_goal_types ~w(gym_muscle weight_loss weight_gain balanced keto)
  @valid_tiers ~w(free premium creator_pro)

  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :name, :string
    field :avatar_url, :string
    field :role, :string, default: "user"
    field :subscription_tier, :string, default: "free"

    # Taste
    field :taste_vector, Pgvector.Ecto.Vector
    field :taste_survey_done, :boolean, default: false
    field :taste_updated_at, :utc_datetime

    # Preferences
    field :dietary_flags, {:array, :string}, default: []
    field :allergy_flags, {:array, :string}, default: []
    field :cuisine_preferences, {:array, :string}, default: []
    field :goal_type, :string

    # Auth
    field :google_uid, :string
    field :email_verified, :boolean, default: false
    field :email_verify_token, :string
    field :password_reset_token, :string
    field :password_reset_at, :utc_datetime
    field :last_sign_in_at, :utc_datetime
    field :sign_in_count, :integer, default: 0

    # State
    field :deactivated_at, :utc_datetime
    field :deactivation_reason, :string

    has_many :recipes, CaramelKitchen.Recipes.Recipe, foreign_key: :creator_id
    has_many :meal_plans, CaramelKitchen.MealPlans.MealPlan
    has_many :shopping_lists, CaramelKitchen.Shopping.ShoppingList
    has_one :subscription, CaramelKitchen.Monetisation.Subscription

    timestamps(type: :utc_datetime)
  end

  # ── Changesets ────────────────────────────────────────────────

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :password_confirmation, :name])
    |> validate_required([:email, :password, :name])
    |> validate_email()
    |> validate_password()
    |> put_password_hash()
    |> unique_constraint(:email, message: "already registered")
  end

  def google_registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :google_uid, :avatar_url])
    |> validate_required([:email, :name, :google_uid])
    |> validate_email()
    |> put_change(:email_verified, true)
    |> put_change(:password_hash, Bcrypt.hash_pwd_salt(generate_random_password()))
    |> unique_constraint(:email)
    |> unique_constraint(:google_uid)
  end

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :name,
      :avatar_url,
      :dietary_flags,
      :allergy_flags,
      :cuisine_preferences,
      :goal_type
    ])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_subset(:dietary_flags, @valid_dietary_flags)
    |> validate_inclusion(:goal_type, @valid_goal_types, allow_nil: true)
  end

  def taste_survey_changeset(user, taste_vector) when is_list(taste_vector) do
    user
    |> change(%{
      taste_vector: taste_vector,
      taste_survey_done: true,
      taste_updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  def taste_update_changeset(user, updated_vector) do
    user
    |> change(%{
      taste_vector: updated_vector,
      taste_updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  def subscription_changeset(user, tier) when tier in @valid_tiers do
    change(user, %{subscription_tier: tier})
  end

  def password_reset_changeset(user, password) do
    user
    |> change(%{password: password})
    |> validate_password()
    |> put_password_hash()
    |> change(%{password_reset_token: nil, password_reset_at: nil})
  end

  def verify_email_changeset(user) do
    change(user, %{email_verified: true, email_verify_token: nil})
  end

  def sign_in_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, %{last_sign_in_at: now, sign_in_count: (user.sign_in_count || 0) + 1})
  end

  # ── Guards ────────────────────────────────────────────────────

  def active?(%__MODULE__{deactivated_at: nil}), do: true
  def active?(_), do: false

  def premium?(%__MODULE__{subscription_tier: tier}), do: tier in ~w(premium creator_pro)
  def creator?(%__MODULE__{role: role}), do: role in ~w(creator admin)
  def admin?(%__MODULE__{role: "admin"}), do: true
  def admin?(_), do: false

  def taste_vector_list(%__MODULE__{taste_vector: nil}), do: default_taste_vector()
  def taste_vector_list(%__MODULE__{taste_vector: vec}) when is_list(vec), do: vec
  def taste_vector_list(%__MODULE__{taste_vector: %Pgvector{} = vec}), do: Pgvector.to_list(vec)

  def taste_vector_list(%__MODULE__{taste_vector: vec}) when is_binary(vec) do
    vec
    |> String.trim("[")
    |> String.trim("]")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn s ->
      case Float.parse(s) do
        {f, _} -> f
        :error -> 0.5
      end
    end)
  end

  def taste_vector_list(_), do: default_taste_vector()

  def default_taste_vector, do: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
  def taste_dimensions, do: @taste_dimensions

  # ── Private ───────────────────────────────────────────────────

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, Regex.compile!("^[^\\s]+@[^\\s]+\\.[^\\s]+$"),
      message: "must be a valid email"
    )
    |> validate_length(:email, max: 255)
    |> update_change(:email, &String.downcase/1)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> validate_format(:password, Regex.compile!("[0-9]"), message: "must contain a number")
    |> validate_confirmation(:password, message: "passwords do not match")
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = cs) do
    change(cs, password_hash: Bcrypt.hash_pwd_salt(pw))
  end

  defp put_password_hash(cs), do: cs

  defp generate_random_password do
    :crypto.strong_rand_bytes(32) |> Base.encode64()
  end
end
