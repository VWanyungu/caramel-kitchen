defmodule CaramelKitchen.Workers.SendEmailWorker do
  @moduledoc "Oban worker: sends transactional emails via Swoosh."
  use Oban.Worker, queue: :email, max_attempts: 5

  alias CaramelKitchen.{Accounts, Emails, Mailer}
  import Ecto.Query
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => type} = args}) do
    with {:ok, user} <- Accounts.get_user(args["user_id"] || "") do
      dispatch(type, user, args)
    else
      {:error, :not_found} ->
        Logger.warning("SendEmailWorker: user #{args["user_id"]} not found, skipping")
        {:cancel, "user_not_found"}
    end
  end

  defp dispatch("verify_email", user, %{"token" => token}) do
    user |> Emails.verify_email(token) |> deliver()
  end

  defp dispatch("password_reset", user, %{"token" => token}) do
    user |> Emails.password_reset(token) |> deliver()
  end

  defp dispatch("welcome", user, _args) do
    user |> Emails.welcome() |> deliver()
  end

  defp dispatch("subscription_confirmed", user, %{"plan" => plan}) do
    user |> Emails.subscription_confirmed(plan) |> deliver()
  end

  defp dispatch("payment_failed", user, _args) do
    user |> Emails.payment_failed() |> deliver()
  end

  defp dispatch("plan_reminder", user, %{"plan_id" => plan_id}) do
    with {:ok, plan} <- CaramelKitchen.Repo.fetch(
           from p in CaramelKitchen.MealPlans.MealPlan, where: p.id == ^plan_id
         ) do
      user |> Emails.meal_plan_reminder(plan) |> deliver()
    else
      _ ->
        Logger.warning("plan_reminder: plan #{plan_id} not found")
        :ok
    end
  end

  defp dispatch(type, _user, _args) do
    Logger.warning("SendEmailWorker: unknown email type '#{type}'")
    :ok
  end

  defp deliver(email) do
    case Mailer.deliver(email) do
      {:ok, _}     -> :ok
      {:error, r}  ->
        Logger.error("Email delivery failed: #{inspect(r)}")
        {:error, r}
    end
  end
end
