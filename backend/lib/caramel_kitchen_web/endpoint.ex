defmodule CaramelKitchenWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :caramel_kitchen

  socket "/socket", CaramelKitchenWeb.UserSocket,
    websocket: [
      timeout: 45_000,
      max_frame_size: 10_000,
      check_origin: {CaramelKitchenWeb.Endpoint, :check_origin, []}
    ],
    longpoll: false

  plug Plug.Static,
    at: "/",
    from: :caramel_kitchen,
    gzip: true,
    only: CaramelKitchenWeb.static_paths()

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :caramel_kitchen
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library(),
    length: 50_000_000  # 50MB for video thumbnails

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, store: :cookie,
    key: "_caramel_kitchen_key",
    signing_salt: System.get_env("SESSION_SALT", "caramel_salt"),
    same_site: "Lax"

  plug CORSPlug,
    origin: &CaramelKitchenWeb.Endpoint.allowed_origins/0,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    headers: ["Authorization", "Content-Type", "X-Request-ID", "X-Stripe-Signature"],
    max_age: 86_400

  plug CaramelKitchenWeb.Router

  def check_origin(origin) do
    allowed = allowed_origins()
    Enum.any?(allowed, &(&1 == origin or String.ends_with?(origin, &1)))
  end

  def allowed_origins do
    Application.get_env(:caramel_kitchen, :allowed_origins, ["http://localhost:3000"])
  end
end
