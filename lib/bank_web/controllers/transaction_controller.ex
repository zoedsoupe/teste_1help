defmodule BankWeb.TransactionController do
  @moduledoc """
  Manages /transactions context endpoints
  """

  use BankWeb, :controller

  import Bank.Common

  alias Bank.Transactions.Transaction
  alias Bank.{Accounts, Changeset, Transactions}

  action_fallback BankWeb.FallbackController

  @accepts ~w(sender_id recipient_id amount)a
  def create(_conn, params) do
    with {:ok, sender} <- Accounts.get_user(params["sender_id"]),
         %{confirmed?: true} <- sender,
         {:ok, recipient} <- Accounts.get_user(params["recipient_id"]),
         %{confirmed?: true} <- recipient,
         {:ok, transaction} <- Transactions.create_transaction(params),
         {:ok, _sender} <- Accounts.withdraw(sender.id, amount: transaction.value),
         {:ok, _recipient} <- Accounts.deposit(recipient.id, amount: transaction.value) do
      {:ok,
       %{
         data: transaction |> Map.take(Transaction.exposed_fields()),
         message: :transferred
       }}
    else
      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :insufficient_balance} ->
        {:error, :insufficient_balance}

      {:error, changeset} ->
        changeset |> Changeset.default_error_response()

      %{confirmed?: false} ->
        {:error, :sender_or_recipient_account_not_confirmed}
    end
  end

  @accepts ~w(transaction_id)a
  def show(_conn, %{"transaction_id" => transaction_id}) do
    case Transactions.get_transaction(transaction_id) do
      {:ok, transaction} ->
        fields =
          transaction
          |> Map.take(Transaction.exposed_fields())

        response =
          %{data: fields}
          |> Map.put(:message, :found)

        {:ok, response}
    end
  end

  def show(_conn, _params), do: {:error, :no_transaction_id}

  @accepts ~w(processing_date)a
  def list(_conn, params) do
    transactions =
      params
      |> map_to_keyword()
      |> Transactions.list_transactions()
      |> Enum.map(&Map.take(&1, Transaction.exposed_fields()))

    response =
      %{data: transactions}
      |> Map.put(:message, :ok)

    {:ok, response}
  end

  @accepts ~w(transaction_id)a
  def delete(_conn, params) do
    with {:ok, transaction} <- Transactions.get_transaction(params["transaction_id"]),
         {:ok, transaction} <- Transactions.delete_transaction(transaction),
         {:ok, _sender} <- Accounts.deposit(transaction.sender_id, amount: transaction.value),
         {:ok, _recipient} <-
           Accounts.withdraw(transaction.recipient_id, amount: transaction.value) do
      {:ok, %{message: :chargebacked}}
    else
      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :insufficient_balance} ->
        {:error, :insufficient_balance}

      {:error, changeset} ->
        changeset |> Changeset.default_error_response()
    end
  end
end
