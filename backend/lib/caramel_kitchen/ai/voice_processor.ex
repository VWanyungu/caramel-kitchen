defmodule CaramelKitchen.AI.VoiceProcessor do
  @moduledoc """
  Whisper API integration for speech-to-text.
  Also handles TTS via OpenAI or ElevenLabs.
  """
  require Logger

  @whisper_url "https://api.openai.com/v1/audio/transcriptions"
  @tts_url "https://api.openai.com/v1/audio/speech"

  @doc "Transcribe audio binary using Whisper API. Returns {:ok, transcript}."
  def transcribe(audio_binary, content_type \\ "audio/webm") do
    api_key = Application.get_env(:caramel_kitchen, :openai_api_key, "sk-placeholder")
    ext = content_type_to_ext(content_type)
    filename = "audio#{ext}"

    case Req.post(@whisper_url,
           headers: [{"Authorization", "Bearer #{api_key}"}],
           form_multipart: [
             file: {audio_binary, filename: filename, content_type: content_type},
             model: "whisper-1",
             language: "en",
             response_format: "json"
           ],
           receive_timeout: 30_000
         ) do
      {:ok, %{status: 200, body: %{"text" => transcript}}} ->
        {:ok, String.trim(transcript)}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Whisper API error #{status}: #{inspect(body)}")
        {:error, "whisper_error_#{status}"}

      {:error, reason} ->
        Logger.error("Whisper request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc "Generate TTS audio for a text string. Returns {:ok, audio_url}."
  def speak(text, voice \\ "nova") when is_binary(text) do
    api_key = Application.get_env(:caramel_kitchen, :openai_api_key, "sk-placeholder")
    # TTS limit
    truncated = String.slice(text, 0, 4096)

    case Req.post(@tts_url,
           headers: [{"Authorization", "Bearer #{api_key}"}],
           json: %{
             model: "tts-1",
             input: truncated,
             voice: voice,
             response_format: "mp3"
           },
           receive_timeout: 15_000
         ) do
      {:ok, %{status: 200, body: audio_binary}} ->
        # Upload to S3 and return CDN URL
        upload_tts_audio(audio_binary)

      {:ok, %{status: status}} ->
        {:error, "tts_error_#{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp upload_tts_audio(audio_binary) do
    bucket = Application.get_env(:caramel_kitchen, :s3_bucket, "caramel-kitchen-videos")
    cdn_url = Application.get_env(:caramel_kitchen, :cdn_url, "https://cdn.caramelkitchen.app")
    key = "tts/#{uuid()}.mp3"

    case ExAws.S3.put_object(bucket, key, audio_binary,
           content_type: "audio/mpeg",
           acl: :public_read,
           cache_control: "max-age=3600"
         )
         |> ExAws.request() do
      {:ok, _} -> {:ok, "#{cdn_url}/#{key}"}
      {:error, r} -> {:error, r}
    end
  end

  defp content_type_to_ext("audio/webm"), do: ".webm"
  defp content_type_to_ext("audio/mp4"), do: ".mp4"
  defp content_type_to_ext("audio/mpeg"), do: ".mp3"
  defp content_type_to_ext("audio/ogg"), do: ".ogg"
  defp content_type_to_ext("audio/wav"), do: ".wav"
  defp content_type_to_ext(_), do: ".webm"

  defp uuid, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
end

defmodule CaramelKitchen.AI.QueryLogger do
  @moduledoc "Persists AI queries to the ai_queries table for analytics."
  import Ecto.Query
  alias CaramelKitchen.Repo
  require Logger

  def log(%{user_id: _, query_type: _, prompt: _} = attrs) do
    %{
      "id" => Ecto.UUID.generate(),
      "user_id" => attrs.user_id,
      "session_id" => attrs[:session_id],
      "query_type" => to_string(attrs.query_type),
      "prompt" => attrs.prompt,
      "response" => attrs[:response],
      "model" => attrs[:model] || "gpt-4o",
      "tokens_used" => attrs[:tokens_used],
      "latency_ms" => attrs[:latency_ms],
      "recipe_ids" => attrs[:recipe_ids] || [],
      "error" => attrs[:error],
      "inserted_at" => DateTime.utc_now() |> DateTime.truncate(:second)
    }
    |> then(fn row ->
      Repo.insert_all("ai_queries", [row])
    end)
  rescue
    e ->
      Logger.error("Failed to log AI query: #{inspect(e)}")
  end

  def recent_for_user(user_id, limit \\ 20) do
    Repo.all(
      from q in "ai_queries",
        where: q.user_id == ^user_id,
        order_by: [desc: q.inserted_at],
        limit: ^limit,
        select: %{
          id: q.id,
          query_type: q.query_type,
          prompt: q.prompt,
          response: q.response,
          tokens_used: q.tokens_used,
          latency_ms: q.latency_ms,
          inserted_at: q.inserted_at
        }
    )
  end
end
