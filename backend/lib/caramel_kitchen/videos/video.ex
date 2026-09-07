defmodule CaramelKitchen.Videos.Video do
  @moduledoc """
  Schema for video content in Caramel Kitchen.
  Supports YouTube embeds, multi-category organization, and access levels.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_categories [
    "Recipe_Videos",
    "Cooking_Tips",
    "Cooking_Techniques",
    "Quick Cooking",
    "Quick_Cooking",
    "Tutorials",
    "Premium_Videos",
    "Masterclasses",
    "Caramel_Academy"
  ]

  @canonical_categories [
    "Recipe_Videos",
    "Cooking_Tips",
    "Cooking_Techniques",
    "Quick Cooking",
    "Tutorials",
    "Premium_Videos",
    "Masterclasses",
    "Caramel_Academy"
  ]

  schema "videos" do
    belongs_to :creator, CaramelKitchen.Accounts.User

    field :title, :string
    field :description, :string
    field :category, :string
    field :is_premium, :boolean, default: false
    field :is_special, :boolean, default: false
    field :yt_embed_code, :string
    field :youtube_video_id, :string
    field :video_url, :string
    field :video_embed_url, :string
    field :thumbnail_url, :string
    field :duration_secs, :integer
    field :view_count, :integer, default: 0
    field :favorite_count, :integer, default: 0
    field :save_count, :integer, default: 0

    # Virtual fields populated for authenticated user context
    field :is_favorited, :boolean, virtual: true, default: false
    field :is_saved, :boolean, virtual: true, default: false
    field :interacted_at, :utc_datetime, virtual: true

    has_many :interactions, CaramelKitchen.Videos.UserVideoInteraction

    timestamps(type: :utc_datetime)
  end

  def valid_categories, do: @canonical_categories

  @doc "Changeset for creating a new video"
  def creation_changeset(video, attrs) do
    video
    |> cast(attrs, [
      :title,
      :description,
      :category,
      :is_premium,
      :is_special,
      :yt_embed_code,
      :thumbnail_url,
      :duration_secs,
      :creator_id
    ])
    |> sync_premium_and_special()
    |> normalize_category()
    |> validate_required([:title, :category, :yt_embed_code])
    |> validate_inclusion(:category, @valid_categories)
    |> process_youtube_embed()
  end

  @doc "Changeset for updating an existing video"
  def update_changeset(video, attrs) do
    video
    |> cast(attrs, [
      :title,
      :description,
      :category,
      :is_premium,
      :is_special,
      :yt_embed_code,
      :thumbnail_url,
      :duration_secs,
      :creator_id
    ])
    |> sync_premium_and_special()
    |> normalize_category()
    |> validate_inclusion(:category, @valid_categories)
    |> process_youtube_embed()
  end

  @doc "Increment view count changeset"
  def increment_view_changeset(video) do
    change(video, view_count: video.view_count + 1)
  end

  # ── Private Helpers ──────────────────────────────────────────

  defp sync_premium_and_special(cs) do
    # Keep is_premium and is_special in sync if one is passed
    case {get_change(cs, :is_premium), get_change(cs, :is_special)} do
      {prem, nil} when not is_nil(prem) ->
        put_change(cs, :is_special, prem)

      {nil, spec} when not is_nil(spec) ->
        put_change(cs, :is_premium, spec)

      _ ->
        cs
    end
  end

  defp normalize_category(cs) do
    case get_change(cs, :category) do
      nil ->
        cs

      cat when is_binary(cat) ->
        normalized =
          cond do
            String.downcase(cat) in ["quick cooking", "quick_cooking"] ->
              "Quick Cooking"

            true ->
              Enum.find(@canonical_categories, cat, fn canonical ->
                String.downcase(canonical) == String.downcase(cat)
              end)
          end

        put_change(cs, :category, normalized)

      _ ->
        cs
    end
  end

  defp process_youtube_embed(cs) do
    case get_change(cs, :yt_embed_code) do
      nil ->
        cs

      code when is_binary(code) ->
        yt = parse_youtube(code)

        cs =
          if yt.youtube_id do
            cs
            |> put_change(:youtube_video_id, yt.youtube_id)
            |> put_change(:video_url, yt.video_url)
            |> put_change(:video_embed_url, yt.video_embed_url)
            |> maybe_put_thumbnail(yt.youtube_id)
          else
            cs
          end

        # Ensure yt_embed_code contains iframe if only a URL/ID was provided
        if yt.iframe_html && !String.contains?(code, "<iframe") do
          put_change(cs, :yt_embed_code, yt.iframe_html)
        else
          cs
        end

      _ ->
        cs
    end
  end

  defp maybe_put_thumbnail(cs, youtube_id) do
    case get_field(cs, :thumbnail_url) do
      nil ->
        put_change(cs, :thumbnail_url, "https://img.youtube.com/vi/#{youtube_id}/hqdefault.jpg")

      "" ->
        put_change(cs, :thumbnail_url, "https://img.youtube.com/vi/#{youtube_id}/hqdefault.jpg")

      _ ->
        cs
    end
  end

  @doc """
  Parses YouTube links, watch URLs, embed links, or HTML <iframe> snippets.
  Returns structured map with youtube_id, video_url, video_embed_url, and iframe_html.
  """
  def parse_youtube(nil),
    do: %{youtube_id: nil, video_url: nil, video_embed_url: nil, iframe_html: nil}

  def parse_youtube(input) when is_binary(input) do
    trimmed = String.trim(input)

    video_id =
      cond do
        String.contains?(trimmed, "<iframe") ->
          case Regex.run(~r/youtube\.com\/(?:embed\/|watch\?v=)([a-zA-Z0-9_-]{11})/, trimmed) do
            [_, id] -> id
            _ -> nil
          end

        String.contains?(trimmed, "youtube.com/embed/") ->
          case Regex.run(~r/youtube\.com\/embed\/([a-zA-Z0-9_-]{11})/, trimmed) do
            [_, id] -> id
            _ -> nil
          end

        String.contains?(trimmed, "youtube.com/watch") ->
          case Regex.run(~r/[?&]v=([a-zA-Z0-9_-]{11})/, trimmed) do
            [_, id] -> id
            _ -> nil
          end

        String.contains?(trimmed, "youtu.be/") ->
          case Regex.run(~r/youtu\.be\/([a-zA-Z0-9_-]{11})/, trimmed) do
            [_, id] -> id
            _ -> nil
          end

        Regex.match?(~r/^[a-zA-Z0-9_-]{11}$/, trimmed) ->
          trimmed

        true ->
          nil
      end

    case video_id do
      nil ->
        %{
          youtube_id: nil,
          video_url: trimmed,
          video_embed_url: trimmed,
          iframe_html: trimmed
        }

      id ->
        embed_url = "https://www.youtube.com/embed/#{id}"
        watch_url = "https://www.youtube.com/watch?v=#{id}"

        iframe =
          ~s(<iframe width="100%" height="100%" src="#{embed_url}" title="Video" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>)

        %{
          youtube_id: id,
          video_url: watch_url,
          video_embed_url: embed_url,
          iframe_html: iframe
        }
    end
  end

  def parse_youtube(_),
    do: %{youtube_id: nil, video_url: nil, video_embed_url: nil, iframe_html: nil}
end
