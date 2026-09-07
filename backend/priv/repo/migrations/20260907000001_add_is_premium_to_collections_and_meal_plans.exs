defmodule CaramelKitchen.Repo.Migrations.AddIsPremiumToCollectionsAndMealPlans do
  use Ecto.Migration

  def change do
    alter table(:collections) do
      add :is_premium, :boolean, default: false, null: false
    end

    create index(:collections, [:is_premium])

    alter table(:meal_plans) do
      add :is_premium, :boolean, default: false, null: false
    end

    create index(:meal_plans, [:is_premium])
  end
end
