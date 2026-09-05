defmodule CaramelKitchen.Repo.Migrations.CreateTaxonomies do
  use Ecto.Migration

  def change do
    create table(:taxonomies, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :type, :string, null: false
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :icon_url, :string
      add :display_order, :integer, default: 0, null: false
      add :is_active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:taxonomies, [:type, :slug])
    create index(:taxonomies, [:type, :is_active])
    create index(:taxonomies, [:type, :display_order])

    # Pre-seed canonical taxonomies
    execute """
    INSERT INTO taxonomies (type, slug, name, display_order, is_active, inserted_at, updated_at)
    VALUES
      -- Categories
      ('category', 'egg_dishes', 'Egg Dishes', 1, true, NOW(), NOW()),
      ('category', 'rice_dishes', 'Rice Dishes', 2, true, NOW(), NOW()),
      ('category', 'soups_stews', 'Soups & Stews', 3, true, NOW(), NOW()),
      ('category', 'meat_dishes', 'Meat Dishes', 4, true, NOW(), NOW()),
      ('category', 'fish_seafood', 'Fish & Seafood', 5, true, NOW(), NOW()),
      ('category', 'salads', 'Salads', 6, true, NOW(), NOW()),
      ('category', 'pasta_noodles', 'Pasta & Noodles', 7, true, NOW(), NOW()),
      ('category', 'breakfast', 'Breakfast', 8, true, NOW(), NOW()),
      ('category', 'baked_goods', 'Baked Goods', 9, true, NOW(), NOW()),
      ('category', 'drinks_juices', 'Drinks & Juices', 10, true, NOW(), NOW()),
      ('category', 'snacks', 'Snacks', 11, true, NOW(), NOW()),
      ('category', 'vegetarian', 'Vegetarian', 12, true, NOW(), NOW()),

      -- Cuisines
      ('cuisine', 'west_african', 'West African', 1, true, NOW(), NOW()),
      ('cuisine', 'east_african', 'East African', 2, true, NOW(), NOW()),
      ('cuisine', 'mediterranean', 'Mediterranean', 3, true, NOW(), NOW()),
      ('cuisine', 'italian', 'Italian', 4, true, NOW(), NOW()),
      ('cuisine', 'asian', 'Asian', 5, true, NOW(), NOW()),
      ('cuisine', 'mexican', 'Mexican', 6, true, NOW(), NOW()),
      ('cuisine', 'american', 'American', 7, true, NOW(), NOW()),
      ('cuisine', 'french', 'French', 8, true, NOW(), NOW()),

      -- Dietary Tags
      ('dietary_tag', 'vegetarian', 'Vegetarian', 1, true, NOW(), NOW()),
      ('dietary_tag', 'vegan', 'Vegan', 2, true, NOW(), NOW()),
      ('dietary_tag', 'gluten_free', 'Gluten Free', 3, true, NOW(), NOW()),
      ('dietary_tag', 'dairy_free', 'Dairy Free', 4, true, NOW(), NOW()),
      ('dietary_tag', 'low_fat', 'Low Fat', 5, true, NOW(), NOW()),
      ('dietary_tag', 'low_carb', 'Low Carb', 6, true, NOW(), NOW()),
      ('dietary_tag', 'keto', 'Keto', 7, true, NOW(), NOW()),
      ('dietary_tag', 'high_protein', 'High Protein', 8, true, NOW(), NOW()),
      ('dietary_tag', 'low_sodium', 'Low Sodium', 9, true, NOW(), NOW()),
      ('dietary_tag', 'diabetic_friendly', 'Diabetic Friendly', 10, true, NOW(), NOW()),
      ('dietary_tag', 'nut_free', 'Nut Free', 11, true, NOW(), NOW()),
      ('dietary_tag', 'halal', 'Halal', 12, true, NOW(), NOW()),
      ('dietary_tag', 'kosher', 'Kosher', 13, true, NOW(), NOW()),
      ('dietary_tag', 'paleo', 'Paleo', 14, true, NOW(), NOW()),
      ('dietary_tag', 'whole30', 'Whole30', 15, true, NOW(), NOW()),

      -- Difficulties
      ('difficulty', 'beginner', 'Beginner', 1, true, NOW(), NOW()),
      ('difficulty', 'intermediate', 'Intermediate', 2, true, NOW(), NOW()),
      ('difficulty', 'advanced', 'Advanced', 3, true, NOW(), NOW())
    ON CONFLICT (type, slug) DO NOTHING;
    """, ""
  end
end
