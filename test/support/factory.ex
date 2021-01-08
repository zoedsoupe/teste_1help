defmodule Bank.Factory do
  @moduledoc """
  Factory for tests
  """

  use ExMachina.Ecto, repo: Bank.Repo

  import Bank.Schema, only: [gen_token: 0]
  import Ecto.UUID, only: [bingenerate: 0]

  alias Bank.Accounts.User
  alias Bank.Accounts.UserConfirmation, as: Confirmation
  alias Bank.Accounts.UserPassRecovery, as: PassRecovery
  alias Bank.Transactions.Transaction

  def user_factory do
    %User{
      first_name: "matheus",
      last_name: "pessanha",
      cpf: sequence(:cpf, &"123.456.789-0#{&1}"),
      email: sequence(:email, &"matheus#{&1}@outlook.com"),
      mobile: sequence(:mobile, &"(22)12345-678#{&1}"),
      password_hash: Argon2.hash_pwd_salt("12345678910"),
      confirmation: build(:confirmation),
      pass_recovery: build(:pass_recovery)
    }
  end

  def confirmation_factory do
    %Confirmation{
      token: gen_token(),
      used?: false
    }
  end

  def pass_recovery_factory do
    %PassRecovery{
      token: gen_token(),
      used?: false,
      expiration: ~N|2090-09-12 12:12:12|
    }
  end

  def transaction_factory do
    %Transaction{
      sender_id: bingenerate(),
      recipient_id: bingenerate(),
      amount: 43.2,
      processing_date: ~N|2021-02-12 12:12:12|
    }
  end
end
