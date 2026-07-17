defmodule CaramelKitchen.Repo.Migrations.CreateRecipes do
  use Ecto.Migration

  def change do
    # ENUMs
    execute "CREATE TYPE recipe_status AS ENUM ('draft', 'scheduled', 'live', 'archived')",
            "DROP TYPE recipe_status"

    execute "CREATE TYPE cooking_method AS ENUM ('boiling','frying','roasting','grilling','baking','steaming','braising','slow_cooking','pressure_cooking','air_frying','raw','fermented','sauteing','smoking','chilling','blanching','stir_frying','poaching')",
            "DROP TYPE cooking_method"

    execute "CREATE TYPE course_type AS ENUM ('pre_starter','starter','soup','salad','main','dessert','after_meal')",
            "DROP TYPE course_type"

    execute "CREATE TYPE dish_category AS ENUM ('egg_dishes','rice_dishes','soups_stews','meat_dishes','fish_seafood','salads','pasta_noodles','breakfast','baked_goods','drinks_juices','snacks','vegetarian')",
            "DROP TYPE dish_category"

    execute "CREATE TYPE difficulty_level AS ENUM ('beginner','intermediate','advanced')",
            "DROP TYPE difficulty_level"

    create table(:recipes, primary_key: false) do
      add :id,                  :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :creator_id,          references(:users, type: :uuid, on_delete: :restrict), null: false
      add :slug,                :string, null: false, size: 200

      # Content
      add :title,               :string, null: false, size: 255
      add :description,         :text
      add :ingredients,         {:array, :map}, null: false, default: []
      # ingredients: [{name, quantity, unit, notes}]
      add :steps,               {:array, :map}, null: false, default: []
      # steps: [{order, instruction, duration_minutes, tip}]
      add :serving_size,        :integer, null: false, default: 2
      add :thumbnail_url,       :string
      add :video_url,           :string
      add :video_key,           :string   # S3 key
      add :video_duration_secs, :integer

      # Classification
      add :dish_category,       :dish_category
      add :course,              :course_type
      add :primary_method,      :cooking_method
      add :secondary_method,    :cooking_method
      add :difficulty,          :difficulty_level, default: "beginner"
      add :cuisine_origin,      {:array, :string}, default: []

      # Time
      add :prep_time_mins,      :integer, default: 0
      add :cook_time_mins,      :integer, default: 0
      add :total_time_mins,     :integer, default: 0  # computed

      # Taste intelligence
      add :taste_tags,          {:array, :string}, default: []
      # taste_vector: float[8] matching the user taste vector dimensions
      add :taste_profile,       :vector, size: 8

      # Dietary / allergy
      add :dietary_flags,       {:array, :string}, default: []
      add :allergens,           {:array, :string}, default: []

      # Nutrition (per serving)
      add :calories,            :integer
      add :macros,              :map, default: %{}
      # macros: {protein_g, carbs_g, fat_g, fibre_g, sugar_g, sodium_mg}

      # Engagement metrics (denormalised for perf)
      add :view_count,          :integer, default: 0
      add :save_count,          :integer, default: 0
      add :cook_count,          :integer, default: 0
      add :avg_rating,          :decimal, precision: 3, scale: 2, default: 0
      add :rating_count,        :integer, default: 0
      add :engagement_score,    :float, default: 0.0

      # Publishing
      add :status,              :recipe_status, null: false, default: "draft"
      add :published_at,        :utc_datetime
      add :scheduled_at,        :utc_datetime
      add :featured_until,      :utc_datetime

      # Search vector (tsvector for full-text)
      add :search_vector,       :tsvector

      timestamps(type: :utc_datetime)
    end

    create unique_index(:recipes, [:slug])
    create index(:recipes, [:creator_id])
    create index(:recipes, [:status])
    create index(:recipes, [:dish_category])
    create index(:recipes, [:course])
    create index(:recipes, [:primary_method])
    create index(:recipes, [:published_at])
    create index(:recipes, [:engagement_score])
    create index(:recipes, [:dietary_flags], using: :gin)
    create index(:recipes, [:taste_tags], using: :gin)
    create index(:recipes, [:cuisine_origin], using: :gin)
    create index(:recipes, [:allergens], using: :gin)

    # Full-text search index
    execute """
    CREATE INDEX recipes_search_vector_idx ON recipes USING gin(search_vector);
    """, "DROP INDEX IF EXISTS recipes_search_vector_idx"

    # Auto-update search_vector on insert/update
    execute """
    CREATE OR REPLACE FUNCTION recipes_search_vector_update() RETURNS trigger AS $$
    BEGIN
      NEW.search_vector :=
        setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(NEW.description, '')), 'B') ||
        setweight(to_tsvector('english', array_to_string(NEW.taste_tags, ' ')), 'C') ||
        setweight(to_tsvector('english', array_to_string(NEW.dietary_flags, ' ')), 'C');
      RETURN NEW;
    END
    $$ LANGUAGE plpgsql;
    """, "DROP FUNCTION IF EXISTS recipes_search_vector_update()"

    execute """
    CREATE TRIGGER recipes_search_vector_trigger
    BEFORE INSERT OR UPDATE ON recipes
    FOR EACH ROW EXECUTE FUNCTION recipes_search_vector_update();
    """, "DROP TRIGGER IF EXISTS recipes_search_vector_trigger ON recipes"

    # Auto compute total_time and engagement_score
    execute """
    CREATE OR REPLACE FUNCTION update_recipe_computed_fields() RETURNS trigger AS $$
    BEGIN
      NEW.total_time_mins := NEW.prep_time_mins + NEW.cook_time_mins;
      NEW.engagement_score :=
        (NEW.view_count * 0.1 + NEW.save_count * 0.4 + NEW.cook_count * 0.5 + NEW.avg_rating * 5.0) /
        GREATEST(1, (EXTRACT(EPOCH FROM (NOW() - NEW.published_at)) / 86400.0));
      RETURN NEW;
    END
    $$ LANGUAGE plpgsql;
    """, "DROP FUNCTION IF EXISTS update_recipe_computed_fields()"

    execute """
    CREATE TRIGGER recipe_computed_fields_trigger
    BEFORE INSERT OR UPDATE ON recipes
    FOR EACH ROW EXECUTE FUNCTION update_recipe_computed_fields();
    """, "DROP TRIGGER IF EXISTS recipe_computed_fields_trigger ON recipes"
  end
end
