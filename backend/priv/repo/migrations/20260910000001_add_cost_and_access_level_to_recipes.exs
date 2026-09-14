defmodule CaramelKitchen.Repo.Migrations.AddCostAndAccessLevelToRecipes do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add :cost, :decimal, precision: 10, scale: 2
      add :is_premium, :boolean, default: false, null: false
      add :access_level, :string, default: "free", null: false
    end

    create index(:recipes, [:cost])
    create index(:recipes, [:is_premium])
    create index(:recipes, [:access_level])
    create index(:recipes, [:serving_size])
    create index(:recipes, [:cook_time_mins])

    execute "UPDATE recipes SET is_premium = is_special, access_level = CASE WHEN is_special = true THEN 'premium' ELSE 'free' END",
            ""
  end
end
