defmodule CaramelKitchen.AI.Orchestrator do
  @moduledoc """
  GenServer managing AI interactions:
  - Rate-limited GPT-4o calls with streaming via Phoenix PubSub
  - Whisper voice-to-text
  - Taste-aware, goal-aware system prompt injection
  - Conversation history (last 10 turns per session)
  - Async query logging to ai_queries table
  """
  use GenServer
  require Logger

  alias CaramelKitchen.AI.{PromptBuilder, QueryLogger, VoiceProcessor}

  @openai_url "https://api.openai.com/v1/chat/completions"
  @model "gpt-4o"
  @max_tokens 1_200
  @session_ttl_ms :timer.minutes(30)

  defstruct sessions: %{}

  # ── Client API ────────────────────────────────────────────────

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "Stream a chat response. Tokens are broadcast on channel ai:{session_id}."
  def chat(user, session_id, message, opts \\ []) do
    GenServer.call(__MODULE__, {:chat, user, session_id, message, opts}, 30_000)
  end

  @doc "One-shot completion (for meal plan generation). Returns {:ok, text}."
  def complete(prompt, opts \\ []) do
    GenServer.call(__MODULE__, {:complete, prompt, opts}, 60_000)
  end

  @doc "Transcribe audio via Whisper API."
  def transcribe_voice(audio_binary, content_type \\ "audio/webm") do
    VoiceProcessor.transcribe(audio_binary, content_type)
  end

  @doc "Get or initialise a session's conversation history."
  def get_history(session_id) do
    GenServer.call(__MODULE__, {:get_history, session_id})
  end

  def clear_session(session_id) do
    GenServer.cast(__MODULE__, {:clear_session, session_id})
  end

  # ── Callbacks ─────────────────────────────────────────────────

  @impl true
  def init(_opts), do: {:ok, %__MODULE__{}}

  @impl true
  def handle_call({:chat, user, session_id, message, opts}, _from, state) do
    history = Map.get(state.sessions, session_id, [])
    system_prompt = PromptBuilder.build_system_prompt(user)
    start_ms = System.monotonic_time(:millisecond)

    updated_history = history ++ [%{role: "user", content: message}]
    messages = [%{role: "system", content: system_prompt} | updated_history]

    case call_openai_streaming(messages, session_id, opts) do
      {:ok, full_response, tokens_used} ->
        new_history =
          trim_history(updated_history ++ [%{role: "assistant", content: full_response}])

        latency = System.monotonic_time(:millisecond) - start_ms

        # Async log
        Task.Supervisor.start_child(CaramelKitchen.AI.TaskSupervisor, fn ->
          QueryLogger.log(%{
            user_id: user.id,
            session_id: session_id,
            query_type: "chat",
            prompt: message,
            response: full_response,
            model: @model,
            tokens_used: tokens_used,
            latency_ms: latency
          })
        end)

        new_sessions = Map.put(state.sessions, session_id, new_history)
        schedule_session_cleanup(session_id)

        {:reply, {:ok, full_response}, %{state | sessions: new_sessions}}

      {:error, reason} = err ->
        Logger.error("AI chat failed: #{inspect(reason)}")
        {:reply, err, state}
    end
  end

  @impl true
  def handle_call({:complete, prompt, opts}, _from, state) do
    format = Keyword.get(opts, :format, :text)

    messages = [
      %{
        role: "system",
        content: "You are a helpful cooking assistant. Always respond with valid JSON when asked."
      },
      %{role: "user", content: prompt}
    ]

    case call_openai_direct(messages, format) do
      {:ok, text, _tokens} -> {:reply, {:ok, text}, state}
      {:error, _} = err -> {:reply, err, state}
    end
  end

  @impl true
  def handle_call({:get_history, session_id}, _from, state) do
    {:reply, Map.get(state.sessions, session_id, []), state}
  end

  @impl true
  def handle_cast({:clear_session, session_id}, state) do
    {:noreply, %{state | sessions: Map.delete(state.sessions, session_id)}}
  end

  @impl true
  def handle_info({:cleanup_session, session_id}, state) do
    {:noreply, %{state | sessions: Map.delete(state.sessions, session_id)}}
  end

  # ── OpenAI Calls ──────────────────────────────────────────────

  defp call_openai_streaming(messages, session_id, _opts) do
    api_key = Application.get_env(:caramel_kitchen, :openai_api_key, "sk-placeholder")

    body =
      Jason.encode!(%{
        model: @model,
        messages: messages,
        max_tokens: @max_tokens,
        stream: true,
        temperature: 0.7
      })

    # Stream using Req with chunked response
    case Req.post(@openai_url,
           headers: [
             {"Authorization", "Bearer #{api_key}"},
             {"Content-Type", "application/json"}
           ],
           body: body,
           receive_timeout: 25_000,
           into: fn {:data, chunk}, {req, resp} ->
             # Parse SSE chunks and broadcast each token
             chunk
             |> String.split("\n")
             |> Enum.each(fn line ->
               case parse_sse_line(line) do
                 {:token, token} ->
                   Phoenix.PubSub.broadcast(
                     CaramelKitchen.PubSub,
                     "ai:#{session_id}",
                     {:ai_token, token}
                   )

                 :done ->
                   Phoenix.PubSub.broadcast(
                     CaramelKitchen.PubSub,
                     "ai:#{session_id}",
                     :ai_done
                   )

                 :skip ->
                   :ok
               end
             end)

             {:cont, {req, resp}}
           end
         ) do
      {:ok, resp} ->
        # Reconstruct full response from body (accumulated by Req)
        full_text = extract_full_text_from_stream(resp.body)
        {:ok, full_text, estimate_tokens(full_text)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp call_openai_direct(messages, _format) do
    api_key = Application.get_env(:caramel_kitchen, :openai_api_key, "sk-placeholder")

    case Req.post(@openai_url,
           headers: [{"Authorization", "Bearer #{api_key}"}],
           json: %{
             model: @model,
             messages: messages,
             max_tokens: @max_tokens,
             temperature: 0.3
           },
           receive_timeout: 30_000
         ) do
      {:ok, %{status: 200, body: body}} ->
        text = get_in(body, ["choices", Access.at(0), "message", "content"]) || ""
        tokens = get_in(body, ["usage", "total_tokens"]) || 0
        {:ok, String.trim(text), tokens}

      {:ok, %{status: status, body: body}} ->
        Logger.error("OpenAI error #{status}: #{inspect(body)}")
        {:error, "openai_error_#{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ── SSE Parsing ───────────────────────────────────────────────

  defp parse_sse_line("data: [DONE]"), do: :done

  defp parse_sse_line("data: " <> json) do
    case Jason.decode(json) do
      {:ok, %{"choices" => [%{"delta" => %{"content" => token}} | _]}} ->
        {:token, token}

      _ ->
        :skip
    end
  end

  defp parse_sse_line(_), do: :skip

  defp extract_full_text_from_stream(body) when is_binary(body) do
    body
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      case parse_sse_line(line) do
        {:token, t} -> [t]
        _ -> []
      end
    end)
    |> Enum.join()
  end

  defp extract_full_text_from_stream(_), do: ""

  defp estimate_tokens(text), do: div(String.length(text), 4)

  defp trim_history(history) when length(history) > 10 do
    Enum.take(history, -10)
  end

  defp trim_history(history), do: history

  defp schedule_session_cleanup(session_id) do
    Process.send_after(self(), {:cleanup_session, session_id}, @session_ttl_ms)
  end
end
