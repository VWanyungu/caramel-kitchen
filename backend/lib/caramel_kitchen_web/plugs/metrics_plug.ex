defmodule CaramelKitchenWeb.MetricsPlug do
  @moduledoc """
  Exposes Prometheus metrics at /metrics.
  In production, protected by a shared secret token via
  X-Metrics-Token header to prevent public scraping.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(%{path_info: ["metrics"]} = conn, _opts) do
    if metrics_allowed?(conn) do
      metrics = PromEx.get_metrics(CaramelKitchen.PromEx)
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, metrics)
      |> halt()
    else
      conn
      |> send_resp(403, "Forbidden")
      |> halt()
    end
  end

  def call(conn, _opts), do: conn

  defp metrics_allowed?(conn) do
    secret = Application.get_env(:caramel_kitchen, :metrics_token)

    if is_nil(secret) do
      # In dev: allow all
      Mix.env() == :dev
    else
      token = get_req_header(conn, "x-metrics-token") |> List.first()
      Plug.Crypto.secure_compare(token || "", secret)
    end
  end
end
