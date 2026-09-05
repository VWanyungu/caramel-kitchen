defmodule CaramelKitchen.Taxonomies.Taxonomy do
  @moduledoc """
  Schema for taxonomy items (categories, cuisines, dietary tags, and difficulty levels).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_types ~w(category cuisine dietary_tag difficulty)

  schema "taxonomies" do
    field :type, :string
    field :name, :string
    field :slug, :string
    field :description, :string
    field :icon_url, :string
    field :display_order, :integer, default: 0
    field :is_active, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  def valid_types, do: @valid_types

  @doc "Changeset for creating a taxonomy"
  def changeset(taxonomy, attrs) do
    taxonomy
    |> cast(attrs, [:type, :name, :slug, :description, :icon_url, :display_order, :is_active])
    |> validate_required([:type, :name])
    |> validate_inclusion(:type, @valid_types)
    |> put_slug()
    |> unique_constraint(:slug, name: :taxonomies_type_slug_index)
  end

  @doc "Changeset for updating a taxonomy"
  def update_changeset(taxonomy, attrs) do
    taxonomy
    |> cast(attrs, [:name, :slug, :description, :icon_url, :display_order, :is_active])
    |> put_slug()
    |> unique_constraint(:slug, name: :taxonomies_type_slug_index)
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
