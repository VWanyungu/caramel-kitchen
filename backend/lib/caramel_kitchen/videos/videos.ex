defmodule CaramelKitchen.Videos do
  @moduledoc """
  Context module for Videos in Caramel Kitchen.
  Provides full CRUD operations, category management, filtering, tier-based access level gating,
  and separate tracking of user favorites and saved (watch later) videos.
  """
  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Videos.Video
  alias CaramelKitchen.Videos.UserVideoInteraction
  alias CaramelKitchen.Accounts.User

  @doc """
  Lists videos with filtering, sorting, and pagination.
  Options supported:
    - `:category` - category name (case-insensitive)
    - `:search` - term to match against title or description
    - `:upload_date` - date string (YYYY-MM-DD) or "today", "this_week", "this_month", "this_year"
    - `:is_premium` - boolean or "true"/"false"
    - `:is_special` - boolean or "true"/"false"
    - `:order` - "newest" (default), "oldest", "popular", "most_favorited", "most_saved"
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

    videos
    |> Enum.map(&redact_video(&1, current_user))
    |> annotate_user_interactions(current_user)
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

  @doc "Get a video redacted for current user's access level and annotated with interaction status"
  def get_video_for_user(id, current_user) do
    case get_video(id) do
      {:ok, video} ->
        is_fav = is_favorited?(current_user, video.id)
        is_sav = is_saved?(current_user, video.id)

        annotated =
          video
          |> redact_video(current_user)
          |> Map.put(:is_favorited, is_fav)
          |> Map.put(:is_saved, is_sav)

        {:ok, annotated, has_access?(video, current_user)}

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

  # ── Favorite & Saved Video Interactions (Issue #112) ───────────

  @doc """
  Favorites a video for a user (videos user enjoys).
  Idempotent: if already favorited, returns existing status.
  Increments video.favorite_count on initial favorite.
  """
  def favorite_video(%User{} = user, video_id, metadata \\ %{}) do
    with {:ok, video} <- get_video(video_id) do
      case Repo.get_by(UserVideoInteraction, user_id: user.id, video_id: video.id, action: "favorite") do
        nil ->
          %UserVideoInteraction{}
          |> UserVideoInteraction.changeset(%{
            user_id: user.id,
            video_id: video.id,
            action: "favorite",
            metadata: metadata
          })
          |> Repo.insert()
          |> case do
            {:ok, interaction} ->
              from(v in Video, where: v.id == ^video.id)
              |> Repo.update_all(inc: [favorite_count: 1])

              updated_video = get_video!(video.id)

              {:ok,
               %{
                 video_id: video.id,
                 action: "favorite",
                 status: "favorited",
                 is_favorited: true,
                 is_saved: is_saved?(user, video.id),
                 favorite_count: updated_video.favorite_count,
                 save_count: updated_video.save_count,
                 favorited_at: interaction.inserted_at
               }}

            {:error, changeset} ->
              {:error, changeset}
          end

        existing ->
          {:ok,
           %{
             video_id: video.id,
             action: "favorite",
             status: "already_favorited",
             is_favorited: true,
             is_saved: is_saved?(user, video.id),
             favorite_count: video.favorite_count,
             save_count: video.save_count,
             favorited_at: existing.inserted_at
           }}
      end
    end
  end

  @doc """
  Unfavorites a video for a user.
  Decrements video.favorite_count safely.
  """
  def unfavorite_video(%User{} = user, video_id) do
    with {:ok, video} <- get_video(video_id) do
      case Repo.get_by(UserVideoInteraction, user_id: user.id, video_id: video.id, action: "favorite") do
        nil ->
          {:ok,
           %{
             video_id: video.id,
             action: "favorite",
             status: "not_favorited",
             is_favorited: false,
             is_saved: is_saved?(user, video.id),
             favorite_count: video.favorite_count,
             save_count: video.save_count
           }}

        interaction ->
          case Repo.delete(interaction) do
            {:ok, _} ->
              from(v in Video, where: v.id == ^video.id and v.favorite_count > 0)
              |> Repo.update_all(inc: [favorite_count: -1])

              updated_video = get_video!(video.id)

              {:ok,
               %{
                 video_id: video.id,
                 action: "favorite",
                 status: "unfavorited",
                 is_favorited: false,
                 is_saved: is_saved?(user, video.id),
                 favorite_count: updated_video.favorite_count,
                 save_count: updated_video.save_count
               }}

            error ->
              error
          end
      end
    end
  end

  @doc """
  Saves a video for a user to watch later.
  Idempotent: if already saved, returns existing status.
  Increments video.save_count on initial save.
  """
  def save_video(%User{} = user, video_id, metadata \\ %{}) do
    with {:ok, video} <- get_video(video_id) do
      case Repo.get_by(UserVideoInteraction, user_id: user.id, video_id: video.id, action: "saved") do
        nil ->
          %UserVideoInteraction{}
          |> UserVideoInteraction.changeset(%{
            user_id: user.id,
            video_id: video.id,
            action: "saved",
            metadata: metadata
          })
          |> Repo.insert()
          |> case do
            {:ok, interaction} ->
              from(v in Video, where: v.id == ^video.id)
              |> Repo.update_all(inc: [save_count: 1])

              updated_video = get_video!(video.id)

              {:ok,
               %{
                 video_id: video.id,
                 action: "saved",
                 status: "saved",
                 is_saved: true,
                 is_favorited: is_favorited?(user, video.id),
                 favorite_count: updated_video.favorite_count,
                 save_count: updated_video.save_count,
                 saved_at: interaction.inserted_at
               }}

            {:error, changeset} ->
              {:error, changeset}
          end

        existing ->
          {:ok,
           %{
             video_id: video.id,
             action: "saved",
             status: "already_saved",
             is_saved: true,
             is_favorited: is_favorited?(user, video.id),
             favorite_count: video.favorite_count,
             save_count: video.save_count,
             saved_at: existing.inserted_at
           }}
      end
    end
  end

  @doc """
  Unsaves a video for a user.
  Decrements video.save_count safely.
  """
  def unsave_video(%User{} = user, video_id) do
    with {:ok, video} <- get_video(video_id) do
      case Repo.get_by(UserVideoInteraction, user_id: user.id, video_id: video.id, action: "saved") do
        nil ->
          {:ok,
           %{
             video_id: video.id,
             action: "saved",
             status: "not_saved",
             is_saved: false,
             is_favorited: is_favorited?(user, video.id),
             favorite_count: video.favorite_count,
             save_count: video.save_count
           }}

        interaction ->
          case Repo.delete(interaction) do
            {:ok, _} ->
              from(v in Video, where: v.id == ^video.id and v.save_count > 0)
              |> Repo.update_all(inc: [save_count: -1])

              updated_video = get_video!(video.id)

              {:ok,
               %{
                 video_id: video.id,
                 action: "saved",
                 status: "unsaved",
                 is_saved: false,
                 is_favorited: is_favorited?(user, video.id),
                 favorite_count: updated_video.favorite_count,
                 save_count: updated_video.save_count
               }}

            error ->
              error
          end
      end
    end
  end

  @doc "Get interaction status (favorited/saved) and counts for a video"
  def get_user_video_status(user, video_id) do
    with {:ok, video} <- get_video(video_id) do
      is_fav = is_favorited?(user, video.id)
      is_sav = is_saved?(user, video.id)

      {:ok,
       %{
         video_id: video.id,
         is_favorited: is_fav,
         is_saved: is_sav,
         favorite_count: video.favorite_count,
         save_count: video.save_count
       }}
    end
  end

  @doc "Check if a user has favorited a video"
  def is_favorited?(nil, _video_id), do: false

  def is_favorited?(%User{id: user_id}, video_id) do
    Repo.exists?(
      from i in UserVideoInteraction,
        where: i.user_id == ^user_id and i.video_id == ^video_id and i.action == "favorite"
    )
  end

  @doc "Check if a user has saved a video to watch later"
  def is_saved?(nil, _video_id), do: false

  def is_saved?(%User{id: user_id}, video_id) do
    Repo.exists?(
      from i in UserVideoInteraction,
        where: i.user_id == ^user_id and i.video_id == ^video_id and i.action == "saved"
    )
  end

  @doc """
  Lists videos favorited by a user with pagination, sorting, and category filtering.
  Redacts premium content based on the user's subscription tier.
  """
  def list_favorite_videos(%User{} = user, params \\ %{}) do
    query =
      from(i in UserVideoInteraction,
        join: v in Video,
        on: v.id == i.video_id,
        where: i.user_id == ^user.id and i.action == "favorite",
        select: {v, i.inserted_at}
      )
      |> apply_interaction_category_filter(params[:category] || params["category"])
      |> apply_interaction_search_filter(params[:search] || params["search"])
      |> apply_interaction_ordering(params[:order] || params["order"])
      |> apply_interaction_pagination(params)

    results = Repo.all(query)

    video_ids = Enum.map(results, fn {v, _} -> v.id end)
    saved_ids = get_user_interaction_ids(user.id, video_ids, "saved")

    Enum.map(results, fn {video, favorited_at} ->
      video
      |> redact_video(user)
      |> Map.put(:is_favorited, true)
      |> Map.put(:is_saved, MapSet.member?(saved_ids, video.id))
      |> Map.put(:interacted_at, favorited_at)
      |> Map.put(:favorited_at, favorited_at)
    end)
  end

  @doc "Count total videos favorited by a user"
  def count_favorite_videos(%User{} = user, params \\ %{}) do
    from(i in UserVideoInteraction,
      join: v in Video,
      on: v.id == i.video_id,
      where: i.user_id == ^user.id and i.action == "favorite"
    )
    |> apply_interaction_category_filter(params[:category] || params["category"])
    |> apply_interaction_search_filter(params[:search] || params["search"])
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Lists videos saved by a user (watch later) with pagination, sorting, and category filtering.
  Redacts premium content based on the user's subscription tier.
  """
  def list_saved_videos(%User{} = user, params \\ %{}) do
    query =
      from(i in UserVideoInteraction,
        join: v in Video,
        on: v.id == i.video_id,
        where: i.user_id == ^user.id and i.action == "saved",
        select: {v, i.inserted_at}
      )
      |> apply_interaction_category_filter(params[:category] || params["category"])
      |> apply_interaction_search_filter(params[:search] || params["search"])
      |> apply_interaction_ordering(params[:order] || params["order"])
      |> apply_interaction_pagination(params)

    results = Repo.all(query)

    video_ids = Enum.map(results, fn {v, _} -> v.id end)
    fav_ids = get_user_interaction_ids(user.id, video_ids, "favorite")

    Enum.map(results, fn {video, saved_at} ->
      video
      |> redact_video(user)
      |> Map.put(:is_saved, true)
      |> Map.put(:is_favorited, MapSet.member?(fav_ids, video.id))
      |> Map.put(:interacted_at, saved_at)
      |> Map.put(:saved_at, saved_at)
    end)
  end

  @doc "Count total videos saved by a user"
  def count_saved_videos(%User{} = user, params \\ %{}) do
    from(i in UserVideoInteraction,
      join: v in Video,
      on: v.id == i.video_id,
      where: i.user_id == ^user.id and i.action == "saved"
    )
    |> apply_interaction_category_filter(params[:category] || params["category"])
    |> apply_interaction_search_filter(params[:search] || params["search"])
    |> Repo.aggregate(:count, :id)
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

  @doc "Annotate video list with interaction status for the current user"
  def annotate_user_interactions(videos, nil) do
    Enum.map(videos, fn v ->
      v
      |> Map.put(:is_favorited, false)
      |> Map.put(:is_saved, false)
    end)
  end

  def annotate_user_interactions(videos, %User{id: user_id}) do
    video_ids = Enum.map(videos, & &1.id)

    interactions =
      from(i in UserVideoInteraction,
        where: i.user_id == ^user_id and i.video_id in ^video_ids,
        select: {i.video_id, i.action}
      )
      |> Repo.all()
      |> MapSet.new()

    Enum.map(videos, fn v ->
      v
      |> Map.put(:is_favorited, MapSet.member?(interactions, {v.id, "favorite"}))
      |> Map.put(:is_saved, MapSet.member?(interactions, {v.id, "saved"}))
    end)
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

  defp apply_ordering(query, "most_favorited"),
    do: from(v in query, order_by: [desc: v.favorite_count, desc: v.inserted_at])

  defp apply_ordering(query, "most_saved"),
    do: from(v in query, order_by: [desc: v.save_count, desc: v.inserted_at])

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

  # ── Interaction-Specific Query Helpers ────────────────────────

  defp get_user_interaction_ids(user_id, video_ids, action) do
    from(i in UserVideoInteraction,
      where: i.user_id == ^user_id and i.video_id in ^video_ids and i.action == ^action,
      select: i.video_id
    )
    |> Repo.all()
    |> MapSet.new()
  end

  defp apply_interaction_category_filter(query, nil), do: query
  defp apply_interaction_category_filter(query, ""), do: query

  defp apply_interaction_category_filter(query, category) do
    normalized =
      cond do
        String.downcase(category) in ["quick cooking", "quick_cooking"] ->
          ["Quick Cooking", "Quick_Cooking"]

        true ->
          [category]
      end

    from [i, v] in query, where: v.category in ^normalized
  end

  defp apply_interaction_search_filter(query, nil), do: query
  defp apply_interaction_search_filter(query, ""), do: query

  defp apply_interaction_search_filter(query, search_term) do
    term = "%#{String.trim(search_term)}%"
    from [i, v] in query, where: ilike(v.title, ^term) or ilike(v.description, ^term)
  end

  defp apply_interaction_ordering(query, "oldest"),
    do: from([i, v] in query, order_by: [asc: i.inserted_at])

  defp apply_interaction_ordering(query, _),
    do: from([i, v] in query, order_by: [desc: i.inserted_at])

  defp apply_interaction_pagination(query, params) do
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

    from [i, v] in query, limit: ^limit, offset: ^offset
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
