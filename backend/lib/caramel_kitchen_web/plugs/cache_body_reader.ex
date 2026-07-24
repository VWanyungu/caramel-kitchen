defmodule CaramelKitchenWeb.CacheBodyReader do
  @moduledoc """
  Custom body reader for Plug.Parsers that caches the raw request body.
  This is required for verifying Stripe webhook signatures which need the exact 
  unmodified payload.
  """

  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = Plug.Conn.assign(conn, :raw_body, body)
    {:ok, body, conn}
  end
end
