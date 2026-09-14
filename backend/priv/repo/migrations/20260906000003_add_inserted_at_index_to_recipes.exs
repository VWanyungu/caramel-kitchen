defmodule CaramelKitchen.Repo.Migrations.AddInsertedAtIndexToRecipes do
  use Ecto.Migration

  def change do
    create_if_not_exists index(:recipes, [:inserted_at])
    create_if_not_exists index(:recipes, [:status, :inserted_at])
  end
end
