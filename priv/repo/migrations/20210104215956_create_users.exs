defmodule Bank.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :cpf, :string, null: true
      add :cnpj, :string, null: true
      add :email, :string
      add :mobile, :string
      add :first_name, :string
      add :last_name, :string
      add :balance, :integer, default: 0, null: false
      add :confirmed?, :boolean, default: false, null: false
      add :password, :string, virtual: true
      add :password_confirmation, :string, virtual: true
      add :password_hash, :string

      timestamps()
    end

    create unique_index(:users, [:cpf])
    create unique_index(:users, [:cnpj])
    create unique_index(:users, [:email])

    create constraint(:users, :cpf_or_cnpj, check: "(cpf IS NOT NULL) OR (cnpj IS NOT NULL)")
  end
end
