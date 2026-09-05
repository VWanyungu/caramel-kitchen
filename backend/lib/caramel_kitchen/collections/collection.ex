defmodule CaramelKitchen.Collections.Collection do
  @moduledoc """
  Schema for a curated Collection containing recipes and videos.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "collections" do
    belongs_to :user, CaramelKitchen.Accounts.User
    has_many :items, CaramelKitchen.Collections.CollectionItem, on_delete: :delete_all

    field :name, :string
    field :slug, :string
    field :description, :string
    field :cover_image_url, :string
    field :is_public, :boolean, default: true
    field :is_curated, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  def changeset(collection, attrs) do
    collection
    |> cast(attrs, [
      :user_id,
      :name,
      :slug,
      :description,
      :cover_image_url,
      :is_public,
      :is_curated
    ])
    |> validate_required([:user_id, :name])
    |> put_slug()
    |> unique_constraint(:slug,
      name: :collections_user_id_slug_index,
      message: "slug already exists for this user"
    )
  end

  def update_changeset(collection, attrs) do
    collection
    |> cast(attrs, [:name, :slug, :description, :cover_image_url, :is_public, :is_curated])
    |> put_slug()
    |> unique_constraint(:slug,
      name: :collections_user_id_slug_index,
      message: "slug already exists for this user"
    )
  end

  defp put_slug(cs) do
    case {get_change(cs, :slug), get_field(cs, :slug), get_field(cs, :name)} do
      {slug, _, _} when is_binary(slug) and slug != "" ->
        put_change(cs, :slug, slugify(slug))

      {_, nil, name} when is_binary(name) and name != "" ->
        put_change(cs, :slug, slugify(name))

      {_, "", name} when is_binary(name) and name != "" ->
        put_change(cs, :slug, slugify(name))

      _ ->
        cs
    end
  end

  defp slugify(text) when is_binary(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/i, "_")
    |> String.trim("_")
  end
end
