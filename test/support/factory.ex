defmodule Bank.Factory do
    @moduledoc """
  Factory for tests
  """

  use ExMachina.Ecto, repo: Bank.Repo

  alias Bank.Accounts.User

  def user_factory do
    %User{
      first_name: "matheus",
      last_name: "pessanha",
      cpf: sequence(:cpf, &"123.456.789-0#{&1}"),
      email: sequence(:email, &"matheus#{&1}@outlook.com"),
      mobile: sequence(:mobile, &"(22)12345-678#{&1}"),
      password_hash: Argon2.hash_pwd_salt("12345678910")
    } 
  end
end
