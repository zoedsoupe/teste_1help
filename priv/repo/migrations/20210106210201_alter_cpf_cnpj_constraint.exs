defmodule Bank.Repo.Migrations.AlterCpfCnpjConstraint do
  use Ecto.Migration

  def change do
    drop constraint(:users, :cpf_or_cnpj)

    create(
      constraint(:users, :cpf_or_cnpj,
        check: ~s|(cpf is null) and (cnpj is not null) or (cpf is not null) and (cnpj is null)|
      )
    )
  end
end
