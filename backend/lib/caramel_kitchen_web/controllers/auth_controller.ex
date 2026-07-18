defmodule CaramelKitchenWeb.AuthController do
  use CaramelKitchenWeb, :controller

  alias CaramelKitchen.Accounts
  alias CaramelKitchen.Auth.Guardian

  action_fallback CaramelKitchenWeb.FallbackController

  # POST /api/v1/auth/register
  def register(conn, params) do
    with {:ok, user} <- Accounts.register_user(params),
         {:ok, tokens} <- Guardian.generate_tokens(user) do
      conn
      |> put_status(:created)
      |> json(%{
        data: %{
          user: render_user(user),
          tokens: tokens
        }
      })
    end
  end

  # POST /api/v1/auth/login
  def login(conn, %{"email" => email, "password" => password}) do
    with {:ok, user} <- Accounts.authenticate(email, password),
         {:ok, tokens} <- Guardian.generate_tokens(user) do
      json(conn, %{data: %{user: render_user(user), tokens: tokens}})
    else
      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "invalid_credentials", message: "Invalid email or password"})

      {:error, :account_deactivated} ->
        conn |> put_status(:forbidden) |> json(%{error: "account_deactivated"})
    end
  end

  # POST /api/v1/auth/refresh
  def refresh(conn, %{"refresh_token" => token}) do
    with {:ok, tokens} <- Guardian.refresh_access_token(token) do
      json(conn, %{data: tokens})
    else
      _ ->
        conn |> put_status(:unauthorized) |> json(%{error: "invalid_refresh_token"})
    end
  end

  # POST /api/v1/auth/google
  def google_oauth(conn, %{"id_token" => _id_token} = params) do
    # Verify Google ID token → extract profile
    with {:ok, profile} <- verify_google_token(params["id_token"]),
         {:ok, user} <- Accounts.upsert_google_user(profile),
         {:ok, tokens} <- Guardian.generate_tokens(user) do
      json(conn, %{data: %{user: render_user(user), tokens: tokens}})
    end
  end

  # POST /api/v1/auth/forgot-password
  def forgot_password(conn, %{"email" => email}) do
    # Always returns 200 to prevent email enumeration
    Accounts.request_password_reset(email)
    json(conn, %{message: "If that email is registered, a reset link has been sent"})
  end

  # POST /api/v1/auth/reset-password
  def reset_password(conn, %{"token" => token, "password" => pw, "password_confirmation" => _pwc}) do
    with {:ok, _user} <- Accounts.reset_password(token, pw) do
      json(conn, %{message: "Password updated successfully"})
    else
      {:error, :invalid_or_expired_token} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid_or_expired_token"})
    end
  end

  # GET /api/v1/auth/verify-email/:token
  def verify_email(conn, %{"token" => token}) do
    with {:ok, _user} <- Accounts.verify_email(token) do
      json(conn, %{message: "Email verified successfully"})
    end
  end

  # ── Private ───────────────────────────────────────────────────

  defp render_user(user) do
    %{
      id: user.id,
      email: user.email,
      name: user.name,
      avatar_url: user.avatar_url,
      role: user.role,
      subscription_tier: user.subscription_tier,
      taste_survey_done: user.taste_survey_done,
      goal_type: user.goal_type,
      dietary_flags: user.dietary_flags,
      email_verified: user.email_verified
    }
  end

  defp verify_google_token(id_token) do
    # Call Google tokeninfo endpoint
    case Req.get("https://oauth2.googleapis.com/tokeninfo?id_token=#{id_token}") do
      {:ok, %{status: 200, body: body}} ->
        {:ok,
         %{
           email: body["email"],
           name: body["name"],
           google_uid: body["sub"],
           avatar_url: body["picture"]
         }}

      _ ->
        {:error, :invalid_google_token}
    end
  end
end
