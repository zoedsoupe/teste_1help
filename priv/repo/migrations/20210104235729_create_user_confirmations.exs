defmodule Bank.Repo.Migrations.CreateUserConfirmations do
  use Ecto.Migration

  def change do
    create table(:user_confirmations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :string
      add :used?, :boolean, default: false, null: false
      add :user_id, references(:user, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:user_confirmations, [:user_id])
  end
end
