defmodule CaramelKitchen.Repo.Migrations.AddVectorIndexes do
  @moduledoc """
  Adds HNSW (Hierarchical Navigable Small World) approximate nearest-neighbour
  indexes on taste vectors for production-scale cosine similarity queries.
  HNSW is much faster than exact scan at >100k rows.
  """
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    # HNSW index on users.taste_vector — for finding similar users
    execute "CREATE INDEX IF NOT EXISTS
      users_taste_vector_hnsw_idx
    ON users
    USING hnsw (taste_vector vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
    "

    # HNSW index on recipes.taste_profile — for feed ranking (most critical)
    execute "CREATE INDEX IF NOT EXISTS
      recipes_taste_profile_hnsw_idx
    ON recipes
    USING hnsw (taste_profile vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
    "

    # Composite index for fast creator recipe listing by status
    create_if_not_exists index(:recipes, [:creator_id, :status, :inserted_at])

    # Partial index: only live recipes (used in 90%+ of queries)
    execute "CREATE INDEX IF NOT EXISTS
      recipes_live_engagement_idx
    ON recipes (engagement_score DESC, published_at DESC)
    WHERE status = 'live';
    "

    # Partial index: upcoming scheduled recipes
    execute "CREATE INDEX IF NOT EXISTS
      recipes_scheduled_idx
    ON recipes (scheduled_at)
    WHERE status = 'scheduled' AND scheduled_at IS NOT NULL;
    "

    # Index for fast AI query analytics
    create_if_not_exists index(:ai_queries, [:user_id, :inserted_at, :query_type])

    # Index for fast meal plan lookups (active plan per user)
    execute "CREATE INDEX IF NOT EXISTS
      meal_plans_active_user_idx
    ON meal_plans (user_id, inserted_at DESC)
    WHERE is_active = true;
    "
  end

  def down do
    execute "DROP INDEX IF EXISTS users_taste_vector_hnsw_idx"
    execute "DROP INDEX IF EXISTS recipes_taste_profile_hnsw_idx"
    execute "DROP INDEX IF EXISTS recipes_live_engagement_idx"
    execute "DROP INDEX IF EXISTS recipes_scheduled_idx"
    execute "DROP INDEX IF EXISTS meal_plans_active_user_idx"
    drop_if_exists index(:recipes, [:creator_id, :status, :inserted_at])
    drop_if_exists index(:ai_queries, [:user_id, :inserted_at, :query_type])
  end
end
