defmodule CaramelKitchen.Repo.Migrations.AddMealToRecipes do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add :meal, :string
    end

    create index(:recipes, [:meal])
  end
end
