defmodule Bank.Repo.Migrations.CreateUserPassRecoveries do
  use Ecto.Migration

  def change do
    create table(:user_pass_recoveries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :string
      add :used?, :boolean, default: false, null: false
      add :expiration, :naive_datetime
      add :user_id, references(:user, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:user_pass_recoveries, [:user_id])
  end
end
