defmodule CaramelKitchen.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create_query = "CREATE TYPE user_role AS ENUM ('user', 'creator', 'admin')"
    drop_query   = "DROP TYPE user_role"
    execute(create_query, drop_query)

    create_query2 = "CREATE TYPE subscription_tier AS ENUM ('free', 'premium', 'creator_pro')"
    drop_query2   = "DROP TYPE subscription_tier"
    execute(create_query2, drop_query2)

    create table(:users, primary_key: false) do
      add :id,                   :uuid,   primary_key: true, default: fragment("uuid_generate_v4()")
      add :email,                :string, null: false, size: 255
      add :password_hash,        :string, null: false
      add :name,                 :string, null: false, size: 100
      add :avatar_url,           :string
      add :role,                 :user_role, null: false, default: "user"
      add :subscription_tier,    :subscription_tier, null: false, default: "free"

      # Taste intelligence
      add :taste_vector,         :vector,  size: 8   # pgvector column [sour,sweet,tangy,spicy,savory,bitter,umami,mild]
      add :taste_survey_done,    :boolean, default: false, null: false
      add :taste_updated_at,     :utc_datetime

      # Preferences
      add :dietary_flags,        {:array, :string}, default: []
      add :allergy_flags,        {:array, :string}, default: []
      add :cuisine_preferences,  {:array, :string}, default: []
      add :goal_type,            :string   # gym | weight_loss | weight_gain | balanced | keto

      # Auth
      add :google_uid,           :string
      add :email_verified,       :boolean, default: false, null: false
      add :email_verify_token,   :string
      add :password_reset_token, :string
      add :password_reset_at,    :utc_datetime
      add :last_sign_in_at,      :utc_datetime
      add :sign_in_count,        :integer, default: 0

      # Account state
      add :deactivated_at,       :utc_datetime
      add :deactivation_reason,  :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:google_uid], where: "google_uid IS NOT NULL")
    create index(:users, [:subscription_tier])
    create index(:users, [:role])

    # GIN index on arrays for fast dietary filtering
    create index(:users, [:dietary_flags], using: :gin)
  end
end
