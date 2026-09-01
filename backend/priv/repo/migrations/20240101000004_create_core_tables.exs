defmodule CaramelKitchen.Repo.Migrations.CreateCoreTables do
  use Ecto.Migration

  def change do
    # ── user_recipe_interactions ──────────────────────────────────
    execute "CREATE TYPE interaction_action AS ENUM ('saved','cooked','skipped','rated','viewed')",
            "DROP TYPE interaction_action"

    create table(:user_recipe_interactions, primary_key: false) do
      add :id,             :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id,        references(:users,   type: :uuid, on_delete: :delete_all), null: false
      add :recipe_id,      references(:recipes, type: :uuid, on_delete: :delete_all), null: false
      add :action,         :interaction_action, null: false
      add :rating,         :integer   # 1-5, only when action = rated
      add :taste_feedback, :map, default: %{}
      # taste_feedback: {dimensions that user confirmed matched}
      add :metadata,       :map, default: %{}
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:user_recipe_interactions, [:user_id])
    create index(:user_recipe_interactions, [:recipe_id])
    create index(:user_recipe_interactions, [:user_id, :action])
    create index(:user_recipe_interactions, [:inserted_at])
    # Partial unique: one row per user/recipe/action combo
    create unique_index(:user_recipe_interactions, [:user_id, :recipe_id, :action])

    # ── meal_plans ────────────────────────────────────────────────
    execute "CREATE TYPE goal_type AS ENUM ('gym_muscle','weight_loss','weight_gain','balanced','keto')",
            "DROP TYPE goal_type"

    create table(:meal_plans, primary_key: false) do
      add :id,             :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id,        references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :goal_type,      :goal_type, null: false
      add :name,           :string, size: 100
      add :week_start,     :date, null: false
      add :week_end,       :date, null: false
      add :calorie_target, :integer
      add :macro_split,    :map, default: %{}
      # macro_split: {protein_pct, carbs_pct, fat_pct}
      add :days,           {:array, :map}, default: []
      # days: [{date, meals:[{slot, recipe_id, servings, macros}]}]
      add :is_ai_generated, :boolean, default: true
      add :ai_model,        :string
      add :is_active,       :boolean, default: true
      timestamps(type: :utc_datetime)
    end

    create index(:meal_plans, [:user_id])
    create index(:meal_plans, [:user_id, :is_active])
    create index(:meal_plans, [:week_start])

    # ── shopping_lists ────────────────────────────────────────────
    create table(:shopping_lists, primary_key: false) do
      add :id,           :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id,      references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :meal_plan_id, references(:meal_plans, type: :uuid, on_delete: :nilify_all)
      add :event_menu_id, :uuid   # soft ref to event_menus
      add :name,         :string, size: 100
      add :items,        {:array, :map}, default: []
      # items: [{name, quantity, unit, category, recipe_ids:[], checked:bool}]
      add :checked_ids,  {:array, :uuid}, default: []
      add :share_token,  :string
      add :servings_multiplier, :float, default: 1.0
      timestamps(type: :utc_datetime)
    end

    create index(:shopping_lists, [:user_id])
    create unique_index(:shopping_lists, [:share_token], where: "share_token IS NOT NULL")

    # ── event_menus (course builder) ──────────────────────────────
    create table(:event_menus, primary_key: false) do
      add :id,      :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :name,    :string, null: false, size: 150
      add :courses, :map, default: %{}
      # courses: {pre_starter:[recipe_ids], starter:[...], ..., after_meal:[...]}
      add :notes,   :text
      add :event_date, :date
      add :guest_count, :integer, default: 4
      timestamps(type: :utc_datetime)
    end

    create index(:event_menus, [:user_id])

    # ── subscriptions ─────────────────────────────────────────────
    execute "CREATE TYPE subscription_status AS ENUM ('active','past_due','canceled','trialing','incomplete')",
            "DROP TYPE subscription_status"

    create table(:subscriptions, primary_key: false) do
      add :id,                  :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id,             references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :stripe_customer_id,  :string
      add :stripe_sub_id,       :string
      add :plan,                :subscription_tier, null: false, default: "free"
      add :status,              :subscription_status, default: "active"
      add :trial_ends_at,       :utc_datetime
      add :current_period_start, :utc_datetime
      add :current_period_end,   :utc_datetime
      add :canceled_at,         :utc_datetime
      add :metadata,            :map, default: %{}
      timestamps(type: :utc_datetime)
    end

    create unique_index(:subscriptions, [:user_id])
    create unique_index(:subscriptions, [:stripe_sub_id], where: "stripe_sub_id IS NOT NULL")
    create index(:subscriptions, [:stripe_customer_id])
    create index(:subscriptions, [:status])

    # ── ai_queries ────────────────────────────────────────────────
    execute "CREATE TYPE ai_query_type AS ENUM ('chat','voice','meal_plan','suggestion')",
            "DROP TYPE ai_query_type"

    create table(:ai_queries, primary_key: false) do
      add :id,             :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id,        references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :session_id,     :string
      add :query_type,     :ai_query_type
      add :prompt,         :text
      add :response,       :text
      add :model,          :string, default: "gpt-4o"
      add :tokens_used,    :integer
      add :latency_ms,     :integer
      add :recipe_ids,     {:array, :uuid}, default: []
      add :error,          :string
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:ai_queries, [:user_id])
    create index(:ai_queries, [:inserted_at])
    create index(:ai_queries, [:query_type])

    # ── guardian_tokens (JWT revocation) ─────────────────────────
    create table(:guardian_tokens, primary_key: false) do
      add :jti,     :string,      primary_key: true
      add :aud,     :string,      null: false
      add :typ,     :string
      add :iss,     :string
      add :sub,     :string
      add :exp,     :bigint
      add :jwt,     :text
      add :claims,  :map
      timestamps(type: :utc_datetime)
    end

    create index(:guardian_tokens, [:jti])
    create index(:guardian_tokens, [:aud])
  end
end
