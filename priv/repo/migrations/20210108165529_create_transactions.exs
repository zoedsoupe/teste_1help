defmodule Bank.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sender_id, :binary_id
      add :recipient_id, :binary_id 
      add :value, :integer
      add :amount, :float, virtual: true
      add :processing_date, :naive_datetime

      timestamps()
    end

    create index(:transactions, [:sender_id, :recipient_id])
  end
end
