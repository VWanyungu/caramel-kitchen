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
    has_many :interactions, CaramelKitchen.Collections.UserCollectionInteraction, on_delete: :delete_all

    field :name, :string
    field :slug, :string
    field :description, :string
    field :cover_image_url, :string
    field :is_public, :boolean, default: true
    field :is_curated, :boolean, default: false
    field :is_premium, :boolean, default: false
    field :is_seasonal, :boolean, default: false
    field :season_name, :string
    field :start_date, :date
    field :end_date, :date
    field :save_count, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  def changeset(collection, attrs) do
    attrs = normalize_seasonal_attrs(attrs)

    collection
    |> cast(attrs, [
      :user_id,
      :name,
      :slug,
      :description,
      :cover_image_url,
      :is_public,
      :is_curated,
      :is_premium,
      :is_seasonal,
      :season_name,
      :start_date,
      :end_date
    ])
    |> validate_required([:user_id, :name])
    |> validate_seasonal()
    |> put_slug()
    |> unique_constraint(:slug,
      name: :collections_user_id_slug_index,
      message: "slug already exists for this user"
    )
  end

  def update_changeset(collection, attrs) do
    attrs = normalize_seasonal_attrs(attrs)

    collection
    |> cast(attrs, [
      :name,
      :slug,
      :description,
      :cover_image_url,
      :is_public,
      :is_curated,
      :is_premium,
      :is_seasonal,
      :season_name,
      :start_date,
      :end_date
    ])
    |> validate_seasonal()
    |> put_slug()
    |> unique_constraint(:slug,
      name: :collections_user_id_slug_index,
      message: "slug already exists for this user"
    )
  end

  @doc "Checks if collection is currently within season (or non-seasonal)"
  def in_season?(collection, date \\ nil)
  def in_season?(collection, nil), do: in_season?(collection, Date.utc_today())
  def in_season?(%__MODULE__{is_seasonal: false}, _date), do: true
  def in_season?(%__MODULE__{is_seasonal: true, start_date: nil, end_date: nil}, _date), do: true

  def in_season?(%__MODULE__{is_seasonal: true, start_date: start_d, end_date: end_d}, date) do
    after_start = is_nil(start_d) or Date.compare(date, start_d) in [:gt, :eq]
    before_end = is_nil(end_d) or Date.compare(date, end_d) in [:lt, :eq]
    after_start and before_end
  end

  defp validate_seasonal(cs) do
    is_seasonal = get_field(cs, :is_seasonal)

    if is_seasonal do
      cs
      |> validate_required([:season_name])
      |> validate_date_range()
    else
      cs
    end
  end

  defp validate_date_range(cs) do
    start_date = get_field(cs, :start_date)
    end_date = get_field(cs, :end_date)

    if start_date && end_date && Date.compare(start_date, end_date) == :gt do
      add_error(cs, :end_date, "must be on or after start_date")
    else
      cs
    end
  end

  defp normalize_seasonal_attrs(attrs) when is_map(attrs) do
    attrs
    |> maybe_map_key("season_start_date", "start_date")
    |> maybe_map_key(:season_start_date, :start_date)
    |> maybe_map_key("season_end_date", "end_date")
    |> maybe_map_key(:season_end_date, :end_date)
  end

  defp normalize_seasonal_attrs(attrs), do: attrs

  defp maybe_map_key(map, old_key, new_key) do
    case Map.fetch(map, old_key) do
      {:ok, val} ->
        map
        |> Map.delete(old_key)
        |> Map.put_new(new_key, val)

      :error ->
        map
    end
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
