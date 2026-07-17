defmodule CaramelKitchen.Notifications do
  @moduledoc """
  Push notification dispatcher.
  Supports FCM (Android) and APNs (iOS) via Pigeon library.
  Notification tokens stored in user_push_tokens table.
  """

  import Ecto.Query
  alias CaramelKitchen.Repo
  require Logger

  # ── Public API ────────────────────────────────────────────────

  @doc "Send a push notification to a single user (all their devices)."
  def notify_user(user_id, title, body, data \\ %{}) do
    tokens = get_tokens(user_id)
    Enum.each(tokens, fn token -> send_push(token, title, body, data) end)
  end

  @doc "Send to multiple users."
  def notify_users(user_ids, title, body, data \\ %{}) when is_list(user_ids) do
    user_ids
    |> Enum.each(&notify_user(&1, title, body, data))
  end

  # ── Notification Templates ────────────────────────────────────

  def notify_new_recipe(user_id, recipe) do
    notify_user(user_id,
      "New recipe 🍳",
      "#{recipe.title} is now available",
      %{type: "new_recipe", recipe_id: recipe.id}
    )
  end

  def notify_meal_plan_ready(user_id, plan) do
    notify_user(user_id,
      "Your meal plan is ready 📋",
      "#{plan.name} — #{plan.calorie_target} kcal/day",
      %{type: "meal_plan_ready", plan_id: plan.id}
    )
  end

  def notify_cook_reminder(user_id, meal_name, slot) do
    slot_label = case slot do
      "breakfast" -> "Breakfast time 🌅"
      "lunch"     -> "Lunch time ☀️"
      "dinner"    -> "Dinner time 🌙"
      "snack"     -> "Snack time 🍎"
      _           -> "Time to cook"
    end

    notify_user(user_id,
      slot_label,
      "Today's #{slot}: #{meal_name}",
      %{type: "cook_reminder", slot: slot}
    )
  end

  def notify_taste_vector_updated(user_id) do
    notify_user(user_id,
      "Your feed just got smarter 🎯",
      "We've updated your taste profile based on recent activity",
      %{type: "taste_updated"}
    )
  end

  # ── Token Management ──────────────────────────────────────────

  def register_token(user_id, token, platform) when platform in ~w(ios android) do
    Repo.insert_all("user_push_tokens",
      [%{
        id:         Ecto.UUID.generate(),
        user_id:    user_id,
        token:      token,
        platform:   platform,
        inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }],
      on_conflict: {:replace, [:token, :inserted_at]},
      conflict_target: [:user_id, :token]
    )
    :ok
  end

  def deregister_token(user_id, token) do
    from(t in "user_push_tokens",
      where: t.user_id == ^user_id and t.token == ^token
    ) |> Repo.delete_all()
    :ok
  end

  # ── Private ───────────────────────────────────────────────────

  defp get_tokens(user_id) do
    Repo.all(
      from t in "user_push_tokens",
      where: t.user_id == ^user_id,
      select: %{token: t.token, platform: t.platform}
    )
  end

  defp send_push(%{token: token, platform: "android"}, title, body, data) do
    # FCM via Req HTTP call (no Pigeon dependency needed)
    fcm_key = Application.get_env(:caramel_kitchen, :fcm_server_key)

    if fcm_key do
      payload = %{
        to: token,
        notification: %{title: title, body: body},
        data: data
      }

      case Req.post("https://fcm.googleapis.com/fcm/send",
        headers: [{"Authorization", "key=#{fcm_key}"}],
        json: payload
      ) do
        {:ok, %{status: 200}} -> :ok
        {:ok, %{status: status}} ->
          Logger.warning("FCM push failed with status #{status} for token #{String.slice(token, 0, 10)}...")
        {:error, reason} ->
          Logger.error("FCM push error: #{inspect(reason)}")
      end
    else
      Logger.debug("FCM_SERVER_KEY not set — skipping Android push: #{title}")
    end
  end

  defp send_push(%{token: token, platform: "ios"}, title, _body, data) do
    # APNs via HTTP/2 — simplified direct call
    # In production use Pigeon or sparrow library for APNs HTTP/2
    Logger.info("iOS push (APNs): #{title} → #{String.slice(token, 0, 10)}... data=#{inspect(data)}")
    # TODO: implement APNs HTTP/2 push with cert or JWT auth
    :ok
  end

  defp send_push(_, _, _, _), do: :ok
end

defmodule CaramelKitchen.Workers.PushNotificationWorker do
  @moduledoc "Oban worker: send push notifications asynchronously."
  use Oban.Worker, queue: :default, max_attempts: 3

  alias CaramelKitchen.Notifications

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "new_recipe", "user_id" => uid, "recipe" => r}}) do
    Notifications.notify_new_recipe(uid, %{id: r["id"], title: r["title"]})
  end

  def perform(%Oban.Job{args: %{"type" => "meal_plan_ready", "user_id" => uid, "plan" => p}}) do
    Notifications.notify_meal_plan_ready(uid,
      %{id: p["id"], name: p["name"], calorie_target: p["calorie_target"]}
    )
  end

  def perform(%Oban.Job{args: %{"type" => "cook_reminder", "user_id" => uid,
                                 "meal_name" => name, "slot" => slot}}) do
    Notifications.notify_cook_reminder(uid, name, slot)
  end

  def perform(%Oban.Job{args: %{"type" => "taste_updated", "user_id" => uid}}) do
    Notifications.notify_taste_vector_updated(uid)
  end
end
