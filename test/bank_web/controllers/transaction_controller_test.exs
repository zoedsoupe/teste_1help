defmodule BankWeb.TransactionControllerTest do
  use BankWeb.ConnCase, async: true

  use Bank.Documenting

  import Bank.Factory

  alias Bank.Accounts

  default_descriptions(%{
    sender_id: "The sender's unique identification",
    recipient_id: "The recipient's unique identification",
    transaction_id: "The transaction's unique identification",
    amount: "How much will be transferred"
  })

  doc_field_transformations(%{sender_id: "UUID", recipient_id: "UUID", amount: "865.89"})

  describe "transactions" do
    @valid_attrs %{
      amount: 12.21
    }

    @invalid_attrs %{
      amount: nil
    }

    @tag auth: true
    test "POST /transactions with valid data creates a transaction", ctx do
      [sender, recipient] = insert_list(2, :user, confirmed?: true, balance: 50_000)

      valid_attrs = %{sender_id: sender.id, recipient_id: recipient.id} |> Enum.into(@valid_attrs)

      conn =
        post(ctx.conn, "/api/v1/transactions", valid_attrs)
        |> doc("Creates a new Transaction between two accounts",
          on_nil: [sender_id: :error, recipient_id: :error, amount: :error]
        )

      %{"message" => message, "data" => transaction} =
        conn |> Map.get(:resp_body) |> Jason.decode!()

      %{balance: sender_balance} = Accounts.get_user!(sender.id)
      %{balance: recipient_balance} = Accounts.get_user!(recipient.id)

      transaction_value = round(@valid_attrs.amount * 100)

      assert conn.status == 201

      assert sender_balance == sender.balance - transaction_value
      assert recipient_balance == recipient.balance + transaction_value

      assert message == "transferred"
      assert transaction["sender_id"] == sender.id
      assert transaction["recipient_id"] == recipient.id
    end

    @tag auth: true
    test "POST /transactions without balance returns error", ctx do
      [sender, recipient] = insert_list(2, :user, confirmed?: true, balance: 0)

      valid_attrs = %{sender_id: sender.id, recipient_id: recipient.id} |> Enum.into(@valid_attrs)

      conn = post(ctx.conn, "/api/v1/transactions", valid_attrs)

      %{"message" => message} = conn |> get_resp_body()

      assert conn.status == 422
      assert message == "insufficient_balance"
    end

    @tag auth: true
    test "POST /transactions with unconfirmed users returns error", ctx do
      [sender, recipient] = insert_list(2, :user)

      valid_attrs = %{sender_id: sender.id, recipient_id: recipient.id} |> Enum.into(@valid_attrs)

      conn = post(ctx.conn, "/api/v1/transactions", valid_attrs)

      %{"message" => message} = conn |> Map.get(:resp_body) |> Jason.decode!()

      assert conn.status == 401
      assert message == "sender_or_recipient_account_not_confirmed"
    end

    @tag auth: true
    test "POST /transactions with invalid data returns error changeset", ctx do
      [sender, recipient] = insert_list(2, :user, confirmed?: true, balance: 50_000)

      conn =
        post(
          ctx.conn,
          "/api/v1/transactions",
          @invalid_attrs |> Enum.into(%{sender_id: sender.id, recipient_id: recipient.id})
        )

      %{"details" => details} = conn |> get_resp_body()

      assert conn.status == 422
      assert details["amount"] == ["can't be blank"]
    end

    @tag auth: true
    test "GET /transactions/:transaction_id returns existing transaction", ctx do
      [sender, recipient] = insert_list(2, :user, confirmed?: true)

      transaction = insert(:transaction, sender_id: sender.id, recipient_id: recipient.id)

      conn =
        ctx.conn
        |> get("/api/v1/transactions/#{transaction.id}")
        |> doc("Get information about existing transaction", on_nil: [transaction_id: :error])

      %{"message" => message, "data" => found_transaction} = conn |> get_resp_body()

      assert conn.status == 200

      assert message == "found"
      assert found_transaction["sender_id"] == sender.id
      assert found_transaction["recipient_id"] == recipient.id
    end

    @tag auth: true
    test "GET /transactions returns all transactions given a initial and a final date",
         ctx do
      insert_list(14, :transaction, processing_date: ~N|2018-02-01 12:12:12|)
      insert_list(10, :transaction, processing_date: ~N|2022-02-01 12:12:12|)

      transactions =
        insert_list(3, :transaction, processing_date: ~N|2020-03-04 12:12:12|) ++
          insert_list(5, :transaction, processing_date: ~N|2021-01-01 12:12:12|)

      conn =
        ctx.conn
        |> get("/api/v1/transactions", %{
          initial_date: "2020-02-01T12:12:12",
          final_date: "2021-02-01T12:12:12"
        })
        |> doc("List all transactions of logged in user given a intial and final date")

      %{"message" => message, "data" => found_transactions} = conn |> get_resp_body()

      assert conn.status == 200
      assert message == "ok"
      assert is_list(found_transactions)
      assert length(found_transactions) == length(transactions)
    end

    @tag auth: true
    test "DELETE /transactions/:transaction_id chargesback a transaction", ctx do
      [sender, recipient] = insert_list(2, :user, confirmed?: true, balance: 50_000)

      valid_attrs = %{sender_id: sender.id, recipient_id: recipient.id} |> Enum.into(@valid_attrs)

      %{"data" => transaction} =
        ctx.conn
        |> post("/api/v1/transactions", valid_attrs)
        |> get_resp_body()

      conn =
        ctx.conn
        |> delete("/api/v1/transactions/#{transaction["id"]}")
        |> doc("Chargesback a transaction", on_nil: [transaction_id: :error])

      %{"message" => message} = conn |> get_resp_body()

      %{balance: sender_balance} = Accounts.get_user!(sender.id)
      %{balance: recipient_balance} = Accounts.get_user!(recipient.id)

      assert conn.status == 200

      assert message == "chargebacked"
      assert sender_balance == 50_000
      assert recipient_balance == 50_000
    end
  end
end
