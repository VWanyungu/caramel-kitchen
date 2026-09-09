defmodule CaramelKitchen.Repo.Migrations.AddCostAndBudgetToMealPlans do
  use Ecto.Migration

  def change do
    alter table(:meal_plans) do
      add :total_cost, :decimal, precision: 10, scale: 2
      add :budget, :decimal, precision: 10, scale: 2
    end

    create index(:meal_plans, [:total_cost])
  end
end
