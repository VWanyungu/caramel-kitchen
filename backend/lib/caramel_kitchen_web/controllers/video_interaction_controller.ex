defmodule CaramelKitchenWeb.VideoInteractionController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.Videos
  alias CaramelKitchenWeb.VideoInteractionJSON

  @doc "POST /api/v1/videos/:id/favorite — Favorite a video"
  def favorite(conn, %{"id" => video_id} = params) do
    user = conn.assigns.current_user
    metadata = Map.get(params, "metadata", %{})

    with {:ok, result} <- Videos.favorite_video(user, video_id, metadata) do
      json(conn, VideoInteractionJSON.action_result(%{result: result}))
    end
  end

  @doc "DELETE /api/v1/videos/:id/favorite — Unfavorite a video"
  def unfavorite(conn, %{"id" => video_id}) do
    user = conn.assigns.current_user

    with {:ok, result} <- Videos.unfavorite_video(user, video_id) do
      json(conn, VideoInteractionJSON.action_result(%{result: result}))
    end
  end

  @doc "POST /api/v1/videos/:id/save — Save a video to watch later"
  def save(conn, %{"id" => video_id} = params) do
    user = conn.assigns.current_user
    metadata = Map.get(params, "metadata", %{})

    with {:ok, result} <- Videos.save_video(user, video_id, metadata) do
      json(conn, VideoInteractionJSON.action_result(%{result: result}))
    end
  end

  @doc "DELETE /api/v1/videos/:id/save — Unsave a video"
  def unsave(conn, %{"id" => video_id}) do
    user = conn.assigns.current_user

    with {:ok, result} <- Videos.unsave_video(user, video_id) do
      json(conn, VideoInteractionJSON.action_result(%{result: result}))
    end
  end

  @doc "GET /api/v1/videos/:id/status — Get video interaction status for current user"
  def status(conn, %{"id" => video_id}) do
    user = conn.assigns[:current_user]

    with {:ok, status} <- Videos.get_user_video_status(user, video_id) do
      json(conn, VideoInteractionJSON.status(%{status: status}))
    end
  end

  @doc "GET /api/v1/me/videos/favorites — List user's favorited videos"
  def favorite_videos(conn, params) do
    user = conn.assigns.current_user
    videos = Videos.list_favorite_videos(user, params)
    total_count = Videos.count_favorite_videos(user, params)

    meta = %{
      count: length(videos),
      limit: parse_int(params["limit"], 20),
      offset: parse_int(params["offset"], 0)
    }

    json(
      conn,
      VideoInteractionJSON.favorite_videos(%{
        videos: videos,
        total_count: total_count,
        meta: meta
      })
    )
  end

  @doc "GET /api/v1/me/videos/saved — List user's saved watch-later videos"
  def saved_videos(conn, params) do
    user = conn.assigns.current_user
    videos = Videos.list_saved_videos(user, params)
    total_count = Videos.count_saved_videos(user, params)

    meta = %{
      count: length(videos),
      limit: parse_int(params["limit"], 20),
      offset: parse_int(params["offset"], 0)
    }

    json(
      conn,
      VideoInteractionJSON.saved_videos(%{
        videos: videos,
        total_count: total_count,
        meta: meta
      })
    )
  end

  # ── Helpers ───────────────────────────────────────────────────

  defp parse_int(val, _default) when is_integer(val), do: val

  defp parse_int(str, default) when is_binary(str) do
    case Integer.parse(str) do
      {val, _} -> val
      :error -> default
    end
  end

  defp parse_int(_, default), do: default
end
