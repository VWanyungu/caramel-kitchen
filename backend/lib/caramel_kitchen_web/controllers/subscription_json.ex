defmodule CaramelKitchenWeb.SubscriptionJSON do
  @moduledoc """
  JSON views for the SubscriptionController.
  """

  @doc """
  Renders a single subscription object.
  """
  def show(%{subscription: subscription}) do
    %{
      data: %{
        id: subscription.id,
        plan: subscription.plan,
        status: subscription.status,
        current_period_start: subscription.current_period_start,
        current_period_end: subscription.current_period_end,
        trial_ends_at: subscription.trial_ends_at,
        canceled_at: subscription.canceled_at
      }
    }
  end

  @doc """
  Renders the checkout URL for Stripe Checkout Session.
  """
  def checkout(%{url: url}) do
    %{data: %{checkout_url: url}}
  end

  @doc """
  Renders the portal URL for Stripe Billing Portal.
  """
  def portal(%{url: url}) do
    %{data: %{portal_url: url}}
  end
end
