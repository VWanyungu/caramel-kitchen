defmodule CaramelKitchen.Repo.Migrations.EnableExtensions do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\""
    execute "CREATE EXTENSION IF NOT EXISTS \"pg_trgm\""
    execute "CREATE EXTENSION IF NOT EXISTS \"vector\""
    execute "CREATE EXTENSION IF NOT EXISTS \"unaccent\""
    execute "CREATE EXTENSION IF NOT EXISTS \"pg_stat_statements\""
  end

  def down do
    execute "DROP EXTENSION IF EXISTS \"pg_stat_statements\""
    execute "DROP EXTENSION IF EXISTS \"unaccent\""
    execute "DROP EXTENSION IF EXISTS \"vector\""
    execute "DROP EXTENSION IF EXISTS \"pg_trgm\""
    execute "DROP EXTENSION IF EXISTS \"uuid-ossp\""
  end
end
