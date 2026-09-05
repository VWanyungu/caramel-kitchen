defmodule CaramelKitchen.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table(:collections, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :cover_image_url, :string
      add :is_public, :boolean, default: true, null: false
      add :is_curated, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:collections, [:user_id])
    create index(:collections, [:is_public])
    create index(:collections, [:is_curated])
    create index(:collections, [:inserted_at])
    create unique_index(:collections, [:user_id, :slug])

    create table(:collection_items, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :collection_id, references(:collections, type: :uuid, on_delete: :delete_all), null: false
      add :item_type, :string, null: false
      add :recipe_id, references(:recipes, type: :uuid, on_delete: :delete_all)
      add :video_id, references(:videos, type: :uuid, on_delete: :delete_all)
      add :position, :integer, default: 0, null: false
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:collection_items, [:collection_id])
    create index(:collection_items, [:recipe_id])
    create index(:collection_items, [:video_id])
    create index(:collection_items, [:collection_id, :position])

    create unique_index(:collection_items, [:collection_id, :recipe_id],
      where: "recipe_id IS NOT NULL",
      name: :collection_items_unique_recipe_idx
    )

    create unique_index(:collection_items, [:collection_id, :video_id],
      where: "video_id IS NOT NULL",
      name: :collection_items_unique_video_idx
    )
  end
end
