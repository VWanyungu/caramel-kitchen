defmodule CaramelKitchenWeb.SubscriptionController do
  use CaramelKitchenWeb, :controller

  alias CaramelKitchen.Monetisation

  action_fallback CaramelKitchenWeb.FallbackController

  @doc """
  Gets the authenticated user's current subscription.
  """
  def show(conn, _params) do
    user = conn.assigns.current_user

    case Monetisation.get_subscription(user.id) do
      {:ok, subscription} ->
        render(conn, :show, subscription: subscription)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(json: CaramelKitchenWeb.ErrorJSON)
        |> render(:"404")
    end
  end

  @doc """
  Creates a Stripe Checkout Session for a given plan (default: premium)
  and returns the session URL.
  """
  def create_checkout(conn, params) do
    user = conn.assigns.current_user
    plan = Map.get(params, "plan", "premium")

    case Monetisation.create_checkout_session(user, plan) do
      {:ok, session} ->
        render(conn, :checkout, url: session.url)

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> Phoenix.Controller.json(%{
          error: "Failed to create checkout session",
          details: inspect(reason)
        })
    end
  end

  @doc """
  Creates a Stripe Billing Portal Session for managing existing subscriptions.
  """
  def billing_portal(conn, _params) do
    user = conn.assigns.current_user

    case Monetisation.create_billing_portal(user) do
      {:ok, session} ->
        render(conn, :portal, url: session.url)

      {:error, :not_found} ->
        conn
        |> put_status(:bad_request)
        |> Phoenix.Controller.json(%{error: "No active subscription found to manage"})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> Phoenix.Controller.json(%{
          error: "Failed to create portal session",
          details: inspect(reason)
        })
    end
  end

  @doc """
  Initiates an M-Pesa STK push for the subscription.
  """
  def mpesa_checkout(conn, %{"phone_number" => phone_number} = params) do
    user = conn.assigns.current_user
    plan = Map.get(params, "plan", "premium")
    amount = if plan == "creator_pro", do: 1500, else: 100

    client = Daraja.Client.new()

    case Daraja.Express.request(client, %{
           amount: amount,
           phone_number: phone_number,
           account_reference: "#{user.id}|#{plan}",
           transaction_desc: "Subscription for #{plan}"
         }) do
      {:ok, response} ->
        # Save a pending subscription with the checkout_request_id (using mpesa_receipt_number temporarily)
        CaramelKitchen.Repo.insert!(%CaramelKitchen.Monetisation.Subscription{
          user_id: user.id,
          payment_method: "mpesa",
          # Temporary mapping
          mpesa_receipt_number: response.checkout_request_id,
          mpesa_phone_number: phone_number,
          plan: plan,
          status: "pending"
        })

        Phoenix.Controller.json(conn, %{
          message: "STK Push initiated",
          merchant_request_id: response.merchant_request_id
        })

      {:error, reason, _details} ->
        conn
        |> put_status(:unprocessable_entity)
        |> Phoenix.Controller.json(%{
          error: "Failed to initiate M-Pesa payment",
          details: inspect(reason)
        })
    end
  end
end
