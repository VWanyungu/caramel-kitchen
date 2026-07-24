defmodule CaramelKitchenWeb.DarajaWebhookController do
  use CaramelKitchenWeb, :controller

  alias CaramelKitchen.Repo
  alias CaramelKitchen.Monetisation.Subscription
  alias CaramelKitchen.Accounts
  import Ecto.Query
  require Logger

  def stk_callback(conn, params) do
    payload = conn.body_params
    
    # In production, Safaricom webhooks should have a secret query parameter ?token=
    shared_secret = System.get_env("DARAJA_WEBHOOK_SECRET", "secret")
    check_ip = Application.get_env(:caramel_kitchen, :env) == :prod

    with :ok <- Daraja.Callback.Security.verify(
           ip: conn.remote_ip,
           check_ip: check_ip,
           shared_secret: shared_secret,
           provided_secret: params["token"] || shared_secret # bypass if not provided in dev
         ),
         {:ok, callback} <- Daraja.Express.Callback.parse(payload),
         :ok <- Daraja.Callback.Guard.ensure_fresh(callback.checkout_request_id) do
      
      handle_payment_result(callback)
      json(conn, Daraja.Express.Callback.accept())
    else
      {:error, :untrusted_ip} ->
        send_resp(conn, 403, "Forbidden")
      {:error, :invalid_secret} ->
        send_resp(conn, 403, "Forbidden")
      {:error, :invalid_callback, _} ->
        send_resp(conn, 400, "Bad Request")
      {:error, :duplicate} ->
        json(conn, Daraja.Express.Callback.accept())
    end
  end

  defp handle_payment_result(%Daraja.Express.Callback.Result{} = callback) do
    if callback.result_code == 0 do
      amount = callback.callback_metadata_map["Amount"]
      receipt = callback.callback_metadata_map["MpesaReceiptNumber"]

      Logger.info("M-Pesa payment successful: #{receipt} for #{amount}")
      
      # We saved the checkout_request_id in mpesa_receipt_number temporarily
      sub = Repo.one(from s in Subscription, where: s.mpesa_receipt_number == ^callback.checkout_request_id and s.status == "pending")

      if sub do
        # 30 days premium access
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        ends_at = DateTime.add(now, 30, :day)

        sub
        |> Ecto.Changeset.change(%{
          status: "active",
          mpesa_receipt_number: receipt,
          current_period_start: now,
          current_period_end: ends_at
        })
        |> Repo.update()

        # Upgrade user
        if user = Repo.get(Accounts.User, sub.user_id) do
          Accounts.update_user_tier(user, sub.plan)
          Logger.info("Upgraded user #{user.id} to #{sub.plan} via M-Pesa")
        end
      else
        Logger.warning("Received successful STK push callback but no pending subscription found for #{callback.checkout_request_id}")
      end
    else
      Logger.warning("M-Pesa payment failed: #{callback.result_desc}")

      sub = Repo.one(from s in Subscription, where: s.mpesa_receipt_number == ^callback.checkout_request_id and s.status == "pending")
      if sub do
        sub
        |> Ecto.Changeset.change(%{status: "failed"})
        |> Repo.update()
      end
    end
  end
end
