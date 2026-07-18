defmodule CaramelKitchen.MealPlans.MealPlan do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "meal_plans" do
    belongs_to :user, CaramelKitchen.Accounts.User

    field :goal_type, :string
    field :name, :string
    field :week_start, :date
    field :week_end, :date
    field :calorie_target, :integer
    field :macro_split, :map, default: %{}
    field :days, {:array, :map}, default: []
    field :is_ai_generated, :boolean, default: true
    field :ai_model, :string
    field :is_active, :boolean, default: true

    timestamps(type: :utc_datetime)
  end
end
