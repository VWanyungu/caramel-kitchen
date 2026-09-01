defmodule CaramelKitchen.Repo.Migrations.AddMpesaToSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :payment_method, :string, default: "stripe"
      add :mpesa_receipt_number, :string
      add :mpesa_phone_number, :string
    end
  end
end
