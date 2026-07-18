defmodule CaramelKitchen.Monetisation do
  @moduledoc """
  Subscription and payment management.
  Handles Stripe webhooks and updates user subscription tier.
  """

  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Accounts
  alias CaramelKitchen.Monetisation.Subscription

  require Logger

  # ── Stripe Checkout ───────────────────────────────────────────

  @doc "Create a Stripe Checkout session for premium subscription."
  def create_checkout_session(user, plan \\ "premium") do
    price_id = get_price_id(plan)
    app_url = Application.get_env(:caramel_kitchen, :app_url, "https://caramelkitchen.app")

    Stripe.Checkout.Session.create(%{
      mode: :subscription,
      customer_email: user.email,
      client_reference_id: user.id,
      line_items: [%{price: price_id, quantity: 1}],
      success_url: "#{app_url}/subscription/success?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "#{app_url}/subscription/cancel",
      metadata: %{"user_id" => user.id, "plan" => plan}
    })
  end

  @doc "Create a Stripe billing portal session."
  def create_billing_portal(user) do
    with {:ok, sub} <- get_subscription(user.id) do
      app_url = Application.get_env(:caramel_kitchen, :app_url, "https://caramelkitchen.app")

      Stripe.BillingPortal.Session.create(%{
        customer: sub.stripe_customer_id,
        return_url: "#{app_url}/profile"
      })
    end
  end

  # ── Webhook Handler ───────────────────────────────────────────

  @doc "Handle incoming Stripe webhook event."
  def handle_webhook(%{"type" => event_type, "data" => %{"object" => obj}}) do
    Logger.info("Stripe webhook: #{event_type}")

    case event_type do
      "checkout.session.completed" ->
        handle_checkout_completed(obj)

      "invoice.payment_succeeded" ->
        handle_payment_succeeded(obj)

      "invoice.payment_failed" ->
        handle_payment_failed(obj)

      "customer.subscription.deleted" ->
        handle_subscription_deleted(obj)

      "customer.subscription.updated" ->
        handle_subscription_updated(obj)

      _other ->
        Logger.debug("Unhandled Stripe event: #{event_type}")
        :ok
    end
  end

  # ── Subscription Queries ──────────────────────────────────────

  def get_subscription(user_id) do
    Repo.fetch(from s in Subscription, where: s.user_id == ^user_id)
  end

  def premium?(user_id) do
    case get_subscription(user_id) do
      {:ok, %{plan: tier, status: "active"}} -> tier in ~w(premium creator_pro)
      _ -> false
    end
  end

  # ── Private ───────────────────────────────────────────────────

  defp handle_checkout_completed(%{
         "client_reference_id" => user_id,
         "customer" => customer_id,
         "subscription" => stripe_sub_id,
         "metadata" => meta
       }) do
    plan = Map.get(meta, "plan", "premium")

    Repo.run_transaction(fn _repo ->
      with {:ok, user} <- Accounts.get_user(user_id) do
        upsert_subscription(%{
          user_id: user_id,
          stripe_customer_id: customer_id,
          stripe_sub_id: stripe_sub_id,
          plan: plan,
          status: "active"
        })

        Accounts.update_user_tier(user, plan)
        Logger.info("User #{user_id} subscribed to #{plan}")
        {:ok, :subscribed}
      end
    end)
  end

  defp handle_checkout_completed(_), do: {:error, :missing_fields}

  defp handle_payment_succeeded(%{
         "subscription" => stripe_sub_id,
         "lines" => %{"data" => [%{"period" => period} | _]}
       }) do
    with {:ok, sub} <- find_by_stripe_sub(stripe_sub_id) do
      sub
      |> Ecto.Changeset.change(%{
        status: "active",
        current_period_start: unix_to_datetime(period["start"]),
        current_period_end: unix_to_datetime(period["end"])
      })
      |> Repo.update()
    end
  end

  defp handle_payment_succeeded(_), do: :ok

  defp handle_payment_failed(%{"subscription" => stripe_sub_id}) do
    with {:ok, sub} <- find_by_stripe_sub(stripe_sub_id) do
      sub
      |> Ecto.Changeset.change(%{status: "past_due"})
      |> Repo.update()

      # TODO: send dunning email via Oban worker
    end
  end

  defp handle_payment_failed(_), do: :ok

  defp handle_subscription_deleted(%{"id" => stripe_sub_id}) do
    with {:ok, sub} <- find_by_stripe_sub(stripe_sub_id),
         {:ok, user} <- Accounts.get_user(sub.user_id) do
      sub
      |> Ecto.Changeset.change(%{
        status: "canceled",
        canceled_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.update()

      Accounts.update_user_tier(user, "free")
      Logger.info("User #{sub.user_id} downgraded to free")
    end
  end

  defp handle_subscription_deleted(_), do: :ok

  defp handle_subscription_updated(%{"id" => stripe_sub_id, "status" => status}) do
    with {:ok, sub} <- find_by_stripe_sub(stripe_sub_id) do
      sub
      |> Ecto.Changeset.change(%{status: status})
      |> Repo.update()
    end
  end

  defp handle_subscription_updated(_), do: :ok

  defp upsert_subscription(attrs) do
    case Repo.one(from s in Subscription, where: s.user_id == ^attrs.user_id) do
      nil ->
        %Subscription{}
        |> Ecto.Changeset.cast(attrs, [
          :user_id,
          :stripe_customer_id,
          :stripe_sub_id,
          :plan,
          :status
        ])
        |> Repo.insert()

      existing ->
        existing
        |> Ecto.Changeset.cast(attrs, [:stripe_customer_id, :stripe_sub_id, :plan, :status])
        |> Repo.update()
    end
  end

  defp find_by_stripe_sub(stripe_sub_id) do
    Repo.fetch(from s in Subscription, where: s.stripe_sub_id == ^stripe_sub_id)
  end

  defp get_price_id("premium"),
    do: Application.fetch_env!(:caramel_kitchen, :stripe_premium_price_id)

  defp get_price_id("creator_pro"),
    do: Application.fetch_env!(:caramel_kitchen, :stripe_creator_price_id)

  defp unix_to_datetime(unix) when is_integer(unix) do
    unix |> DateTime.from_unix!() |> DateTime.truncate(:second)
  end

  defp unix_to_datetime(_), do: nil
end
