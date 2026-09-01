defmodule CaramelKitchen.Content.Supervisor do
  use Supervisor
  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    children = [
      {Task.Supervisor, name: CaramelKitchen.Content.TaskSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule CaramelKitchen.Content do
  @moduledoc """
  Content management — presigned S3 URLs, video metadata,
  recipe publishing pipeline.
  """
  require Logger

  alias CaramelKitchen.Recipes
  alias CaramelKitchen.Workers.PublishRecipeWorker

  defp bucket do
    Application.get_env(:caramel_kitchen, :s3_bucket, "caramel-kitchen-videos")
  end

  defp cdn_url do
    Application.get_env(:caramel_kitchen, :cdn_url, "https://cdn.caramelkitchen.app")
  end

  # 15 minutes
  @presigned_ttl 900

  # ── S3 Presigned URL ─────────────────────────────────────────

  @doc """
  Generate a presigned PUT URL for direct browser→S3 upload.
  Returns {:ok, %{presigned_url, key, cdn_url_after_process}}.
  """
  def presigned_upload_url(creator_id, filename, content_type) do
    ext = Path.extname(filename)
    key = "videos/#{creator_id}/#{uuid()}#{ext}"

    config = ExAws.Config.new(:s3)

    case ExAws.S3.presigned_url(config, :put, bucket(), key,
           expires_in: @presigned_ttl,
           headers: [{"content-type", content_type}],
           query_params: [{"x-amz-server-side-encryption", "AES256"}]
         ) do
      {:ok, url} ->
        {:ok,
         %{
           presigned_url: url,
           key: key,
           cdn_url_after_process: "#{cdn_url()}/#{key}",
           expires_in: @presigned_ttl
         }}

      {:error, reason} ->
        Logger.error("Failed to generate presigned URL: #{inspect(reason)}")
        {:error, :presigned_url_failed}
    end
  end

  @doc "Called by webhook after S3 upload completes and transcoding finishes."
  def on_video_processed(recipe_id, video_key, duration_secs, thumbnail_key) do
    cdn_video = "#{cdn_url()}/#{video_key}"
    cdn_thumbnail = "#{cdn_url()}/#{thumbnail_key}"

    with {:ok, recipe} <- Recipes.get_recipe(recipe_id) do
      Recipes.set_video(recipe, %{
        video_url: cdn_video,
        video_key: video_key,
        video_duration_secs: duration_secs,
        thumbnail_url: cdn_thumbnail
      })
    end
  end

  @doc "Schedule or immediately publish a recipe."
  def schedule_publish(recipe) do
    cond do
      recipe.scheduled_at && DateTime.compare(recipe.scheduled_at, DateTime.utc_now()) == :gt ->
        PublishRecipeWorker.new(%{recipe_id: recipe.id}, scheduled_at: recipe.scheduled_at)
        |> Oban.insert()

      recipe.status == "draft" ->
        # stay draft, creator must manually publish
        {:ok, recipe}

      true ->
        Recipes.publish_recipe(recipe)
    end
  end

  @doc "Soft delete from S3 (moves to archive prefix)."
  def archive_video(video_key) when is_binary(video_key) do
    archive_key = String.replace(video_key, "videos/", "archive/videos/")

    ExAws.S3.put_object_copy(bucket(), archive_key, bucket(), video_key)
    |> ExAws.request()
    |> case do
      {:ok, _} ->
        ExAws.S3.delete_object(bucket(), video_key) |> ExAws.request()

      err ->
        err
    end
  end

  defp uuid, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
end
