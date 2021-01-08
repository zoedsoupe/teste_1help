defmodule Bank.Accounts.Jobs.ConfirmationEmail do
  @moduledoc """
  Sends an email to new users confirm their email address
  """
  use Bank.Jobs.Worker, queue: :mailing

  alias Bank.{Accounts, Repo}
  alias Bank.Mailing

  def perform(%{"id" => id}) do
    user = id |> Accounts.get_user!() |> Repo.preload(:confirmation)

    %{
      subject: "Confirmação de email",
      template: "user_confirmation",
      assigns: %{
        token: user.confirmation.token
      },
      to_email: user.email
    }
    |> Mailing.send_single_mail()
  end
end
