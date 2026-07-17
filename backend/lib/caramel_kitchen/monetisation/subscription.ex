defmodule CaramelKitchen.Monetisation.Subscription do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "subscriptions" do
    belongs_to :user, CaramelKitchen.Accounts.User

    field :stripe_customer_id,    :string
    field :stripe_sub_id,         :string
    field :plan,                  :string, default: "free"
    field :status,                :string, default: "active"
    field :trial_ends_at,         :utc_datetime
    field :current_period_start,  :utc_datetime
    field :current_period_end,    :utc_datetime
    field :canceled_at,           :utc_datetime
    field :metadata,              :map, default: %{}

    timestamps(type: :utc_datetime)
  end
end
