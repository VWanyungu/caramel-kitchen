defmodule CaramelKitchenWeb.Plugs.VerifyStripeSignature do
  @moduledoc """
  Verifies the Stripe webhook signature using the raw body cached by CacheBodyReader.
  """

  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    with [signature] <- get_req_header(conn, "stripe-signature"),
         {:ok, raw_body} <- get_raw_body(conn),
         secret when is_binary(secret) <- get_secret(),
         {:ok, event} <- Stripe.Webhook.construct_event(raw_body, signature, secret) do
      # Optionally, we can put the verified event in assigns if we want to avoid re-parsing it
      assign(conn, :stripe_event, event)
    else
      [] ->
        Logger.error("Missing Stripe signature")
        halt_with_error(conn)

      {:error, :missing_raw_body} ->
        Logger.error("Missing raw body for Stripe signature verification. Is CacheBodyReader configured?")
        halt_with_error(conn)

      nil ->
        Logger.error("Missing stripe_webhook_secret in configuration")
        halt_with_error(conn)

      {:error, reason} ->
        Logger.error("Invalid Stripe signature: #{inspect(reason)}")
        halt_with_error(conn)
    end
  end

  defp get_raw_body(%{assigns: %{raw_body: body}}), do: {:ok, body}
  defp get_raw_body(_), do: {:error, :missing_raw_body}

  defp get_secret do
    Application.get_env(:caramel_kitchen, :stripe_webhook_secret) ||
      System.get_env("STRIPE_WEBHOOK_SECRET")
  end

  defp halt_with_error(conn) do
    conn
    |> put_status(:bad_request)
    |> Phoenix.Controller.json(%{error: "Invalid Stripe signature"})
    |> halt()
  end
end
