# Appended to accounts.ex as a patch module — merged into Accounts context
defmodule CaramelKitchen.Accounts.TierUpdater do
  @moduledoc false
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Accounts.User

  def update_user_tier(%User{} = user, tier) when tier in ~w(free premium creator_pro) do
    user
    |> User.subscription_changeset(tier)
    |> Repo.update()
  end
end
