defmodule Bank.TransactionsTest do
  use Bank.DataCase, async: true

  import Bank.Factory

  alias Bank.Transactions
  alias Bank.Transactions.Transaction

  describe "transactions" do
    @valid_attrs %{
      amount: 12.21,
      processing_date: ~N|2021-02-12 13:13:13|
    }

    @invalid_attrs %{
      sender_id: nil,
      recipient_id: nil,
      amount: nil,
      processing_date: nil
    }

    test "list_transactions/0 returns all transactions" do
      [sender, recipient] = insert_list(2, :user, confirmed?: true)

      transactions =
        insert_list(5, :transaction, sender_id: sender.id, recipient_id: recipient.id)

      found_transactions = Transactions.list_transactions()

      assert is_list(found_transactions)
      assert length(transactions) == length(found_transactions)
    end

    test "get_user!/1 returns the transaction with given id" do
      [sender, recipient] = insert_list(2, :user, confirmed?: true)

      transaction = insert(:transaction, sender_id: sender.id, recipient_id: recipient.id)

      found_transaction = Transactions.get_transaction!(transaction.id)

      assert found_transaction.sender_id == transaction.sender_id
      assert found_transaction.recipient_id == transaction.recipient_id
      assert found_transaction.value == transaction.value
      assert found_transaction.processing_date == transaction.processing_date
    end

    test "create_transaction/1 with valid data creates a transaction" do
      [sender, recipient] = insert_list(2, :user, confirmed?: true)

      assert {:ok, %Transaction{} = transaction} =
               %{sender_id: sender.id, recipient_id: recipient.id}
               |> Enum.into(@valid_attrs)
               |> Transactions.create_transaction()

      assert transaction.sender_id == sender.id
      assert transaction.recipient_id == recipient.id
      assert transaction.value == round(@valid_attrs.amount * 100)
      assert transaction.processing_date == @valid_attrs.processing_date
    end

    test "create_transaction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Transactions.create_transaction(@invalid_attrs)
    end

    test "delete_transaction/1 deletes the transaction" do
      [sender, recipient] = insert_list(2, :user, confirmed?: true)

      transaction = insert(:transaction, sender_id: sender.id, recipient_id: recipient.id)

      assert {:ok, %Transaction{}} = Transactions.delete_transaction(transaction)
      assert_raise Ecto.NoResultsError, fn -> Transactions.get_transaction!(transaction.id) end
    end
  end
end
