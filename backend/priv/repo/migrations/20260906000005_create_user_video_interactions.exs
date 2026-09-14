defmodule CaramelKitchen.Repo.Migrations.CreateUserVideoInteractions do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :favorite_count, :integer, default: 0, null: false
      add :save_count, :integer, default: 0, null: false
    end

    create index(:videos, [:favorite_count])
    create index(:videos, [:save_count])

    create table(:user_video_interactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :video_id, references(:videos, type: :binary_id, on_delete: :delete_all), null: false
      add :action, :string, null: false
      add :metadata, :map, default: "{}"

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:user_video_interactions, [:user_id])
    create index(:user_video_interactions, [:video_id])
    create index(:user_video_interactions, [:user_id, :action])
    create index(:user_video_interactions, [:inserted_at])
    create unique_index(:user_video_interactions, [:user_id, :video_id, :action])
  end
end
