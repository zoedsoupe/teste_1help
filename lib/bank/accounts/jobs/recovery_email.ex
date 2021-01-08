defmodule Bank.Accounts.Jobs.RecoveryEmail do
  @moduledoc """
  Sends an email to user that forgot their password
  """
  use Bank.Jobs.Worker, queue: :mailing

  import Bank.Common.Wrapping

  alias Bank.{Accounts, Repo}
  alias Bank.Mailing

  def perform(%{"token" => token}) do
    %{user: user} =
      token
      |> Accounts.get_password_recovery()
      |> ok_unwrap()
      |> Repo.preload(:user)

    %{
      subject: "Recuperação de conta",
      template: "password_recovery",
      assigns: %{token: token},
      to_email: user.email
    }
    |> Mailing.send_single_mail()
  end

  def create_worker(%{token: token}) do
    %{token: token}
    |> __MODULE__.new()
    |> Oban.insert()
  end
end
