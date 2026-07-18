defmodule CaramelKitchen.MealPlans.Supervisor do
  use Supervisor
  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    children = [
      {Task.Supervisor, name: CaramelKitchen.MealPlans.TaskSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
