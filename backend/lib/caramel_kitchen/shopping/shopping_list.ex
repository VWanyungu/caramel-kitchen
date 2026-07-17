defmodule CaramelKitchen.Shopping.ShoppingList do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "shopping_lists" do
    belongs_to :user, CaramelKitchen.Accounts.User
    belongs_to :meal_plan, CaramelKitchen.MealPlans.MealPlan

    field :event_menu_id,        :binary_id
    field :name,                 :string
    field :items,                {:array, :map}, default: []
    field :checked_ids,          {:array, :integer}, default: []
    field :share_token,          :string
    field :servings_multiplier,  :float, default: 1.0

    timestamps(type: :utc_datetime)
  end
end
