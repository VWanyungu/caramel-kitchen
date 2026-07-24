defmodule CaramelKitchenWeb.NotificationController do
  use CaramelKitchenWeb, :controller
  require Logger

  @doc """
  Streams push notifications to the connected client via Server-Sent Events (SSE).
  Maintains a long-lived HTTP connection and pushes events when PubSub broadcasts them.
  """
  def stream(conn, _params) do
    user = conn.assigns.current_user

    conn =
      conn
      |> put_resp_header("content-type", "text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> send_chunked(200)

    # Subscribe to the user's specific notification topic
    Phoenix.PubSub.subscribe(CaramelKitchen.PubSub, "user_notifications:#{user.id}")
    
    Logger.info("SSE Stream started for user: #{user.id}")

    # Enter the recursive receive loop
    loop(conn)
  end

  defp loop(conn) do
    receive do
      {:notification, payload} ->
        # Send standard SSE formatted data
        json_payload = Jason.encode!(payload)
        sse_message = "data: #{json_payload}\n\n"

        case Plug.Conn.chunk(conn, sse_message) do
          {:ok, conn} ->
            loop(conn)

          {:error, _reason} ->
            # Connection closed by client
            conn
        end

    after
      # 30-second heartbeat ping to prevent reverse-proxy timeouts
      30_000 ->
        case Plug.Conn.chunk(conn, ": ping\n\n") do
          {:ok, conn} ->
            loop(conn)

          {:error, _reason} ->
            conn
        end
    end
  end
end
