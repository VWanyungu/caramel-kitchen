defmodule CaramelKitchen.UserRecipeInteraction do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_recipe_interactions" do
    belongs_to :user,   CaramelKitchen.Accounts.User
    belongs_to :recipe, CaramelKitchen.Recipes.Recipe

    field :action,         :string
    field :rating,         :integer
    field :taste_feedback, :map,    default: %{}
    field :metadata,       :map,    default: %{}

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
