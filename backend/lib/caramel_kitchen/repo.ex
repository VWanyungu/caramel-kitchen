defmodule CaramelKitchen.Repo do
  use Ecto.Repo,
    otp_app: :caramel_kitchen,
    adapter: Ecto.Adapters.Postgres

  Postgrex.Types.define(
    CaramelKitchen.PostgresTypes,
    [Pgvector.Extensions.Vector] ++ Ecto.Adapters.Postgres.extensions(),
    []
  )

  use Paginator

  @doc """
  Wraps a function in a transaction and pipes error tuples cleanly.
  """
  def run_transaction(fun) do
    transaction(fn repo ->
      case fun.(repo) do
        {:ok, result} -> result
        {:error, reason} -> rollback(reason)
        result -> result
      end
    end)
  end

  @doc """
  Safely fetch one record; returns {:ok, record} | {:error, :not_found}
  """
  def fetch(queryable, opts \\ []) do
    case one(queryable, opts) do
      nil -> {:error, :not_found}
      record -> {:ok, record}
    end
  end
end
