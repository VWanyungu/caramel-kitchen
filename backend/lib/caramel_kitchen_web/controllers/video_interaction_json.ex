defmodule CaramelKitchenWeb.VideoInteractionJSON do
  @moduledoc """
  JSON serializer for video interactions (favorites and saved watch-later videos).
  """
  alias CaramelKitchenWeb.VideoJSON

  @doc "Renders action result (favorite, unfavorite, save, unsave)"
  def action_result(%{result: result}) do
    %{
      data: %{
        video_id: result.video_id,
        action: result.action,
        status: result.status,
        is_favorited: result.is_favorited,
        is_saved: result.is_saved,
        favorite_count: result.favorite_count,
        save_count: result.save_count,
        interacted_at: Map.get(result, :favorited_at) || Map.get(result, :saved_at)
      }
    }
  end

  @doc "Renders status of video interactions for a user"
  def status(%{status: status}) do
    %{
      data: %{
        video_id: status.video_id,
        is_favorited: status.is_favorited,
        is_saved: status.is_saved,
        favorite_count: status.favorite_count,
        save_count: status.save_count
      }
    }
  end

  @doc "Renders a paginated list of favorited videos"
  def favorite_videos(%{videos: videos, total_count: total_count, meta: meta}) do
    %{
      data: Enum.map(videos, &render_favorite_item/1),
      meta: Map.put(meta, :total_count, total_count)
    }
  end

  @doc "Renders a paginated list of saved (watch later) videos"
  def saved_videos(%{videos: videos, total_count: total_count, meta: meta}) do
    %{
      data: Enum.map(videos, &render_saved_item/1),
      meta: Map.put(meta, :total_count, total_count)
    }
  end

  defp render_favorite_item(video) do
    video_data = VideoJSON.data(video)

    video_data
    |> Map.put(:favorited_at, video.favorited_at || video.interacted_at)
    |> Map.put(:video, video_data)
  end

  defp render_saved_item(video) do
    video_data = VideoJSON.data(video)

    video_data
    |> Map.put(:saved_at, video.saved_at || video.interacted_at)
    |> Map.put(:video, video_data)
  end
end
