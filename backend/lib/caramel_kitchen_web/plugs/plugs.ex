defmodule CaramelKitchenWeb.Plugs.AuthenticateUser do
  @moduledoc "Extracts and verifies the Bearer JWT from Authorization header."
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias CaramelKitchen.Auth.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user, claims} <- Guardian.resource_from_token(token, %{"typ" => "access"}) do
      conn
      |> assign(:current_user, user)
      |> assign(:jwt_claims, claims)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "unauthorized", message: "Valid authentication token required"})
        |> halt()
    end
  end
end

defmodule CaramelKitchenWeb.Plugs.RequirePremium do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]
  alias CaramelKitchen.Accounts.User

  def init(opts), do: opts

  def call(%{assigns: %{current_user: user}} = conn, _opts) do
    if User.premium?(user) do
      conn
    else
      conn
      |> put_status(:payment_required)
      |> json(%{
        error: "premium_required",
        message: "This feature requires a Premium subscription",
        upgrade_url: "/subscription/checkout"
      })
      |> halt()
    end
  end
end

defmodule CaramelKitchenWeb.Plugs.RequireCreator do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]
  alias CaramelKitchen.Accounts.User

  def init(opts), do: opts

  def call(%{assigns: %{current_user: user}} = conn, _opts) do
    if User.creator?(user) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "forbidden", message: "Creator access required"})
      |> halt()
    end
  end
end

defmodule CaramelKitchenWeb.Plugs.RequireAdmin do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]
  alias CaramelKitchen.Accounts.User

  def init(opts), do: opts

  def call(%{assigns: %{current_user: user}} = conn, _opts) do
    if User.admin?(user) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "forbidden", message: "Admin access required"})
      |> halt()
    end
  end
end

defmodule CaramelKitchenWeb.Plugs.RateLimit do
  @moduledoc "Hammer-based rate limiting plug."
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, opts) do
    scale = Keyword.get(opts, :scale, 60_000)
    limit = Keyword.get(opts, :limit, 100)
    bucket = Keyword.get(opts, :bucket, "api")

    identifier = rate_limit_key(conn, bucket)

    case Hammer.check_rate(identifier, scale, limit) do
      {:allow, _count} ->
        conn

      {:deny, _limit} ->
        conn
        |> put_resp_header("x-ratelimit-limit", to_string(limit))
        |> put_resp_header("retry-after", "60")
        |> put_status(:too_many_requests)
        |> json(%{
          error: "rate_limit_exceeded",
          message: "Too many requests. Please try again later."
        })
        |> halt()

      {:error, reason} ->
        require Logger
        Logger.error("Rate limiter failure: #{inspect(reason)}. Failing open for identifier: #{identifier}")
        conn
    end
  end

  defp rate_limit_key(conn, bucket) do
    user_id = if user = conn.assigns[:current_user], do: user.id
    ip = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")
    key = user_id || ip
    "#{bucket}:#{key}"
  end
end


defmodule CaramelKitchenWeb.Plugs.TrackRequest do
  @moduledoc "Injects request metadata for telemetry."
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    start_time = System.monotonic_time(:millisecond)

    conn
    |> assign(:request_start, start_time)
    |> put_resp_header("x-request-id", generate_request_id())
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
