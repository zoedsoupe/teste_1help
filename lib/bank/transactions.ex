defmodule Bank.Transactions do
  @moduledoc """
  Transactions repository 
  """

  import Ecto.Query, warn: false

  alias Bank.Repo
  alias Bank.Transactions.Transaction

  @doc """
  Returns the list of transactions.

  ## Examples

      iex> list_transactions()
      [%Transaction{}, ...]

  """
  def list_transactions(params \\ []) do
    params
    |> Transaction.get_query()
    |> Repo.all()
  end

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transaction(attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs, [:save_as_integer, :set_process_date])
    |> Repo.insert()
  end

  @doc """
  Deletes a transaction.

  ## Examples

      iex> delete_transaction(transaction)
      {:ok, %Transaction{}}

      iex> delete_transaction(transaction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  @doc """
  Gets a single transaction.

  Raises `Ecto.NoResultsError` if the Transaction does not exist.

  ## Examples

      iex> get_transaction!(123)
      %Transaction{}

      iex> get_transaction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transaction!(id), do: Repo.get!(Transaction, id)

  def get_transaction(id) do
    Repo.get(Transaction, id)
    |> case do
      nil -> {:error, :not_found}
      transaction -> {:ok, transaction}
    end
  end
end
