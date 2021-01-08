defmodule Bank.Repo.Migrations.AddNewPasswordUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :new_password, :string, virtual: true
      add :new_password_confirmation, :string, virtual: true
    end
  end
end
