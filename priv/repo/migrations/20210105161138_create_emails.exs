defmodule Bank.Repo.Migrations.CreateEmails do
  use Ecto.Migration

  def change do
    create table(:emails, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :subject, :string
      add :template, :string
      add :assigns, :map
      add :from_email, :string
      add :from_name, :string
      add :to_email, :string
      add :bcc, :map
      add :message, :string
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:emails, [:user_id])
    create index(:emails, [:subject])
    create index(:emails, [:template])
    create index(:emails, [:to_email])
    create index(:emails, [:from_email])
    create index(:emails, [:from_name])
    create index(:emails, [:inserted_at])
  end
end
