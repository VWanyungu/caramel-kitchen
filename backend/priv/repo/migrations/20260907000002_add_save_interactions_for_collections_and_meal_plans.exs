defmodule CaramelKitchen.Repo.Migrations.AddSaveInteractionsForCollectionsAndMealPlans do
  use Ecto.Migration

  def change do
    alter table(:collections) do
      add :save_count, :integer, default: 0, null: false
    end

    create index(:collections, [:save_count])

    alter table(:meal_plans) do
      add :save_count, :integer, default: 0, null: false
    end

    create index(:meal_plans, [:save_count])

    create table(:user_collection_interactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :collection_id, references(:collections, type: :binary_id, on_delete: :delete_all), null: false
      add :action, :string, null: false
      add :metadata, :map, default: "{}"

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:user_collection_interactions, [:user_id])
    create index(:user_collection_interactions, [:collection_id])
    create index(:user_collection_interactions, [:user_id, :action])
    create index(:user_collection_interactions, [:inserted_at])
    create unique_index(:user_collection_interactions, [:user_id, :collection_id, :action])

    create table(:user_meal_plan_interactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :meal_plan_id, references(:meal_plans, type: :binary_id, on_delete: :delete_all), null: false
      add :action, :string, null: false
      add :metadata, :map, default: "{}"

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:user_meal_plan_interactions, [:user_id])
    create index(:user_meal_plan_interactions, [:meal_plan_id])
    create index(:user_meal_plan_interactions, [:user_id, :action])
    create index(:user_meal_plan_interactions, [:inserted_at])
    create unique_index(:user_meal_plan_interactions, [:user_id, :meal_plan_id, :action])
  end
end
