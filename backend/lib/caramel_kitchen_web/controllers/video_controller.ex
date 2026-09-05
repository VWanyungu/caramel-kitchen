defmodule CaramelKitchenWeb.VideoController do
  use CaramelKitchenWeb, :controller
  action_fallback CaramelKitchenWeb.FallbackController

  alias CaramelKitchen.Videos
  alias CaramelKitchenWeb.VideoJSON

  # ── Public / Browsing Endpoints ───────────────────────────────

  @doc "GET /api/v1/videos — List & filter videos"
  def index(conn, params) do
    current_user = conn.assigns[:current_user]
    videos = Videos.list_videos(params, current_user)
    total_count = Videos.count_videos(params)

    meta = %{
      count: length(videos),
      limit: parse_int(params["limit"], 20),
      offset: parse_int(params["offset"], 0)
    }

    json(conn, VideoJSON.index(%{videos: videos, total_count: total_count, meta: meta}))
  end

  @doc "GET /api/v1/videos/categories — List categories and counts"
  def categories(conn, _params) do
    categories = Videos.list_categories()
    json(conn, VideoJSON.categories(%{categories: categories}))
  end

  @doc "GET /api/v1/videos/:id — Show video details"
  def show(conn, %{"id" => id}) do
    current_user = conn.assigns[:current_user]

    with {:ok, video, _has_access?} <- Videos.get_video_for_user(id, current_user) do
      # Track view count safely
      {:ok, updated_video} = Videos.increment_views(video)
      # Preserve redacted state
      result = Map.put(updated_video, :is_locked, Map.get(video, :is_locked, false))

      result =
        if result.is_locked do
          result
          |> Map.put(:yt_embed_code, nil)
          |> Map.put(:video_embed_url, nil)
          |> Map.put(:video_url, nil)
        else
          result
        end

      json(conn, VideoJSON.show(%{video: result}))
    end
  end

  # ── Admin / Creator Management Endpoints ──────────────────────

  @doc "POST /api/v1/admin/videos — Create a new video"
  def create(conn, params) do
    current_user = conn.assigns[:current_user]
    video_attrs = unwrap_params(params)

    with {:ok, video} <- Videos.create_video(video_attrs, current_user) do
      conn
      |> put_status(:created)
      |> json(VideoJSON.show(%{video: video}))
    end
  end

  @doc "PUT /api/v1/admin/videos/:id — Update an existing video"
  def update(conn, %{"id" => id} = params) do
    video_attrs = unwrap_params(params) |> Map.delete("id") |> Map.delete(:id)

    with {:ok, video} <- Videos.get_video(id),
         {:ok, updated} <- Videos.update_video(video, video_attrs) do
      json(conn, VideoJSON.show(%{video: updated}))
    end
  end

  @doc "DELETE /api/v1/admin/videos/:id — Delete a video"
  def delete(conn, %{"id" => id}) do
    with {:ok, video} <- Videos.get_video(id),
         {:ok, _deleted} <- Videos.delete_video(video) do
      json(conn, %{data: %{id: id, message: "Video deleted successfully"}})
    end
  end

  # ── Helpers ───────────────────────────────────────────────────

  defp unwrap_params(%{"video" => video_params}) when is_map(video_params), do: video_params
  defp unwrap_params(params) when is_map(params), do: params

  defp parse_int(val, _default) when is_integer(val), do: val

  defp parse_int(str, default) when is_binary(str) do
    case Integer.parse(str) do
      {val, _} -> val
      :error -> default
    end
  end

  defp parse_int(_, default), do: default
end
