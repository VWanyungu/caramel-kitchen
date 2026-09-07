defmodule CaramelKitchen.Collections.UserCollectionInteraction do
  @moduledoc """
  Schema for tracking user interactions on collections, specifically
  "saved" (collections saved to user's favorites/library) and "favorite".
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_actions ["favorite", "saved"]

  schema "user_collection_interactions" do
    belongs_to :user, CaramelKitchen.Accounts.User
    belongs_to :collection, CaramelKitchen.Collections.Collection

    field :action, :string
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc "List of valid collection interaction actions"
  def valid_actions, do: @valid_actions

  @doc "Changeset for recording a user collection interaction"
  def changeset(interaction, attrs) do
    interaction
    |> cast(attrs, [:user_id, :collection_id, :action, :metadata])
    |> normalize_action()
    |> validate_required([:user_id, :collection_id, :action])
    |> validate_inclusion(:action, @valid_actions)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:collection_id)
    |> unique_constraint([:user_id, :collection_id, :action],
      name: :user_collection_interactions_user_id_collection_id_action_index
    )
  end

  defp normalize_action(changeset) do
    case get_change(changeset, :action) do
      nil ->
        changeset

      action when is_binary(action) ->
        normalized =
          action
          |> String.trim()
          |> String.downcase()
          |> case do
            "favourite" -> "favorite"
            "favourites" -> "favorite"
            "favorites" -> "favorite"
            "save" -> "saved"
            other -> other
          end

        put_change(changeset, :action, normalized)

      _ ->
        changeset
    end
  end
end
