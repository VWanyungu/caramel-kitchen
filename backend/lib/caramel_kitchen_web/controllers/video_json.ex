defmodule CaramelKitchenWeb.VideoJSON do
  @moduledoc """
  JSON views for VideoController.
  Handles serialization of videos, collections, categories, and access levels.
  """

  @doc "Renders a list of videos with metadata"
  def index(%{videos: videos, total_count: total_count, meta: meta}) do
    %{
      data: Enum.map(videos, &data/1),
      meta: Map.put(meta, :total_count, total_count)
    }
  end

  def index(%{videos: videos}) do
    %{
      data: Enum.map(videos, &data/1),
      meta: %{count: length(videos)}
    }
  end

  @doc "Renders a single video"
  def show(%{video: video}) do
    %{data: data(video)}
  end

  @doc "Renders categories with counts"
  def categories(%{categories: categories}) do
    %{data: categories}
  end

  @doc "Serializes a single video struct"
  def data(video) do
    %{
      id: video.id,
      title: video.title,
      description: video.description,
      category: video.category,
      is_premium: video.is_premium,
      is_special: video.is_special || video.is_premium,
      is_locked: Map.get(video, :is_locked, false),
      yt_embed_code: video.yt_embed_code,
      youtube_video_id: video.youtube_video_id,
      video_url: video.video_url,
      video_embed_url: video.video_embed_url,
      thumbnail_url: video.thumbnail_url,
      duration_secs: video.duration_secs,
      view_count: video.view_count,
      creator_id: video.creator_id,
      created_at: video.inserted_at,
      updated_at: video.updated_at,
      inserted_at: video.inserted_at
    }
  end
end
