defmodule CaramelKitchen.Repo.Migrations.CreatePushTokens do
  use Ecto.Migration

  def change do
    create table(:user_push_tokens, primary_key: false) do
      add :id,         :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id,    references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :token,      :string, null: false, size: 512
      add :platform,   :string, null: false   # ios | android
      add :device_name, :string
      add :active,     :boolean, default: true

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:user_push_tokens, [:user_id, :token])
    create index(:user_push_tokens, [:user_id])
    create index(:user_push_tokens, [:platform])
  end
end
