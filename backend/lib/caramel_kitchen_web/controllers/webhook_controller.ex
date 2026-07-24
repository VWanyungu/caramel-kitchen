defmodule CaramelKitchenWeb.WebhookController do
  use CaramelKitchenWeb, :controller

  alias CaramelKitchen.Monetisation
  require Logger

  @doc """
  Handles incoming Stripe webhooks. The signature is already verified by
  CaramelKitchenWeb.Plugs.VerifyStripeSignature before reaching this action.
  """
  def stripe(conn, _params) do
    # If the plug assigned the verified event, we can use it directly
    event = conn.assigns[:stripe_event] || %{
      "type" => conn.params["type"],
      "data" => conn.params["data"]
    }
    
    # We pass the raw map to Monetisation.handle_webhook/1 which expects %{"type" => ..., "data" => ...}
    # If it's a Stripe.Event struct, we convert it to the expected map structure
    event_map = case event do
      %Stripe.Event{} -> 
        %{"type" => event.type, "data" => %{"object" => event.data.object}}
      map when is_map(map) -> 
        map
    end

    case Monetisation.handle_webhook(event_map) do
      {:ok, _} ->
        send_resp(conn, 200, "")

      :ok ->
        send_resp(conn, 200, "")

      {:error, reason} ->
        Logger.error("Failed to process webhook: #{inspect(reason)}")
        send_resp(conn, 400, "")
    end
  end
end
