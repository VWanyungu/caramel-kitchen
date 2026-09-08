defmodule CaramelKitchen.Repo.Migrations.AddSeasonalFieldsToCollections do
  use Ecto.Migration

  def change do
    alter table(:collections) do
      add :is_seasonal, :boolean, default: false, null: false
      add :season_name, :string
      add :start_date, :date
      add :end_date, :date
    end

    create index(:collections, [:is_seasonal])
    create index(:collections, [:season_name])
    create index(:collections, [:is_seasonal, :start_date, :end_date])
  end
end
