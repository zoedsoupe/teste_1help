defmodule Bank.Accounts.Jobs.WelcomeEmail do
  @moduledoc """
  Sends an email to new users confirm their email address
  """
  use Bank.Jobs.Worker, queue: :mailing

  alias Bank.Accounts
  alias Bank.Mailing

  def perform(%{"id" => id}) do
    user = id |> Accounts.get_user!()

    %{
      subject: "Seja bem vindo!",
      template: "welcome",
      assigns: %{
        name: ~s|user.first_name user.last_name|
      },
      to_email: user.email
    }
    |> Mailing.send_single_mail()
  end
end
