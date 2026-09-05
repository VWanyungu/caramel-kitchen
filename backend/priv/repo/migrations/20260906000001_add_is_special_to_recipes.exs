defmodule CaramelKitchen.Repo.Migrations.AddIsSpecialToRecipes do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add :is_special, :boolean, default: false, null: false
    end

    create index(:recipes, [:is_special])
  end
end
