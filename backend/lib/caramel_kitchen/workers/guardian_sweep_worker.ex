defmodule CaramelKitchen.Workers.GuardianSweepWorker do
  @moduledoc "Oban cron: removes expired JWT tokens from guardian_tokens table."
  use Oban.Worker, queue: :maintenance, max_attempts: 1

  import Ecto.Query
  alias CaramelKitchen.Repo
  require Logger

  @impl Oban.Worker
  def perform(_job) do
    now = System.system_time(:second)

    {count, _} =
      from(t in "guardian_tokens", where: t.exp < ^now)
      |> Repo.delete_all()

    Logger.info("GuardianSweep: removed #{count} expired tokens")
    :ok
  end
end
