defmodule CaramelKitchen.Workers.PublishRecipeWorker do
  @moduledoc "Oban job: publishes a scheduled recipe at the configured time."
  use Oban.Worker,
    queue: :content,
    max_attempts: 3,
    unique: [period: 300, fields: [:args]]

  alias CaramelKitchen.Recipes
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"recipe_id" => id}}) do
    with {:ok, recipe} <- Recipes.get_recipe(id),
         {:ok, _}      <- Recipes.publish_recipe(recipe) do
      Logger.info("Published recipe #{id}")
      :ok
    else
      {:error, :not_found} ->
        Logger.warning("Recipe #{id} not found for publishing")
        {:cancel, "recipe_not_found"}
      {:error, reason} ->
        {:error, reason}
    end
  end
end

defmodule CaramelKitchen.Workers.EngagementWorker do
  @moduledoc "Oban job: increments engagement counters in batch."
  use Oban.Worker, queue: :analytics, max_attempts: 2

  alias CaramelKitchen.Recipes
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"recipe_id" => recipe_id, "action" => action}}) do
    field = action_to_field(action)
    if field do
      Recipes.increment_engagement(recipe_id, field)
    end
    :ok
  end

  defp action_to_field("view"),  do: "view_count"
  defp action_to_field("save"),  do: "save_count"
  defp action_to_field("cook"),  do: "cook_count"
  defp action_to_field(_),       do: nil
end


defmodule CaramelKitchen.Workers.TasteVectorCleanupWorker do
  @moduledoc "Oban cron: re-normalise drift in taste vectors once daily."
  use Oban.Worker, queue: :maintenance, max_attempts: 1

  import Ecto.Query
  alias CaramelKitchen.Repo
  alias CaramelKitchen.Accounts.User

  @impl Oban.Worker
  def perform(_job) do
    # Find users whose taste vectors have extreme values (all near 1 or all near 0)
    users_to_normalise =
      Repo.all(
        from u in User,
        where: not is_nil(u.taste_vector) and u.taste_survey_done == true
      )

    Enum.each(users_to_normalise, fn user ->
      vec = User.taste_vector_list(user)
      normalised = normalise_vector(vec)

      if normalised != vec do
        Repo.update!(User.taste_update_changeset(user, normalised))
      end
    end)

    :ok
  end

  # Soft normalise: pull extreme values back toward 0.5
  defp normalise_vector(vec) do
    Enum.map(vec, fn v ->
      cond do
        v > 0.95 -> v * 0.95
        v < 0.05 -> v + 0.02
        true     -> v
      end
      |> Float.round(4)
    end)
  end
end
