defmodule CaramelKitchen.Accounts.Helpers do
  @moduledoc "Additional account helpers used by Monetisation and SuperAdmin."

  alias CaramelKitchen.Repo
  alias CaramelKitchen.Accounts.User

  @doc "Update subscription tier — called from Monetisation on Stripe events."
  def update_user_tier(%User{} = user, tier) when tier in ~w(free premium creator_pro) do
    user
    |> User.subscription_changeset(tier)
    |> Repo.update()
  end
end
