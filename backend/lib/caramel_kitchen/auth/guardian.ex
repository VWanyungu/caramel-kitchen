defmodule CaramelKitchen.Auth.Guardian do
  use Guardian, otp_app: :caramel_kitchen

  alias CaramelKitchen.Accounts

  @impl true
  def subject_for_token(%{id: id}, _claims), do: {:ok, to_string(id)}
  def subject_for_token(_, _), do: {:error, :unknown_resource}

  @impl true
  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(id) do
      {:ok, user} -> {:ok, user}
      _ -> {:error, :resource_not_found}
    end
  end

  @doc "Issue access + refresh token pair."
  def generate_tokens(user) do
    {:ok, access_token, _access_claims} =
      encode_and_sign(user, %{}, token_type: "access", ttl: {15, :minute})

    {:ok, refresh_token, _refresh_claims} =
      encode_and_sign(user, %{}, token_type: "refresh", ttl: {30, :day})

    {:ok,
     %{
       access_token: access_token,
       refresh_token: refresh_token,
       expires_in: 15 * 60,
       token_type: "Bearer",
       user_id: user.id,
       role: user.role,
       tier: user.subscription_tier
     }}
  end

  @doc "Refresh access token using refresh token (rotation)."
  def refresh_access_token(refresh_token) do
    with {:ok, %{"sub" => id}} <- decode_and_verify(refresh_token, %{"typ" => "refresh"}),
         {:ok, user} <- Accounts.get_user(id) do
      # Issue a brand new access and refresh token pair
      generate_tokens(user)
    end
  end
end
