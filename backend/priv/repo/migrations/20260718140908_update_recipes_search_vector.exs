defmodule CaramelKitchen.Repo.Migrations.UpdateRecipesSearchVector do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION recipes_search_vector_update() RETURNS trigger AS $$
    DECLARE
      ingredients_text text;
    BEGIN
      SELECT string_agg(i->>'name', ' ') INTO ingredients_text FROM unnest(NEW.ingredients) AS i;
      
      NEW.search_vector :=
        setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(NEW.description, '')), 'B') ||
        setweight(to_tsvector('english', coalesce(ingredients_text, '')), 'C') ||
        setweight(to_tsvector('english', array_to_string(NEW.taste_tags, ' ')), 'C') ||
        setweight(to_tsvector('english', array_to_string(NEW.dietary_flags, ' ')), 'C') ||
        setweight(to_tsvector('english', coalesce(NEW.dish_category::text, '')), 'C') ||
        setweight(to_tsvector('english', coalesce(NEW.course::text, '')), 'C') ||
        setweight(to_tsvector('english', array_to_string(NEW.cuisine_origin, ' ')), 'C');
      RETURN NEW;
    END
    $$ LANGUAGE plpgsql;
    """

    execute "UPDATE recipes SET updated_at = NOW();"
  end

  def down do
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
    """

    execute "UPDATE recipes SET updated_at = NOW();"
  end
end
