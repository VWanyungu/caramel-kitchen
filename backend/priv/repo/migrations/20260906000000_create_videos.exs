defmodule CaramelKitchen.Repo.Migrations.CreateVideos do
  use Ecto.Migration

  def change do
    create table(:videos, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :description, :text
      add :category, :string, null: false
      add :is_premium, :boolean, default: false, null: false
      add :is_special, :boolean, default: false, null: false
      add :yt_embed_code, :text, null: false
      add :youtube_video_id, :string
      add :video_url, :string
      add :video_embed_url, :string
      add :thumbnail_url, :string
      add :duration_secs, :integer
      add :view_count, :integer, default: 0, null: false
      add :creator_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:videos, [:category])
    create index(:videos, [:is_premium])
    create index(:videos, [:is_special])
    create index(:videos, [:inserted_at])
    create index(:videos, [:creator_id])
    create index(:videos, [:category, :inserted_at])

    # Trigram indexes for fast search on title and description
    execute "CREATE INDEX IF NOT EXISTS videos_title_trgm_idx ON videos USING gin (title gin_trgm_ops);"

    execute "CREATE INDEX IF NOT EXISTS videos_desc_trgm_idx ON videos USING gin (description gin_trgm_ops);"
  end
end
