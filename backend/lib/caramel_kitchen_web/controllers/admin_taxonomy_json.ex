defmodule CaramelKitchenWeb.AdminTaxonomyJSON do
  @moduledoc """
  JSON serializer for AdminTaxonomyController.
  """

  def index(%{taxonomies: taxonomies}) do
    %{data: Enum.map(taxonomies, &data/1)}
  end

  def show(%{taxonomy: taxonomy}) do
    %{data: data(taxonomy)}
  end

  def data(taxonomy) do
    %{
      id: taxonomy.id,
      type: taxonomy.type,
      name: taxonomy.name,
      slug: taxonomy.slug,
      description: taxonomy.description,
      icon_url: taxonomy.icon_url,
      display_order: taxonomy.display_order,
      is_active: taxonomy.is_active,
      created_at: taxonomy.inserted_at,
      updated_at: taxonomy.updated_at
    }
  end
end
