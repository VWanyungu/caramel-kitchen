defmodule CaramelKitchen.Collections.CollectionItem do
  @moduledoc """
  Schema for an item (recipe or video) inside a curated Collection.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_item_types ~w(recipe video)

  schema "collection_items" do
    belongs_to :collection, CaramelKitchen.Collections.Collection
    belongs_to :recipe, CaramelKitchen.Recipes.Recipe
    belongs_to :video, CaramelKitchen.Videos.Video

    field :item_type, :string
    field :position, :integer, default: 0
    field :notes, :string

    timestamps(type: :utc_datetime)
  end

  def valid_item_types, do: @valid_item_types

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:collection_id, :item_type, :recipe_id, :video_id, :position, :notes])
    |> validate_required([:collection_id, :item_type])
    |> validate_inclusion(:item_type, @valid_item_types)
    |> validate_item_reference()
    |> unique_constraint(:recipe_id,
      name: :collection_items_unique_recipe_idx,
      message: "recipe already in collection"
    )
    |> unique_constraint(:video_id,
      name: :collection_items_unique_video_idx,
      message: "video already in collection"
    )
  end

  defp validate_item_reference(cs) do
    case get_field(cs, :item_type) do
      "recipe" ->
        validate_required(cs, [:recipe_id])

      "video" ->
        validate_required(cs, [:video_id])

      _ ->
        cs
    end
  end
end
