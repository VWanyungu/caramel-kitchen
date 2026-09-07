defmodule CaramelKitchenWeb.CollectionJSON do
  @moduledoc """
  JSON serializer for Collections.
  Renders collection cards, full details with recipes and videos, and collection items.
  """

  def index(%{collections: collections} = assigns) do
    meta = Map.get(assigns, :meta, %{})
    viewer = Map.get(assigns, :current_user)

    %{
      data: Enum.map(collections, &collection_card(&1, viewer)),
      meta: meta
    }
  end

  def show(%{collection: collection} = assigns) do
    viewer = Map.get(assigns, :current_user)
    %{data: collection_detail(collection, viewer)}
  end

  def item(%{item: item}) do
    %{data: render_item(item)}
  end

  def action_result(%{result: result}) do
    %{data: result}
  end

  def status(%{status: status}) do
    %{data: status}
  end

  def collection_card(collection, viewer \\ nil) do
    items = collection.items || []
    is_premium = collection.is_premium || false
    is_locked = is_premium and not CaramelKitchen.Collections.has_access?(collection, viewer)
    is_saved = CaramelKitchen.Collections.is_saved?(viewer, collection.id)

    %{
      id: collection.id,
      user_id: collection.user_id,
      name: collection.name,
      slug: collection.slug,
      description: collection.description,
      cover_image_url: derive_cover_image(collection, items),
      is_public: collection.is_public,
      is_curated: collection.is_curated,
      is_premium: is_premium,
      is_locked: is_locked,
      save_count: collection.save_count || 0,
      is_saved: is_saved,
      recipe_count: Enum.count(items, &(&1.item_type == "recipe")),
      video_count: Enum.count(items, &(&1.item_type == "video")),
      total_items: length(items),
      author: render_author(collection.user),
      created_at: collection.inserted_at,
      updated_at: collection.updated_at
    }
  end

  def collection_detail(collection, viewer \\ nil) do
    items = collection.items || []

    collection
    |> collection_card(viewer)
    |> Map.put(:items, Enum.map(items, &render_item/1))
  end

  def render_item(item) do
    %{
      id: item.id,
      collection_id: item.collection_id,
      item_type: item.item_type,
      position: item.position,
      notes: item.notes,
      recipe_id: item.recipe_id,
      video_id: item.video_id,
      recipe:
        if(Ecto.assoc_loaded?(item.recipe) && item.recipe,
          do: render_recipe(item.recipe),
          else: nil
        ),
      video:
        if(Ecto.assoc_loaded?(item.video) && item.video, do: render_video(item.video), else: nil),
      created_at: item.inserted_at
    }
  end

  defp render_author(nil), do: nil
  defp render_author(%Ecto.Association.NotLoaded{}), do: nil

  defp render_author(user) do
    %{
      id: user.id,
      name: user.name,
      avatar_url: user.avatar_url,
      role: user.role
    }
  end

  defp render_recipe(recipe) do
    %{
      id: recipe.id,
      slug: recipe.slug,
      title: recipe.title,
      thumbnail_url: recipe.thumbnail_url,
      dish_category: recipe.dish_category,
      dish_categories: recipe.dish_categories || [],
      course: recipe.course,
      difficulty: recipe.difficulty,
      total_time_mins: recipe.total_time_mins,
      calories: recipe.calories,
      avg_rating: recipe.avg_rating,
      is_special: recipe.is_special
    }
  end

  defp render_video(video) do
    %{
      id: video.id,
      title: video.title,
      description: video.description,
      category: video.category,
      thumbnail_url: video.thumbnail_url,
      duration_secs: video.duration_secs,
      is_premium: video.is_premium,
      is_special: video.is_special,
      youtube_video_id: video.youtube_video_id
    }
  end

  defp derive_cover_image(collection, items) do
    cond do
      is_binary(collection.cover_image_url) and collection.cover_image_url != "" ->
        collection.cover_image_url

      first_recipe = Enum.find(items, &(&1.item_type == "recipe" and &1.recipe)) ->
        first_recipe.recipe.thumbnail_url

      first_video = Enum.find(items, &(&1.item_type == "video" and &1.video)) ->
        first_video.video.thumbnail_url

      true ->
        nil
    end
  end
end
