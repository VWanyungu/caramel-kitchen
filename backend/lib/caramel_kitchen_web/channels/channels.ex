defmodule CaramelKitchenWeb.UserSocket do
  use Phoenix.Socket

  channel "ai:*", CaramelKitchenWeb.AIChannel
  channel "feed:*", CaramelKitchenWeb.FeedChannel
  channel "cooking:*", CaramelKitchenWeb.CookingChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case CaramelKitchen.Auth.Guardian.resource_from_token(token) do
      {:ok, user, _claims} ->
        {:ok, assign(socket, :current_user, user)}

      _ ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "users_socket:#{socket.assigns.current_user.id}"
end

# ── AI Channel ─────────────────────────────────────────────────

defmodule CaramelKitchenWeb.AIChannel do
  use Phoenix.Channel
  require Logger

  alias CaramelKitchen.AI.Orchestrator

  def join("ai:" <> session_id, _params, socket) do
    {:ok, assign(socket, :session_id, session_id)}
  end

  # Client sends a message — server streams tokens back
  def handle_in("message", %{"text" => text}, socket) do
    user = socket.assigns.current_user
    session_id = socket.assigns.session_id

    # Subscribe to PubSub stream for this session
    Phoenix.PubSub.subscribe(CaramelKitchen.PubSub, "ai:#{session_id}")

    # Async: call AI (tokens will come via PubSub → handle_info)
    Task.Supervisor.start_child(CaramelKitchen.AI.TaskSupervisor, fn ->
      Orchestrator.chat(user, session_id, text)
    end)

    {:noreply, socket}
  end

  def handle_in("clear", _params, socket) do
    Orchestrator.clear_session(socket.assigns.session_id)
    {:reply, {:ok, %{cleared: true}}, socket}
  end

  # Receive streamed tokens from Orchestrator via PubSub
  def handle_info({:ai_token, token}, socket) do
    push(socket, "token", %{token: token})
    {:noreply, socket}
  end

  def handle_info(:ai_done, socket) do
    push(socket, "done", %{})
    {:noreply, socket}
  end

  def handle_info({:ai_error, reason}, socket) do
    push(socket, "error", %{reason: reason})
    {:noreply, socket}
  end
end

# ── Feed Channel ───────────────────────────────────────────────

defmodule CaramelKitchenWeb.FeedChannel do
  use Phoenix.Channel

  def join("feed:" <> user_id, _params, socket) do
    if socket.assigns.current_user.id == user_id do
      Phoenix.PubSub.subscribe(CaramelKitchen.PubSub, "feed:updates")
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:new_recipe, recipe}, socket) do
    push(socket, "new_recipe", %{
      id: recipe.id,
      title: recipe.title,
      thumbnail_url: recipe.thumbnail_url,
      taste_tags: recipe.taste_tags
    })

    {:noreply, socket}
  end

  def handle_info({:taste_updated, user_id}, socket) do
    if socket.assigns.current_user.id == user_id do
      push(socket, "taste_updated", %{})
    end

    {:noreply, socket}
  end
end

# ── Cooking Channel (voice cooking mode) ──────────────────────

defmodule CaramelKitchenWeb.CookingChannel do
  use Phoenix.Channel
  require Logger

  alias CaramelKitchen.AI.Orchestrator

  def join("cooking:" <> recipe_id, _params, socket) do
    {:ok, assign(socket, :recipe_id, recipe_id) |> assign(:step, 0)}
  end

  # Client: "next step" voice command
  def handle_in("next_step", _params, socket) do
    user = socket.assigns.current_user
    recipe_id = socket.assigns.recipe_id
    step = socket.assigns.step

    recipe = CaramelKitchen.Recipes.get_recipe!(recipe_id)
    steps = recipe.steps

    if step < length(steps) do
      current_step = Enum.at(steps, step)
      instruction = current_step["instruction"]

      # AI reads back the step with TTS
      session_id = "cooking:#{user.id}:#{recipe_id}"
      prompt = "[VOICE_COOKING] Read step #{step + 1}: #{instruction}"

      Task.Supervisor.start_child(CaramelKitchen.AI.TaskSupervisor, fn ->
        {:ok, response} = Orchestrator.chat(user, session_id, prompt)

        Phoenix.PubSub.broadcast(
          CaramelKitchen.PubSub,
          "cooking:#{recipe_id}",
          {:step_response, step, response}
        )
      end)

      {:noreply, assign(socket, :step, step + 1)}
    else
      push(socket, "cooking_complete", %{message: "You've completed all steps! Enjoy your meal."})
      {:noreply, socket}
    end
  end

  def handle_info({:step_response, step_num, text}, socket) do
    push(socket, "step", %{step: step_num + 1, text: text})
    {:noreply, socket}
  end
end
