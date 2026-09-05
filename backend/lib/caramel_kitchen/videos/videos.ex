defmodule CaramelKitchen.Videos do
  @moduledoc """
  Context module for Videos in Caramel Kitchen.
  Provides full CRUD operations, category management, filtering, and access level gating.
  """
  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Videos.Video
  alias CaramelKitchen.Accounts.User

  @doc """
  Lists videos with filtering, sorting, and pagination.
  Options supported:
    - `:category` - category name (case-insensitive)
    - `:search` - term to match against title or description
    - `:upload_date` - date string (YYYY-MM-DD) or "today", "this_week", "this_month", "this_year"
    - `:is_premium` - boolean or "true"/"false"
    - `:is_special` - boolean or "true"/"false"
    - `:order` - "newest" (default), "oldest", "popular"
    - `:limit` - integer (default 20, max 100)
    - `:offset` - integer (default 0)
  """
  def list_videos(params \\ %{}, current_user \\ nil) do
    base_query = from(v in Video)

    videos =
      base_query
      |> apply_category_filter(params[:category] || params["category"])
      |> apply_search_filter(params[:search] || params["search"])
      |> apply_upload_date_filter(params[:upload_date] || params["upload_date"])
      |> apply_premium_filter(
        params[:is_premium] || params["is_premium"] || params[:is_special] || params["is_special"]
      )
      |> apply_ordering(params[:order] || params["order"])
      |> apply_pagination(params)
      |> Repo.all()

    Enum.map(videos, &redact_video(&1, current_user))
  end

  @doc "Count total videos matching filters"
  def count_videos(params \\ %{}) do
    from(v in Video)
    |> apply_category_filter(params[:category] || params["category"])
    |> apply_search_filter(params[:search] || params["search"])
    |> apply_upload_date_filter(params[:upload_date] || params["upload_date"])
    |> apply_premium_filter(
      params[:is_premium] || params["is_premium"] || params[:is_special] || params["is_special"]
    )
    |> Repo.aggregate(:count, :id)
  end

  @doc "Get a single video by id"
  def get_video(id) do
    case Repo.get(Video, id) do
      nil -> {:error, :not_found}
      video -> {:ok, video}
    end
  end

  @doc "Get a single video by id, raising if not found"
  def get_video!(id), do: Repo.get!(Video, id)

  @doc "Get a video redacted for current user's access level"
  def get_video_for_user(id, current_user) do
    case get_video(id) do
      {:ok, video} ->
        {:ok, redact_video(video, current_user), has_access?(video, current_user)}

      error ->
        error
    end
  end

  @doc "Create a video (requires creator or admin user)"
  def create_video(attrs, creator \\ nil) do
    creator_id = if creator, do: creator.id, else: nil

    attrs =
      cond do
        is_nil(creator_id) ->
          attrs

        Map.has_key?(attrs, "creator_id") or Map.has_key?(attrs, :creator_id) ->
          attrs

        Enum.any?(Map.keys(attrs), &is_binary/1) ->
          Map.put(attrs, "creator_id", creator_id)

        true ->
          Map.put(attrs, :creator_id, creator_id)
      end

    %Video{}
    |> Video.creation_changeset(attrs)
    |> Repo.insert()
  end

  @doc "Update an existing video"
  def update_video(%Video{} = video, attrs) do
    video
    |> Video.update_changeset(attrs)
    |> Repo.update()
  end

  @doc "Delete a video"
  def delete_video(%Video{} = video) do
    Repo.delete(video)
  end

  @doc "Increment video views"
  def increment_views(%Video{} = video) do
    video
    |> Video.increment_view_changeset()
    |> Repo.update()
  end

  @doc "List canonical categories and their video counts"
  def list_categories do
    counts_by_category =
      from(v in Video,
        group_by: v.category,
        select: {v.category, count(v.id)}
      )
      |> Repo.all()
      |> Map.new()

    Enum.map(Video.valid_categories(), fn cat ->
      %{
        name: cat,
        count: Map.get(counts_by_category, cat, 0)
      }
    end)
  end

  # ── Access Level Verification ─────────────────────────────────

  @doc "Check if a user has access to a video"
  def has_access?(%Video{is_premium: false}, _user), do: true
  def has_access?(%Video{is_premium: true}, nil), do: false

  def has_access?(%Video{is_premium: true}, %User{} = user) do
    User.admin?(user) || User.premium?(user)
  end

  @doc "Redact video fields if user does not have access"
  def redact_video(%Video{} = video, user) do
    if has_access?(video, user) do
      Map.put(video, :is_locked, false)
    else
      video
      |> Map.put(:is_locked, true)
      |> Map.put(:yt_embed_code, nil)
      |> Map.put(:video_embed_url, nil)
      |> Map.put(:video_url, nil)
    end
  end

  # ── Filter Builders ──────────────────────────────────────────

  defp apply_category_filter(query, nil), do: query
  defp apply_category_filter(query, ""), do: query

  defp apply_category_filter(query, category) do
    normalized =
      cond do
        String.downcase(category) in ["quick cooking", "quick_cooking"] ->
          ["Quick Cooking", "Quick_Cooking"]

        true ->
          [category]
      end

    from v in query, where: v.category in ^normalized
  end

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, search_term) do
    term = "%#{String.trim(search_term)}%"

    from v in query,
      where: ilike(v.title, ^term) or ilike(v.description, ^term)
  end

  defp apply_upload_date_filter(query, nil), do: query
  defp apply_upload_date_filter(query, ""), do: query

  defp apply_upload_date_filter(query, "today") do
    start_of_day =
      DateTime.utc_now() |> DateTime.to_date() |> DateTime.new!(~T[00:00:00], "Etc/UTC")

    from v in query, where: v.inserted_at >= ^start_of_day
  end

  defp apply_upload_date_filter(query, "this_week") do
    seven_days_ago = DateTime.utc_now() |> DateTime.add(-7, :day)
    from v in query, where: v.inserted_at >= ^seven_days_ago
  end

  defp apply_upload_date_filter(query, "this_month") do
    thirty_days_ago = DateTime.utc_now() |> DateTime.add(-30, :day)
    from v in query, where: v.inserted_at >= ^thirty_days_ago
  end

  defp apply_upload_date_filter(query, "this_year") do
    now = DateTime.utc_now()
    start_of_year = Date.new!(now.year, 1, 1) |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    from v in query, where: v.inserted_at >= ^start_of_year
  end

  defp apply_upload_date_filter(query, date_str) when is_binary(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} ->
        start_time = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
        end_time = DateTime.new!(date, ~T[23:59:59], "Etc/UTC")
        from v in query, where: v.inserted_at >= ^start_time and v.inserted_at <= ^end_time

      _ ->
        query
    end
  end

  defp apply_premium_filter(query, nil), do: query
  defp apply_premium_filter(query, ""), do: query
  defp apply_premium_filter(query, true), do: from(v in query, where: v.is_premium == true)
  defp apply_premium_filter(query, "true"), do: from(v in query, where: v.is_premium == true)
  defp apply_premium_filter(query, false), do: from(v in query, where: v.is_premium == false)
  defp apply_premium_filter(query, "false"), do: from(v in query, where: v.is_premium == false)
  defp apply_premium_filter(query, _), do: query

  defp apply_ordering(query, "oldest"), do: from(v in query, order_by: [asc: v.inserted_at])

  defp apply_ordering(query, "popular"),
    do: from(v in query, order_by: [desc: v.view_count, desc: v.inserted_at])

  defp apply_ordering(query, _), do: from(v in query, order_by: [desc: v.inserted_at])

  defp apply_pagination(query, params) do
    limit = parse_int(params[:limit] || params["limit"], 20) |> min(100) |> max(1)

    offset =
      cond do
        params[:offset] || params["offset"] ->
          parse_int(params[:offset] || params["offset"], 0)

        params[:page] || params["page"] ->
          page = parse_int(params[:page] || params["page"], 1) |> max(1)
          (page - 1) * limit

        true ->
          0
      end

    from v in query, limit: ^limit, offset: ^offset
  end

  defp parse_int(val, _default) when is_integer(val), do: val

  defp parse_int(str, default) when is_binary(str) do
    case Integer.parse(str) do
      {val, _} -> val
      :error -> default
    end
  end

  defp parse_int(_, default), do: default
end
