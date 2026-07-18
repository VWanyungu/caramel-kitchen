defmodule CaramelKitchen.Accounts do
  @moduledoc """
  Accounts context — user registration, authentication, profile management.
  All public functions return {:ok, result} | {:error, reason}.
  """

  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Accounts.User
  alias CaramelKitchen.Workers.SendEmailWorker
  alias CaramelKitchen.Cache

  require Logger

  # ── Registration ──────────────────────────────────────────────

  @doc "Register a new user with email + password."
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> tap_ok(&send_verification_email/1)
  end

  @doc "Register or sign in via Google OAuth."
  def upsert_google_user(%{email: email, google_uid: uid} = attrs) do
    case Repo.one(from u in User, where: u.email == ^email or u.google_uid == ^uid) do
      nil ->
        %User{}
        |> User.google_registration_changeset(attrs)
        |> Repo.insert()

      user ->
        user
        |> User.google_registration_changeset(Map.take(attrs, [:google_uid, :avatar_url]))
        |> Repo.update()
    end
  end

  # ── Authentication ────────────────────────────────────────────

  @doc "Authenticate user by email/password. Returns {:ok, user} or {:error, :invalid_credentials}."
  def authenticate(email, password) when is_binary(email) and is_binary(password) do
    user = Repo.one(from u in User, where: u.email == ^String.downcase(email))

    cond do
      is_nil(user) ->
        # Run bcrypt to prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      not User.active?(user) ->
        {:error, :account_deactivated}

      not Bcrypt.verify_pass(password, user.password_hash) ->
        {:error, :invalid_credentials}

      true ->
        {:ok, _} = Repo.update(User.sign_in_changeset(user))
        {:ok, user}
    end
  end

  # ── User Queries ──────────────────────────────────────────────

  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id) do
    case Repo.get(User, id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def get_user_by_email(email) do
    Repo.fetch(from u in User, where: u.email == ^String.downcase(email))
  end

  def list_users(opts \\ []) do
    User
    |> apply_user_filters(opts)
    |> order_by([u], desc: u.inserted_at)
    |> Repo.all()
  end

  # ── Profile ───────────────────────────────────────────────────

  def update_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
    |> tap_ok(&Cache.invalidate_user/1)
  end

  # ── Taste ─────────────────────────────────────────────────────

  @doc """
  Submit taste survey results. Converts 1-5 scores into a normalised 0.0-1.0 vector.
  survey_responses: [%{taste: "spicy", score: 4}, ...]
  """
  def submit_taste_survey(%User{} = user, survey_responses) when is_list(survey_responses) do
    vector =
      User.taste_dimensions()
      |> Enum.map(fn dim ->
        case Enum.find(survey_responses, &(to_string(&1.taste) == dim)) do
          nil -> 0.5
          %{score: s} -> normalise_score(s)
        end
      end)

    user
    |> User.taste_survey_changeset(vector)
    |> Repo.update()
    |> tap_ok(&Cache.invalidate_user_feed/1)
  end

  @doc """
  Apply a delta to the user's taste vector based on an interaction.
  action: :saved | :cooked | :skipped | :rated_5 | :rated_1
  recipe_taste_profile: list of 8 floats
  """
  def update_taste_vector(%User{} = user, recipe_taste_profile, action) do
    delta = taste_delta(action)
    current = User.taste_vector_list(user)

    updated =
      current
      |> Enum.zip(recipe_taste_profile)
      |> Enum.map(fn {u_val, r_val} ->
        Float.round(clamp(u_val + delta * r_val, 0.0, 1.0), 4)
      end)

    user
    |> User.taste_update_changeset(updated)
    |> Repo.update()
    |> tap_ok(&Cache.invalidate_user_feed/1)
  end

  # ── Email Verification ────────────────────────────────────────

  def verify_email(token) when is_binary(token) do
    with {:ok, user} <- Repo.fetch(from u in User, where: u.email_verify_token == ^token) do
      user
      |> User.verify_email_changeset()
      |> Repo.update()
    end
  end

  def request_password_reset(email) do
    with {:ok, user} <- get_user_by_email(email) do
      token = generate_secure_token()
      expires_at = DateTime.add(DateTime.utc_now(), 3600, :second) |> DateTime.truncate(:second)

      user
      |> Ecto.Changeset.change(%{password_reset_token: token, password_reset_at: expires_at})
      |> Repo.update()
      |> tap_ok(&send_password_reset_email(&1, token))
    end
  end

  def reset_password(token, new_password) do
    now = DateTime.utc_now()

    with {:ok, user} <-
           Repo.fetch(
             from u in User,
               where: u.password_reset_token == ^token and u.password_reset_at > ^now
           ) do
      user
      |> User.password_reset_changeset(new_password)
      |> Repo.update()
    else
      {:error, :not_found} -> {:error, :invalid_or_expired_token}
    end
  end

  # ── Admin ─────────────────────────────────────────────────────

  def update_user_role(%User{} = user, role) when role in ~w(user creator admin) do
    user
    |> Ecto.Changeset.change(%{role: role})
    |> Repo.update()
  end

  def deactivate_user(%User{} = user, reason \\ nil) do
    user
    |> Ecto.Changeset.change(%{
      deactivated_at: DateTime.utc_now() |> DateTime.truncate(:second),
      deactivation_reason: reason
    })
    |> Repo.update()
  end

  # ── Private Helpers ───────────────────────────────────────────

  defp apply_user_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:role, role}, q -> where(q, [u], u.role == ^role)
      {:tier, tier}, q -> where(q, [u], u.subscription_tier == ^tier)
      {:active, true}, q -> where(q, [u], is_nil(u.deactivated_at))
      _, q -> q
    end)
  end

  defp normalise_score(score) when score in 1..5 do
    Float.round((score - 1) / 4.0, 2)
  end

  defp normalise_score(_), do: 0.5

  defp taste_delta(:cooked), do: 0.10
  defp taste_delta(:saved), do: 0.07
  defp taste_delta(:skipped), do: -0.05
  defp taste_delta(:rated_5), do: 0.15
  defp taste_delta(:rated_1), do: -0.10
  defp taste_delta(_), do: 0.0

  defp clamp(val, min, max), do: val |> max(min) |> min(max)

  defp generate_secure_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  defp send_verification_email(user) do
    token = generate_secure_token()
    Repo.update!(Ecto.Changeset.change(user, %{email_verify_token: token}))

    SendEmailWorker.new(%{type: "verify_email", user_id: user.id, token: token})
    |> Oban.insert()
  end

  defp send_password_reset_email(user, token) do
    SendEmailWorker.new(%{type: "password_reset", user_id: user.id, token: token})
    |> Oban.insert()
  end

  defp tap_ok({:ok, val} = result, fun) do
    fun.(val)
    result
  end

  defp tap_ok(result, _fun), do: result

  # Called by Monetisation on Stripe events
  def update_user_tier(%User{} = user, tier) do
    CaramelKitchen.Accounts.TierUpdater.update_user_tier(user, tier)
  end
end
